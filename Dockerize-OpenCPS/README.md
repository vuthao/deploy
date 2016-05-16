# Yêu cầu  
* Cài đặt Docker  
* Cài đặt Docker-compose  

# Cài đặt Docker  
Link tài liệu tham khảo cài đặt: https://docs.docker.com/installation/centos/  
* Bước 1: Truy cập ssh vào VM, su lên quyền root  
* Bước 2: Update các gói cài đặt  
  #yum update -y  
* Bước 3: Chạy script cài đặt Docker  
  #curl -fsSL https://get.docker.com/ | sh  
* Bước 4: Chạy Docker Daemon  
  #sudo service docker start  
* Bước 5: Cho phép Docker tự động run trong quá trình khởi động VM  
  #chkconfig docker on  
* Bước 6: Kiểm tra  
  #docker run hello-world  

# Cài đặt Docker-Compose  
* Bước 1: Chạy scipt và cài đặt Docker-compose  
  ```#sudo wget https://github.com/docker/compose/releases/download/1.7.1/docker-compose-`uname -s`-`uname -m` -O /usr/local/bin/docker-compose```   

* Bước 2:  
  ```#sudo chmod +x /usr/local/bin/docker-compose```  

# Hướng dẫn triển khai demo  
* Bước 3: Download file Docker-compose
  #wget https://github.com/VietOpenCPS/deploy/blob/master/Dockerize-OpenCPS/compose/docker-compose.yml
* Bước 4: Chạy Docker-compose để tạo các containers  
  #docker-compose -f docker-compose.yml up -d  
* Bước 5: Kiểm tra  
 * Trên command line:  
   #docker ps               (Sẽ xuất hiện 2 containers)  
   #netstat -plnt           (Port 8080 sẽ mở)  
 * Kiểm tra trên giao diện web, truy cập vào địa chỉ:  
   * localhost:8080  
