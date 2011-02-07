<?php


/**
 * Do whatever we want to shipments based on tracking info
 *
 *
 * @package  Davis
 */
class Davis_Ship_Track_ShipmentHandler extends Davis_Ship_Track_AbstractHandler implements Davis_Ship_Track_Handler {
   
   /**
    * @var Merc_DAO_Davis_ShipmentDao
    */
   private $shipmentDao;

   /**
    * ctor
    *
    */
   function __construct() {
      parent::__construct();
      $this->shipmentDao = Merc_Registry::get('shipmentDao');
   }

   /**
    * Save changes to a shipment from data in a tracking response.
    *
    * @var Merc_Model_Davis_Shipment $shipment
    * @var Merc_Model_Davis_TrackingResponse $trackingResponse
    */
   public function handle($shipment, $trackingResponse) {
      $this->logger->mlog('Begin '.__METHOD__, Zend_Log::INFO, $this);
      $shouldUpdate = false;
      // here we use a new shipment object so we can make sure not to overwrite any
      // fields in the database that we aren't explicitly updating.
      $updater = new Merc_Model_Davis_Shipment();
      $updater->setShipmentId($shipment->getShipmentId());
      
      $determinedPickupDate = $this->determinePickupDate($trackingResponse, $shipment);
            
      
      if ($determinedPickupDate != $shipment->getPickupDate()) {
         $updater->setPickupDate($determinedPickupDate);
         $shouldUpdate = true;
         $this->logger->mlog('Updating pickup date for shipment '.$shipment->getShipmentId().' to '.Merc_Util_Date::unix2mysqlDatetime($determinedPickupDate) , Zend_Log::DEBUG, $this);
      }
      if($trackingResponse->getDeliveryDate() && $trackingResponse->getDeliveryDate() != $shipment->getDeliveryDate()) {
         $updater->setDeliveryDate($trackingResponse->getDeliveryDate());
         $shouldUpdate = true;
         $this->logger->mlog('Updating delivery date for shipment '.$shipment->getShipmentId().' to '.Merc_Util_Date::unix2mysqlDatetime($trackingResponse->getDeliveryDate()) , Zend_Log::DEBUG, $this);
      }
      if($trackingResponse->getNumberOfBoxes() && $trackingResponse->getNumberOfBoxes() != $shipment->getNumberOfBoxes()) {
         $updater->setNumberOfBoxes($trackingResponse->getNumberOfBoxes());
         $shouldUpdate = true;
         $this->logger->mlog('Updating number of boxes for shipment '.$shipment->getShipmentId().' to '.$trackingResponse->getNumberOfBoxes(), Zend_Log::DEBUG, $this);
      }
      if($trackingResponse->getActualWeight() && $trackingResponse->getActualWeight() != $shipment->getActualWeightPounds()) {
         $updater->setActualWeightPounds($trackingResponse->getActualWeight());
         $shouldUpdate = true;
         $this->logger->mlog('Updating actual total weight for shipment '.$shipment->getShipmentId().' to '.$trackingResponse->getActualWeight(), Zend_Log::DEBUG, $this);
      }
      if($shouldUpdate){
         $this->shipmentDao->updateById($updater);
      }
      
      $this->logger->mlog('End '.__METHOD__, Zend_Log::INFO, $this);
   }

   /**
    * This setter here just to help with testing via mocks
    *
    * @param Merc_DAO_Davis_ShipmentDao $shipmentDao
    */
   public function setShipmentDao($shipmentDao) {
      $this->shipmentDao = $shipmentDao;
   }

}

