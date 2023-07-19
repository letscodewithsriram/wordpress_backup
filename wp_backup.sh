# ------------------------------------------------------------------------------#
# Copyright (C) 2023 Sriram Ramanujam, Baeldung - All rights reserved		#
# For any code modification queries, please contact team@baeldung.com		#
# Last revised - July 19, 2023							#
# ------------------------------------------------------------------------------#

#!/bin/bash

STARTTIME=`date +%s`

echo `date` ":Backup Script Started" > runtime.log

VALIDATE_FLAG=false
VERIFY_FLAG=false
REMOTE_USER="evaluser"
REMOTE_PEM="devops-eval-evaluser.pem"
REMOTE_IPADDR="3.88.106.171"

if [ -z "$1" ]
then
	echo `date` ":Backup Archive Date is EMPTY, Please provide date as the argument in YYYY-MM-DD format"
else
	echo `date` ":Backup Archive Date: $1"

	YYYY=`echo $1 | cut -f1 -d-`
	MM=`echo $1 | cut -f2 -d-`
	DD=`echo $1 | cut -f3 -d-`

	echo "$YYYY $MM $DD"

	CURYEAR=`date | cut -f6 -d" "` 

	if [ "$YYYY" -gt 2000 ] && [ "$YYYY" -lt $((CURYEAR + 1)) ];
        then
		echo `date` ":Backup Archive Date Validation Success"
		echo `date` ":Backup Archive File Name: $1.tar.gz"
		VALIDATE_FLAG=true
        else
               echo `date` ":Backup Archive Date Validation Failed, Please provide the valid date in YYYY-MM-DD format"
        fi
fi

if $VALIDATE_FLAG;
then
	FILE_VERIFY=`ssh -i $REMOTE_PEM $REMOTE_USER@$REMOTE_IPADDR "ls backups | grep $1 | grep -v '^$'"`
	if [ -z "$FILE_VERIFY" ]
	then
		echo `date` ":VERIFY FAILED: $1.tar.gz is not available in remote host ($REMOTE_IPADDR)"
		exit
	else
		VERIFY_FLAG=true
		echo `date` ":VERIFY SUCCESS: $1.tar.gz is available in remote host ($REMOTE_IPADDR)"
	fi
fi

if $VERIFY_FLAG;
then
	echo `date` ":FILE TRANSFER STAGE: Initiating the file transfer from the Local to the remote worker node"
	`scp -i $REMOTE_PEM $REMOTE_USER@$REMOTE_IPADDR:backups/$1.tar.gz ./`
	echo `date` ":FILE TRANSFER STAGE: Successfully completed the file transfer from the Local to the remote worker node"

	echo `date` ":FILE UNZIP STAGE: Initiating the tar.gz unzip of the file on the local node"
	`tar -xf $1.tar.gz`
	echo `date` ":FILE UNZIP STAGE: Successfully completed the unzip of the file on the local node"

	echo `date` "SANITY CHECK STAGE: Carriage Return - Removing the ctrl-m characters from the unzipped files"
	`sed -i 's///g' $1/*`
	echo `date` "SANITY CHECK STAGE: Carriage Return - Successfully removed the ctrl-m characters from the unzipped files"

	echo `date` "PASSWORD CHANGE STAGE: Starting the password change stage"
	echo `date` "PASSWORD CHANGE STAGE: Old Password in wp-config.php is - " `grep "DB_PASSWORD" $1/wp-config.php`
	# echo `grep "DB_PASSWORD" $1/wp-config.php`

	echo `date` "PASSWORD CHANGE STAGE: Changing the password using the sed command"
	`sed -i 's/test_user_password/New_Baeldung12\@\#/g' $1/wp-config.php`
	echo `date` "PASSWORD CHANGE STAGE: Successfully completed the password change task in the wp-config.php"	

	echo `date` "PASSWORD CHANGE STAGE: New Password in wp-config.php is - " `grep "DB_PASSWORD" $1/wp-config.php`
	echo `date` "PASSWORD CHANGE STAGE: Successfully completed the password change stage"
	
	echo `date` "ARCHIVE STAGE: Initiating the file archive using the tar command and remove the original folder"
	`tar -caf $1.tar.gz $1 --remove-files`
	echo `date` "ARCHIVE STAGE: Successfully completed the file archive using the tar command and removed the original folder"
	
	echo `date` "LOG CAPTURE STAGE: Starting the status update in backup-log.log file"
	echo `date +%Y-%b-%d` ",DOWNLOADED,VERIFIED" >> backup-log.log
	echo `date` "LOG CAPTURE STAGE: Completed the status update in backup-log.log file"
	
fi
