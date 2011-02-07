<?php


/**
 * Data Access Object for Merc_DAO_Davis_UPSDao
 *
 * @package Merc
 * @subpackage Davis
 * @subpackage API
 */
class Merc_DAO_Davis_API_UPSDao implements Merc_DAO_Davis_API_Tracking {
   
   /**
    * @var Merc_Log
    */
   private $logger;
   
   private $maxRetries;
   private $sleepSeconds;
   
   /**
    * These things below are not likely to change, and so are not in config (at this time).
    */
   private $accessLicenseNumber = "******";
   private $userId = "example";
   private $password = "blahlblahfoo";

   /**
    * ctor
    * inits $db adapter and logger
    */
   public function __construct() {
      $this->logger = Merc_Registry::get('loggerShip');
      $this->maxRetries = Merc_Registry::get('configAppIni')->general->backgroundMaxRetries;
      $this->sleepSeconds = Merc_Registry::get('configAppIni')->general->backgroundSleepSeconds;
   }

   /**
    * Get tracking response from API based on tracking number
    *
    * @param string $trackingNumber
    * @return Merc_Model_Davis_TrackingResponse
    */
   public function getTrackingResponseByTrackingNumber($trackingNumber) {
      $this->logger->mlog("Begin getTrackingResponseByTrackingNumber(): " . $trackingNumber, Zend_Log::INFO, $this);
      
      // sanity check
      if(!$this->isValidTrackingNumber($trackingNumber)) {
         throw new Merc_Exception_Ship_InvalidTrackingNumber('Invalid Ups tracking number: ' . $trackingNumber);
      }
      $request = $this->buildRequest($trackingNumber);
      
      $upsTrackURL = Merc_Registry::get('configAppIni')->carriers->ups->url;
      
      //initialise a CURL session
      $ch = curl_init();
      
      //set the server we are using
      curl_setopt($ch, CURLOPT_URL, $upsTrackURL);
      curl_setopt($ch, CURLOPT_HEADER, true);
      
      //set it to return the transfer as a string from curl_exec
      curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
      
      //stop CURL from verifying the peer's certificate
      curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
      curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
      
      //set method as POST
      curl_setopt($ch, CURLOPT_POST, 1);
      
      //set the XML body of the request
      curl_setopt($ch, CURLOPT_POSTFIELDS, array("body" => $request));
      $response = curl_exec($ch);
      
      $maxRetries = $this->maxRetries;
      $sleepSeconds = $this->sleepSeconds;
      
      for($i = 0; $i <= $maxRetries; $i++) {
         
         $responseRaw = curl_exec($ch);
         
         if($responseRaw === false) {
            // error and retry
            $this->logger->mlog('There was a curl error: ' . curl_error($ch), Zend_Log::INFO, $this);
            sleep($sleepSeconds++);
            continue;
         
         } else {
            // received a response
            $response = strstr($responseRaw, '<?xml');
            
            if($response) {
               // convert to SimpleXML
               $response = simplexml_load_string($response);
               $this->logger->mlog("Response: " . print_r($response, true), Zend_Log::DEBUG, $this);
               
               if(sizeof($response->Shipment)) {
                  // should be 1... unless no track data
                  $trackingResponse = $this->mapTrackingResponse($trackingNumber, $response);
               } else {
                  $this->logger->mlog("Ups tracking response was empty.", Zend_Log::DEBUG, $this);
                  $trackingResponse = null;
               }
               
               curl_close($ch);
               $this->logger->mlog("End getTrackingResponseByTrackingNumber(): " . sizeof($trackingResponse), Zend_Log::INFO, $this);
               return $trackingResponse;
            
            } else {
               // if there is no XML segment in the response, retry
               $this->logger->mlog('There was no XML in the response: ' . $responseRaw, Zend_Log::INFO, $this);
               sleep($sleepSeconds++);
               continue;
            }
         }
      }
      
      // if we've arrived here, we went through retries without success.
      // throw exception.
      curl_close($ch);
      throw new Merc_Exception("Retries fully exhausted. Unable to track UPS tracking number: " . $trackingNumber);
   }

