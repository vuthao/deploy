# Triển khai MariaDB Master-Slave
###Môi trường cài đặt:
- Database version: MariaDB 10.1 (Stable)
- OS: Centos 7.2 64bit
- 2 server:
  + Master: 192.168.1.181
  + Slave : 192.168.1.182

Triển khai Master-Slave với cấu hình đơn giản bằng:
- Triển khai bằng script.
- Triển khai theo hướng dẫn

####*(dùng cách 1 hoặc dùng cách 2, nếu bạn dùng Script thì không cần cài đặt theo hướng dẫn và ngược lại)*

###1 - Sử dụng Script để cài Master-Slave tự động
Download từng Script Master.sh, Slave.sh về node tương ứng và chạy bằng câu lệnh sh
ví dụ: 
Trên Master Server:
```
#sh Master.sh
```
Slave Server:
```
#sh Slave.sh

```
*Lưu ý: Sau khi trên Master Server chạy xong thì mới bắt đầu chạy Slave.sh trên Slave Server.*

Tiế theo sẽ tiến hành Import dữ liệu trên Master
```
#ImportDatabase.sh
```
Trong qusa trình chạy tool import này chương trình sẽ hỏi mật khẩu root Master Server 

Kiểm tra lại dữ liệu trên Master và Slave.
```
#Master
mysql -u root -p  -e "SELECT count(*)  FROM opencps.user_";

#Slave 1
mysql -u root -p  -e "SELECT count(*)  FROM opencps.user_";
```

Nếu có nhiều Slave, khi download tool về cần sửa lại dòng 
```
sed -i '/mysqld/ a\server_id=2' /etc/my.cnf.d/server.cnf
```
Trong đó server_id tăng dần, không trùng nhau giữa ác server