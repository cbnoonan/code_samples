<?php


/**
 * Base class for tracking packages via Carrier APIs and such
 *
 * @package Davis
 */
abstract class Davis_Ship_Track_Abstract {
   
   /**
    * @var Davis_Ship_Manager
    */
   protected $shipManager;
   
   /**
    * Instantiated in child class contructors to be the API DAO specific to that carrier.
    *
    * @var Merc_Dao_Davis_Api_Tracking
    */
   protected $trackingApiDao;
   
   /**
    * @var Merc_DAO_Davis_OrderLineShipmentMapDao
    */
   protected $orderLineShipmentMapDao;
   
   /**
    * @var Merc_DAO_Davis_CarrierDao
    */
   protected $carrierDao;
   
   /**
    * @var Merc_DAO_Davis_OrderLineDao
    */
   protected $orderLineDao;
   
   /**
    * @var Merc_DAO_Davis_ShipmentDao
    */
   protected $shipmentDao;
   
   /**
    * @var array of
    */
   protected $trackingHandlers;
   
   /**
    * @var Merc_Log
    */
   protected $logger;
   
   /**
    * @var Merc_Log
    */
   protected $loggerCrit;
   
   /**
    * @var int the number of shipments records to deal with at a time.
    *      Since the collectShipments() method is doing two queries, we could
    *      actually get up to twice this number, but oh well. it still serves to
    *      operate in chunks.
    */
   private $chunkSize = 100;
   
   /**
    * @var string
    */
   protected $carrierCode;
   
   /**
    * The date before which we should not track in any case.
    * @var int unix timestamp
    */
   protected $dayOne;
   
   /**
    * A unix timestamp before which we do not log critical errors when we
    * try to track an invalid tracking number.
    * @var int $tolerateInvalidTrackingBeforeDate
    */
   protected $tolerateInvalidTrackingBeforeDate;
   
   /**
    * The number of days into the past that we will track shipments that have not been delivered
    * @var int
    */
   protected $daysPastToTrackUndelivered;
   
   /**
    * The number of days into the past that we will track canceled shipments
    * @var int
    */
   protected $daysPastToTrackCanceled;
   
   /**
    * @var Merc_TransactionManager
    */
   protected $transactionManager;
   
   /**
    *
    */
   protected function __construct() {
      $this->logger = Merc_Registry::get('loggerShip');
      
      // There are two loggers here because we have a unit test that specifically
      // tests for a CRIT log line. Having two loggers is the cleanest way.
      $this->loggerCrit =  Merc_Registry::get('loggerShip');

      $this->shipmentDao = Merc_Registry::get('shipmentDao');
      $this->orderLineShipmentMapDao = Merc_Registry::get('orderLineShipmentMapDao');
      $this->orderLineDao = Merc_Registry::get('orderLineDao');
      $this->carrierDao = Merc_Registry::get('carrierDao');
      
      $this->shipManager = Merc_Registry::get('shipManager');
      $this->transactionManager = Merc_Registry::get('transactionManager');
      $this->trackingHandlers[] = Merc_Registry::get('trackingHandlerShipment');
      $this->trackingHandlers[] = Merc_Registry::get('trackingHandlerProduct');
      $this->trackingHandlers[] = Merc_Registry::get('trackingHandlerOrderLine');
      $this->trackingHandlers[] = Merc_Registry::get('trackingHandlerCanceledShipment');
      $this->trackingHandlers[] = Merc_Registry::get('trackingHandlerReturn');
      $this->daysPastToTrackUndelivered = Merc_Registry::get('configAppIni')->carriers->daysPastToTrackUndelivered;
      $this->daysPastToTrackCanceled = Merc_Registry::get('configAppIni')->carriers->daysPastToTrackCanceled;
      $this->dayOne = Merc_Util_Date::mysql2unixDate(Merc_Registry::get('configAppIni')->carriers->dayOne);
      $this->tolerateInvalidTrackingBeforeDate = Merc_Util_Date::mysql2unixDate(Merc_Registry::get('configAppIni')->carriers->tolerateInvalidTrackingBeforeDate);
   }