   /**
    * Building the XML request to UPS track
    *
    * @param string $trackingNumber
    * @return obj $request
    */
   private function buildRequest($trackingNumber) {
      $this->logger->mlog('Begin buildRequest():', Zend_Log::INFO, $this);
      
      $request = '
          <?xml version="1.0"?>
         <AccessRequest xml:lang="en-US">
            <AccessLicenseNumber>' . $this->accessLicenseNumber . '</AccessLicenseNumber>
            <UserId>' . $this->userId . '</UserId>
           <Password>' . $this->password . '</Password>
        </AccessRequest>
        <?xml version="1.0"?>
        <TrackRequest xml:lang="en-US">
          <Request>
            <TransactionReference>
             <CustomerContext>Example 1</CustomerContext>
             <XpciVersion>1.0001</XpciVersion>
            </TransactionReference>
            <RequestAction>Track</RequestAction>
            <RequestOption>activity</RequestOption>
          </Request>
          <TrackingNumber>' . $trackingNumber . '</TrackingNumber>
          <IncludeFreight>01</IncludeFreight>
         </TrackRequest>';
      
      $this->logger->mlog('Built request: ' . $request, Zend_Log::DEBUG, $this);
      $this->logger->mlog('End buildRequest()', Zend_Log::INFO, $this);
      return $request;
   }

   /**
    * Map Curl response to Tracking Response object
    *
    * @param string
    * @param SimpleXMLElement
    *
    * @return Merc_Model_Davis_TrackingResponse
    */
   private function mapTrackingResponse($trackingNumber, $response) {
      $this->logger->mlog("Begin mapTrackingResponse()", Zend_Log::INFO, $this);
      
      $trackingResponse = new Merc_Model_Davis_TrackingResponse();
      $trackingResponse->setTrackingNumber($trackingNumber);
      $trackingResponse->setNumberOfBoxes(NULL);
      
      // get weight information
      $weight = $this->getActualWeight($response);
      if($weight) {
         $trackingResponse->setActualWeight($weight);
      }
      
      // get pickup information
      $pickupDate = $this->getPickupDate($response);
      if($pickupDate) {
         $trackingResponse->setPickupDate($pickupDate);
      }
      
      // get delivery information
      $deliveryDate = $this->getDeliveryDate($response);
      if($deliveryDate) {
         $trackingResponse->setDeliveryDate($deliveryDate);
      }
      
      $this->logger->mlog("End mapTrackingResponse(): " . print_r($trackingResponse, true), Zend_Log::INFO, $this);
      return $trackingResponse;
   }

   /**
    * Format validation
    * @param string $trackingNumber
    * @return bool
    */
   private function isValidTrackingNumber($trackingNumber) {
      return Merc_Util_Validate::isUpsTrackingNumber($trackingNumber);
   }

   /**
    * Get the actual weight from the response
    *
    * @param SimpleXMLElement
    *
    * @return double
    */
   private function getActualWeight($response) {
      $this->logger->mlog("Begin getActualWeight()", Zend_Log::INFO, $this);
      
      // get actual weight
      $xml = $response->Shipment->ShipmentWeight;
      // is there a better way!?
      if (is_object($xml) && count($xml->children()) > 0) {
        foreach ($xml->children() as $key => $value) {
           if ($key == 'Weight') {
              $value = (array)$value;
              $weight = $value[0];
              break;
           }
         }
      }

      
      if (!$weight) {
         $xml = $response->Shipment->Package->PackageWeight;
         if (is_object($xml)) {
            foreach ($xml->children() as $key => $value) {
               if ($key == 'Weight') {
                  $value = (array)$value;
                  $weight = $value[0];
                  break;
               }
            }
         }
      }
      
      if ($weight) {
         $this->logger->mlog("End getActualWeight(): ", Zend_Log::INFO, $this);
         return $weight;
      } else {
         $this->logger->mlog("End getActualWeight(): null", Zend_Log::INFO, $this);
         return null;
      }
   }

