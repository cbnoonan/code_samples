<?php

/**
 * Payment Manager
 *
 * @package Davis
 */
class Davis_Payment_Generator_Factory
{
   
	/**
    * @var Merc_Log
    */
   protected $logger;

   /**
    * ctor.
    *
    */
   function __construct() {
      $this->logger = Merc_Registry::get('loggerPay');
   }
   
   /**
    * Takes a config value and determines which payment Generator to use
    * @param string bank -- fastTrack or bofa. Set in the ini.  
    * @return Davis_Payment_Abstract
    */
   public function getPaymentFactory($bank) {
     $this->logger->mlog("Begin getPaymentService() with {$bank}.", Zend_Log::INFO, $this);
   	
     switch ($bank) {
        // factory for Payment Generator classes
        case 'bofa':
           $this->logger->mlog("End getPaymentFactory() with bofa.", Zend_Log::INFO, $this);
           return new Davis_Payment_Generator_BankOfAmerica();
        case 'svb':
           $this->logger->mlog("End getPaymentFactory() with svb", Zend_Log::INFO, $this);
           return new Davis_Payment_Generator_Svb();
        default:
           throw new Merc_Exception("No Payment class implemented for bank: {$bank}");
     }
   	
   }
}