   /**
    *
    */
   public function execute() {
      $this->logger->mlog('Begin '.__METHOD__, Zend_Log::INFO, $this);
      
      $shipments = array();
      $chunkNumber = 1;
      
      do {
         
         $shipments = $this->collectShipments($chunkNumber);
         
         foreach ($shipments as $shipment) {
            /* @var $shipment Merc_Model_Davis_Shipment */
            if($this->shouldTrackShipment($shipment)){
               $this->logger->mlog('Asking carrier about shipment ID: '.$shipment->getShipmentId(). ' tracking number: '.$shipment->getTrackingNumber(), Zend_Log::DEBUG, $this);
               try{
                  $this->transactionManager->beginTransaction();
                  $response = $this->getTrackingResponse($shipment);
                  if (is_object($response)){
                     if ($this->shouldHandleResponse($response)){
                        $this->handleResponse($shipment, $response);
                     }
                  } else {
                     $this->logger->mlog('No tracking found for '.$this->carrierCode.' tracking number '.$shipment->getTrackingNumber(), Zend_Log::ERR, $this);
                  }
                  $this->transactionManager->commit();
               } catch (Merc_Exception_Ship_InvalidTrackingNumber $itn){
                  if($shipment->getCreatedDate() > $this->tolerateInvalidTrackingBeforeDate){
                     // log invalid tracking number at CRIT
                     $this->loggerCrit->mlog('Invalid tracking number: '.$shipment->getTrackingNumber(), Zend_Log::CRIT, $this);
                     $this->transactionManager->rollBack();
                  }
               } catch (Exception $ex1){
                  // log individual record failure at CRIT which we monitor then rollback and continue.
                  $this->logger->mlog('Exception tracking '.$this->carrierCode.' shipment '.$shipment->getTrackingNumber().': '.$ex1->getMessage(), Zend_Log::CRIT, $this);
                  $this->transactionManager->rollBack();
               }
            }
         }
         
         $chunkNumber++;
         
      } while (count($shipments) > 0);
      
      $this->logger->mlog('End '.__METHOD__, Zend_Log::INFO, $this);
      
   }
   
   /**
    * @param Merc_Model_Davis_Shipment $shipment
    */
   protected function shouldTrackShipment($shipment){
      $shouldTrackShipment = true;
      if($shipment->getDeliveryDate() > 0 && $shipment->getPickupDate() > 0){
         $this->logger->mlog('Shipment '.$shipment->getShipmentId().' already has both pickup and delivery dates. Skipping...', Zend_Log::DEBUG, $this);
         $shouldTrackShipment = false;
      }
      return $shouldTrackShipment;
   }

   /**
    * Determine if $trackResponse is ready to handle
    *
    * @param Merc_Model_Davis_TrackingResponse $trackingResponse
    */
   protected function shouldHandleResponse($trackingResponse) {
      $shouldHandleResponse = true;
      if (!$trackingResponse->getPickupDate() && $trackingResponse->getDeliveryDate()) {
      	// This is (usually) caused by an error in the 3rd party tracking system. 
      	// We handle the backfill of data for this case elsewhere.
   	   $this->loggerCrit->mlog('Delivery date set, but ship date still NULL, for tracking number: ' . 
   	     $trackingResponse->getTrackingNumber(), Zend_Log::ERR, $this);
      }
      return $shouldHandleResponse;
   }
   
