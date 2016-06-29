# OpenCPS is the open source Core Public Services software
# Copyright (C) 2016-present OpenCPS community

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

echo '####################################'
echo '####### INSTALL MARIADB 10.1 #######'
echo '####################################'

if [ $(id -u) != "0" ]; then
    printf "You need to use the root account"
    exit
fi

if [[ $(arch) != "x86_64" ]] ; then
	echo "Script only works on CentOS 7 64bit."
	exit
fi

timedatectl set-timezone Asia/Ho_Chi_Minh

pkg1=$(rpm -qa| grep MariaDB-server)
if [[ "$pkg1" == *"MariaDB-server-10.1."*  ]];then
  echo 'MariaDB package... OK!' 
else
	
	#Create MariaDB.repo
	touch /etc/yum.repos.d/MariaDB.repo
	echo '[mariadb]' >> /etc/yum.repos.d/MariaDB.repo
	echo 'name = MariaDB' >> /etc/yum.repos.d/MariaDB.repo
	echo 'baseurl = http://yum.mariadb.org/10.1/centos7-amd64/' >>/etc/yum.repos.d/MariaDB.repo
	echo 'gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB' >> /etc/yum.repos.d/MariaDB.repo
	echo 'gpgcheck=1' >> /etc/yum.repos.d/MariaDB.repo
	
	#Install MariaDB 
	setenforce 0
	yum install MariaDB-server MariaDB-client -y
fi 

pkg1=$(rpm -qa| grep MariaDB-server)
if [[ "$pkg1" == *"MariaDB-server-10.1."*  ]];then
	 systemctl start mariadb
	 systemctl enable mariadb
	
	 echo ''
	 #Set Root password for MariaDB
	 echo "Create Root password for Database"
	 echo "==========================================="
	 unset password
	 export password=$(date +%s | sha256sum | base64 | head -c 12 ; echo)
	 mysql -u root -e "UPDATE mysql.user SET Password=PASSWORD('$password') WHERE User='root'; flush privileges;"
	 mysql -u root -p$password -e "DELETE FROM mysql.user WHERE User='';"
	 mysql -u root -p$password -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
	 mysql -u root -p$password -e "DROP DATABASE IF EXISTS test;"
	 mysql -u root -p$password -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
	 mysql -u root -p$password -e "FLUSH PRIVILEGES;"
	 echo "** DONE! **"
	 echo "==========================================="
	
	 echo ''
	 #Edit /etc/my.cnf.d/server.cnf
	 echo "Cau hinh Database Slave"
	 echo "==========================================="
	 mkdir /var/log/mysql
	 sed -i '/# this is only for the mysqld standalone daemon/d' /etc/my.cnf.d/server.cnf
	 sed -i "/mysqld/ a\replicate-do-db=opencps" /etc/my.cnf.d/server.cnf
	 mysql -u root -p$password -e "create database opencps";
	 sed -i '/mysqld/ a\server_id=1' /etc/my.cnf.d/server.cnf
	 sed -i '/mysqld/ a\log-bin=master-bin' /etc/my.cnf.d/server.cnf
	 sed -i '/mysqld/ a\log_error=/var/log/mysql/mysql.log' /etc/my.cnf.d/server.cnf
	 ln -s /etc/my.cnf.d/server.cnf /etc/my.cnf > /dev/null 2>&1
	 echo "** DONE! **"
	 echo "==========================================="
	
	 echo ''
	 echo "Create slave user for Master Database"
	 echo "==========================================="
	 read -s -p "Please enter your Slave Password: " passslave
	 mysql -u root -p$password -e "grant replication slave on *.* to 'slave'@'%' identified by '$passslave';"
	 mysql -u root -p$password -e "flush privileges;"
	 echo ''
	 echo "** DONE! ** "
	 echo "==========================================="
	 
	 #Create configure file for Slave
	 echo ''
	 echo "Create configure file for Slave"
	 echo "==========================================="
	 export numeth=$(ip addr |grep 'inet ' |grep -v '127.0.0.1'| cut -d' ' -f6|cut -d/ -f1 |wc -l)
	 if [[ "$numeth" > 1 ]] ; then
	 title="You have $numeth Network Interfaces, please choose IP that could connect to Slave Server"
	 prompt="Choose option: "
	 options=($(hostname -I))
	
	     echo "$title"
	     PS3="$prompt "
	     select opt in "${options[@]}"; do
	         case "$REPLY" in
	         1 ) export ipmaster=$opt && break;;
	         2 ) export ipmaster=$opt && break;;
	         $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;*) echo "Invalid option. Try another one.";continue;;
	         esac
	     done
	 else
	     export ipmaster=$(hostname -I)
	 fi
	
	 echo "change master to master_host='"$ipmaster"'," > /tmp/changemaster.sql
	 echo "master_user='"slave"'," >> /tmp/changemaster.sql
	 echo "master_password='"$passslave"'," >> /tmp/changemaster.sql
	 echo "master_port=3306," >> /tmp/changemaster.sql
	 master_log_file=$(mysql -uroot -p$password -s -e "select variable_value from information_schema.global_status where variable_name='Binlog_snapshot_file';"| awk '{print $1}';)
	 echo "master_log_file='"$master_log_file"'," >> /tmp/changemaster.sql
	 master_log_pos=$(mysql -uroot -p$password -s -e "select variable_value from information_schema.global_status where variable_name='BINLOG_SNAPSHOT_POSITION';"| awk '{print $1}';)
	 echo "master_log_pos="$master_log_pos"," >> /tmp/changemaster.sql
	 echo "master_connect_retry=10;" >> /tmp/changemaster.sql
	 echo '** DONE! **'
	 echo "==========================================="
	 setenforce 1
	
	 #Configure Firewall
	 echo ''
	 echo "Create Zone for Firewall"
	 echo "==========================================="
	 
	 pkg2=$(rpm -qa| grep firewalld)
	 if [[ "$pkg2" == *"firewalld"*  ]];then
	  echo 'firewalld package... OK!' 
	 else
	  echo 'Installing firewalld...'; 
	  yum install -y firewalld
	  systemctl start firewalld
	  systemctl enable firewalld
	  echo " Done!"
	 fi 
	
	 firewall-cmd --permanent --new-zone=mariadb
	 firewall-cmd --permanent --zone=mariadb --add-port=3306/tcp
	 firewall-cmd --reload
	
	 systemctl restart mysql
	 echo "** DONE! **"
	 echo "==========================================="
	
	
	 echo "** DONE! **"
	 echo "==========================================="
	
	 echo ''
	 echo '----------------Result-------------------'
	 echo '- Installed MariaDB Server                            DONE!'
	 echo '- Created and Imported data into OpenCPS Database     DONE!'
	 echo '- Root Database password: '$password
	 echo '- User/Pass Slave:  slave/'$passslave

else
 	echo 'There are something wrong with install MariaDB-Server, please try again!'
fi
