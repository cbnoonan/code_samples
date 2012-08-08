<?php

/**
 * Payment File Engine
 *
 * @package Davis
 */
class Davis_Payment_PaymentEngine {
   
   /**
    * @var Merc_Log
    */
   private $logger;
   
   /**
    * @var Davis_Vendor_CreditDebit
    */
   private $creditDebitService;
   
   /**
    * @var Merc_DAO_Davis_OrderLineDao
    */
   private $orderLineDao;
   
   /**
    * @var Merc_DAO_Davis_VendorPaymentDao
    */
   private $vendorPaymentDao;
   
   /**
    * @var Merc_DAO_Davis_PurchaseOrderDao
    */
   private $purchaseOrderDao;
   
   /**
    * @var Merc_DAO_Davis_OrderLineVendorDiscountDao
    */
   private $orderLineVendorDiscountDao;
   
   /**
    * @var Merc_DAO_Davis_VendorAddressDao
    */
   private $vendorAddressDao;
   
   /**
    * @var Merc_DAO_Davis_VendorDao
    */
   private $vendorDao;
   
   /**
    * @var Davis_PurchaseOrder
    */
   private $purchaseOrderService;
   
   /**
    * @var Merc_TransactionManager
    */
   private $transactionManager;
   
   /**
    * @var Davis_Payment_Generator_Factory
    */
   private $paymentFactory;

   /**
    * @var Davis_Payment_Abstract
    */
   private $paymentGenerator;
   
   /**
    * @var Merc_DAO_Davis_SequenceDao
    */
   private $sequenceDao;
   
   /**
    * @var Davis_EventPublisher
    */
   private $eventPublisher;
   
   /**
    * @var Merc_DAO_Davis_VendorPaymentOrderLineMapDao
    */
   private $vendorPaymentOrderLineMapDao;
   
   /**
    * @var Merc_DAO_Davis_ShipmentDao
    */
   private $shipmentDao;
   
   /**
    * @var Merc_DAO_Davis_ChangeProposalDao
    */
   private $changeProposalDao;
   
   /**
    * @var int
    */
   private $fileId;

   /*
    * @var string
    */
   private $data;
   
   /*
    * @var Merc_DAO_Davis_OrderLineOptionDao
    */
   private $orderLineOptionDao;
   
   /*
    * @var Davis_Vendor
    */
   private $vendorService;
   
   /*
    * @var Davis_Ship_Shipment
    */
   private $shipmentService;
   
   private $paymentConfig;
   
   private $payables = array();
   private $allPayableOrderLines = array();
   private $purchaseOrders = array();
   
   // Time it takes ACH to deliver payment to Vendor
   const DAYS_PAID_BEFORE_TERMS_EXPIRE_ACH = 1;
   const DAYS_PAID_BEFORE_TERMS_EXPIRE_CHECK = 1;
   const PERCENT_CLOSE_TO_CREDIT_LIMIT = '.10';
   const PERCENT_REMAIN_ON_CREDIT = .75;
   const EARLY_DISCOUNT_BUFFER = 2;

   /**
    * ctor.
    */
   function __construct() {
      $this->logger = Merc_Registry::get('loggerPay');
            
      $this->orderLineDao = Merc_Registry::get('orderLineDao');
      $this->vendorPaymentDao = Merc_Registry::get('vendorPaymentDao');
      $this->purchaseOrderDao = Merc_Registry::get('purchaseOrderDao');
      $this->orderLineVendorDiscountDao = Merc_Registry::get('orderLineVendorDiscountDao');
      $this->vendorAddressDao = Merc_Registry::get('vendorAddressDao');
      $this->vendorDao = Merc_Registry::get('vendorDao');
      $this->purchaseOrderService = Merc_Registry::get('purchaseOrderService');
      $this->transactionManager = Merc_Registry::get('transactionManager');
      $this->paymentFactory = Merc_Registry::get('paymentFactory');
      $this->paymentConfig = Merc_Registry::get('configAppIni')->payment;
      $this->orderLineOptionDao = Merc_Registry::get('orderLineOptionDao');
      $this->shipmentDao = Merc_Registry::get('shipmentDao');
      $this->changeProposalDao = Merc_Registry::get('changeProposalDao');
      $this->eventPublisher = Merc_Registry::get('eventPublisher');
      $this->sequenceDao = Merc_Registry::get('sequenceDao');
      $this->vendorPaymentOrderLineMapDao = Merc_Registry::get('vendorPaymentOrderLineMapDao');
      $this->shipmentService = Merc_Registry::get('shipmentService');
      $this->creditDebitService = Merc_Registry::get('creditDebitService');
      $this->vendorService = Merc_Registry::get('vendorService');
   }

