## 1. Hướng dẫn chạy
Cấp quyền thực thi và chạy script tự động:
```bash
chmod +x commands.sh
./commands.sh
```

Hoặc thực thi từng bước bằng Docker CLI:
1. **Tạo network & volume:**
   ```bash
   docker network create --driver bridge app-net
   docker volume create db-data
   ```
2. **Chạy Database Container:**
   ```bash
   docker run -d \
     --name db-server \
     --network app-net \
     -v db-data:/var/lib/postgresql/data \
     -e POSTGRES_DB=testdb \
     -e POSTGRES_USER=postgres \
     -e POSTGRES_PASSWORD=secret \
     postgres:15-alpine
   ```
3. **Chạy Backend Container:**
   ```bash
   docker run -d \
     --name app-container \
     --network app-net \
     -e DB_HOST=db-server \
     alpine sleep 3600
   ```
4. **Kiểm tra tính bền vững (Persistence):**
   ```bash
   # Thêm dữ liệu vào DB
   docker exec -i db-server psql -U postgres -d testdb -c "CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(50)); INSERT INTO users (name) VALUES ('Alice'), ('Bob');"
   
   # Xóa cứng DB container
   docker rm -f db-server
   
   # Khởi chạy lại DB container mới gắn cùng volume db-data
   docker run -d \
     --name db-server \
     --network app-net \
     -v db-data:/var/lib/postgresql/data \
     -e POSTGRES_DB=testdb \
     -e POSTGRES_USER=postgres \
     -e POSTGRES_PASSWORD=secret \
     postgres:15-alpine
   
   # Xác minh dữ liệu vẫn còn
   docker exec -i db-server psql -U postgres -d testdb -c "SELECT * FROM users;"
   ```

## 2. Lệnh kiểm tra & Kết quả mong đợi

### 2.1. Kiểm tra Network & Volume
```bash
docker network ls | grep app-net
docker volume ls | grep db-data
docker network inspect app-net
```
**Kết quả mong đợi:**
- Network `app-net` có driver là `bridge`.
- Volume `db-data` có driver là `local`.
- Lệnh `inspect` cho thấy 2 container `db-server` và `app-container` cùng thuộc subnet của `app-net`.

### 2.2. Kiểm tra DNS Resolution
```bash
docker exec -it app-container ping -c 2 db-server
```
**Kết quả mong đợi:**
- Gói tin ping gửi thành công đến hostname `db-server` (được Docker DNS phân giải ra IP nội bộ trong dải mạng `app-net`, ví dụ `172.18.0.2`), không xảy ra packet loss.

### 2.3. Kiểm tra Data Persistence
- Truy vấn `SELECT * FROM users;` sau khi tạo mới container vẫn trả về đầy đủ các bản ghi đã thêm trước khi xóa container.