   /**
    * Get the Pickup status from the response
    *
    * @param SimpleXMLElement[]
    *
    * @return int
    */
   private function getPickupDate($response) {
      $this->logger->mlog("Begin getPickupDate()", Zend_Log::INFO, $this);
      
      // get pick up date, if it exists....
      preg_match('/(\d{4})(\d{2})(\d{2})/', $response->Shipment->PickupDate, $matches);
      if($matches) {
         $pickupDate = mktime(0, 0, 0, $matches[2], $matches[3], $matches[1]);
         $this->logger->mlog("End getPickupDate()", Zend_Log::INFO, $this);
         return $pickupDate;
      }
      
      // Ugh, if pick up date is not set, try looking for the origin scan...
      if(!$pickupDate) {
         
         $xml = $response->Shipment->Package;
         if (is_object($xml) && count($xml->children()) > 0) {
            foreach($xml->children() as $firstKey => $firstValue) {
               
               if($firstKey == 'Activity') {
                  foreach($firstValue->children() as $secondKey => $secondValue) {
                     
                     if($secondKey == 'Status') {
                        $secondValue = (array)$secondValue;
                        $status = (array)$secondValue['StatusType'];
                        
                        // code for 'ORIGIN SCAN'
                        if($status['Code'] == 'I') {
                           $pickupDate = (array)$firstValue->Date;
                           preg_match('/(\d{4})(\d{2})(\d{2})/', $pickupDate[0], $pickupMatches);
                           
                           if($pickupMatches) {
                              $pickupDate = mktime(0, 0, 0, $pickupMatches[2], $pickupMatches[3], $pickupMatches[1]);
                              break;
                           }
                        }
                     }
                  }
               }
            }
         }
      }
      
      if($pickupDate) {
         $this->logger->mlog("End getPickupDate(): ", Zend_Log::INFO, $this);
         return $pickupDate;
      } else {
         $this->logger->mlog("End getPickupDate(): null", Zend_Log::INFO, $this);
         return null;
      }
   }

   /**
    * Get the Delivery status from the response
    *
    * @param SimpleXMLElement[]
    *
    * @return int
    */
   private function getDeliveryDate($response) {
      $this->logger->mlog("Begin getDeliveryDate()", Zend_Log::INFO, $this);
      
      // get delivery date, if it exists...
      preg_match('/(\d{4})(\d{2})(\d{2})/', $response->Shipment->DeliveryDetails->DeliveryDate, $deliveredMatches);
      if($deliveredMatches) {
         $deliveryDate = mktime(0, 0, 0, $deliveredMatches[2], $deliveredMatches[3], $deliveredMatches[1]);
         $this->logger->mlog("End getDeliveryDate()", Zend_Log::INFO, $this);
         return $deliveryDate;
      }
      
      // Ugh, if delivery date is not set, try looking for the delivery status...
      if(!$deliveryDate) {
         
         $xml = $response->Shipment->Package->Activity;
         
         if(!is_object($xml)) {
            $this->logger->mlog('Strange: even though we got a response from the UPS tracking API, it had no "Activites" in it. In ' . __METHOD__, Zend_Log::ERR, $this);
            return null;
         }
         
         foreach($xml->children() as $key => $value) {
            
            if($key == 'Status') {
               
               $value = (array)$value;
               $status = (array)$value['StatusType'];
               
               if($status['Code'] == 'D') {
                  
                  $deliveryDate = (array)$xml->Date;
                  preg_match('/(\d{4})(\d{2})(\d{2})/', $deliveryDate[0], $deliveredMatches);
                  
                  if($deliveredMatches) {
                     $deliveryDate = mktime(0, 0, 0, $deliveredMatches[2], $deliveredMatches[3], $deliveredMatches[1]);
                     break;
                  }
               }
            }
         }
      }
      
      if($deliveryDate) {
         $this->logger->mlog("End getDeliveryDate(): ", Zend_Log::INFO, $this);
         return $deliveryDate;
      } else {
         $this->logger->mlog("End getDeliveryDate(): null", Zend_Log::INFO, $this);
         return null;
      }
   }

}