   /**
    * Main Vendor Payment method.
    * Processes all the Order Payments (that have not yet been paid)
    * Sends them to a Payment Generator to create a file for the bank
    * Creates Events for the Queue
    *
    * TODO -- possible refactor to use DAO methods to grab everything at once,
    * instead of just orderlines. (this will eliminate the "caching" )
    */
   public function createVendorPayments() {
      $this->logger->mlog('Begin createVendorPayments()', Zend_Log::INFO, $this);
      
      // reset payables
      $this->payables = array();
      // start timer
      $beginTime = time();
        
      try {
    	    $this->transactionManager->beginTransaction();
    	    // passing empty vendorIdArray will retrieve for all vendors
          $orderLines = $this->orderLineDao->getForPaymentEngineByVendor(array());

          if ($orderLines) {
             $this->logger->mlog('COUNT ORDERLINES: ' . count($orderLines), Zend_Log::DEBUG, $this);
             // determine which orderLines need to be paid and add to payables array
             $this->createVendorPaymentsFromOrderLines($orderLines);
       
     	       if (count($this->payables) > 0) {
               $this->attachOptions();
	            $this->processCreditLimitPayments();
	          }
          }
          
          // we now have all the things we *should* be paying based on our vendor
          // agreements. However, we may want to adjust based on credits, debits,
          // and rebates. So, let's augment as needed.
          $this->processCreditsDebits();
       
          // both processCreditLimitPayments() and processCreditsDebits can add/prune payables, so test again.
          if (count($this->payables) > 0) {
          	
              // get the generator...
             /* @var $this->paymentGenerator Davis_Payment_Generator_Abstract */
	          $this->paymentGenerator = $this->paymentFactory->getPaymentFactory($this->paymentConfig->bank);
	           
              // create the File
	          $this->data = $this->paymentGenerator->generate($this->payables);

	           // grab the next fileId from the sequence and set
	           $this->fileId = $this->sequenceDao->nextVal(Merc_DAO_Davis_SequenceDao::SEQUENCE_PAYMENT_FILE);
	           foreach ($this->payables as $payment) {
	              $payment->setFileId($this->fileId);
	           }
	           
	           // insert/update data into db
	           $this->insertPaymentDataIntoDatabase();
	          
	           // do a db commit BEFORE Sending Emails
	           $this->transactionManager->commit();
	            
	           // publish events post-commit
	          
	           //  $this->publishAchEvent();
	           $this->paymentGenerator->publishAchEvent($this->payables);

	           $this->publishPaymentEvents($this->data);
	          
	           // (optionally) send file to bank
	           if ($this->paymentConfig->sendToBank === "1") {
	                $this->logger->mlog('Flag set to TRUE - Running Jesus Bank Script.', Zend_Log::DEBUG, $this);
	                $this->paymentGenerator->sendBankFile($this->data, $this->fileId);
	           } else {
	                $this->logger->mlog('Flag set to FALSE - NOT running Jesus Bank script.', Zend_Log::DEBUG, $this);
	           }
           
        } else {
           $this->logger->mlog('No payments to process.', Zend_Log::INFO, $this);
        }
         
     	} catch(Merc_Exception $mex) {
           // if there's an expected merc_exception, we need to just rollback and send an alert.
           $this->transactionManager->rollBack();
           
         $details = array('timestamp' => time(),
						        'subject' => 'The Payment Process Failed.',
						        'details' => $mex->getMessage(),
						        'from' => __METHOD__);
        
           $this->eventPublisher->createEvent(Davis_EventPublisher::ALERT, $details);
           
        } catch(Exception $ex) {
      	// if there's an unexpected exception, we need to just rollback and kill the process.
         $this->transactionManager->rollBack();
         throw $ex;
      }
      
      $endTime = time();
      $this->logger->mlog('Total Time: ' . date('i:s', $endTime - $beginTime), Zend_Log::INFO, $this);
      $this->logger->mlog('End createVendorPayments()', Zend_Log::INFO, $this);
   }
   
