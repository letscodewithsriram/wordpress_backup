# ------------------------------------------------------------------------------#
# Copyright (C) 2023 Sriram Ramanujam, Baeldung - All rights reserved		#
# For any code modification queries, please contact team@baeldung.com		#
# Last revised - July 20, 2023							#
# ------------------------------------------------------------------------------#

#!/bin/bash

echo `date` "WORDPRESS BACKUP SCRIPTS - STARTED" > runtime.log

VALIDATE_FLAG=false
VERIFY_FLAG=false

REMOTE_USER="evaluser"
REMOTE_PEM="devops-eval-evaluser.pem"
REMOTE_IPADDR="3.88.106.171"

echo `date` "VALIDATE DATE STAGE: Date Format Validation Started" >> runtime.log

if [ -z "$1" ]
then
	echo `date` "VALIDATE DATE STAGE: Backup Archive Date is EMPTY, Please provide date as the argument in YYYY-MM-DD format" >> runtime.log
else
	echo `date` "VALIDATE DATE STAGE: Backup Archive Date: $1" >> runtime.log

	YYYY=`echo $1 | cut -f1 -d-`
	MM=`echo $1 | cut -f2 -d-`
	DD=`echo $1 | cut -f3 -d-`

	CURYEAR=`date | cut -f6 -d" "` 

	if [ "$YYYY" -gt 2000 ] && [ "$YYYY" -lt $((CURYEAR + 1)) ];
        then
		echo `date` "VERIFY FILE STAGE: File availability check in the remote server started" >> runtime.log
		echo `date` "VERIFY FILE STAGE: Backup Archive Date Validation Success" >> runtime.log
		echo `date` "VERIFY FILE STAGE: Backup Archive File Name: $1.tar.gz" >> runtime.log
		VALIDATE_FLAG=true
        else
               echo `date` "VALIDATE DATE STAGE:Backup Archive Date Validation Failed, Please provide the valid date in YYYY-MM-DD format" >> runtime.log
        fi
fi

if $VALIDATE_FLAG;
then
	FILE_VERIFY=`ssh -i $REMOTE_PEM $REMOTE_USER@$REMOTE_IPADDR "ls backups | grep $1 | grep -v '^$'"`
	if [ -z "$FILE_VERIFY" ]
	then
		echo `date` "VERIFY FAILED STAGE: $1.tar.gz is not available in remote host ($REMOTE_IPADDR)" >> runtime.log
		exit
	else
		VERIFY_FLAG=true
		echo `date` "VERIFY SUCCESS STAGE: $1.tar.gz is available in remote host ($REMOTE_IPADDR)" >> runtime.log
	fi
fi

if $VERIFY_FLAG;
then
	echo `date` ":FILE TRANSFER STAGE: Initiating the file transfer from the Local to the remote worker node" >> runtime.log
	`scp -i $REMOTE_PEM $REMOTE_USER@$REMOTE_IPADDR:backups/$1.tar.gz ./`
	echo `date` ":FILE TRANSFER STAGE: Successfully completed the file transfer from the Local to the remote worker node" >> runtime.log

	echo `date` ":FILE UNZIP STAGE: Initiating the tar.gz unzip of the file on the local node" >> runtime.log
	`tar -xf $1.tar.gz`
	echo `date` ":FILE UNZIP STAGE: Successfully completed the unzip of the file on the local node" >> runtime.log

	echo `date` "SANITY CHECK STAGE: Carriage Return - Removing the ctrl-m characters from the unzipped files" >> runtime.log
	`sed -i 's///g' $1/*`
	echo `date` "SANITY CHECK STAGE: Carriage Return - Successfully removed the ctrl-m characters from the unzipped files" >> runtime.log

	echo `date` "PASSWORD CHANGE STAGE: Starting the password change stage" >> runtime.log
	echo `date` "PASSWORD CHANGE STAGE: Old Password in wp-config.php is - " `grep "DB_PASSWORD" $1/wp-config.php` >> runtime.log
	# echo `grep "DB_PASSWORD" $1/wp-config.php`

	echo `date` "PASSWORD CHANGE STAGE: Changing the password using the sed command" >> runtime.log
	`sed -i 's/test_user_password/New_Baeldung12\@\#/g' $1/wp-config.php`
	echo `date` "PASSWORD CHANGE STAGE: Successfully completed the password change task in the wp-config.php" >> runtime.log	

	echo `date` "PASSWORD CHANGE STAGE: New Password in wp-config.php is - " `grep "DB_PASSWORD" $1/wp-config.php` >> runtime.log
	echo `date` "PASSWORD CHANGE STAGE: Successfully completed the password change stage" >> runtime.log
	
	echo `date` "ARCHIVE STAGE: Initiating the file archive using the tar command and remove the original folder" >> runtime.log
	`tar -caf $1.tar.gz $1 --remove-files`
	echo `date` "ARCHIVE STAGE: Successfully completed the file archive using the tar command and removed the original folder" >> runtime.log
	
	echo `date` "LOG CAPTURE STAGE: Starting the status update in backup-log.log file" >> runtime.log
	echo "$1,DOWNLOADED,VERIFIED" >> backup-log.log
	echo `date` "LOG CAPTURE STAGE: Completed the status update in backup-log.log file" >> runtime.log
	
fi

echo `date` "WORDPRESS BACKUP SCRIPTS - COMPLETED" >> runtime.log
