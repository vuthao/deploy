#!/bin/bash
# bachkhoabk47@gmail.com

############## Installing for Centos 7, Ubuntu & Fedora #####################################

DIR="`pwd`"
DIR_CURR=$DIR/docker-compose

############### Installing Docker on Centos, Ubuntu, Fedora ########################
# Update installed package
#M_PLATFORM=`python -mplatform |grep -Eo "Ubuntu"`

M_PLATFORM_UBUNTU=`python -mplatform |grep -Eo "Ubuntu"`
M_PLATFORM_CENTOS=`python -mplatform |grep -Eo "centos"`
M_PLATFORM_FEDORA=`python -mplatform |grep -Eo "fedora"`
echo $M_PLATFORM_CENTOS

function app_update {
 if [[ $M_PLATFORM_UBUNTU == "Ubuntu" ]]; then
  sudo apt-get update -y
 elif [ $M_PLATFORM_CENTOS == "centos" ]; then
  sudo yum update -y
 elif [ $M_PLATFORM_FEDORA == "fedora" ]; then
  sudo yum update -y
 else
  echo "This could not ecognize any distro of Linux, please check it again"
 fi
}

function install_svn {
 if [[ $M_PLATFORM_UBUNTU == "Ubuntu" ]]; then
  if which svn >/dev/null; then
    echo "svn installed, so next to install other app"
  else
    sudo apt-get install subversion -y
  fi
 elif [[ $M_PLATFORM_CENTOS == "centos" ]]; then
  if which svn >/dev/null; then
    echo "svn installed, so next to install other app"
  else
    sudo yum install svn -y
  fi
 elif [[ $M_PLATFORM_FEDORA == "fedora" ]]; then
  if which svn >/dev/null; then
    echo "svn installed, so next to install other app"
  else
    sudo yum install svn -y
  fi
 else
  echo "This could not ecognize any distro of Linux, please check it again"
 fi
}

function chkconfig_docker {
 if [[ $M_PLATFORM_UBUNTU == "Ubuntu" ]]; then
  echo "Version Ubuntu > 14.10, this just needs"
 elif [[ $M_PLATFORM_CENTOS == "centos" ]]; then
  sudo chkconfig docker on
 elif [[ M_PLATFORM_FEDORA == "fedora" ]]; then
  sudo chkconfig docker on
 else 
  echo "This could not ecognize any distro of Linux, please check it again"
 fi
}

function install_docker {
 if which docker >/dev/null; then
    echo "docker installed, so go to next step"
 else
    sudo curl -fsSL https://get.docker.com/ | sh
    sudo service docker start
 fi

 if which docker-compose >/dev/null; then
    echo "docker-compose installed, so go to next step"
 else
    ############## Installing Docker-compose on Centos 7, Ubuntu, Fedora ###############
    # Download and run script for installing docker-compose
    sudo wget https://github.com/docker/compose/releases/download/1.7.1/docker-compose-`uname -s`-`uname -m` -O /usr/local/bin/docker-compose
    # Chown permission
    sudo chmod +x /usr/local/bin/docker-compose
 fi

}

function check_distro {
 app_update
 
 sudo apt-get install curl -y
 install_svn
 install_docker
 chkconfig_docker

}
check_distro

##########################################################################

######################## DEPLOYING OPENCPS APPLICATION ##################
#sudo svn export https://github.com/VietOpenCPS/deploy.git/trunk/Dockerize-OpenCPS/all-in-one-container/docker-compose

echo $DIR_CURR

if [ -d "$DIR_CURR" ]; then
  
  echo -n "Folder exists. Please type y for overried folder"."</br>"
  echo -n "y/n"
  read text
  echo "You enteredi: $text"
  
  if [ $text == "y" ]; then
    sudo svn export https://github.com/VietOpenCPS/deploy.git/trunk/opencps-dockerize/dockerize-all-in-one-container/docker-compose --force
  else
    echo "You've exited running script"
    exit;
  fi 
else
  sudo svn export https://github.com/VietOpenCPS/deploy/trunk/opencps-dockerize/dockerize-all-in-one-container/docker-compose
fi

sh -c `cd $DIR_CURR && sudo docker-compose -f docker-compose.yml up -d`
echo "Done! You can open browser with the address: localhost:8080 for testing application. Thanks"
