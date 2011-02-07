<?php


/**
 * Tracking packages via UPS.
 *
 */
class Davis_Ship_Track_Ups extends Davis_Ship_Track_Abstract {
   
   /**
    * @var string This code is required for the parent class to query shipments for only this carrier.
    */
   protected $carrierCode = Merc_Model_Davis_Carrier::UPS;
   

   /**
    *
    */
   public function __construct() {
      parent::__construct();
      $this->trackingApiDao = Merc_Registry::get('upsDao');
   }


}

