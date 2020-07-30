CREATE DATABASE `ko` /*!40100 DEFAULT CHARACTER SET utf8mb4 */;
CREATE DATABASE `grafana` /*!40100 DEFAULT CHARACTER SET utf8mb4 */;
use mysql;
update user set host = '%' where user ='root';
FLUSH PRIVILEGES;