   /*
    * From an array of orderlines, create the vendor payment array
    *
    * @param $orderLines Merc_Model_Davis_OrderLine[]
    */
   private function createVendorPaymentsFromOrderLines($orderLines) {
   	
   	$this->logger->mlog('Begin createVendorPaymentsFromOrderLines()', Zend_Log::INFO, $this);
   	
	   foreach ($orderLines as &$orderLine) {
	   	
		    $this->logger->mlog('--ORDERLINE ID: ' . $orderLine->getOrderLineId(), Zend_Log::DEBUG, $this);
		    
		    // Handle the non-AUTO payable modes on an order line. Force pay, force do-not-pay.
		    // Here: Force do-not-pay.
		    /* @var $orderLine Merc_Model_Davis_OrderLine */
		    if ($orderLine->getPayableMode() === Merc_Model_Davis_OrderLine::PAYABLE_MODE_FORCE_DO_NOT_PAY) {
		       $this->logger->mlog('Do NOT pay. Skipping...', Zend_Log::DEBUG, $this);
		       // if the orderLine is forced to not pay, we just skip it.
		       continue;
		    }
		    
		    if (array_key_exists($orderLine->getPurchaseOrderId(), $this->purchaseOrders)) {
		       $po = $this->purchaseOrders[$orderLine->getPurchaseOrderId()];
		    } else {
		       $po = $this->purchaseOrderService->getByIdShallow($orderLine->getPurchaseOrderId());
		       $this->purchaseOrders[$orderLine->getPurchaseOrderId()] = $po;
		    }
		
		    if (is_null($po)) {
		       $this->logger->mlog('Order line ID: ' . $orderLine->getOrderLineId() .
		                           ' has no record in the purchase_order table!', Zend_Log::CRIT, $this);
		       continue;
		    }
		    
		    $vendor = $this->vendorDao->getById($po->getVendorId());
		    if ($vendor->getPaymentType() == Merc_Model_Davis_Vendor::PAYMENT_TYPE_DO_NOT_PAY) {
		       $this->logger->mlog('Forced to NOT pay. Skipping...', Zend_Log::DEBUG, $this);
		       continue;
		    }
		    
		    $this->logger->mlog('VENDOR TERMS: ' . $vendor->getPaymentTerms(), Zend_Log::DEBUG, $this);
		    $this->logger->mlog('OrderLineState: ' . $orderLine->getState(), Zend_Log::DEBUG, $this);
		    
		    
		    $filters = array('vendor_id' => $vendor->getVendorId());
		    $vendorAddresses = $this->vendorAddressDao->get($filters);
		    $vendor->setVendorAddresses($vendorAddresses);
		    
		    $paymentTerms = $vendor->getPaymentTerms();
		    
		    $prePay = $paymentTerms == -1 && $orderLine->getState() == Davis_AuditAction::PO_STATE_APPROVED;
		    $immediatePay = $paymentTerms <= 0 && $orderLine->getState() == Davis_AuditAction::PO_STATE_SHIPPED;
		    $shortTermsPay = ($paymentTerms <= self::DAYS_PAID_BEFORE_TERMS_EXPIRE_ACH ||
		                      $paymentTerms <= self::DAYS_PAID_BEFORE_TERMS_EXPIRE_CHECK) &&
		                      $orderLine->getState() == Davis_AuditAction::PO_STATE_SHIPPED;
		    $standardTermsPay = $paymentTerms > 0 && $orderLine->getState() == Davis_AuditAction::PO_STATE_SHIPPED;
		    
		    // Handle the non-AUTO payable modes on an order line.
		    // Here: Force pay.
		    if ($orderLine->getPayableMode() === Merc_Model_Davis_OrderLine::PAYABLE_MODE_FORCE_PAY) {
		       // if the orderLine is forced to pay, we directly add it to the payable queue.
		       $this->logger->mlog('Forced to pay.', Zend_Log::DEBUG, $this);
		       $this->preProcessOrderLine($po, $vendor, $orderLine);
		    } elseif ($prePay || $immediatePay || $shortTermsPay) {
		       // -1 is PRE PAY. (0 is PAY NOW && SHIPPED)
		       $orderLine = $this->preProcessOrderLine($po, $vendor, $orderLine);
		    } elseif ($standardTermsPay) {
		       
		       // PAYMENT TERMS
		       $paymentTermsInSeconds = $paymentTerms * Merc_Util_Date::SECONDS_IN_DAY;
		       $shipDate = $this->shipmentService->getForwardShipDateByOrderLineId($orderLine->getOrderLineId());  //$orderLine->getShipDate();
		       if (empty($shipDate)) {
		          $this->logger->mlog("Ship date missing for order line ID {$orderLine->getOrderLineId()} when attempting to create a payment for it.", Zend_Log::CRIT, $this);
		          continue;
		       }
		       
		       $weShouldPayBy = $shipDate + $paymentTermsInSeconds;
		       $now = time();
		       
		       // check to see if there are some discounts for paying early.
		       if ($this->testForEarlyDiscounts($orderLine->getOrderLineId())) {
		          $orderLine = $this->preProcessOrderLine($po, $vendor, $orderLine);
		          continue;
		       }
		
		       $this->logger->mlog('SHIP DATE: ' . $shipDate . ' date: ' . date('m-d-Y', $shipDate), Zend_Log::DEBUG, $this);
		       $this->logger->mlog('PAYMENT TERMS IN SECONDS: ' . $paymentTermsInSeconds . ' days: ' . print_r($paymentTermsInSeconds / Merc_Util_Date::SECONDS_IN_DAY, true), Zend_Log::DEBUG, $this);
		       $this->logger->mlog('WE SHOULD PAY BY: ' . $weShouldPayBy . ' date: ' . date('m-d-Y', $weShouldPayBy), Zend_Log::DEBUG, $this);
		       
		       // subtracting Merc_Util_Date::SECONDS_IN_DAY is making sure we pay before terms expire X days before.
		       // $now is in-between when we should pay by and just up until the limit it it needs to be in
		       // their bank account
		       if (($now <= $weShouldPayBy) &&
		           (($vendor->getPaymentType() == Merc_Model_Davis_Vendor::PAYMENT_TYPE_ACH &&
		              $now >= $weShouldPayBy - (self::DAYS_PAID_BEFORE_TERMS_EXPIRE_ACH * Merc_Util_Date::SECONDS_IN_DAY)) ||
		              ($vendor->getPaymentType() == Merc_Model_Davis_Vendor::PAYMENT_TYPE_CHECK &&
		             $now >= $weShouldPayBy - (self::DAYS_PAID_BEFORE_TERMS_EXPIRE_CHECK * Merc_Util_Date::SECONDS_IN_DAY)))) {
		                
		             $orderLine = $this->preProcessOrderLine($po, $vendor, $orderLine);
		           
		       } elseif ($now >= $weShouldPayBy) {
		          $this->logger->mlog('Lateness potential is high. We should have paid by: ' . date('m-d-Y', $weShouldPayBy), Zend_Log::DEBUG, $this);
		          // we should have paid this already.
		          // this is officially a late payment
		          $orderLine = $this->preProcessOrderLine($po, $vendor, $orderLine);
		      } else {
		          $creditLimit = $vendor->getCreditLimit();
		          
		          if ($creditLimit > 0) {
		             $this->logger->mlog('Normally we wouldn\'t pay this orderline:' . $orderLine->getOrderLineId(), Zend_Log::INFO, $this);
		             $orderLine = $this->preProcessOrderLine($po, $vendor, $orderLine);
		             $orderLine->setIfCreditLimitPay(TRUE);
		          }
		       }
		    }
	  }
	 
	  $this->logger->mlog('End createVendorPaymentsFromOrderLines()', Zend_Log::INFO, $this);
   }
   
   
   /**
    * This OrderLine is Ready to PAY!
    *
    * @param Merc_Model_Davis_PurchaseOrder $po
    * @param Merc_Model_Davis_Vendor $vendor
    * @param Merc_Model_Davis_OrderLine $orderLine
    *
    * @return Merc_Model_Davis_OrderLine
    */
   private function preProcessOrderLine($po, $vendor, $orderLine) {
      $this->logger->mlog('Begin preProcessOrderLine():', Zend_Log::INFO, $this);
      
      if (array_key_exists($po->getVendorId(), $this->payables)) {
         $vendorPayment = $this->payables[$po->getVendorId()];
      } else {
         $vendorPayment = new Merc_Model_Davis_VendorPayment();
         $this->payables[$po->getVendorId()] = $vendorPayment;
         $vendorPayment->setVendor($vendor);
      }
       
      $discountAmount = $this->getDiscountSum($orderLine);
      
      $orderLine->setPayableDiscountAmount($discountAmount);
      
      // determine "not exempt from the late penalty" and vendor is not pre-pay
      if ($this->paymentConfig->latePenalties === "1") {
      	list($year, $month, $day) = split('-',$this->paymentConfig->latePenaltyDayOne);
      	$latePenaltyDayOneSecs = mktime(0,0,0,$month, $day, $year);
      	
      	$this->logger->mlog('We\'re about to test late penalty ' , Zend_Log::DEBUG, $this );

      	if (($orderLine->getIsExemptLatePenalty() === FALSE)
      	    && ($orderLine->getCreatedDate() >= $latePenaltyDayOneSecs)) {
      		$this->calculateLatePenalty($orderLine, $vendor);
         }
      }
      
      $this->logger->mlog('READY TO PAY: ' . print_r($orderLine->getOrderLineId(), true), Zend_Log::DEBUG, $this);
      
      $po->setPayableOrderLine($orderLine);
      $vendorPayment->setPurchaseOrder($po);
      $this->allPayableOrderlines[$orderLine->getOrderLineId()] = $orderLine;
      
      $this->logger->mlog('End preProcessOrderLine():', Zend_Log::INFO, $this);
      return $orderLine;
   }
   
