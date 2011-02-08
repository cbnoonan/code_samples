<?php

main();

/**
 * Main function.  Parse local file into an array of cities and
 * coordinates.  Calculate distance using the TSP calculator.
 * Return quickest path results starting with Beijing.
 */
public function main() {
  $lines = file('cities.txt');

  $tsp = new TravelingSalesmanProblem();

   foreach ($lines as $line) {
      preg_match('/^(\S+)\t(\-?[0-9\.]+)\t(\-?[0-9\.]+)/', $line, $matches); 
      $city = $matches[1];
      $latitude = $matches[2];
      $longitude = $matches[3]; 
      $tsp->add($city, $latitude, $longitude);
   } 

   $tsp->compute();

   foreach ($tsp->getShortestRoute() as $city) {
      print($city. "\n");
   }
}


/** 
 * Traveling Salesman Problem 
 *
 *  
 * It takes any number of coordinates and brute force calculates the shortest 
 *    distance to travel to all those points.
 * It doesn't do anything clever like forcing a starting / ending point, 
 *    however this could easily be implemented.
 *
 * Note on solving: always travel to the unvisited node that is closest 
 *    to the one you’re currently at.
 *
 */
class TravelingSalesmanProblem {

    /**
     * all locations to visit
     */
    private $locations;

    /**
     * all longitudes 
     */
    private $longitudes;

    /**
     * all latitudes
     */
    private $latitudes;

    /**
     * holds the shorted route 
     */
    private $shortestRoute;

    /**
     * any matching shortest route 
     */
    private $shortestRoutes;

    /**
     * shortest distance 
     */
    private $shortestDistance;

    /**
     * all possible combination and their distances 
     */
    private $allRoutes;

    const START_CITY = "BEIJING";

    /**
     * Constructor
     *
     */
    public function __construct() {
        $this->locations  = array();
        $this->longitudes = array();
        $this->latitudes  = array();

        $this->shortestRoute    = array();
        $this->shortestRoutes   = array();
        $this->shortestDistance = 0;
        $this->allRoutes        = array();
    }
    
    /**
     * add a location
     * 
     * @param $city string
     * @param $logitude float
     * @param $latitude float
     */
    public function add($city, $longitude, $latitude) {
        $this->locations[$city] = array('longitude' => $longitude, 'latitude' => $latitude);
    }

    /**
     * The main function that does the calculations
     */
    public function compute() {
        $locations = $this->locations;
        
        foreach ($locations as $city => $coordinates) {
            $this->longitudes[$city] = $coordinates['longitude'];
            $this->latitudes[$city] = $coordinates['latitude'];
        }
        $locations = array_keys($locations);
        
        $this->allRoutes = $this->getAllPermutationsBeginningWithBeijing($locations);
        
        foreach ($this->allRoutes as $key => $permutation) {
            $i = 0;
            $total = 0;
            foreach ($permutation as $value) {
                if ($i < (count($this->locations) -1) ) {
                    $total += $this->calculateDistance($this->latitudes[$permutation[$i]],
                                              $this->longitudes[$permutation[$i]],
                                              $this->latitudes[$permutation[$i+1]],
                                              $this->longitudes[$permutation[$i+1]]
                                             );
                }
                $i++;
            }
            $this->allRoutes[$key]['distance'] = $total;
            if ($total < $this->shortestDistance || $this->shortestDistance == 0) {
                $this->shortestDistance = $total;
                $this->shortestRoute = $permutation;
                $this->shortestRoutes = array();
            }
            if ($total == $this->shortestDistance) {
                $this->shortestRoutes[] = $permutation;
            }
        }
    }

    /**
     * Work out the distance between 2 longitude and latitude pairs
     *
     * This uses the ‘haversine’ formula to calculate great-circle distances between 
     *  the two points – that is, the shortest distance over the earth’s surface – 
     *  giving an ‘as-the-crow-flies’ distance between the points (ignoring any hills!).
     *
     * Haversine formula:
     *
     * R = earth’s radius (mean radius = 6,371km)
     * Δlat = lat2− lat1
     * Δlong = long2− long1
     * a = sin²(Δlat/2) + cos(lat1).cos(lat2).sin²(Δlong/2)
     * c = 2.atan2(√a, √(1−a))
     * d = R.c
     *
     * (Note that angles need to be in radians to pass to trig functions).
     *
     * @param $latutude1 float
     * @param $longitude1 float
     * @param $latutude2 float
     * @param $longitude2 float
     */
    private function calculateDistance($latutude1, $longitude1, $latutude2, $longitude2) { 
        if ($latutude1 == $latutude2 && $longitude1 == $longitude2) return 0;

        $theta = $longitude1 - $longitude2; 

        // convert to radians from degrees... the earth is a sphere.
        $distance = sin(deg2rad($latutude1)) * sin(deg2rad($latutude2)) + 
                cos(deg2rad($latutude1)) * cos(deg2rad($latutude2)) * cos(deg2rad($theta)); 
        $distance = acos($distance); 
        $distance = rad2deg($distance); 
        $miles = $distance * 60 * 1.1515;
        
        return $miles;  // in miles
    }

    /**
     * Borrowed from the PHP Cookbook
     *
     * This equation can be represented like this: n! = n * ((n - 1)!) That is, the 
     *   factorial for any given number is equal to that number multiplied by the 
     *   factorial of the number one lower - this is clearly a case for recursive functions! 
     *
     * @param $items hash of locations, with key index
     * @param $permutation array 
     * 
     * @return array of all possible permutations
     */
    private function getAllPermutations($items, $permutation = array( )) {
        static $allPermutations;

        if (empty($items)) {
            $allPermutations[] = $permutation;
        }  else {
            for ($i = count($items) - 1; $i >= 0; --$i) {
                $newitems = $items;
                $newpermutation = $permutation;

                list($temporaryVariable) = array_splice($newitems, $i, 1);

                array_unshift($newpermutation, $temporaryVariable);
                $this->getAllPermutations($newitems, $newpermutation);
            }
        }

        return $allPermutations;
    }

    private function getAllPermutationsBeginningWithBeijing($locations) {
//        $allPermutations = $this->getAllPermutations($locations);

        $routesBeginningWithBeijing = array();
        foreach ($this->getAllPermutations($locations) as $p) {
           if (strtoupper($p[0]) == self::START_CITY) {
              $routesBeginningWithBeijing[] = $p;
           }
        }
        return $routesBeginningWithBeijing;
    }
        
        
    /**
     * Return an array of the shortest possible route
     *
     * @return array
     */
    public function getShortestRoute() {
        return $this->shortestRoute;
    }

    /**
     * returns an array of any routes that are exactly the same 
     * distance as the shortest (ie the shortest backwards normally)
     *
     * @return array of $shortestRoutes
     */
    public function getMatchingShortestRoutes() {
        return $this->shortestRoutes;
    }

    /**
     *  The shortest possible distance to travel
     *
     * @return int
     */
    public function getShortestDistance() {
        return $this->shortestDistance;
    }

    /**
     *  Returns an array of all the possible routes
     *
     * @return array
     */
    public function getAllRoutes() {
        return $this->allRoutes;
    }

    public function setAllRoutes($allRoutes) {
       $this->allRoutes = $allRoutes;
    }
}

?>
