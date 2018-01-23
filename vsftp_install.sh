#!/bin/sh
#install vsftp 
if yum install vsftpd pam* db4* -y >/dev/null
then
	echo "vsftp pam db4 install success!"
else
	echo "vsftp pam db4 install faild!"
	exit 1
fi

#put vsftp into system service
systemctl enable vsftpd

#create account:vsftpdadmin
if ! grep -wq "vsftpdadmin" /etc/passwd
then
	useradd vsftpdadmin -s /sbin/nologin
else
	echo "vsftpdadmin exists!"
fi

#create account:ftpuser
if ! grep -wq "ftpuser" /etc/passwd
then
	useradd ftpuser -s /sbin/nologin	
else	
	echo "ftpuser exists!"
fi

#vsftpd.conf configration
if [ -e /etc/vsftpd/vsftpd.conf ]
then
	cat>/etc/vsftpd/vsftpd.conf<<EOF
anonymous_enable=NO
chroot_list_enable=YES
chroot_list_file=/etc/vsftpd/chroot_list
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES

listen=NO
listen_ipv6=YES

pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES
#add conf
guest_enable=YES
guest_username=ftpuser
virtual_use_local_privs=YES
user_config_dir=/etc/vsftpd/vconf
EOF
fi

#create log file
if [ ! -e /var/log/vsftpd.log ]
then
	touch /var/log/vsftpd.log
fi

if [ -e /var/log/vsftpd.log ]
then
	chown vsftpdadmin.vsftpdadmin /var/log/vsftpd.log
fi

#create user virtual configration file
if [ ! -d /etc/vsftpd/vconf ]
then
	mkdir -p /etc/vsftpd/vconf
fi

if [ -d /etc/vsftpd/vconf ]
then
	touch /etc/vsftpd/vconf/vir_user
fi

#load/create pamdb
db_load -T -t hash -f /etc/vsftpd/vconf/vir_user /etc/vsftpd/vconf/vir_user.db

#chmod pamdb file access
if [ -e /etc/vsftpd/vconf/vir_user.db -a -e /etc/vsftpd/vconf/vir_user ]
then
	chmod 600 /etc/vsftpd/vconf/vir_user.db
	chmod 600 /etc/vsftpd/vconf/vir_user
fi

#change pam.d for vsftpd
if [ -e /etc/pam.d/vsftpd ]
then
	cat>/etc/pam.d/vsftpd<<EOF
#%PAM-1.0
session    optional     pam_keyinit.so    force revoke
#auth       required    pam_listfile.so item=user sense=deny file=/etc/vsftpd/ftpusers onerr=succeed
#auth       required    pam_shells.so
#auth       include     password-auth
#account    include     password-auth
#session    required     pam_loginuid.so
#session    include     password-auth
session    required     pam_loginuid.so
session    include      password-auth
account    required     pam_userdb.so db=/etc/vsftpd/vconf/vir_user
auth       required     pam_userdb.so db=/etc/vsftpd/vconf/vir_user
EOF
fi

#create ftp dir
if [ ! -d /home/ftp ]
then
	mkdir -p /home/ftp
	chmod 755 /home/ftp -R
fi

#create chroot conf file
if [ ! -e /etc/vsftpd/chroot_list ]
then
	touch /etc/vsftpd/chroot_list
fi

echo  "restart vsftpd"
#restart vsftpd
systemctl restart vsftpd
echo -e "\033[32mvsftpd installed Successful!\033[0m"