   /**
    * Calculates Late Penalty, if any
    *
    * @param Merc_Model_Davis_OrderLine $orderLine
    * @param Merc_Model_Davis_Vendor $vendor
    */
    private function calculateLatePenalty($orderLine, $vendor) {
   	$this->logger->mlog('Begin calculateLatePenalty():', Zend_Log::INFO, $this);
   	
     // first test to see if there was a change to the ship_date
      $initialShipDate = $orderLine->getCustomerExpectedShipDate();
      
      // test if the orderline is late
      // from when tracking number was entered, or pickup date was determined from carrier apis.
      $actualShipDate = $this->shipmentService->getForwardShipDateByOrderLineId($orderLine->getOrderLineId()); //$orderLine->getShipDate();
      $this->logger->mlog('customer expected ship date: ' . Merc_Util_Date::unix2mysqlDate($initialShipDate) .
         ' actualDate: ' . Merc_Util_Date::unix2mysqlDate($actualShipDate), Zend_Log::DEBUG, $this );
        
      
      if (($actualShipDate > $initialShipDate) && (!is_null($initialShipDate))) {
         $payableGross = $orderLine->getPayableGrossAmount();
         $this->logger->mlog('Payable gross = '.$payableGross, Zend_Log::DEBUG, $this);
         
         // getting the options
         $filters = array('orderLineId'=>$orderLine->getOrderLineId());
         $options = $this->orderLineOptionDao->get($filters);
         
         
         /* @var $option Merc_Model_Davis_OrderLineOption */
         $optionDelta = 0;
         foreach((array)$options as $option) {
            $optionDelta += $option->getWholesaleDelta() + $option->getWholesaleDropshipDelta();
            $this->logger->mlog("Wholesale delta: " . $option->getWholesaleDelta() . " + Wholesale dropship delta: " . $option->getWholesaleDropshipDelta() . "  = Option delta: " .$optionDelta , Zend_Log::DEBUG, $this);
         }
         $payableGross += ($optionDelta * $orderLine->getQuantity());
         
          
         // if so, calculate the amount
         if ($vendor->getLatePenaltyType() === Merc_Model_Davis_Vendor::LATE_PENALTY_TYPE_PERCENT) {
            $orderLine->setLatePenaltyAmount(round($payableGross * $vendor->getLatePenaltyPercent(), 2));
         }
         else {
            $orderLine->setLatePenaltyAmount($vendor->getLatePenaltyDollar());
         }
        $this->logger->mlog('***Late Penalty: ' . $orderLine->getLatePenaltyAmount(), Zend_Log::DEBUG, $this);
      }
      $this->logger->mlog('End calculateLatePenalty():', Zend_Log::INFO, $this);
      
   }
   

   /**
    * Tests an orderLine to see if there any discounts for paying early
    *
    * @param int $orderLineId
    * @return bool
    */
   private function testForEarlyDiscounts($orderLineId) {
      $this->logger->mlog('Begin testForEarlyDiscounts()', Zend_Log::INFO, $this);
   	
      $filters['orderLineId'] = $orderLineId;
      $discounts = $this->orderLineVendorDiscountDao->get($filters);

      if ($discounts) {
         $today = Merc_Util_Date::unixToday();
         
         foreach ($discounts as $discount) {
            /* @var $discount Merc_Model_Davis_OrderLineVendorDiscount */
            if ($discount->getTerminationDate()) {
               
               $terminationDate = $discount->getTerminationDate();
               $earlyDiscountBufferDate = $terminationDate - (Merc_Util_Date::SECONDS_IN_DAY * self::EARLY_DISCOUNT_BUFFER); 
            
               $this->logger->mlog('EarlyDiscountBufferDate: ' . date('m-d-Y', $earlyDiscountBufferDate) . ' <= Today: ' . date('m-d-Y', $today)  . ' <= Termination Business Day: '.  date('m-d-Y', $terminationDate)  , Zend_Log::DEBUG, $this);
            
               if (Merc_Util_Date::isWeekendDay($terminationDate)) {
                  if ($today <= Merc_Util_Date::getMostRecentBusinessDay($terminationDate) && $today >=  $earlyDiscountBufferDate) { 
                     $this->logger->mlog('Eligable for Early Terms Discount. PAY', Zend_Log::DEBUG, $this);
                     $this->logger->mlog('End testForEarlyDiscounts()', Zend_Log::INFO, $this);
                     return TRUE;
                  }
               } else {
                  if ($today <= $terminationDate && $today >= Merc_Util_Date::getMostRecentBusinessDay($earlyDiscountBufferDate)) {
                     $this->logger->mlog('Eligable for Early Terms Discount. PAY', Zend_Log::DEBUG, $this);
                     $this->logger->mlog('End testForEarlyDiscounts()', Zend_Log::INFO, $this);
                     return TRUE;
                  }
               }
            }
         }
      }
      $this->logger->mlog('Not Eligable for Early Terms Discount.', Zend_Log::DEBUG, $this);
      $this->logger->mlog('End testForEarlyDiscounts()', Zend_Log::INFO, $this);
      return FALSE;
   }
   
