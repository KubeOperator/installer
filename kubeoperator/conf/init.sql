CREATE DATABASE `ko` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
use mysql;
update user set host = '%' where user ='root';
FLUSH PRIVILEGES;