#!/bin/bash

echo 'Initializing docker container...'

# terminate on errors
set -e

#Start mysql 
/etc/init.d/mysqld start
    
# Generate database passwords if does not exists in volume
MYSQL_LIFERAY_USER="liferay";
MYSQL_LIFERAY_DATABASE="liferay";
LIFERAY_FOLDER=`cat /tmp/liferay_home`;
    
# A file in a docker volume to be persisted. This file also is used to know if backup must be restored or not.
MYSQL_PASSWORD_FILE="/var/lib/mysql/autogenerated"

if [ ! -f "$MYSQL_PASSWORD_FILE" ] ; 
then 
	echo 'Setting up mysql config'
	MYSQL_RANDOM_ROOT_PASSWORD=`pwgen -s 40 1`;
	MYSQL_LIFERAY_USER_PASSWORD=`pwgen -s 40 1`;
	
	#Create mysql user
	mysql -e "CREATE DATABASE ${MYSQL_LIFERAY_DATABASE};"
	mysql -e "CREATE USER ${MYSQL_LIFERAY_USER}@localhost IDENTIFIED BY '${MYSQL_LIFERAY_USER_PASSWORD}';"
	mysql -e "GRANT ALL PRIVILEGES ON ${MYSQL_LIFERAY_DATABASE}.* TO '${MYSQL_LIFERAY_USER}'@'localhost';"
	mysql -e "FLUSH PRIVILEGES;"
    
	#Set root password
	mysqladmin -u root password $MYSQL_RANDOM_ROOT_PASSWORD
	echo "GENERATED ROOT PASSWORD AS '$MYSQL_RANDOM_ROOT_PASSWORD'"            
	echo "GENERATED LIFERAY USER PASSWORD AS '$MYSQL_LIFERAY_USER_PASSWORD'" 
	
	#Update configuration files
	echo 'Adding liferay database configuration'
	echo "jdbc.default.username=${MYSQL_LIFERAY_USER}" >> ${LIFERAY_FOLDER}/portal-bd-MYSQL.properties
	echo "jdbc.default.password=${MYSQL_LIFERAY_USER_PASSWORD}" >>  ${LIFERAY_FOLDER}/portal-bd-MYSQL.properties

	#Copy passwords for next deploy
	echo $MYSQL_RANDOM_ROOT_PASSWORD > $MYSQL_PASSWORD_FILE
	echo $MYSQL_LIFERAY_USER_PASSWORD >> $MYSQL_PASSWORD_FILE
	
else 

	echo 'Old installation already found!'
	#Read password from file in volume
	MYSQL_RANDOM_ROOT_PASSWORD=`head -1 ${MYSQL_PASSWORD_FILE}`;
	MYSQL_LIFERAY_USER_PASSWORD=`tail -1 ${MYSQL_PASSWORD_FILE}`;
fi
    
echo 'Entrypoint finished!'

exec "$@"