   /**
    * Grab everything from order_line_vendor_discounts and sum it.
    *
    * @param Merc_Model_Davis_OrderLine $orderLine
    * @return decimal
    */
    private function getDiscountSum($orderLine) {
       $this->logger->mlog('Begin getDiscountSum()', Zend_Log::INFO, $this);
    	
    	// add to filters array
      $filters['orderLineId']= $orderLine->getOrderLineId();
      $discounts = $this->orderLineVendorDiscountDao->get($filters);

       $discountSum = 0;
      if ($discounts) {
         $today = Merc_Util_Date::unixToday();

         
         foreach ($discounts as $discount) {
            /* @var $discount Merc_Model_Davis_OrderLineVendorDiscount */
            if (!$discount->getEffectiveDate() && !$discount->getTerminationDate()) { 
               $discountSum = $discountSum + $discount->getAmount();
               $orderLine->addDiscount($discount);
               $this->logger->mlog('Adding amount: ' .  $discount->getAmount() . ' No Effective or Termination dates!', Zend_Log::DEBUG, $this);
            } else {
            
               $effectiveDate = Merc_Util_Date::getNextBusinessDayIfWeekend($discount->getEffectiveDate());
               $terminationDate = Merc_Util_Date::getNextBusinessDayIfWeekend($discount->getTerminationDate());
               if ($today >= $effectiveDate && $today <= $terminationDate) { 
                  $this->logger->mlog('Adding amount: ' .  $discount->getAmount() . ' Effective date: ' . date('m-d-Y', $effectiveDate) . ' <= Today: ' . date('m-d-Y', $today) . ' <=  Termination Business Day: '.  date('m-d-Y', $terminationDate), Zend_Log::DEBUG, $this);
                  $discountSum = $discountSum + $discount->getAmount();
                  $orderLine->addDiscount($discount);
               }
            }
         }
      }
      
      $this->logger->mlog('End getDiscountSum() discountSum: ' . $discountSum, Zend_Log::INFO, $this);
      return $discountSum;
   }
  

   private function attachOptions() {
      $this->logger->mlog('Begin ' . __METHOD__, Zend_Log::INFO, $this);
              
      $filters = array('orderLineIds'=> array_keys($this->allPayableOrderlines));
      $options = $this->orderLineOptionDao->get($filters);

      if ($options){
         foreach ($options as $option){
         	$orderLine = $this->allPayableOrderlines[$option->getOrderLineId()];
         	$orderLine->addOption($option);
         }
      }
       	
      $this->logger->mlog('End ' . __METHOD__, Zend_Log::INFO, $this);
   }
   
   /**
    * Now that we have our payables, check to see if the Vendor
    * has a credit limit.  If so, test the orderLines that belong to that payment.
    */
   private function processCreditLimitPayments() {
     $this->logger->mlog('Begin processCreditLimitPayments()', Zend_Log::INFO, $this);
     
     if ($this->payables) {
        /* @var $payment Merc_Model_Davis_VendorPayment */
        foreach ($this->payables as $paymentId => &$payment) {
            $purchaseOrders = $payment->getPurchaseOrders();
            $vendor = $payment->getVendor();
            $creditLimit = $vendor->getCreditLimit();
            if ($creditLimit > 0) {
               $this->pruneOrderLines($purchaseOrders, $creditLimit);
               $payment->setPurchaseOrders($purchaseOrders);
            }
            if (count($purchaseOrders) == 0) {
               unset($this->payables[$paymentId]);
            }
         }
      }
      
      $this->logger->mlog('End processCreditLimitPayments()', Zend_Log::INFO, $this);
   }
   
