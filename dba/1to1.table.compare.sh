#!/bin/bash
#

# Time tracking
start=`date +"%s"`

incdir="/home/maxim/sh/db/snap/include"

source "$incdir/db_param.inc.sh"
source "$incdir/sh_param.inc.sh"

check_set_param "$1" "$2" "$3"

master='m1'
user="admin"
pass="L8apx!ng"

check_slave_availability "$1"
echo "----------------"
check_master_availability "$1"

# Location of db files
# Master
m_db_dir=`mysqladmin -h$master -u$user -p$pass variables | awk -F"|" '/datadir/{print $3}' | sed -e 's/ //g'`
# Slave
s_db_dir=`mysqladmin -h$slave -u$user -p$pass variables | awk -F"|" '/datadir/{print $3}' | sed -e 's/ //g'`

echo "Master dir $m_db_dir"
echo "Slave dir $s_db_dir"

      # Stop slave 
      mysql -h$slave -u$user -p$pass -e "STOP SLAVE"
      #
      # Master status
      #
      echo "Locking table on master: $master ..."
      mysql -h$master -u$user -p$pass $db -e "FLUSH TABLE  $table; LOCK TABLE $table WRITE"
#     mysql -h$master -u$user -p$pass $db -e "LOCK TABLES $table WRITE"
      master_status=`mysql -h$master -u$user -p$pass -e "SHOW MASTER STATUS"`

      echo "Getting table status on master: $master ..."
      table_status=`mysqlshow --status -h$master -u$user -p$pass $db $table | awk '{if(NR == 5) print $0}' | sed -e 's/ //g'`
      m_rows=`echo $table_status | awk -F"|" '{print $6}'`
      m_data_length=`echo $table_status | awk -F"|" '{print $6}'`
      m_max_data_length=`echo $table_status | awk -F"|" '{print $9}'`
      m_index_length=`echo $table_status | awk -F"|" '{print $10}'`
      m_checksum=`echo $table_status | awk -F"|" '{print $6}'`

      master_status=`mysql -h$master -u$user -p$pass -e "SHOW MASTER STATUS"`

      # Set variables to master log file and master position
      master_log_file=`echo $master_status | awk '{print $5}'`
      master_log_pos=`echo $master_status | awk '{print $6}'`

      echo "Start $slave UNTIL ..."
      mysql -h$slave -u$user -p$pass -e "START SLAVE UNTIL MASTER_LOG_FILE = '$master_log_file', MASTER_LOG_POS = $master_log_pos "

	 log_pos=0
	 while (( log_pos > master_log_pos ))
	 do 
	    echo "Waiting for $slave to catch up ..."
	    sleep 2
	    log_pos=`mysql -h$slavei -u$user -p$pass -e "SHOW SLAVE STATUS\G" | awk -F":" '/Read_Master_Log_Pos/{print $2}'`
	 done
      echo "Getting table status on slave ..."
      table_status=`mysqlshow --status -h$slave -u$user -p$pass $db $table | awk '{if(NR == 5) print $0}' | sed -e 's/ //g'`
      s_rows=`echo $table_status | awk -F"|" '{print $6}'`
      s_data_length=`echo $table_status | awk -F"|" '{print $6}'`
      s_max_data_length=`echo $table_status | awk -F"|" '{print $9}'`
      s_index_length=`echo $table_status | awk -F"|" '{print $10}'`
      s_checksum=`echo $table_status | awk -F"|" '{print $6}'`

# Perform table syncing only if table on two servers is different.
if(( m_rows != s_rows || m_data_length != s_data_length || m_index_length != s_index_length || m_checksum != s_checksum  ))
then
   echo "--------------------------------------"
   echo "| Syncing files for $table on $slave |"
   echo "--------------------------------------"
   
   mysql -h$slave -u$user -p$pass $db -e "FLUSH TABLE $table; LOCK TABLES $table READ" 
#   rsync -c -a $m_db_dir$db/$table.* root@$slave:$s_db_dir$db/
   mysql -h$slave -u$user -p$pass $db -e "UNLOCK TABLES"

else
   echo "------------------------"
   echo "| No syncing needed... |"
   echo "------------------------"
fi

echo "Startig $slave ..."
mysql -h$slave -u$user -p$pass -e "STOP SLAVE"
mysql -h$slave -u$user -p$pass -e "START SLAVE"

echo "Unlocking table on master ..."
mysql -h$master -u$user -p$pass -e "UNLOCK TABLES"

# Stop timer
stop=`date +"%s"`
sec=$((stop - start))

# Calculate minutes:seconds
hour=$((sec / 3600))
 sec=$((sec % 3600))
 min=$((sec / 60))
 sec=$((sec % 60))

# Result
echo "Done. Table $db.$table was synchronized $master --> $slave."
echo "Operation performed in $hour:$min:$sec" 
    
