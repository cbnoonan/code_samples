<?php


/**
 * File Engine
 *
 * @package Davis
 */
abstract class Davis_Payment_Generator_Abstract {
   /**
    * Class constants used in creation/formatting of file
    */
   const END_OF_LINE = "\n";
   
   /**
    * @var Merc_Log
    */
   protected $logger;
   /*
    * @var Davis_Vendor
    */
   protected $vendorService;
   
   /**
    * @var Davis_EventPublisher
    */
   protected $eventPublisher;
   
   protected $paymentConfig;

   /**
    * ctor.
    *
    */
   function __construct() {
      $this->logger = Merc_Registry::get('loggerPay');
      $this->paymentConfig = Merc_Registry::get('configAppIni')->payment;
      $this->vendorService = Merc_Registry::get('vendorService');
      $this->eventPublisher = Merc_Registry::get('eventPublisher');
   }

   /**
    * Generates the file for payments.
    * 
    *
    * @param Merc_Model_Davis_VendorPayment[] $payments
    * @param Davis_Payment_Abstract
    */
   abstract protected function generate($payments);
   

   /**
    * Send ACH transmission email after Generation
    * 
    *
    * @param Merc_Model_Davis_VendorPayment[] $payments
    */
   public function publishAchEvent($payables) {
      $this->logger->mlog('Begin publishAchEvent()', Zend_Log::INFO, $this);
   
      $achCount = 0;
      $achTotal = 0.0;
      
      $this->logger->mlog("Number of Payments to review for ACH event: ".count($payables),
         Zend_Log::DEBUG, $this);
      
      /* @var $payment Merc_Model_Davis_VendorPayment */
      foreach ($payables as $payment) {
         
         $this->logger->mlog("Payment of id {$payment->getVendorPaymentId()} has status {$payment->getStatus()} and ".
                             "type {$payment->getPaymentType()}.", Zend_Log::DEBUG, $this);
         
         if ($payment->getStatus() === Merc_Model_Davis_VendorPayment::STATUS_SUBMITTED &&
             $payment->getPaymentType() === Merc_Model_Davis_Vendor::PAYMENT_TYPE_ACH) {
            
            $achCount++;
            $achTotal += $payment->getAmount();
         }
      }
            
      if ($achCount > 0) {
         // publish ach submission event
         $dataArray = array('timestamp' => time(),
                            'entryCount' => $achCount,
                            'creditAmount' => $achTotal,
                            'fileId' => $payment->getFileId(),
                            'bank' => $this->paymentConfig->bank);
         $this->logger->mlog('Publishing achTransmittal event: '.print_r($dataArray, true), Zend_Log::INFO, $this);
         $this->eventPublisher->createEvent(Davis_EventPublisher::PAYMENT_ACH_FILE_SUBMITTED, $dataArray);
      } else {
         $this->logger->mlog('NOT Publishing achTransmittal event since there are 0 submitted ACH payments.', Zend_Log::INFO, $this);
      }
      
      $this->logger->mlog('End publishAchEvent()', Zend_Log::INFO, $this);
   }

}