   /**
    * For credit limit payable orderlines.
    * We add up both those that passed all tests + those that didn't
    * To see if they reach credit limit, if not then remove the ones that didn't pass.
    *
    *
    * @param Merc_Model_Davis_PurchaseOrder $purchaseOrders
    * @param decimal $creditLimit
    */
   private function pruneOrderLines(&$purchaseOrders, $creditLimit) {
      $this->logger->mlog('Begin pruneOrderLines()', Zend_Log::INFO, $this);
      
      $totalPayableAmount = 0;
      foreach ($purchaseOrders as $purchaseOrder) {
      	$payableAmount = 0;
      	$payableDiscount = 0;
      	$payableGross = 0;
         /* @var $orderLine Merc_Model_Davis_OrderLine */
         foreach ($purchaseOrder->getPayableOrderLines() as $orderLine) {
            
            $payableGross = $orderLine->getPayableGrossAmount();//($orderLine->getWholesale() + $orderLine->getWholesaleDropship());
            $payableDiscount = $orderLine->getPayableDiscountAmount();
            $latePenalty = $orderLine->getLatePenaltyAmount();
            
            /* @var $option Merc_Model_Davis_OrderLineOption */
            $options = $orderLine->getOptions();
            $optionDelta = 0;
            foreach((array)$options as $option) {
               $optionDelta += $option->getWholesaleDelta() + $option->getWholesaleDropshipDelta();
            }
                        
            $this->logger->mlog('orderlineId:'. $orderLine->getOrderLineId(), Zend_Log::DEBUG, $this);
            $this->logger->mlog('gross so far..:'. $payableGross, Zend_Log::DEBUG, $this);
            $this->logger->mlog('discount so far..:'. $payableDiscount, Zend_Log::DEBUG, $this);
            $this->logger->mlog('late penalty so far...:'. $latePenalty, Zend_Log::DEBUG, $this);
            $this->logger->mlog('payableOption = '.$optionDelta, Zend_Log::DEBUG, $this);

            $payableAmount += ($payableGross - $payableDiscount - $latePenalty);
            $payableAmount += ($optionDelta * $orderLine->getQuantity());
         }

         $totalPayableAmount += $payableAmount;
         $this->logger->mlog('total payable..:'. $totalPayableAmount, Zend_Log::DEBUG, $this);
       }
       
       if ($creditLimit - ($creditLimit * self::PERCENT_CLOSE_TO_CREDIT_LIMIT) >= $totalPayableAmount) {
          $this->logger->mlog('We are NOT close to our credit limit. Unset all questionable orderlines.', Zend_Log::INFO, $this);
         
          /* @var $orderLine Merc_Model_Davis_PurchaseOrder */
          foreach ($purchaseOrders as $poId => $purchaseOrder) {
          	
            /* @var $orderLine Merc_Model_Davis_OrderLine */
            $orderLines = $purchaseOrder->getPayableOrderLines();
            
            foreach ($orderLines as $olId => $orderLine) {
               if ($orderLine->getIfCreditLimitPay() == TRUE) {
                  $this->logger->mlog('UNSET:' . $orderLine->getOrderLineId(), Zend_Log::DEBUG, $this);
                  unset($orderLines[$olId]);
               }
            }
            $purchaseOrder->setPayableOrderLines($orderLines);
            //if purchaseOrder has no payable Order Lines, UNSET
            if (count($orderLines) == 0) {
                unset($purchaseOrders[$poId]);
             }
          }
       } else {
          // We are close to our credit limit. Pay percentage of our outstanding payments. oldest first.
          $this->logger->mlog("We are close to our credit limit of {$creditLimit}. We owe {$totalPayableAmount}. ".
                              "Let us figue out what to pay and not pay.",
                              Zend_Log::DEBUG, $this);
          
          // Dev Note: Currently, we are paying all "payable" lines, even those that are credit limit pay.
          // We want to prune POLines that we do not need to.
          // We will prune so that we do NOT pay up to an amount = self::PERCENT_REMAIN_ON_CREDIT * $creditLimit
          $targetCreditRemaining = self::PERCENT_REMAIN_ON_CREDIT * $creditLimit;
          $currentCreditRemaining = 0;
          
          $targetReached = false;
          $this->logger->mlog("Current Credit is {$currentCreditRemaining} while the target is {$targetCreditRemaining}.",
            Zend_Log::DEBUG, $this);
          
          // resort in reverse order - so we prune most recent first (we pay the oldest)
          krsort($purchaseOrders);
            
          /* @var $purchaseOrder Merc_Model_Davis_PurchaseOrder */
          foreach ($purchaseOrders as $poId => &$purchaseOrder) {
          	          	
          	 if ($targetReached) {
          	 	break;
          	 }

	          /* @var $orderLine Merc_Model_Davis_OrderLine */
             $orderLines = $purchaseOrder->getPayableOrderLines();
                        
             foreach ($orderLines as $olId => &$orderLine) {
             	
	             if ($targetReached) {
	               break;
	             }
	             
	             if (!$orderLine->getIfCreditLimitPay()) {
	             	// we cannot remove this payment
	             	continue;
	             }

             	 $this->logger->mlog('Our current credit is: '.$currentCreditRemaining,
                  Zend_Log::DEBUG, $this);
                
	             $thisLineNetPayableAmount = $orderLine->getPayableGrossAmount() - $orderLine->getPayableDiscountAmount() - $orderLine->getLatePenaltyAmount();
	             /* @var $option Merc_Model_Davis_OrderLineOption */
	             $options = $orderLine->getOptions();
	             $optionDelta = 0;
	             foreach((array)$options as $option) {
	                $optionDelta += $option->getWholesaleDelta() + $option->getWholesaleDropshipDelta();
	             }
	             
	             $thisLineNetPayableAmount += ($optionDelta * $orderLine->getQuantity());
	             $currentCreditRemaining += $thisLineNetPayableAmount;
	             $this->logger->mlog("To remove payment on orderLine {$orderLine->getOrderLineId()} ".
	                                  "from purchaseOrder {$purchaseOrder->getPoNumber()} ".
                                     "would bring our current credit up {$thisLineNetPayableAmount} to {$currentCreditRemaining}.",
                                     Zend_Log::DEBUG, $this);
                                     
	             if ($currentCreditRemaining > $targetCreditRemaining) {
	             	// We have more credit that our target. We cannot unset this. Exit routine.
	             	$this->logger->mlog("This is more than our target credit. We cannot unset. Exit pruning.",
	             	   Zend_Log::DEBUG, $this);
	             	$targetReached = true;
	             } else {
	             	// We still have some credit to retain, unset.
	             	$this->logger->mlog("This is allowed. Prune payment for orderLineId= {$olId}.",
                     Zend_Log::DEBUG, $this);
	             	unset($orderLines[$olId]);
	             }
             } // foreach orderLine
             
             if (count($orderLines) == 0) {
             	$this->logger->mlog("No orderlines in poId = {$poId}. Removing this PO...",
                     Zend_Log::DEBUG, $this);
             	unset($purchaseOrders[$poId]);
             }
          }
       }
         
       $this->logger->mlog('End pruneOrderLines()', Zend_Log::INFO, $this);
   }

