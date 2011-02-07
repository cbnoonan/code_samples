<?php

/**
 *
 * @package Davis
 */
class Merc_Model_Davis_TrackingResponse {

   private $trackingNumber;
   private $pickupDate;
   private $deliveryDate;
   private $numberOfBoxes;
   private $actualWeight;

   /**
    * @return unknown
    */
   public function getNumberOfBoxes() {
      return $this->numberOfBoxes;
   }

   /**
    * @param unknown_type $numberOfBoxes
    */
   public function setNumberOfBoxes($numberOfBoxes) {
      $this->numberOfBoxes = $numberOfBoxes;
   }

   /**
    * @return unknown
    */
   public function getPickupDate() {
      return $this->pickupDate;
   }

   /**
    * @param unknown_type $pickupDate
    */
   public function setPickupDate($pickupDate) {
      $this->pickupDate = $pickupDate;
   }

   /**
    * @return unknown
    */
   public function getTrackingNumber() {
      return $this->trackingNumber;
   }

   /**
    * @param unknown_type $trackingNumber
    */
   public function setTrackingNumber($trackingNumber) {
      $this->trackingNumber = $trackingNumber;
   }

   /**
    * @return unknown
    */
   public function getActualWeight() {
      return $this->actualWeight;
   }

   /**
    * @param unknown_type $actualWeight
    */
   public function setActualWeight($actualWeight) {
      $this->actualWeight = $actualWeight;
   }
   
	/**
	 * @return unknown
	 */
	public function getDeliveryDate() {
		return $this->deliveryDate;
	}
	
	/**
	 * @param unknown_type $deliveryDate
	 */
	public function setDeliveryDate($deliveryDate) {
		$this->deliveryDate = $deliveryDate;
	}



}

