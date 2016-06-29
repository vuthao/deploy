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
	#TAO REPOSITORY MariaDB.repo
	touch /etc/yum.repos.d/MariaDB.repo
	echo '[mariadb]' >> /etc/yum.repos.d/MariaDB.repo
	echo 'name = MariaDB' >> /etc/yum.repos.d/MariaDB.repo
	echo 'baseurl = http://yum.mariadb.org/10.1/centos7-amd64/' >>/etc/yum.repos.d/MariaDB.repo
	echo 'gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB' >> /etc/yum.repos.d/MariaDB.repo
	echo 'gpgcheck=1' >> /etc/yum.repos.d/MariaDB.repo
	
	#CAI DAT MariaDB Server
	setenforce 0
	yum install MariaDB-server MariaDB-client -y
fi 

pkg1=$(rpm -qa| grep MariaDB-server)
if [[ "$pkg1" == *"MariaDB-server-10.1."*  ]];then
	systemctl start mariadb
	systemctl enable mariadb
	
	echo "===========install sshpass firewalld ==============="
	yum -y install epel-release >/dev/null 
	yum -y install sshpass >/dev/null 2>&1
	yum -y remove epel-release >/dev/null 
	
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
	
	echo ''
	#DAT PASSWORD ROOT CHO MariaDB
	echo "Khoi tao Root password cho Database" 
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
	mysql -u root -p$password -e "create database opencps";             
	sed -i "/mysqld/ a\replicate-do-db=opencps" /etc/my.cnf.d/server.cnf
	sed -i '/mysqld/ a\innodb_file_per_table=1' /etc/my.cnf.d/server.cnf
	sed -i '/mysqld/ a\read-only=1' /etc/my.cnf.d/server.cnf
	sed -i '/mysqld/ a\max_allowed_packet=64M' /etc/my.cnf.d/server.cnf
	sed -i '/mysqld/ a\relay-log=slave-relay-bin' /etc/my.cnf.d/server.cnf
	sed -i '/mysqld/ a\server_id=2' /etc/my.cnf.d/server.cnf
	#sed -i '/mysqld/ a\log-slave-updates' /etc/my.cnf.d/server.cnf
	sed -i '/mysqld/ a\log-bin=slave-bin' /etc/my.cnf.d/server.cnf
	sed -i '/mysqld/ a\log_error=/var/log/mysql/mysql.log' /etc/my.cnf.d/server.cnf
	rm -rf /etc/my.cnf
	ln -s /etc/my.cnf.d/server.cnf /etc/my.cnf >/dev/null 2>&1
	echo "** DONE! **"
	echo "==========================================="
	systemctl restart mysql
	
	echo "Tao tai khoan Slave cho Database"
	echo "==========================================="
	read -s -p "Please enter your Slave Password: " passslave
	mysql -u root -p$password -e "grant replication slave on *.* to 'slave'@'localhost' identified by '$passslave'; flush privileges;"
	echo ''
	echo "** DONE! ** "
	echo "==========================================="
	
	echo ''
	echo "Cau hinh dong bo giua Master va Slave"
	echo "==========================================="
	cd /tmp && check=$(ls changemaster.sql 2>/dev/null)
	until [[ "$check" == *"changemaster"* ]]; do
	read -p "Please input your Master's IP: " ipmaster
	if echo "$ipmaster" | egrep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' >/dev/null 2>&1
	then
	 VALID_IP_ADDRESS="$(echo $ipmaster | awk -F'.' '$1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255')"
	 if [ -z "$VALID_IP_ADDRESS" ]
	 then
	   echo "====The IP address wasn't valid; octets must be less than 256===="
	 else
	   touch /tmp/scp
	   read -s -p "Please input your Master's Root Password (System Password, not DB Password): " masterpassword
	   echo 'sshpass -p '$masterpassword' scp -o "StrictHostKeyChecking=no" -q root@'$ipmaster':/tmp/changemaster.sql /tmp/changemaster.sql' > /tmp/scp
	   sh /tmp/scp >/dev/null 2>&1 && rm -rf /tmp/scp && cd /tmp
	   cd /tmp/ && check=$(ls changemaster.sql 2>/dev/null)
	   if [[ "$check" == *"changemaster"*  ]];then
	     mysql -uroot -p$password -e "source changemaster.sql;" && rm -rf /tmp/changemaster.sql >/dev/null 2>&1
	     echo ''	
	     export numeth=$(ip addr |grep 'inet ' |grep -v '127.0.0.1'| cut -d' ' -f6|cut -d/ -f1 |wc -l)
	     if [[ "$numeth" > 1 ]]; then
	       title="You have $numeth Network Interfaces, please choose one that will be used to connect to Master"
	       prompt="Pick an Network Interface:"
	       options=($(hostname -I))
	       echo "$title"
	       PS3="$prompt "
	       select opt in "${options[@]}"; do
		  case "$REPLY" in
		    1 ) export ipslave=$opt && break;;
		    2 ) export ipslave=$opt && break;;
		    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
		    *) echo "Invalid option. Try another one.";continue;;
		  esac
	       done
	     else
	       export ipslave=$(hostname -I)
	     fi
	     echo 'sshpass -p '$masterpassword' ssh -o "StrictHostKeyChecking=no" -q root@'$ipmaster '"firewall-cmd --permanent --zone=mariadb --add-source='$ipslave'; firewall-cmd --reload"' > /tmp/firewall
	     sh /tmp/firewall >/dev/null 2>&1 && rm -rf /tmp/firewall
	     echo ''
	     echo "Firewall in Master Server was added rules for this Slave"
		
	   else
	     echo "====This IP is not your Master DB's IP Address===="
	   fi
	 fi
	else
	    echo "====The IP address was malformed===="
	fi
	done
	echo "** DONE! **"
	echo "==========================================="
	
	echo ''
	echo "Khoi dong dong bo giua Master va Slave"
	echo "==========================================="
	mysql -uroot -p$password -e "start slave;"
	echo "** DONE! **"
	echo "==========================================="
	setenforce 1
	
	echo ''
	echo '----------------Ket Qua-------------------'
	echo '- Tao Database OpenCPS trong CSDL	DONE!'
	echo '- Cau hinh dong bo voi Master		DONE!'
	echo '- Mat khau Root Database: '$password
	echo '- User/Pass user Slave: slave/'$passslave
else
	echo 'There are something wrong with network, please try again later'
fi
