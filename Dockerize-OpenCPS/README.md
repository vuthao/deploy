# Dockerize OpenCPS  
* Dự án OpenCPS áp dụng công nghệ Docker. Ứng dụng OpenCPS được đóng gói trong Docker Image, sau đó được lưu trữ trên Docker hub để chia sẻ cho cộng đồng  
* Các version của images được xác định bởi các tag, mặc định version của image là "latest"  
* Mọi người sẽ download image về và sử dụng theo hướng dẫn  

### Version hiện tại của ứng dụng:  
* Version OpenCPS v0.0.1  

### Các thành phần đóng gói:  
* Ứng dụng OpenCPS
* Java 1.7  
* Liferay (Bundle with tomcat 7) đã được đóng gói, tích hợp sẵn Tomcat  
* Mariadb 10  

### Các tính năng chính:  


# Hướng dẫn sử dụng  

### Yêu cầu  
* Cài đặt Docker  
* Cài đặt Docker-compose  

### Cài đặt Docker trên Centos 7  
Link tài liệu tham khảo cài đặt: https://docs.docker.com/installation/centos/  
* Bước 1: Login vào máy tính, sau đó su lên quyền root  
  ```$su -```  
* Bước 2: Update các gói cài đặt  
  ```#yum update -y```  
* Bước 3: Chạy script cài đặt Docker  
  ```#curl -fsSL https://get.docker.com/ | sh```  
* Bước 4: Chạy Docker Daemon  
  ```#service docker start```  
* Bước 5: Cho phép Docker tự động run trong quá trình khởi động VM  
  ```#chkconfig docker on```  
* Bước 6: Kiểm tra  
  ```#docker run hello-world```  

### Cài đặt Docker-Compose  
* Bước 1: Chạy scipt và cài đặt Docker-compose  
  ```#wget https://github.com/docker/compose/releases/download/1.7.1/docker-compose-`uname -s`-`uname -m` -O /usr/local/bin/docker-compose```   

* Bước 2:  
  ```#chmod +x /usr/local/bin/docker-compose```  

### Hướng dẫn triển khai demo  
* Bước 1: Download file Docker-compose  
  ```#wget https://github.com/VietOpenCPS/deploy/blob/master/Dockerize-OpenCPS/compose/docker-compose.yml```  
* Bước 2: Chạy Docker-compose để tạo các containers  
  ```#docker-compose -f docker-compose.yml up -d```  
* Bước 3: Kiểm tra  
 * Trên command line:  
   ```#docker ps```               (Sẽ xuất hiện 2 containers)  
   ```#netstat -plnt```           (Port 8080 sẽ mở)  
 * Kiểm tra trên giao diện web, truy cập vào địa chỉ:  
   * localhost:8080  

# Hướng dẫn sử dụng cho người phát triển (Developer)  
* Viết Dockerfile để đóng gói ứng dụng OpenCPS, bao gồm các thành phần   
    *  Java 7
    *  Ứng dụng OpenCPS
  * Chú ý: Trong cấu hình Dockerfile, có câu lệnh 
    *  RUN wget -q http://172.17.0.1/server.zip -O /server.zip \  
    *  Ứng dụng OpenCPS được đóng gói với tên là server.zip.
    *  Sau đó sử dụng giao thức http để download gói ưng dụng trên localhost
    *  Cách làm
      *  Cài http
         #yum -y install httpd
      * Chown quyền httpd
         #chown apache:apache /var/www/html
      * Copy file server.zip vaò trong thư mục /var/www/html
         #cp server.zip /var/www/html 
* Tạo image từ Dockerfile  
  #docker build -t opencps/liferay-all-in-one:0.0.1 -t opencps/liferay-all-in-one:latest .
