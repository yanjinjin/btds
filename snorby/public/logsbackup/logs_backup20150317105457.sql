-- MySQL dump 10.13  Distrib 5.1.73, for redhat-linux-gnu (x86_64)
--
-- Host: 172.16.25.12    Database: snorby
-- ------------------------------------------------------
-- Server version	5.1.73

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `logs`
--

DROP TABLE IF EXISTS `logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `logs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `optime` datetime DEFAULT NULL,
  `ip` varchar(50) DEFAULT NULL,
  `username` varchar(50) DEFAULT NULL,
  `opobject` varchar(50) DEFAULT NULL,
  `opdetail` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=65 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `logs`
--

LOCK TABLES `logs` WRITE;
/*!40000 ALTER TABLE `logs` DISABLE KEYS */;
INSERT INTO `logs` VALUES (1,'2015-01-23 13:32:00','192.168.3.223','administrator','登录','登录成功'),(2,NULL,'192.168.3.223','administrator','登录','登录成功11'),(3,'2015-01-23 15:24:21','192.168.3.223','administrator','登录','登录成功111'),(4,'2015-01-23 15:42:23','192.168.3.223','administrator','登录','登录成功2'),(5,NULL,'192.168.3.223','administrator','登录','登录成功3'),(6,'2015-01-23 16:11:13','test','suncle','login','login s'),(7,'2015-01-23 17:59:17','test','suncle','login','login s'),(8,'2015-01-23 18:07:29','test','suncle','login','login s'),(9,'2015-01-23 18:09:05','test','suncle','login','login s'),(10,'2015-01-23 18:11:29','test','suncle','login','login f'),(11,'2015-01-23 18:11:35','test','suncle','login','login s'),(12,'2015-02-02 09:49:50','test','suncle','login','login s'),(13,'2015-02-06 11:02:30','test','suncle','login','login s'),(14,'2015-02-06 11:02:38','test','suncle','login','login s'),(15,'2015-02-06 11:10:29','test','Administrator','login','login s'),(16,'2015-02-06 11:11:54','127.0.0.1','Administrator','login','login s'),(17,'2015-02-06 11:12:42','172.16.206.32','Administrator','login','login s'),(18,'2015-02-06 11:41:52','172.16.20.1','unknown','login','login f'),(19,'2015-02-06 11:41:59','172.16.20.1','Administrator','login','login s'),(20,'2015-02-06 18:32:30','172.16.20.8','Administrator','login','login s'),(21,'2015-02-13 10:41:23','127.0.0.1','Administrator','login','login s'),(22,'2015-02-13 16:16:19','192.168.1.254','Administrator','login','login s'),(23,'2015-02-13 16:18:39','192.168.1.254','Administrator','login','login s'),(24,'2015-02-13 16:20:56','192.168.1.254','Administrator','login','login s'),(25,'2015-02-13 16:52:52','127.0.0.1','Administrator','login','login s'),(26,'2015-02-13 18:02:40','192.168.1.254','Administrator','login','login s'),(27,'2015-02-15 13:25:08','127.0.0.1','Administrator','login','login s'),(28,'2015-02-27 14:07:52','127.0.0.1','Administrator','login','login s'),(29,'2015-02-28 09:51:24','172.16.206.32','Administrator','login','login s'),(30,'2015-02-28 14:33:12','192.168.1.1','Administrator','login','login s'),(31,'2015-03-03 15:07:04','127.0.0.1','Administrator','login','login s'),(32,'2015-03-03 17:05:03','172.16.20.15','Administrator','login','login s'),(33,'2015-03-03 17:05:49','172.16.20.15','Administrator','login','login s'),(34,'2015-03-04 09:01:32','127.0.0.1','Administrator','login','login s'),(35,'2015-03-10 09:57:48','192.168.1.1','Administrator','login','login s'),(36,'2015-03-10 17:33:57','127.0.0.1','Administrator','login','login s'),(37,'2015-03-10 17:34:37','127.0.0.1','Administrator','login','login s'),(38,'2015-03-10 17:36:04','127.0.0.1','Administrator','login','login s'),(39,'2015-03-11 15:51:39','127.0.0.1','Administrator','login','login s'),(40,'2015-03-13 13:14:06','192.168.1.1','Administrator','login','login s'),(41,'2015-03-13 14:26:26','127.0.0.1','Administrator','login','login s'),(42,'2015-03-13 16:53:22','172.16.20.15','Administrator','login','login s'),(43,'2015-03-16 17:14:16','192.168.1.1',NULL,'login','login f'),(44,'2015-03-16 17:16:17','192.168.1.1',NULL,'login','login s'),(45,'2015-03-16 17:33:44','192.168.1.1',NULL,'登录','login s'),(46,'2015-03-16 17:34:52','192.168.1.1',NULL,'登录','login s'),(47,'2015-03-16 17:36:50','192.168.1.1','Administrator','登录','登录成功'),(48,'2015-03-16 17:54:39','192.168.1.1','Administrator','登录','登录成功'),(49,'2015-03-16 17:59:30','192.168.1.1','Administrator','登录','登录成功'),(50,'2015-03-16 18:00:13','192.168.1.1','Administrator','登录','登录成功'),(51,'2015-03-16 18:00:40','192.168.1.1','Administrator','登录','登录成功'),(52,'2015-03-16 18:02:14','192.168.1.1','Administrator','登录','登录成功'),(53,'2015-03-16 18:26:31','192.168.1.1','Administrator','登录','登录成功'),(54,'2015-03-16 18:29:16','192.168.1.1','Administrator','登录','登录成功'),(55,'2015-03-16 18:29:38','192.168.1.1','Administrator','登录','登录成功'),(56,'2015-03-16 18:29:59','192.168.1.1','Administrator','登录','登录成功'),(57,'2015-03-16 18:33:43','192.168.1.1','Administrator','登录','登录成功'),(58,'2015-03-16 18:33:55','192.168.1.1','Administrator','登录','登录成功'),(59,'2015-03-17 09:13:10','192.168.1.1','Administrator','登录','登录成功'),(60,'2015-03-17 09:13:24','192.168.1.1','Administrator','登录','登录成功'),(61,'2015-03-17 09:41:31','192.168.1.1','Administrator','report export','s'),(62,'2015-03-17 09:45:32','192.168.1.1','Administrator','报表导出','导出成功'),(63,'2015-03-17 10:39:42','192.168.1.1','Administrator','删除用户','删除用户成功'),(64,'2015-03-17 10:40:15','192.168.1.1','Administrator','添加用户','添加用户成功');
/*!40000 ALTER TABLE `logs` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-03-17 10:54:57
