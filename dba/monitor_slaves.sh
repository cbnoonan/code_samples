#!/bin/bash
# Slave DB monitor.
#
# What script does :
#  - queries DB hosts 
#  - logs slaves status into respective log files
#  - sends alert if slave stopped replication or slave is over 3 hours behind.
#
# The list of hosts with slaves is read from slaves.txt file.


###################### CONFIGURABLE #####################################################
# Log directory.
LOG='/var/log/slaves/'

# E-mail pager.
EMAILS='9256407494@cingularme.com'

#
# SMS pagers
# 6465524228@cingularme.com   Gidon
# 5108615151@cingular.net     Long
#

EMAILS_MASTER='ab-dba@adbrite.com'
Subject='Problem with slave.'
Message='Check slave.'
user='admin'
pass='L8apx1ng'
master='mumysql.pkwinteractive.com'

##########################################################################################

H=`date +%k`
PAGER=true

while true
do

   hour=`date +%k`
   TIME=`date +"%F %H:%M:%S"`   

   if [ "$hour" -gt "$H" ]
   then
      H=$hour
      PAGER=true
      echo "~"
   fi

   # Check master for number of connections.
   master_connections=`mysqladmin extended-status -h$master -u$user -p$pass | awk -F"|" '/Threads_connected/ {print $3}'`

   if ((master_connections>400)) 
   then
      echo -e "\E[0;34m~~~~~~~~~!Problem with Master!~~~~~~~~> $master_connections connections"
      tput sgr0
         if [ $PAGER == true ]
         then
	    echo "DB Master: $master_connections connections! " | mail -s "~~!Mayday DB Master!~~" $EMAILS_MASTER
            PAGER=false
         fi
   fi

   echo ""
   echo $TIME
   echo -e '\E[0;34mShow slave status.'
   echo -e '\E[0;34mHost		        sec'
   echo -e '\E[0;34m--------------------------------'
   tput sgr0 # Resets colors to "normal."

   # We don't want recieve pagers from m65 while it is doing backup.
   if ((hour>0 && hour<5))
   then
      SLAVES=`more slaves.txt | grep -v "#" | grep -v m65 | grep -v b1 | grep -v b2`   
   else
      SLAVES=`more slaves.txt | grep -v "#"`
   fi
   
   for slave in $SLAVES
      do
	 long=${#slave}
         status=`mysqladmin ping -u $user -p$pass -h $slave  2>&1 | grep -c "alive"`
	 if ((status>0))
	 then
	    seconds=`mysql -h$slave -u $user -p$pass -e "show slave status\G" | grep Seconds_Behind_Master | awk -F":" '{print $2}'`
	 else
	    seconds="DOWN"
      fi

      echo $TIME " " $seconds >> $LOG$slave.log

      if [ $long -lt 8 ]
      then
	 space="\t\t"
      else
         space="\t"
      fi
      
      # Slave is OK
      if [ $seconds == 0 ]; then
	 echo -e $slave $space $seconds

      # Server is down. Red
      elif [ $seconds == "DOWN" ]; then
         echo -e '\E[0;31m'$slave $space "Server $slave is down."
         tput sgr0
         if [ $PAGER == true ]
         then
	    echo "Server $slave is down." | mail -s "$slave is DOWN." $EMAILS	    	    
            PAGER=false
            echo   -e '\E[0;31m' "                     P A G I N G ...Server is Down!...$slave" 
	    tput sgr0
         fi

      # Slave is down. Red
      elif [ $seconds == "NULL" ]; then
         echo -e '\E[0;31m'$slave $space "Slave is down."
	 tput sgr0
         if [ $PAGER == true ]
         then
	    echo "Problem with $slave." | mail -s "$slave --> NULL." $EMAILS
            PAGER=false
            echo  -e '\E[0;31m' "                     P A G I N G ...Slave is Down!...$slave"
	    tput sgr0
         fi

      # Slave is over 1h behind. Red
      elif [ "$seconds" -gt "3600" ]; then
         sec=$((seconds%60))
	 behind=`expr $((((seconds-sec)/60)/60))`":"`expr $((((seconds-sec)/60)%60))`":"`expr $((seconds%60))`
         echo -e '\E[0;31m'$slave $space $seconds "( $behind )"
         tput sgr0

      # Slave is getting behind. Yellow
      else
	 sec=$((seconds%60))
	 behind=`expr $((((seconds-sec)/60)%60))`":"`expr $((seconds%60))`
	 echo -e '\E[0;33m'$slave $space $seconds " ( $behind ) "
         tput sgr0
      fi

      # Slave is over 4h behind. Red
      if ((seconds>14400)); then
#	 echo "$slave is over 4h behind." | mail -s "$slave --> 4h." $EMAILS
	 PAGER=false
	 echo -e '\E[0;31m' "			   P A G I N G ...Over 4h...$slave"
	 tput sgr0
      fi
   done
   echo -e '\E[0;34m--------------------------------'
   sleep 30s
clear

done
