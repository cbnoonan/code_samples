<?php


/**
 * Facade for retrieving package tracking info from carriers
 *
 * @package Davis
 */
class Davis_Ship_Track {
   
   /**
    * @var array of Davis_Ship_Track_Abstract
    */
   private $trackers;
   
   /**
    * @var Merc_Log
    */
   private $logger;

   /**
    *
    */
   public function __construct() {
      $this->logger = Merc_Registry::get('loggerShip');
      $this->trackers = array(
         Merc_Registry::get('trackServiceHomeDirect'),
         Merc_Registry::get('trackServiceCeva'),
         Merc_Registry::get('trackServiceFedex'),
         Merc_Registry::get('trackServiceIcat'),
         Merc_Registry::get('trackServiceUps'),
      );
   }

   /**
    *
    */
   public function execute() {
      foreach($this->trackers as $tracker) {
         $tracker->execute();
      }
   }

   /**
    * This setter just here to facilitate testing with mocks.
    *
    * @param array $trackers
    */
   public function setTrackers($trackers) {
      $this->trackers = $trackers;
   }

}