   /**
    * Insert the vendor payment records into the db
    */
   private function insertPaymentDataIntoDatabase() {
      $this->logger->mlog('Begin insertPaymentDataIntoDatabase()', Zend_Log::INFO, $this);
      
      /* @var $payment Merc_Model_Davis_VendorPayment */
      foreach ($this->payables as $payment) {

      	// insert vendor payment record into db
      	$this->vendorPaymentDao->insert($payment);
      	
         $vendorPaymentId = $payment->getVendorPaymentId();
         $purchaseOrders = $payment->getPurchaseOrders();

         /* @var $po Merc_Model_Davis_PurchaseOrder */
         foreach ($purchaseOrders as $po) {
            $orderLines = $po->getPayableOrderLines();
            /* @var $ol Merc_Model_Davis_OrderLine */
            foreach ($orderLines as $ol) {
      
              // state change, if payment is successfully submitted
              if ($payment->getStatus() === Merc_Model_Davis_VendorPayment::STATUS_SUBMITTED) {
              	
              	  // only update the discounts if the vendor payment was successfully submitted
              	  $discounts = $ol->getDiscounts();
              	  foreach ((array)$discounts as $disc) {
              	  	   $disc->setIsApplied(1);
              	  	   $this->orderLineVendorDiscountDao->updateById($disc);
              	  }

                 try {
                    // this may be an illegal state change
                    // but we still pay because of force pay
                    Merc_Registry::get('purchaseOrderLineFactory')->createByOrderLineId($ol->getOrderLineId())->pay();
                  } catch (Merc_Exception $mex) {
                     // we catch and swallow this issue, but we need to set Paid status
                     $ol->setIsPaid(true);
                     $this->orderLineDao->updateById($ol);
                  }
         	   }
         	   
	            /* @var $option Merc_Model_Davis_OrderLineOption */
	            $options = $ol->getOptions();
	            $optionDelta = 0;
	            foreach((array)$options as $option) {
	               $optionDelta += $option->getWholesaleDelta() + $option->getWholesaleDropshipDelta();
	            }
         	
               $vendorPaymentOrderLineMap = new Merc_Model_Davis_VendorPaymentOrderLineMap();
               $vendorPaymentOrderLineMap->setVendorPaymentId($vendorPaymentId);
               $vendorPaymentOrderLineMap->setOrderLineId($ol->getOrderLineId());
               $vendorPaymentOrderLineMap->setDiscountAmount($ol->getPayableDiscountAmount());
               $vendorPaymentOrderLineMap->setGrossAmount($ol->getPayableGrossAmount() + ($optionDelta*($ol->getQuantity())));
               $vendorPaymentOrderLineMap->setLatePenaltyAmount($ol->getLatePenaltyAmount());
               $this->vendorPaymentOrderLineMapDao->insert($vendorPaymentOrderLineMap);
            }
         }
         
         // insert debits
         /* @var $vendorDebit Merc_Model_Davis_VendorDebit */
         foreach ((array)$payment->getVendorDebits() as $vendorDebit) {
         	$this->creditDebitService->applyDebit($vendorDebit->getVendorDebitId(), 
         	                                      $payment->getVendorPaymentId(),
         	                                      $vendorDebit->getAmount());
         }
         
      }
      $this->logger->mlog('End insertPaymentDataIntoDatabase()', Zend_Log::INFO, $this);
   }

   
   /**
    * Publish Payment events
    *
    */
   private function publishPaymentEvents() {
      $this->logger->mlog('Begin publishPaymentEvents()', Zend_Log::INFO, $this);

      /* @var $payment Merc_Model_Davis_VendorPayment */
      foreach ($this->payables as $payment) {
      	
      	if ($payment->getStatus() === Merc_Model_Davis_VendorPayment::STATUS_SUBMITTED)
      	{
	      	// publish payment success event
		      $this->eventPublisher->createEvent(Davis_EventPublisher::PAYMENT_RECORD_SUBMITTED,
		                                         array('vendorPaymentId' => $payment->getVendorPaymentId()));
		                                         
      	} else if ($payment->getStatus() === Merc_Model_Davis_VendorPayment::STATUS_EXCEPTION) {
      		// publish payment failure event so that someone can handle this situation.
            $msg = "Payment is missing required information! We tried to pay vendorId = {$payment->getVendorId()}, but got: ".$payment->getComment();
                       
            $details = array('timestamp' => time(),
                             'comment' => $msg,
                             'vendorPaymentId' => $payment->getVendorPaymentId());
            $this->eventPublisher->createEvent(Davis_EventPublisher::PAYMENT_RECORD_FAILED, $details);
      	}
      }
      
      $this->logger->mlog('End publishPaymentEvents()', Zend_Log::INFO, $this);
   }

   /**
    * Process creditsDebits to payables.
    */
   private function processCreditsDebits() {
   	
   	$this->logger->mlog('Begin processCreditsDebits()', Zend_Log::INFO, $this);
   	
   	$this->processDebits();
   	$this->processCredits();
   	
   	$this->logger->mlog('End processCreditsDebits()', Zend_Log::INFO, $this);
   }
   
