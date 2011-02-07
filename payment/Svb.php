<?php

/**
 * Svb File Engine
 *
 * @package Davis
 */
class Davis_Payment_Generator_Svb extends Davis_Payment_Generator_Abstract 
{

    private $config;
    /**
     * @var Davis_Payment_Generator_Svb_FileHeader
     */
    private $fileHeaderRecordGenerator;
	
   /**
    * @var Davis_Payment_Generator_Svb_Email
    */
   private $emailRecordGenerator;
	
   /**
    * @var Davis_Payment_Generator_Svb_Payment
    */
    private $paymentRecordGenerator;
	
   /**
    * @var Davis_Payment_Generator_Svb_PaymentAddress
    */
   private $paymentAddressRecordGenerator;
   
   /**
    * @var Davis_Payment_Generator_Svb_Remittance
    */
   private $remittanceRecordGenerator;
   
   /**
    * @var Davis_Payment_Generator_Svb_FileTrailer
    */
   private $fileTrailerRecordGenerator;
	
      
   /**
    * Class constants used in creation/formatting of Svb file.
    */
   
   const DELIMITER                             = "^";
   
   /**
    * ctor.
    *
    */
   function __construct() {
      $this->config = Merc_Registry::get('configAppIni')->svb;
      $this->fileHeaderRecordGenerator = new Davis_Payment_Generator_Svb_FileHeader();
      $this->emailRecordGenerator = new Davis_Payment_Generator_Svb_Email();
      $this->paymentRecordGenerator = new Davis_Payment_Generator_Svb_Payment();
      $this->paymentAddressRecordGenerator = new Davis_Payment_Generator_Svb_PaymentAddress();
      $this->remittanceRecordGenerator = new Davis_Payment_Generator_Svb_Remittance();
      $this->fileTrailerRecordGenerator = new Davis_Payment_Generator_Svb_FileTrailer();
      parent::__construct();
   }
   
   /**
    * This is called in generate() in the parent class. 
    * 
    * $this->data comes from the parent
    */
   protected function generateEmail() {
      $emails = $this->config->receiptNotification->toArray();
      foreach ($emails as $email) {
         $this->data .= $this->emailRecordGenerator->generate($email);
      }
   }
   
   protected function generateTrailer($lineCount, $total) { 
      $this->data .= $this->fileTrailerRecordGenerator->generate($lineCount, $total);
   }
   
   protected function generateDebitRemittance($vendorDebit) {
      return $this->remittanceRecordGenerator->generateForDebit($vendorDebit);
   }
   
