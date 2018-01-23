#!/bin/sh
if [ $# -eq 2 ]
then
	username=$1
	password=$2
else
	echo "$0:username password"
	exit 2
fi

#create/add user to auth file
if [ -e /etc/vsftpd/vconf/vir_user ]
then
	if grep -wq "$username" /etc/vsftpd/vconf/vir_user
	then
		echo "$username exists"
		exit 5
	else
		echo $username >> /etc/vsftpd/vconf/vir_user
		echo $password >> /etc/vsftpd/vconf/vir_user
	fi
else
	echo "error:create user:$username </etc/vsftpd/vconf/$username>"
fi

#reload auth pamdb
db_load -T -t hash -f /etc/vsftpd/vconf/vir_user /etc/vsftpd/vconf/vir_user.db

echo "create user configration"
#create user configration
touch  /etc/vsftpd/vconf/$username
if [ -e /etc/vsftpd/vconf/$username ]
then
cat>/etc/vsftpd/vconf/$username<<EOF
local_root=/home/ftp/$username
allow_writeable_chroot=YES
anonymous_enable=NO
write_enable=YES
local_umask=022
anon_upload_enable=NO
anon_mkdir_write_enable=NO
idle_session_timeout=600
data_connection_timeout=120
max_clients=10
max_per_ip=5
local_max_rate=1048576
EOF
fi

echo "add user into chroot config"
#add user into chroot config
if [ -e /etc/vsftpd/chroot_list ]
then
	echo $username >> /etc/vsftpd/chroot_list
else
	echo "/etc/vsftpd/chroot_list not exists!"
	exit 2
fi

echo "mkdir -p /home/ftp/$username"
mkdir -p /home/ftp/$username

if [ -d /home/ftp/$username ]
then
	chown ftpuser.ftpuser /home/ftp/$username
	chmod 700 /home/ftp/$username
else
	echo "privileges $username failed!"
	exit 6
fi