   /**
    * @param int $chunkNumber
    * @return array of Merc_Model_Davis_Shipment
    */
   private function collectShipments($chunkNumber){
      $this->logger->mlog('Begin '.__METHOD__, Zend_Log::INFO, $this);
      $shipments = array();
      
      //  we want to track undelivered, uncanceled shipments for a certain period of time
      $notCanceledStartDate = max($this->dayOne, Merc_Util_Date::startOfDay(time() - ($this->daysPastToTrackUndelivered * Merc_Util_Date::SECONDS_IN_DAY)));
      $filters = array(
        'carrierCode' => $this->carrierCode, // this is set in the child class.
        'estShipDateAfter' => $notCanceledStartDate,
        'isCanceledForAllOrderLines' => false,
        'ignoreTracking' => false,
      );
      $result = $this->shipmentDao->getPagedWithIsCanceledFilters($filters, $chunkNumber, $this->chunkSize);
      $shipments = $result->getRecords();

      //  we want to track undelivered, canceled shipments for a certain period of time
      $canceledStartDate = max($this->dayOne, Merc_Util_Date::startOfDay(time() - ($this->daysPastToTrackCanceled * Merc_Util_Date::SECONDS_IN_DAY)));
      $filters = array(
        'carrierCode' => $this->carrierCode, // this is set in the child class.
        'estShipDateAfter' => $canceledStartDate,
        'isCanceledForAllOrderLines' => true,
        'ignoreTracking' => false,
      );
      $result = $this->shipmentDao->getPagedWithIsCanceledFilters($filters, $chunkNumber, $this->chunkSize);

      // array_merge doesn't preserve the array index, so here's our workaround
      $allShipments = array();
      foreach ($shipments as $id=>$value) {
      	$allShipments[$id] = $value;
      }
      foreach ((array)$result->getRecords() as $id => $value) {
      	$allShipments[$id] = $value;
      }

      // and go!
      $this->logger->mlog('End '.__METHOD__.' found '.count($allShipments), Zend_Log::INFO, $this);
      return $allShipments;
   }
   
   /**
    * Call the tracking APIs to get shipment tracking information for the given shipment.
    *
    * @param Merc_Model_Davis_Shipment $shipment
    * @return Merc_Model_Davis_TrackingResponse
    */
   protected function getTrackingResponse($shipment){
      $this->logger->mlog('Begin '.__METHOD__, Zend_Log::INFO, $this);
      
      $trackingNumber = $shipment->getTrackingNumber();
      $this->logger->mlog('Getting tracking for '.$trackingNumber, Zend_Log::DEBUG, $this);
      $tracking = $this->trackingApiDao->getTrackingResponseByTrackingNumber($trackingNumber);
      if (is_object($tracking)){
         $this->logger->mlog('Tracking received: '.print_r($tracking, true), Zend_Log::DEBUG, $this);
      }
      
      $this->logger->mlog('End '.__METHOD__.(is_object($tracking) ? '' : ' NO').' tracking received.', Zend_Log::INFO, $this);
      return $tracking;
   }
      
   /**
    * Call out to handler classes that are registered in the constructor to apply changes to
    * in our systems based on the information in the tracking response.
    *
    * @var Merc_Model_Davis_Shipment $shipment
    * @var Merc_Model_Davis_TrackingResponse $trackingResponse
    */
   protected function handleResponse($shipment, $trackingResponse){
      $this->logger->mlog('Begin '.__METHOD__, Zend_Log::INFO, $this);
      foreach ($this->trackingHandlers as $handler){
      	// we'd kind of like to prevent the handlers from affecting each other.
      	$s = clone $shipment;
      	$response = clone $trackingResponse;
        $handler->handle($s, $response);
      }
      $this->logger->mlog('End '.__METHOD__, Zend_Log::INFO, $this);
   }

   /**
    * This setter helps with testing so you can inject mocks
    * @param Davis_Ship_Shipping $shippingService
    */
   public function setShippingService($shippingService) {
      $this->shippingService = $shippingService;
   }

   /**
    * This setter helps with testing so you can inject mocks
    * @param Merc_Dao_Davis_Api_Tracking $trackingApiDao
    */
   public function setTrackingApiDao($trackingApiDao) {
      $this->trackingApiDao = $trackingApiDao;
   }

   /**
    * This setter helps with testing so you can inject mocks
    * @param array $trackingHandlers
    */
   public function setTrackingHandlers($trackingHandlers) {
      $this->trackingHandlers = $trackingHandlers;
   }

   /**
    * This setter helps with testing so we can test the
    * case of expected log behavior
    * @param unknown_type $logger
    */
   public function setLogger($logger) {
   	$this->logger = $logger;
   }
   
   /**
    * This setter helps with testing so we can test the
    * case of expected log behavior
    * @param unknown_type $logger
    */
   public function setLoggerCrit($loggerCrit) {
      $this->loggerCrit = $loggerCrit;
   }
   
   /**
    * @param Davis_EventPublisher $eventPublisher
    */
   public function setEventPublisher($eventPublisher) {
      $this->eventPublisher = $eventPublisher;
   }
   
   /**
    * @param int $dayOne
    */
   public function setDayOne($dayOne) {
      $this->dayOne = $dayOne;
   }

}