    /**
    * Generates the file for payments.
    * 
    *
    * @param Merc_Model_Davis_VendorPayment[] $payments
    * @param Davis_Payment_Abstract
    */
   public function generate($payments) {
      $this->logger->mlog('Begin generate(): # of payments=' . count($payments), Zend_Log::INFO, $this);
      
      // start with nothing
      $this->data = "";
      
      // generate header record
      $this->data .= $this->fileHeaderRecordGenerator->generate();
      
      // generate as many email records as specified in config
      $this->generateEmail();
      
      // generate payment records
      $paymentTotal = 0;
      $paymentRecords = array();
      $successfulPayments = 0;
      $failedPayments = 0;
      
      /* @var $payment Merc_Model_Davis_VendorPayment */
      foreach ($payments as $payment) {
         
         try {
            // we need to isolate the payment lines in case there's an isolated failure
            $paymentRecord = "";
            $paymentRecord .= $this->paymentRecordGenerator->generate($payment);
            $paymentRecord .= $this->paymentAddressRecordGenerator->generatePayer($this->vendorService->getMercantila());
            $paymentRecord .= $this->paymentAddressRecordGenerator->generatePayee($payment->getVendor());
            
            foreach ($payment->getPurchaseOrders() as $po) {
                 $paymentRecord .= $this->remittanceRecordGenerator->generate($po);
            }
            
            if (count($payment->getVendorDebits()) > 0) {
               /* @var $vendorDebit Merc_Model_Davis_VendorDebit */
               foreach ($payment->getVendorDebits() as $vendorDebit) {
                  $paymentRecord .= $this->generateDebitRemittance($vendorDebit);
               }
            }
            
            $this->logger->mlog("Adding to the payment array: " . $paymentRecord, Zend_Log::DEBUG, $this);
            
            $paymentRecords[] = $paymentRecord;
            $paymentTotal += $payment->getAmount();

            $payment->setStatus(Merc_Model_Davis_VendorPayment::STATUS_SUBMITTED);
            $successfulPayments++;
         
         } catch (Merc_Exception_Payment_ZeroPayableAmount $zex) {
            // the payable amount is zero, so we cannot submit to SVB;
            // however, we still want to consider the payment as paid
            $payment->setStatus(Merc_Model_Davis_VendorPayment::STATUS_SUBMITTED);
            $payment->setComment($zex->getMessage());
            $successfulPayments++;
         
         } catch (Merc_Exception $mex) {
            $payment->setStatus(Merc_Model_Davis_VendorPayment::STATUS_EXCEPTION);
            $payment->setComment($mex->getMessage());
            $failedPayments++;
         }
      }
      
      $this->data .= implode("", $paymentRecords);

      $this->generateTrailer(substr_count($this->data, self::END_OF_LINE) + 1, $paymentTotal);
      
      $this->logger->mlog("End generate(): \n" . $this->data, Zend_Log::INFO, $this);
      $this->logger->mlog("End generate(): {$successfulPayments} payments are being sent.", Zend_Log::INFO, $this);
      $this->logger->mlog("End generate(): {$failedPayments} payments have failed and need review.", Zend_Log::INFO, $this);
      
      // finally, check for payment limit breach, if necessary
      // will throw uncaught Merc_Exception if breached
      Davis_Payment_Utility::isPaymentTotalTooHigh($paymentTotal, $this->paymentConfig);
      
      return $this->data;
   }
   


   /**
    * sends Fast Track File to SVB
    *
    * @param $data string -- data file we are transmitting
    * @param $fileId int -- unique fileId per transmission
    * @return bool
    */
   public function sendBankFile($data, $fileId) {
      $this->logger->mlog('Begin sendBankFile()', Zend_Log::INFO, $this);

      $filePath = $this->config->storageDirectory;
      
      $filePrefix = $this->config->filePrefix;
      
      $filename = $filePath . "/" . $filePrefix . $fileId . "_" . date('mdYHis') . '.txt';
      $this->logger->mlog(' file: ' . $filename, Zend_Log::DEBUG, $this);
      
      if (file_put_contents($filename, $data)) {
         $command = APPLICATION_PATH . '/scripts/encrypt_and_transfer_file.pl --bank=svb --ciphertext-storage-dir=' . $filePath;
         $command .= ' --ftp-server=' . $this->config->ftpServer . ' ';
         $command .= ' --ftp-user=' . $this->config->ftpUser . ' ';
         $command .= ' --ftp-password=' . $this->config->ftpPassword . ' ';
         $command .= ' --sender="' . $this->config->sender . '" ';
         $command .= '  --recipient="' . $this->config->recipient . '" ';
         $command .= '  --cleartext-file=' . $filename;
         
         // call shell command to send PGP'ed file to Bank
         $this->logger->mlog('Calling shell command: '.$command, Zend_Log::INFO, $this);
         $execOutput = exec($command, $execResultArray, $execResultCode);
         $this->logger->mlog("Output of shell command is {$execResultCode}: ".$execOutput,
            Zend_Log::INFO, $this);
         if ($execResultCode != 0) {
            // failure, barf entire process
            throw new Exception("FTP shell script to Bank Failed with code {$execResultCode}! :".$execOutput);
         }
         
         // success! - delete cleartext file
         if (file_exists($filename)) {
            unlink($filename);
         }
      }
      $this->logger->mlog('End sendBankFile()', Zend_Log::INFO, $this);
   }

}
