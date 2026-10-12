#!/bin/bash

set -e

echo "=== 1. Tạo Custom Bridge Network ==="
docker network create --driver bridge app-net

echo "=== 2. Tạo Named Volume ==="
docker volume create db-data

echo "=== 3. Khởi chạy Database Container (db-server) ==="
docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=testdb \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=secret \
  postgres:15-alpine

echo "=== 4. Khởi chạy Backend Container (app-container) ==="
docker run -d \
  --name app-container \
  --network app-net \
  -e DB_HOST=db-server \
  alpine sleep 3600

echo "=== Chờ database khởi động (5s)... ==="
sleep 5

echo "=== 5. Test Data Persistence: Tạo bảng & chèn dữ liệu ==="
docker exec -i db-server psql -U postgres -d testdb -c "
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL
);
INSERT INTO users (name) VALUES ('Alice'), ('Bob');
"

echo "Dữ liệu ban đầu trong database:"
docker exec -i db-server psql -U postgres -d testdb -c "SELECT * FROM users;"

echo "=== 6. Xóa cứng container DB ==="
docker rm -f db-server

echo "=== 7. Khởi chạy lại container DB mới gắn cùng Volume db-data ==="
docker run -d \
  --name db-server \
  --network app-net \
  -v db-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=testdb \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=secret \
  postgres:15-alpine

echo "=== Chờ database mới khởi động lại (5s)... ==="
sleep 5

echo "=== 8. Xác minh dữ liệu không bị mất (Data Persistence) ==="
docker exec -i db-server psql -U postgres -d testdb -c "SELECT * FROM users;"

echo "=== 9. Kiểm tra Network & Volume ==="
docker network ls | grep app-net
docker volume ls | grep db-data
docker network inspect app-net

echo "=== 10. Kiểm tra DNS Resolution từ Backend Container ==="
docker exec -it app-container ping -c 2 db-server

echo "=== Hoàn thành Bài 4 ==="