   /**
    * Add VendorDebits to VendorPayment objects
    */
   private function processDebits() {
      $this->logger->mlog('Begin processDebits()', Zend_Log::INFO, $this);
      
      $allVendorDebits = $this->creditDebitService->getAllUnappliedDebits();
            
      /* @var $vendorDebit Merc_Model_Davis_VendorDebit */
      foreach ($allVendorDebits as $vendorDebit) {
      	if (array_key_exists($vendorDebit->getVendorId(), $this->payables)) {
      		// we already have a payment for this vendor set up,
      		// just add new debit to vendorPayment
      		$this->logger->mlog("Adding VendorDebit of {$vendorDebit->getAmount()} to EXISTING ".
      		                    "vendorPayment for vendorId=".$vendorDebit->getVendorId(), Zend_Log::INFO, $this);
            $this->payables[$vendorDebit->getVendorId()]->addVendorDebit($vendorDebit);
      	} else {
      		// we don't yet have an existing payment for this vendor
      		// so we need to create one
      		$this->logger->mlog("Adding VendorDebit of {$vendorDebit->getAmount()} to NEW ".
      		                    "vendorPayment for vendorId=".$vendorDebit->getVendorId(), Zend_Log::INFO, $this);
      		$vendorPayment = new Merc_Model_Davis_VendorPayment();
      		$vendorToPay = $this->vendorService->getById($vendorDebit->getVendorId());
      		if ($vendorToPay==null) {
      			// if vendor doesn't exist, we can't pay; continue.
      			continue;
      		}
            $vendorPayment->setVendor($vendorToPay);
            $vendorPayment->addVendorDebit($vendorDebit);
            // no Purchase Orders will be paid
            $vendorPayment->setPurchaseOrders(array());
            $this->payables[$vendorDebit->getVendorId()] = $vendorPayment;
      	}
      }
      
      $this->logger->mlog('End processDebits()', Zend_Log::INFO, $this);
   }
   
   /**
    * Add VendorCredits to VendorPayment objects
    */
   private function processCredits() {
      $this->logger->mlog('Begin processCredits()', Zend_Log::INFO, $this);
      
      // grab the vendorIds for the payments we're processing
      $vendorIdsArray = array();
      /* @var $vendorPayment Merc_Model_Davis_VendorPayment */
      foreach ($this->payables as $vendorId => $vendorPayment) {
      	$vendorIdsArray[] = $vendorId;
      }
      
      // grab all the credits for the current payments
      $vendorCreditArray = $this->creditDebitService->getUnappliedCredits($vendorIdsArray);
      
      /* @var $vendorPayment Merc_Model_Davis_VendorPayment */
      foreach ($this->payables as $vendorId => $vendorPayment) {
                  
         // so we have all the vendor credits for a given vendor, now let's use them.
         // Note that there is only 1 payment per vendorId
        	/* @var $purchaseOrder Merc_Model_Davis_PurchaseOrder */
        	foreach ($vendorPayment->getPurchaseOrders() as $purchaseOrder) {

		      /* @var $orderLine Merc_Model_Davis_OrderLine */
		      foreach ($purchaseOrder->getPayableOrderLines() as $orderLine) {
		  
		         // now we have the payable amounts for this order line.
		         // Calculate the net and subtract the credits from this.
		         // Dev Note: payableGross already considers quantity
		         $payableNet = $orderLine->getPayableGrossAmount() +
		                       $orderLine->getPayableOptionAmount() -
		                       $orderLine->getPayableDiscountAmount() -
		                       $orderLine->getLatePenaltyAmount();
		         
		         // we will cycle through all the vendor credits, applying them to the orderline
		         /* @var $vendorCredit Merc_Model_Davis_VendorCredit */
		         foreach ((array)$vendorCreditArray as $vendorCredit) {

		         	if ($purchaseOrder->getVendorId() != $vendorCredit->getVendorId()) {
		         		// we can only apply credits belonging to this vendor; bummer
		         		continue;
		         	} else if ($vendorCredit->getAmount() <= 0) {
		         		// likewise, we can only apply credits with a positive amount remaining
		         		continue;
		         	}
		         	
		         	$this->logger->mlog("Applying credit of {$vendorCredit->getAmount()} to EXISTING ".
                                      "vendorPayment for vendorId=".$vendorCredit->getVendorId(), Zend_Log::INFO, $this);

		         	// determine how much credit to use
	         		if ($vendorCredit->getAmount() >= $payableNet) {
	         			// we use enough credit to cover the remaining payableNet
	         			$creditUsed = $payableNet;	         			
	         		} else {
	         			// we use the entire credit amount available
	         			$creditUsed = $vendorCredit->getAmount();
	         		}
	         			         		
	         		// decrease the available credit
                  $vendorCredit->setAmount($vendorCredit->getAmount() - $creditUsed);
                  // increase the orderLine's credit amount
                  $orderLine->setVendorCreditAmount($orderLine->getVendorCreditAmount() + $creditUsed);
                  // since payableNet==0, break from loop
                  $payableNet = $payableNet - $creditUsed;
                  
                  $this->logger->mlog("Credit amount being applied is {$creditUsed}. ".
                                      "Remaining orderLine net is {$payableNet}. ".
                                      "Cummulative credit applied to this orderLine is {$orderLine->getVendorCreditAmount()}. ". 
                                      "Remaining amount on vendor credit is {$vendorCredit->getAmount()}.", Zend_Log::INFO, $this);
                  
                  // mark credit as applied via service
                  $this->creditDebitService->applyCredit($vendorCredit->getVendorCreditId(),
                                                         $orderLine->getOrderLineId(),
                                                         $creditUsed);
                                                         
                  // if we've reduced our payable amount to 0, break.
	         		if ($payableNet==0) {
	         			break;
	         		}
	         		
		         }
		      }
         }
      }
      
      $this->logger->mlog('End processCredits()', Zend_Log::INFO, $this);
   }
   
   /**
    * Sets the creditDebitService to a customized service.
    * This is really only used for unit tests.
    */
   public function setCreditDebitService($fastTrakService) {
   	$this->creditDebitService = $fastTrakService;
   }
   
}
