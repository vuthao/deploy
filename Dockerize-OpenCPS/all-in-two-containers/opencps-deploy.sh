#!/bin/bash
# bachkhoabk47@gmail.com

DIR="`pwd`"
DIR_CURR=$DIR/docker-compose

M_PLATFORM_UBUNTU=`python -mplatform |grep -Eo "Ubuntu"`
M_PLATFORM_CENTOS=`python -mplatform |grep -Eo "centos"`
M_PLATFORM_FEDORA=`python -mplatform |grep -Eo "fedora"`
echo $M_PLATFORM

function check_distro {
# Update installed package
 if [ $M_PLATFORM_UBUNTU == "Ubuntu" ]; then
  sudo apt-get update && apt-get install subversion && apt-get install curl -y  
  curl -fsSL https://get.docker.com/ | sh  
  #chkconfig docker on 
  #Using chkconfig from 14.10 Ubuntu version
 elif [ $M_PLATFORM_CENTOS == "centos" ]; then
  sudo yum update && yum install svn && yum install curl -y
  curl -fsSL https://get.docker.com/ | sh
  chkconfig docker on 
 elif [ M_PLATFORM_FEDORA == "fedora" ]; then
  sudo yum update && yum install svn && install curl -y
  curl -fsSL https://get.docker.com/ | sh
  chkconfig docker on
 else
  echo "Wrong script and then need to makes it an issue sticket or inform to author"
 fi
}
check_distro

# Start Docker service
service docker start

############## Installing Docker-compose on Centos 7 ###############
# Download and run script for installing docker-compose
wget https://github.com/docker/compose/releases/download/1.7.1/docker-compose-`uname -s`-`uname -m` -O /usr/local/bin/docker-compose
# Chown permission
chmod +x /usr/local/bin/docker-compose

##########################################################################

######################## DEPLOYING OPENCPS APPLICATION ##################
svn export https://github.com/VietOpenCPS/deploy.git/trunk/Dockerize-OpenCPS/all-in-two-containers/docker-compose

echo $DIR_CURR

if [ -d "$DIR_CURR" ]; then
  sh -c `cd $DIR_CURR && docker-compose -f docker-compose.yml up -d`
  echo "Done! You can open browser with the address: localhost:8080 for testing application. Thanks"
else
  echo "docker-compose directory not found, please check it again or contact to author"
fi
