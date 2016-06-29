pkg1=$(rpm -qa| grep MariaDB-server)
if [[ "$pkg1" == *"MariaDB-server-10.1."*  ]];then

	 pkg2=$(rpm -qa| grep wget)
	 if [[ "$pkg2" == *"wget"*  ]];then
	  echo 'wget package... OK!' 
	 else
	  echo 'Installing wget...'; 
	  yum install -y wget
	  echo " Done!"
	 fi 
	 wget https://github.com/VietOpenCPS/deploy/raw/master/opencps-mariadb-master-slave/opencps.tar.gz -P /tmp/ && cd /tmp/ && tar zxvf opencps.tar.gz >/dev/null 2>&1
	 mysql -uroot -p opencps < /tmp/opencps.sql
	 rm -rf /tmp/opencps.*
	 echo "** DONE! **"
else
 	echo 'There are something wrong with install MariaDB-Server, please try again!'
fi
