<?php


/**
 * @package Davis
 * @author cnoonan
 */
class Davis_Payment_Utility {


   /**
    * Calculate and set the payable amount.
    *
    * @param Merc_Model_Davis_VendorPayment $payment
    */
   public static function calculatePaymentAmount(Merc_Model_Davis_VendorPayment $payment) {
      $logger = Merc_Registry::get('loggerPay');
      $logger->mlog('Begin calculatePaymentAmount(): vendor='.$payment->getVendor()->getVendorId(), Zend_Log::INFO, $this);
      
      $payableAmount = 0.0;
      
      // get all POs
      $purchaseOrders = $payment->getPurchaseOrders();
      /* @var $purchaseOrder Merc_Model_Davis_PurchaseOrder */
      foreach ($purchaseOrders as $purchaseOrder) {
         $payableGross = 0.0;
         $payableDiscount = 0.0;
         $payableLatePenalty = 0.0;
         $payableVendorCredit = 0.0;
         
         /* @var $orderLine Merc_Model_Davis_OrderLine */
         foreach ((array)$purchaseOrder->getPayableOrderLines() as $orderLine) {
            $logger->mlog('OrderLine payableGross = '.$orderLine->getPayableGrossAmount(),
               Zend_Log::DEBUG, $this);
            $logger->mlog('OrderLine payableOption = '.$orderLine->getPayableOptionAmount(),
               Zend_Log::DEBUG, $this);
            $logger->mlog('OrderLine payableDiscount = '.$orderLine->getPayableDiscountAmount(),
               Zend_Log::DEBUG, $this);
            $logger->mlog('OrderLine latePenalty = '.$orderLine->getLatePenaltyAmount(),
               Zend_Log::DEBUG, $this);
            $logger->mlog('OrderLine vendorCredit = '.$orderLine->getVendorCreditAmount(),
               Zend_Log::DEBUG, $this);
         	
            // payableGross already considers quantity
            $payableGross += $orderLine->getPayableGrossAmount() + $orderLine->getPayableOptionAmount();
            $payableDiscount += $orderLine->getPayableDiscountAmount();
            $payableLatePenalty += $orderLine->getLatePenaltyAmount();
            $payableVendorCredit += $orderLine->getVendorCreditAmount();
         }
         
         $payableAmount += ($payableGross - $payableDiscount - $payableLatePenalty - $payableVendorCredit);
         
         $logger->mlog('OrderLine payableAmount = '. ($payableGross - $payableDiscount - $payableLatePenalty - $payableVendorCredit) .
               " for poId " . $purchaseOrder->getPoNumber(), Zend_Log::DEBUG, $this);
      }
      
      // consider debits
      if (count($payment->getVendorDebits()) > 0) {
         /* @var $vendorDebit Merc_Model_Davis_VendorDebit */
         foreach ($payment->getVendorDebits() as $vendorDebit) {
            $payableAmount += $vendorDebit->getAmount();
         }
      }
      
      $logger->mlog('After Debits: VendorPayment payableAmount = '. $payableAmount, Zend_Log::DEBUG, $this);
      
      $payment->setAmount(number_format($payableAmount, 2, '.', ''));
      
      if ($payableAmount <= 0) {
         // we have nothing to pay
         throw new Merc_Exception_Payment_ZeroPayableAmount("Vendor of id={$payment->getVendor()->getVendorId()} is due a payment of {$payableAmount}.
              This payment will not be sent.");
      }
      $logger->mlog('End calculatePaymentAmount(): '.$payableAmount, Zend_Log::INFO, $this);
      
   }
   
  
   /**
    * Check to see if the current payment total is over the daily treshold
    *
    * @param $total
    *
    * @return boolean
    */
   public static function isPaymentTotalTooHigh($total, $paymentConfig) {
      $logger = Merc_Registry::get('loggerPay');
      $logger->mlog("Begin isPaymentTotalTooHigh.", Zend_Log::INFO);
   	
      // check to see if payment cap is enabled
      $enablePaymentCap = $paymentConfig->enablePaymentCap;
      
      if (is_null($enablePaymentCap)) {
         throw new Merc_Exception("No setting for enablePaymentCap in ini. Please review and then resubmit.");
      }
      
      if ($enablePaymentCap) {
         // what is the numeric representation of the day of the week? 0=Sunday; 6=Saturday
         $todayDayOfWeek = date("l", time());
         // what is today's payment cap?
         $todayPaymentCap = $paymentConfig->paymentCap->$todayDayOfWeek;
         
         if (is_null($todayPaymentCap)) {
            throw new Merc_Exception("No daily cap is set for today: {$todayDayOfWeek}.
                                      Please review and then resubmit.");
         }
         
         $logger->mlog("Today is {$todayDayOfWeek} and the paymentCap is {$todayPaymentCap}",
            Zend_Log::INFO);
            
         if ($total > $todayPaymentCap) {
            $errorMessage = "The payment total, {$total}, is greater than the daily cap of {$todayPaymentCap}. " .
                             "Please review and then resubmit.";
            // do 2 things... open/edit file for monitoring tool
            $violationFile = fopen($paymentConfig->paymentCap->violationFile, "w");
            fwrite($violationFile, $errorMessage);
            fclose($violationFile);
            // throw exception to rollback
            throw new Merc_Exception($errorMessage);
         }
      } else {
         $logger->mlog("Payment Cap is turned OFF.", Zend_Log::INFO, $this);
      }

      $logger->mlog('End isPaymentTotalTooHigh(): false', Zend_Log::INFO, $this);
      return false;
   }

}
