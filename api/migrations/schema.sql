-- MySQL dump 10.13  Distrib 8.0.41, for Win64 (x86_64)
--
-- Host: mysql-314cb117-hpimage10-6228.g.aivencloud.com    Database: hotel_management_app
-- ------------------------------------------------------
-- Server version	8.4.8

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ 'd478eb5d-b34b-11f1-a45a-9696ace701e2:1-1630,
faf6b5a4-b27e-11f1-9be3-de34fd1b8d4d:1-250';

--
-- Table structure for table `business_staff`
--

DROP TABLE IF EXISTS `business_staff`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `business_staff` (
  `id` int NOT NULL AUTO_INCREMENT,
  `business_id` int NOT NULL,
  `user_id` int NOT NULL,
  `role` enum('manager','kitchen','front_desk','waiter') NOT NULL DEFAULT 'manager',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_biz_user` (`business_id`,`user_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `business_staff_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `business_staff_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `business_staff`
--

LOCK TABLES `business_staff` WRITE;
/*!40000 ALTER TABLE `business_staff` DISABLE KEYS */;
/*!40000 ALTER TABLE `business_staff` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `businesses`
--

DROP TABLE IF EXISTS `businesses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `businesses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `owner_id` int NOT NULL,
  `name` varchar(150) NOT NULL,
  `slug` varchar(170) NOT NULL,
  `type` enum('hotel','restaurant','cafe','guest_house') NOT NULL,
  `description` text,
  `logo_url` varchar(255) DEFAULT NULL,
  `cover_image_url` varchar(255) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `has_food_ordering` tinyint(1) DEFAULT '1',
  `has_table_booking` tinyint(1) DEFAULT '1',
  `has_room_booking` tinyint(1) DEFAULT '0',
  `delivery_radius_km` decimal(5,2) DEFAULT '5.00',
  `base_delivery_fee` decimal(10,2) DEFAULT '50.00',
  `min_order_amount` decimal(10,2) DEFAULT '0.00',
  `avg_prep_time_mins` int DEFAULT '20',
  `commission_percent` decimal(5,2) DEFAULT '15.00',
  `status` enum('pending','approved','suspended','rejected') NOT NULL DEFAULT 'pending',
  `is_open` tinyint(1) DEFAULT '1',
  `opens_at` time DEFAULT '08:00:00',
  `closes_at` time DEFAULT '22:00:00',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid` (`uuid`),
  UNIQUE KEY `slug` (`slug`),
  KEY `owner_id` (`owner_id`),
  KEY `idx_businesses_type_status` (`type`,`status`),
  CONSTRAINT `businesses_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `businesses`
--

LOCK TABLES `businesses` WRITE;
/*!40000 ALTER TABLE `businesses` DISABLE KEYS */;
INSERT INTO `businesses` VALUES (1,'6f4b108e-b96e-11f1-8789-9696ace701e2',1,'Himalayan Spice Kitchen','himalayan-spice-kitchen','restaurant','Authentic Nepali & Indian cuisine - momos, thakali sets, curries and tandoori grills.','https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400','https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1200','9800000001','contact.himalayanspice@example.com','New Road','Dhangadhi',28.6944000,80.5992000,1,1,0,8.00,50.00,200.00,25,15.00,'approved',1,'08:00:00','22:00:00','2026-09-26 05:52:18','2026-09-26 05:52:18'),(2,'c58d2f1f-b96e-11f1-8789-9696ace701e2',2,'Spice Junction','spice-junction','restaurant','Indo-Chinese favorites - chowmein, chilli chicken, fried rice and more.','https://images.unsplash.com/photo-1585032226651-759b368d7246?w=400','https://images.unsplash.com/photo-1585032226651-759b368d7246?w=1200','9800000002','contact.spicejunction@example.com','Attariya Road','Dhangadhi',28.6981000,80.6012000,1,1,0,7.00,50.00,150.00,25,15.00,'approved',1,'10:00:00','21:30:00','2026-09-26 05:54:43','2026-09-26 06:35:53'),(3,'c6f70f91-b96e-11f1-8789-9696ace701e2',3,'Ganga Vista Hotel','ganga-vista-hotel','hotel','Comfortable rooms with river views, in-house restaurant and room service.','https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400','https://images.unsplash.com/photo-1566073771259-6a8506099945?w=1200','9800000003','contact.gangavista@example.com','Hasanpur Road','Dhangadhi',28.7015000,80.5940000,1,0,1,0.00,0.00,0.00,35,15.00,'approved',1,'00:00:00','23:59:00','2026-09-26 05:54:46','2026-09-26 06:35:53'),(4,'c7a0709b-b96e-11f1-8789-9696ace701e2',4,'Bean & Brew Cafe','bean-and-brew-cafe','cafe','Specialty coffee, fresh pastries and a cozy spot to work or hang out.','https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400','https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1200','9800000004','contact.beanbrew@example.com','Tikapur Chowk','Dhangadhi',28.6905000,80.6050000,1,1,0,5.00,40.00,100.00,25,15.00,'approved',1,'07:00:00','20:00:00','2026-09-26 05:54:47','2026-09-26 06:35:54'),(5,'c8e8d7ee-b96e-11f1-8789-9696ace701e2',5,'Mountain View Guest House','mountain-view-guest-house','guest_house','Budget-friendly guest house with home-style meals on request.','https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400','https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=1200','9800000005','contact.mountainview@example.com','Godavari Marg','Dhangadhi',28.7050000,80.6100000,0,0,1,0.00,0.00,0.00,25,15.00,'approved',1,'00:00:00','23:59:00','2026-09-26 05:54:49','2026-09-26 06:35:54'),(6,'c9d84767-b96e-11f1-8789-9696ace701e2',6,'Everest Bites','everest-bites','restaurant','Newari specialties, momos and traditional thali sets.','https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400','https://images.unsplash.com/photo-1601050690597-df0568f70950?w=1200','9800000006','contact.everestbites@example.com','Lamki Road','Dhangadhi',28.6870000,80.5975000,1,1,0,8.00,50.00,200.00,25,15.00,'approved',1,'09:00:00','22:00:00','2026-09-26 05:54:50','2026-09-26 06:35:55'),(7,'34cb9550-b96f-11f1-8789-9696ace701e2',7,'Butwal Bazaar Kitchen','butwal-bazaar-kitchen','restaurant','Local favorite for Nepali thali, Indian curries and tandoori grills.','https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400','https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1200','9800000007','contact.butwalbazaar@example.com','Traffic Chowk','Butwal',27.7000000,83.4486000,1,1,0,8.00,60.00,200.00,25,15.00,'approved',1,'09:00:00','22:00:00','2026-09-26 05:57:50','2026-09-26 06:35:55'),(8,'36f7aa9a-b96f-11f1-8789-9696ace701e2',8,'Thamel Coffee House','thamel-coffee-house','cafe','Specialty coffee, all-day breakfast, pastries and light bites.','https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400','https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1200','9800000008','contact.thamelcoffee@example.com','Thamel Marg','Kathmandu',27.7172000,85.3240000,1,1,0,6.00,60.00,150.00,25,15.00,'approved',1,'07:00:00','21:00:00','2026-09-26 05:57:53','2026-09-26 06:35:55'),(9,'38bdb4f4-b96f-11f1-8789-9696ace701e2',9,'Lakeside Heritage Hotel','lakeside-heritage-hotel','hotel','Lakeside views, in-house restaurant, and easy access to boating & paragliding.','https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400','https://images.unsplash.com/photo-1566073771259-6a8506099945?w=1200','9800000009','contact.lakesideheritage@example.com','Lakeside Road','Pokhara',28.2096000,83.9856000,1,0,1,0.00,0.00,0.00,25,15.00,'approved',1,'00:00:00','23:59:00','2026-09-26 05:57:56','2026-09-26 06:35:56'),(10,'39749f17-b96f-11f1-8789-9696ace701e2',10,'Rapti Guest House','rapti-guest-house','guest_house','Simple, clean rooms near the bus park, with home-cooked meals on request.','https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400','https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=1200','9800000010','contact.raptiguesthouse@example.com','Surkhet Road','Nepalgunj',28.1000000,81.6167000,0,0,1,0.00,0.00,0.00,25,15.00,'approved',1,'00:00:00','23:59:00','2026-09-26 05:57:58','2026-09-26 06:35:56'),(11,'3a31684d-b96f-11f1-8789-9696ace701e2',11,'Koshi Delights','koshi-delights','restaurant','Family restaurant serving Nepali, Indian and Chinese cuisine.','https://images.unsplash.com/photo-1543353071-873f17a7a088?w=400','https://images.unsplash.com/photo-1543353071-873f17a7a088?w=1200','9800000011','contact.koshidelights@example.com','Main Road','Biratnagar',26.4525000,87.2718000,1,1,0,8.00,60.00,200.00,25,15.00,'approved',1,'10:00:00','22:00:00','2026-09-26 05:57:59','2026-09-26 06:35:57'),(17,'cef698d3-b973-11f1-8789-9696ace701e2',18,'El Dorado Avenue','el-dorado-avenue','restaurant','Fine-dining restaurant known for momo, matka biryani and sekuwa.','https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400','https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=1200','9800000012','contact.eldorado@example.com','Kalikanagar 11, Horizon Chowk','Butwal',27.6784517,83.4621997,1,1,0,8.00,70.00,250.00,25,15.00,'approved',1,'07:00:00','23:30:00','2026-09-26 06:30:46','2026-09-26 06:30:46'),(18,'d01fd752-b973-11f1-8789-9696ace701e2',19,'Soulmate Restaurant Butwal','soulmate-restaurant-butwal','restaurant','Cozy family restaurant known for chicken biryani and timur chicken.','https://images.unsplash.com/photo-1552566626-52f8b828add9?w=400','https://images.unsplash.com/photo-1552566626-52f8b828add9?w=1200','9800000013','contact.soulmate@example.com','Kalikanagar Butwal-11','Butwal',27.6764449,83.4626109,1,1,0,8.00,60.00,200.00,25,15.00,'approved',1,'08:00:00','22:00:00','2026-09-26 06:30:48','2026-09-26 06:35:57'),(19,'d147b55f-b973-11f1-8789-9696ace701e2',20,'Daddy\'s Kitchen','daddys-kitchen-butwal','restaurant','Lively family restaurant with a big menu of Nepali, fast-food and continental dishes.','https://images.unsplash.com/photo-1550547660-d9450f859349?w=400','https://images.unsplash.com/photo-1550547660-d9450f859349?w=1200','9800000014','contact.daddyskitchen@example.com','Butwal','Butwal',27.6669015,83.4609114,1,1,0,8.00,60.00,200.00,25,15.00,'approved',1,'07:00:00','23:00:00','2026-09-26 06:30:50','2026-09-26 06:35:58'),(20,'d28ff625-b973-11f1-8789-9696ace701e2',21,'Grassland Nepal','grassland-nepal','restaurant','Restaurant, bar and cafe combo with live music, sushi and wood-fired pizza.','https://images.unsplash.com/photo-1544148103-0773bf10d330?w=400','https://images.unsplash.com/photo-1544148103-0773bf10d330?w=1200','9800000015','contact.grassland@example.com','Butwal','Butwal',27.6856134,83.4626004,1,1,0,8.00,60.00,250.00,25,15.00,'approved',1,'10:00:00','23:00:00','2026-09-26 06:30:53','2026-09-26 06:30:53'),(21,'d3b7b086-b973-11f1-8789-9696ace701e2',22,'Hide Out Restro','hide-out-restro','restaurant','Green, quiet outdoor restaurant surrounded by nature.','https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400','https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1200','9800000016','contact.hideout@example.com','Butwal','Butwal',27.7017324,83.4530679,1,1,0,8.00,60.00,200.00,25,15.00,'approved',1,'08:00:00','22:00:00','2026-09-26 06:30:54','2026-09-26 06:35:58'),(22,'d4ded557-b973-11f1-8789-9696ace701e2',23,'Butwal Veg & Vegan Restaurant','butwal-veg-vegan-restaurant','restaurant','Pure vegetarian and vegan restaurant, including onion-and-garlic-free options.','https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400','https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=1200','9800000017','contact.butwalveg@example.com','Traffic Chowk','Butwal',27.7021861,83.4668620,1,1,0,8.00,60.00,150.00,25,15.00,'approved',1,'07:00:00','22:00:00','2026-09-26 06:30:56','2026-09-26 06:35:58'),(23,'d604b901-b973-11f1-8789-9696ace701e2',24,'Good DO, The Vegan Kitchen','good-do-vegan-kitchen','restaurant','Creative, wholesome vegan kitchen with a cozy outdoor view.','https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400','https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=1200','9800000018','contact.gooddo@example.com','Traffic Chowk','Butwal',27.7015075,83.4664875,1,1,0,8.00,60.00,150.00,25,15.00,'approved',1,'10:00:00','22:00:00','2026-09-26 06:30:58','2026-09-26 06:35:59'),(24,'d72aebdb-b973-11f1-8789-9696ace701e2',25,'Cloud 9 Cafe','cloud-9-cafe','cafe','Cozy cafe known for its chicken wraps and relaxed hookah lounge vibe.','https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400','https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1200','9800000019','contact.cloud9@example.com','Devinagar','Butwal',27.6821325,83.4581235,1,1,0,6.00,60.00,150.00,25,15.00,'approved',1,'07:00:00','22:00:00','2026-09-26 06:31:00','2026-09-26 06:35:59'),(25,'d833e8ef-b973-11f1-8789-9696ace701e2',26,'Papaya Butwal','papaya-butwal','cafe','Cozy cafe and bakery known for smoothie bowls, sliders and bubble tea.','https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400','https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=1200','9800000020','contact.papaya@example.com','Kalika Path','Butwal',27.6843715,83.4624088,1,1,0,6.00,60.00,150.00,25,15.00,'approved',1,'07:00:00','22:00:00','2026-09-26 06:31:02','2026-09-26 06:36:00'),(26,'d93c324b-b973-11f1-8789-9696ace701e2',27,'Caffeine Cup Cafe & Restaurant','caffeine-cup-cafe','cafe','Small, top-rated coffee spot on Moti Path with a relaxed atmosphere.','https://images.unsplash.com/photo-1445116572660-236099ec97a0?w=400','https://images.unsplash.com/photo-1445116572660-236099ec97a0?w=1200','9800000021','contact.caffeinecup@example.com','Moti Path','Butwal',27.6867868,83.4624920,1,1,0,6.00,60.00,150.00,25,15.00,'approved',1,'07:00:00','22:00:00','2026-09-26 06:31:04','2026-09-26 06:36:00');
/*!40000 ALTER TABLE `businesses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `menu_categories`
--

DROP TABLE IF EXISTS `menu_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `menu_categories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `business_id` int NOT NULL,
  `name` varchar(100) NOT NULL,
  `sort_order` int DEFAULT '0',
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `business_id` (`business_id`),
  CONSTRAINT `menu_categories_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=108 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `menu_categories`
--

LOCK TABLES `menu_categories` WRITE;
/*!40000 ALTER TABLE `menu_categories` DISABLE KEYS */;
INSERT INTO `menu_categories` VALUES (1,1,'Momo & Starters',1,1),(2,1,'Main Course',2,1),(3,1,'Tandoori & Grill',3,1),(4,1,'Beverages',4,1),(5,2,'Starters',1,1),(6,2,'Noodles & Rice',2,1),(7,2,'Beverages',3,1),(8,4,'Coffee',1,1),(9,4,'Bakery',2,1),(10,6,'Momo & Newari',1,1),(11,6,'Thali Sets',2,1),(12,7,'Starters',1,1),(13,7,'Main Course',2,1),(14,7,'Breads & Rice',3,1),(15,7,'Desserts',4,1),(16,7,'Beverages',5,1),(17,8,'Coffee',1,1),(18,8,'Breakfast',2,1),(19,8,'Bakery',3,1),(20,8,'Sandwiches',4,1),(21,11,'Starters',1,1),(22,11,'Main Course',2,1),(23,11,'Noodles & Rice',3,1),(24,11,'Desserts',4,1),(25,11,'Beverages',5,1),(26,37,'Starters',1,1),(27,37,'Main Course',2,1),(28,37,'Breads & Rice',3,1),(29,37,'Desserts',4,1),(30,37,'Beverages',5,1),(31,45,'Coffee',1,1),(32,45,'Breakfast',2,1),(33,45,'Bakery',3,1),(34,45,'Sandwiches',4,1),(35,15,'Starters',1,1),(36,15,'Main Course',2,1),(37,15,'Noodles & Rice',3,1),(38,15,'Desserts',4,1),(39,15,'Beverages',5,1),(40,17,'Starters',1,1),(41,17,'Main Course',2,1),(42,17,'Beverages',3,1),(43,18,'Starters',1,1),(44,18,'Main Course',2,1),(45,18,'Beverages',3,1),(46,19,'Starters',1,1),(47,19,'Fast Food',2,1),(48,19,'Main Course',3,1),(49,19,'Beverages',4,1),(50,20,'Starters',1,1),(51,20,'Pizza & Sushi',2,1),(52,20,'Beverages',3,1),(53,21,'Starters',1,1),(54,21,'Main Course',2,1),(55,21,'Beverages',3,1),(56,22,'Starters',1,1),(57,22,'Main Course',2,1),(58,22,'Beverages',3,1),(59,23,'Starters',1,1),(60,23,'Main Course',2,1),(61,23,'Beverages',3,1),(62,24,'Coffee',1,1),(63,24,'Wraps & Snacks',2,1),(64,25,'Beverages',1,1),(65,25,'Snacks & Bowls',2,1),(66,26,'Coffee',1,1),(67,26,'Snacks',2,1),(68,108,'Starters',1,1),(69,108,'Main Course',2,1),(70,108,'Breads & Rice',3,1),(71,108,'Desserts',4,1),(72,108,'Beverages',5,1),(73,111,'Starters',1,1),(74,111,'Main Course',2,1),(75,111,'Noodles & Rice',3,1),(76,111,'Desserts',4,1),(77,111,'Beverages',5,1),(78,122,'Starters',1,1),(79,122,'Fast Food',2,1),(80,122,'Main Course',3,1),(81,122,'Desserts',4,1),(82,122,'Beverages',5,1),(83,131,'Starters',1,1),(84,131,'Pizza & Sushi',2,1),(85,131,'Main Course',3,1),(86,131,'Beverages',4,1),(87,139,'Starters',1,1),(88,139,'Main Course',2,1),(89,139,'Desserts',3,1),(90,139,'Beverages',4,1),(91,147,'Starters',1,1),(92,147,'Main Course',2,1),(93,147,'Desserts',3,1),(94,147,'Beverages',4,1),(95,154,'Starters',1,1),(96,154,'Main Course',2,1),(97,154,'Desserts',3,1),(98,154,'Beverages',4,1),(99,162,'Coffee',1,1),(100,162,'Wraps & Snacks',2,1),(101,162,'Bakery',3,1),(102,169,'Beverages',1,1),(103,169,'Snacks & Bowls',2,1),(104,169,'Bakery',3,1),(105,175,'Coffee',1,1),(106,175,'Snacks',2,1),(107,175,'Sandwiches',3,1);
/*!40000 ALTER TABLE `menu_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `menu_item_addons`
--

DROP TABLE IF EXISTS `menu_item_addons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `menu_item_addons` (
  `id` int NOT NULL AUTO_INCREMENT,
  `menu_item_id` int NOT NULL,
  `name` varchar(100) NOT NULL,
  `price` decimal(10,2) NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`id`),
  KEY `menu_item_id` (`menu_item_id`),
  CONSTRAINT `menu_item_addons_ibfk_1` FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `menu_item_addons`
--

LOCK TABLES `menu_item_addons` WRITE;
/*!40000 ALTER TABLE `menu_item_addons` DISABLE KEYS */;
/*!40000 ALTER TABLE `menu_item_addons` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `menu_items`
--

DROP TABLE IF EXISTS `menu_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `menu_items` (
  `id` int NOT NULL AUTO_INCREMENT,
  `business_id` int NOT NULL,
  `category_id` int DEFAULT NULL,
  `name` varchar(150) NOT NULL,
  `description` text,
  `price` decimal(10,2) NOT NULL,
  `discount_percent` decimal(5,2) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `is_veg` tinyint(1) DEFAULT '1',
  `is_available` tinyint(1) DEFAULT '1',
  `prep_time_mins` int DEFAULT '15',
  `tags` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `category_id` (`category_id`),
  KEY `idx_menu_items_business` (`business_id`,`is_available`),
  CONSTRAINT `menu_items_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `menu_items_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `menu_categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_menu_items_discount_percent` CHECK (((`discount_percent` is null) or ((`discount_percent` >= 5) and (`discount_percent` <= 90))))
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `menu_items`
--

LOCK TABLES `menu_items` WRITE;
/*!40000 ALTER TABLE `menu_items` DISABLE KEYS */;
INSERT INTO `menu_items` VALUES (1,1,1,'Chicken Momo','Steamed dumplings with spicy tomato achar.',220.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,15,'momo,steamed,spicy','2026-09-26 05:52:20','2026-09-26 05:52:20'),(2,1,1,'Veg Momo','Steamed veg dumplings with sesame achar.',180.00,NULL,'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=600',1,1,15,'momo,veg,steamed','2026-09-26 05:52:20','2026-09-26 05:52:20'),(3,1,2,'Chicken Thakali Set','Traditional Thakali thali with chicken curry, rice, dal, sides.',450.00,NULL,'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=600',0,1,25,'thakali,set,rice','2026-09-26 05:52:20','2026-09-26 05:52:20'),(4,1,2,'Paneer Butter Masala','Cottage cheese in a rich buttery tomato gravy.',340.00,NULL,'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=600',1,1,20,'paneer,curry,veg','2026-09-26 05:52:20','2026-09-26 05:52:20'),(5,1,3,'Tandoori Chicken (Half)','Char-grilled chicken marinated in yogurt & spices.',380.00,NULL,'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=600',0,1,30,'tandoori,grill,chicken','2026-09-26 05:52:20','2026-09-26 05:52:20'),(6,1,4,'Masala Chiya','Spiced Nepali milk tea.',60.00,NULL,'https://images.unsplash.com/photo-1571934811356-5cc061b6821f?w=600',1,1,5,'tea,hot,drink','2026-09-26 05:52:20','2026-09-26 05:52:20'),(7,1,4,'Fresh Lime Soda','Chilled lime soda, sweet or salted.',90.00,NULL,'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=600',1,1,5,'cold,drink,refreshing','2026-09-26 05:52:20','2026-09-26 05:52:20'),(8,2,5,'Chilli Chicken','Crispy chicken tossed in a spicy chilli-soy sauce.',320.00,NULL,'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600',0,1,20,'spicy,chicken,starter','2026-09-26 05:54:45','2026-09-26 05:54:45'),(9,2,6,'Veg Chowmein','Stir-fried noodles with fresh vegetables.',220.00,NULL,'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=600',1,1,15,'noodles,veg','2026-09-26 05:54:45','2026-09-26 05:54:45'),(10,2,6,'Chicken Fried Rice','Wok-tossed rice with chicken and egg.',260.00,NULL,'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=600',0,1,18,'rice,chicken','2026-09-26 05:54:45','2026-09-26 05:54:45'),(11,2,7,'Iced Lemon Tea','Chilled lemon tea, lightly sweetened.',80.00,NULL,'https://images.unsplash.com/photo-1499638673689-79a0b5115d87?w=600',1,1,5,'cold,tea','2026-09-26 05:54:45','2026-09-26 05:54:45'),(12,4,8,'Cappuccino','Espresso with steamed milk foam.',150.00,NULL,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600',1,1,8,'coffee,hot','2026-09-26 05:54:48','2026-09-26 05:54:48'),(13,4,8,'Cold Brew','Slow-steeped, smooth cold coffee.',180.00,NULL,'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=600',1,1,5,'coffee,cold','2026-09-26 05:54:48','2026-09-26 05:54:48'),(14,4,9,'Butter Croissant','Flaky, buttery French croissant.',130.00,NULL,'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600',1,1,5,'bakery,pastry','2026-09-26 05:54:48','2026-09-26 05:54:48'),(15,4,9,'Chocolate Muffin','Rich chocolate chip muffin.',110.00,NULL,'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=600',1,1,5,'bakery,dessert','2026-09-26 05:54:48','2026-09-26 05:54:48'),(16,6,10,'Buff Momo (Jhol)','Buffalo momos in spicy soupy achar.',240.00,NULL,'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=600',0,1,18,'momo,newari,spicy','2026-09-26 05:54:51','2026-09-26 05:54:51'),(17,6,10,'Chatamari','Rice-flour crepe topped with egg and minced meat.',200.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,15,'newari,snack','2026-09-26 05:54:51','2026-09-26 05:54:51'),(18,6,11,'Dal Bhat Set','Rice, lentils, seasonal veg curry, pickle and papad.',260.00,NULL,'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=600',1,1,20,'thali,rice,veg','2026-09-26 05:54:51','2026-09-26 05:54:51'),(19,7,12,'Chicken Chilli','Wok-tossed chicken in spicy chilli sauce.',300.00,NULL,'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600',0,1,18,'spicy,chicken,starter','2026-09-26 05:57:52','2026-09-26 05:57:52'),(20,7,12,'Paneer Pakoda','Cottage cheese fritters, crispy fried.',220.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',1,1,15,'veg,fried,snack','2026-09-26 05:57:52','2026-09-26 05:57:52'),(21,7,13,'Chicken Curry','Home-style bone-in chicken curry.',340.00,NULL,'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=600',0,1,25,'curry,chicken','2026-09-26 05:57:52','2026-09-26 05:57:52'),(22,7,13,'Mutton Curry','Slow-cooked goat meat in a rich masala gravy.',480.00,NULL,'https://images.unsplash.com/photo-1585937421612-70a008356c36?w=600',0,1,35,'curry,mutton','2026-09-26 05:57:52','2026-09-26 05:57:52'),(23,7,13,'Paneer Butter Masala','Cottage cheese in a buttery tomato gravy.',320.00,NULL,'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=600',1,1,20,'paneer,veg,curry','2026-09-26 05:57:52','2026-09-26 05:57:52'),(24,7,13,'Dal Bhat Set','Rice, lentils, veg curry, pickle and papad.',260.00,NULL,'https://images.unsplash.com/photo-1547592180-85f173990554?w=600',1,1,20,'thali,rice,veg','2026-09-26 05:57:52','2026-09-26 05:57:52'),(25,7,14,'Butter Naan','Soft tandoor-baked bread with butter.',60.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',1,1,10,'bread,tandoor','2026-09-26 05:57:52','2026-09-26 05:57:52'),(26,7,14,'Steamed Rice','Plain steamed basmati rice.',100.00,NULL,'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600',1,1,15,'rice,plain','2026-09-26 05:57:52','2026-09-26 05:57:52'),(27,7,15,'Gulab Jamun (2 pcs)','Deep-fried milk dumplings in sugar syrup.',90.00,NULL,'https://images.unsplash.com/photo-1601303516361-b0a4c0bd6f1e?w=600',1,1,5,'dessert,sweet','2026-09-26 05:57:52','2026-09-26 05:57:52'),(28,7,16,'Masala Chiya','Spiced Nepali milk tea.',60.00,NULL,'https://images.unsplash.com/photo-1571934811356-5cc061b6821f?w=600',1,1,5,'tea,hot','2026-09-26 05:57:52','2026-09-26 05:57:52'),(29,8,17,'Cappuccino','Espresso with steamed milk foam.',160.00,NULL,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600',1,1,8,'coffee,hot','2026-09-26 05:57:56','2026-09-26 05:57:56'),(30,8,17,'Americano','Espresso shots topped with hot water.',140.00,NULL,'https://images.unsplash.com/photo-1497935586047-9242eb4fc339?w=600',1,1,6,'coffee,hot','2026-09-26 05:57:56','2026-09-26 05:57:56'),(31,8,17,'Iced Latte','Espresso with cold milk over ice.',180.00,NULL,'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=600',1,1,6,'coffee,cold','2026-09-26 05:57:56','2026-09-26 05:57:56'),(32,8,18,'Pancake Stack','Fluffy pancakes with maple syrup.',250.00,NULL,'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=600',1,1,15,'breakfast,sweet','2026-09-26 05:57:56','2026-09-26 05:57:56'),(33,8,18,'Veg Omelette','Three-egg omelette with mixed vegetables.',200.00,NULL,'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=600',0,1,10,'breakfast,egg','2026-09-26 05:57:56','2026-09-26 05:57:56'),(34,8,19,'Butter Croissant','Flaky, buttery French croissant.',140.00,NULL,'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600',1,1,5,'bakery,pastry','2026-09-26 05:57:56','2026-09-26 05:57:56'),(35,8,19,'Chocolate Muffin','Rich chocolate chip muffin.',120.00,NULL,'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=600',1,1,5,'bakery,dessert','2026-09-26 05:57:56','2026-09-26 05:57:56'),(36,8,20,'Grilled Cheese Sandwich','Melted cheese between toasted bread.',190.00,NULL,'https://images.unsplash.com/photo-1528736235302-52922df5c122?w=600',1,1,10,'sandwich,cheese','2026-09-26 05:57:56','2026-09-26 05:57:56'),(37,11,21,'Chicken Momo','Steamed dumplings with spicy tomato achar.',220.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,15,'momo,steamed','2026-09-26 05:58:01','2026-09-26 05:58:01'),(38,11,21,'Veg Spring Rolls','Crispy rolls stuffed with veggies.',180.00,NULL,'https://images.unsplash.com/photo-1548507200-64a1c2a30a66?w=600',1,1,12,'fried,veg,starter','2026-09-26 05:58:01','2026-09-26 05:58:01'),(39,11,22,'Chicken Chowmein','Stir-fried noodles with chicken.',260.00,NULL,'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=600',0,1,18,'noodles,chicken','2026-09-26 05:58:01','2026-09-26 05:58:01'),(40,11,22,'Fish Curry','Freshwater fish in a tangy Nepali-style curry.',380.00,NULL,'https://images.unsplash.com/photo-1626200926749-4585f8e8ffc0?w=600',0,1,30,'fish,curry','2026-09-26 05:58:01','2026-09-26 05:58:01'),(41,11,23,'Chicken Fried Rice','Wok-tossed rice with chicken and egg.',260.00,NULL,'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=600',0,1,18,'rice,chicken','2026-09-26 05:58:01','2026-09-26 05:58:01'),(42,11,23,'Veg Fried Rice','Wok-tossed rice with mixed vegetables.',200.00,NULL,'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600',1,1,15,'rice,veg','2026-09-26 05:58:01','2026-09-26 05:58:01'),(43,11,24,'Rasbari (2 pcs)','Soft milk-based sweet in sugar syrup.',90.00,NULL,'https://images.unsplash.com/photo-1601303516361-b0a4c0bd6f1e?w=600',1,1,5,'dessert,sweet','2026-09-26 05:58:01','2026-09-26 05:58:01'),(44,11,25,'Fresh Lime Soda','Chilled lime soda, sweet or salted.',90.00,NULL,'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=600',1,1,5,'cold,drink','2026-09-26 05:58:01','2026-09-26 05:58:01'),(45,37,26,'Chicken Chilli','Wok-tossed chicken in spicy chilli sauce.',300.00,NULL,'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600',0,1,18,'spicy,chicken,starter','2026-09-26 06:26:55','2026-09-26 06:26:55'),(46,37,26,'Paneer Pakoda','Cottage cheese fritters, crispy fried.',220.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',1,1,15,'veg,fried,snack','2026-09-26 06:26:55','2026-09-26 06:26:55'),(47,37,27,'Chicken Curry','Home-style bone-in chicken curry.',340.00,NULL,'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=600',0,1,25,'curry,chicken','2026-09-26 06:26:55','2026-09-26 06:26:55'),(48,37,27,'Mutton Curry','Slow-cooked goat meat in a rich masala gravy.',480.00,NULL,'https://images.unsplash.com/photo-1585937421612-70a008356c36?w=600',0,1,35,'curry,mutton','2026-09-26 06:26:55','2026-09-26 06:26:55'),(49,37,27,'Paneer Butter Masala','Cottage cheese in a buttery tomato gravy.',320.00,NULL,'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=600',1,1,20,'paneer,veg,curry','2026-09-26 06:26:55','2026-09-26 06:26:55'),(50,37,27,'Dal Bhat Set','Rice, lentils, veg curry, pickle and papad.',260.00,NULL,'https://images.unsplash.com/photo-1547592180-85f173990554?w=600',1,1,20,'thali,rice,veg','2026-09-26 06:26:55','2026-09-26 06:26:55'),(51,37,28,'Butter Naan','Soft tandoor-baked bread with butter.',60.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',1,1,10,'bread,tandoor','2026-09-26 06:26:55','2026-09-26 06:26:55'),(52,37,28,'Steamed Rice','Plain steamed basmati rice.',100.00,NULL,'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600',1,1,15,'rice,plain','2026-09-26 06:26:55','2026-09-26 06:26:55'),(53,37,29,'Gulab Jamun (2 pcs)','Deep-fried milk dumplings in sugar syrup.',90.00,NULL,'https://images.unsplash.com/photo-1601303516361-b0a4c0bd6f1e?w=600',1,1,5,'dessert,sweet','2026-09-26 06:26:55','2026-09-26 06:26:55'),(54,37,30,'Masala Chiya','Spiced Nepali milk tea.',60.00,NULL,'https://images.unsplash.com/photo-1571934811356-5cc061b6821f?w=600',1,1,5,'tea,hot','2026-09-26 06:26:55','2026-09-26 06:26:55'),(55,45,31,'Cappuccino','Espresso with steamed milk foam.',160.00,NULL,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600',1,1,8,'coffee,hot','2026-09-26 06:26:57','2026-09-26 06:26:57'),(56,45,31,'Americano','Espresso shots topped with hot water.',140.00,NULL,'https://images.unsplash.com/photo-1497935586047-9242eb4fc339?w=600',1,1,6,'coffee,hot','2026-09-26 06:26:57','2026-09-26 06:26:57'),(57,45,31,'Iced Latte','Espresso with cold milk over ice.',180.00,NULL,'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=600',1,1,6,'coffee,cold','2026-09-26 06:26:57','2026-09-26 06:26:57'),(58,45,32,'Pancake Stack','Fluffy pancakes with maple syrup.',250.00,NULL,'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=600',1,1,15,'breakfast,sweet','2026-09-26 06:26:57','2026-09-26 06:26:57'),(59,45,32,'Veg Omelette','Three-egg omelette with mixed vegetables.',200.00,NULL,'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=600',0,1,10,'breakfast,egg','2026-09-26 06:26:57','2026-09-26 06:26:57'),(60,45,33,'Butter Croissant','Flaky, buttery French croissant.',140.00,NULL,'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600',1,1,5,'bakery,pastry','2026-09-26 06:26:57','2026-09-26 06:26:57'),(61,45,33,'Chocolate Muffin','Rich chocolate chip muffin.',120.00,NULL,'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=600',1,1,5,'bakery,dessert','2026-09-26 06:26:57','2026-09-26 06:26:57'),(62,45,34,'Grilled Cheese Sandwich','Melted cheese between toasted bread.',190.00,NULL,'https://images.unsplash.com/photo-1528736235302-52922df5c122?w=600',1,1,10,'sandwich,cheese','2026-09-26 06:26:57','2026-09-26 06:26:57'),(63,15,35,'Chicken Momo','Steamed dumplings with spicy tomato achar.',220.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,15,'momo,steamed','2026-09-26 06:27:02','2026-09-26 06:27:02'),(64,15,35,'Veg Spring Rolls','Crispy rolls stuffed with veggies.',180.00,NULL,'https://images.unsplash.com/photo-1548507200-64a1c2a30a66?w=600',1,1,12,'fried,veg,starter','2026-09-26 06:27:02','2026-09-26 06:27:02'),(65,15,36,'Chicken Chowmein','Stir-fried noodles with chicken.',260.00,NULL,'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=600',0,1,18,'noodles,chicken','2026-09-26 06:27:02','2026-09-26 06:27:02'),(66,15,36,'Fish Curry','Freshwater fish in a tangy Nepali-style curry.',380.00,NULL,'https://images.unsplash.com/photo-1626200926749-4585f8e8ffc0?w=600',0,1,30,'fish,curry','2026-09-26 06:27:02','2026-09-26 06:27:02'),(67,15,37,'Chicken Fried Rice','Wok-tossed rice with chicken and egg.',260.00,NULL,'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=600',0,1,18,'rice,chicken','2026-09-26 06:27:02','2026-09-26 06:27:02'),(68,15,37,'Veg Fried Rice','Wok-tossed rice with mixed vegetables.',200.00,NULL,'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600',1,1,15,'rice,veg','2026-09-26 06:27:02','2026-09-26 06:27:02'),(69,15,38,'Rasbari (2 pcs)','Soft milk-based sweet in sugar syrup.',90.00,NULL,'https://images.unsplash.com/photo-1601303516361-b0a4c0bd6f1e?w=600',1,1,5,'dessert,sweet','2026-09-26 06:27:02','2026-09-26 06:27:02'),(70,15,39,'Fresh Lime Soda','Chilled lime soda, sweet or salted.',90.00,NULL,'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=600',1,1,5,'cold,drink','2026-09-26 06:27:02','2026-09-26 06:27:02'),(71,17,40,'Chicken Sekuwa','Grilled marinated chicken skewers, smoky and spiced.',380.00,NULL,'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=600',0,1,22,'grill,chicken,starter','2026-09-26 06:30:48','2026-09-26 06:30:48'),(72,17,40,'Steam Momo','Classic steamed dumplings with tomato achar.',240.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,18,'momo,steamed','2026-09-26 06:30:48','2026-09-26 06:30:48'),(73,17,41,'Matka Biryani','Slow-cooked biryani sealed and served in a clay pot.',450.00,NULL,'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600',0,1,35,'biryani,rice','2026-09-26 06:30:48','2026-09-26 06:30:48'),(74,17,41,'Mustang Aloo','Spiced boiled potatoes, Mustang-style.',220.00,NULL,'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=600',1,1,15,'veg,potato,spicy','2026-09-26 06:30:48','2026-09-26 06:30:48'),(75,17,42,'Mango Smoothie','Fresh mango blended with yogurt.',180.00,NULL,'https://images.unsplash.com/photo-1546173159-315724a31696?w=600',1,1,8,'smoothie,cold','2026-09-26 06:30:48','2026-09-26 06:30:48'),(76,17,42,'Cappuccino','Espresso with steamed milk foam.',160.00,NULL,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600',1,1,8,'coffee,hot','2026-09-26 06:30:48','2026-09-26 06:30:48'),(77,18,43,'Chicken Sandheko','Spiced, tossed chicken salad with herbs and lime.',260.00,NULL,'https://images.unsplash.com/photo-1598515213692-5f252f4dc22b?w=600',0,1,15,'spicy,chicken,starter','2026-09-26 06:30:50','2026-09-26 06:30:50'),(78,18,44,'Chicken Biryani','Fragrant, spice-packed biryani with tender chicken.',340.00,NULL,'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600',0,1,30,'biryani,rice,chicken','2026-09-26 06:30:50','2026-09-26 06:30:50'),(79,18,44,'Timur Chicken','Chicken tossed in a zesty Szechwan-pepper sauce.',360.00,NULL,'https://images.unsplash.com/photo-1610057099431-d73a1c9d2ef7?w=600',0,1,25,'spicy,chicken','2026-09-26 06:30:50','2026-09-26 06:30:50'),(80,18,45,'Masala Chiya','Spiced Nepali milk tea.',60.00,NULL,'https://images.unsplash.com/photo-1571934811356-5cc061b6821f?w=600',1,1,5,'tea,hot','2026-09-26 06:30:50','2026-09-26 06:30:50'),(81,19,46,'Chicken Wings','Crispy fried wings tossed in house sauce.',300.00,NULL,'https://images.unsplash.com/photo-1608039755401-742074f0548d?w=600',0,1,18,'fried,chicken,starter','2026-09-26 06:30:52','2026-09-26 06:30:52'),(82,19,47,'Cheese Burger','Grilled patty with melted cheese and salad.',280.00,NULL,'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600',0,1,15,'burger,fastfood','2026-09-26 06:30:52','2026-09-26 06:30:52'),(83,19,48,'Chicken Biryani','Layered rice with spiced chicken.',340.00,NULL,'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600',0,1,30,'biryani,rice','2026-09-26 06:30:52','2026-09-26 06:30:52'),(84,19,49,'Iced Tea','Chilled black tea with lemon.',120.00,NULL,'https://images.unsplash.com/photo-1499638673689-79a0b5115d87?w=600',1,1,6,'tea,cold','2026-09-26 06:30:52','2026-09-26 06:30:52'),(85,20,50,'Juicy Momo','Steamed momo with a rich, juicy filling.',240.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,18,'momo,steamed','2026-09-26 06:30:54','2026-09-26 06:30:54'),(86,20,51,'Margherita Pizza','Classic tomato, mozzarella and basil pizza.',480.00,NULL,'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600',1,1,25,'pizza,veg','2026-09-26 06:30:54','2026-09-26 06:30:54'),(87,20,51,'California Roll','Crab stick, avocado and cucumber sushi roll.',420.00,NULL,'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=600',0,1,20,'sushi,seafood','2026-09-26 06:30:54','2026-09-26 06:30:54'),(88,20,52,'Iced Americano','Chilled espresso over ice.',180.00,NULL,'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=600',1,1,6,'coffee,cold','2026-09-26 06:30:54','2026-09-26 06:30:54'),(89,21,53,'Hot Wings','Crispy chicken wings tossed in a hot glaze.',280.00,NULL,'https://images.unsplash.com/photo-1608039755401-742074f0548d?w=600',0,1,18,'fried,chicken,spicy','2026-09-26 06:30:56','2026-09-26 06:30:56'),(90,21,54,'Veg Pizza','Loaded vegetable pizza on a thin crust.',380.00,NULL,'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600',1,1,22,'pizza,veg','2026-09-26 06:30:56','2026-09-26 06:30:56'),(91,21,54,'Chicken Sandwich','Grilled chicken breast sandwich with veggies.',260.00,NULL,'https://images.unsplash.com/photo-1521305916504-4a1121188589?w=600',0,1,15,'sandwich,chicken','2026-09-26 06:30:56','2026-09-26 06:30:56'),(92,21,55,'Peach Iced Tea','Chilled tea with peach syrup.',150.00,NULL,'https://images.unsplash.com/photo-1499638673689-79a0b5115d87?w=600',1,1,6,'tea,cold','2026-09-26 06:30:56','2026-09-26 06:30:56'),(93,22,56,'Veg Momo','Steamed vegetable momo with achar.',200.00,NULL,'https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?w=600',1,1,15,'momo,veg','2026-09-26 06:30:58','2026-09-26 06:30:58'),(94,22,57,'Veg Biryani','Mixed-vegetable biryani, no onion or garlic option available.',280.00,NULL,'https://images.unsplash.com/photo-1633945274309-2a991dd7cf20?w=600',1,1,25,'biryani,veg','2026-09-26 06:30:58','2026-09-26 06:30:58'),(95,22,57,'Chukauni Set','Potato salad in a mustard-yogurt dressing with rice.',220.00,NULL,'https://images.unsplash.com/photo-1547592180-85f173990554?w=600',1,1,18,'veg,nepali','2026-09-26 06:30:58','2026-09-26 06:30:58'),(96,22,58,'Fresh Lime Soda','Chilled lime soda, sweet or salted.',90.00,NULL,'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=600',1,1,5,'cold,drink','2026-09-26 06:30:58','2026-09-26 06:30:58'),(97,23,59,'Veg Bytz Sekuwa','Plant-based grilled skewers with house spices.',260.00,NULL,'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=600',1,1,18,'vegan,grill,starter','2026-09-26 06:31:00','2026-09-26 06:31:00'),(98,23,60,'Buddha Bowl','Mixed grains, greens and roasted vegetables.',300.00,NULL,'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600',1,1,15,'vegan,healthy,bowl','2026-09-26 06:31:00','2026-09-26 06:31:00'),(99,23,60,'Vegan Burger','Plant-based patty with vegan mayo and greens.',320.00,NULL,'https://images.unsplash.com/photo-1520072959219-c595dc870360?w=600',1,1,18,'vegan,burger','2026-09-26 06:31:00','2026-09-26 06:31:00'),(100,23,61,'Green Detox Juice','Cold-pressed spinach, cucumber and apple juice.',160.00,NULL,'https://images.unsplash.com/photo-1622597467836-f3285f2131b8?w=600',1,1,8,'vegan,juice,cold','2026-09-26 06:31:00','2026-09-26 06:31:00'),(101,24,62,'Iced Latte','Espresso with cold milk over ice.',180.00,NULL,'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=600',1,1,6,'coffee,cold','2026-09-26 06:31:01','2026-09-26 06:31:01'),(102,24,63,'Chicken Wrap','Grilled chicken, veggies and sauce in a soft tortilla.',260.00,NULL,'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=600',0,1,15,'wrap,chicken','2026-09-26 06:31:01','2026-09-26 06:31:01'),(103,24,63,'Stuffed Mushroom','Baked mushrooms stuffed with cheese and herbs.',220.00,NULL,'https://images.unsplash.com/photo-1547181093-4d84c2af9c9c?w=600',1,1,15,'veg,snack','2026-09-26 06:31:01','2026-09-26 06:31:01'),(104,25,64,'Strawberry Matcha Latte','Matcha latte layered with strawberry syrup.',220.00,NULL,'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=600',1,1,8,'matcha,cold','2026-09-26 06:31:03','2026-09-26 06:31:03'),(105,25,64,'Red Velvet Boba','Red velvet milk tea with tapioca pearls.',200.00,NULL,'https://images.unsplash.com/photo-1558857563-b371033873b8?w=600',1,1,8,'boba,cold','2026-09-26 06:31:03','2026-09-26 06:31:03'),(106,25,65,'Healthy Smoothie Bowl','Mixed berries, granola and banana over smoothie base.',260.00,NULL,'https://images.unsplash.com/photo-1490474504059-bf2db5ab2348?w=600',1,1,12,'healthy,bowl','2026-09-26 06:31:03','2026-09-26 06:31:03'),(107,25,65,'Chicken Sliders (3 pcs)','Mini burgers with grilled chicken patties.',280.00,NULL,'https://images.unsplash.com/photo-1550317138-10000687a72b?w=600',0,1,15,'sliders,chicken','2026-09-26 06:31:03','2026-09-26 06:31:03'),(108,26,66,'Dopio Espresso','Double shot of rich espresso.',140.00,NULL,'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=600',1,1,5,'coffee,hot','2026-09-26 06:31:05','2026-09-26 06:31:05'),(109,26,66,'Cappuccino','Espresso with steamed milk foam.',160.00,NULL,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600',1,1,8,'coffee,hot','2026-09-26 06:31:05','2026-09-26 06:31:05'),(110,26,67,'Chocolate Muffin','Rich chocolate chip muffin.',120.00,NULL,'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=600',1,1,5,'bakery,dessert','2026-09-26 06:31:05','2026-09-26 06:31:05'),(111,108,68,'Chicken Sekuwa','Grilled marinated chicken skewers, smoky and spiced.',380.00,NULL,'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=600',0,1,22,'grill,chicken,starter','2026-09-26 06:36:20','2026-09-26 06:36:20'),(112,108,68,'Steam Momo','Classic steamed dumplings with tomato achar.',240.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,18,'momo,steamed','2026-09-26 06:36:20','2026-09-26 06:36:20'),(113,108,68,'Paneer Tikka','Char-grilled cottage cheese cubes in tandoori spice.',300.00,NULL,'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=600',1,1,20,'paneer,veg,grill','2026-09-26 06:36:20','2026-09-26 06:36:20'),(114,108,69,'Matka Biryani','Slow-cooked biryani sealed and served in a clay pot.',450.00,NULL,'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600',0,1,35,'biryani,rice','2026-09-26 06:36:20','2026-09-26 06:36:20'),(115,108,69,'Mustang Aloo','Spiced boiled potatoes, Mustang-style.',220.00,NULL,'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=600',1,1,15,'veg,potato,spicy','2026-09-26 06:36:20','2026-09-26 06:36:20'),(116,108,69,'Butter Chicken','Creamy tomato-based chicken curry.',420.00,NULL,'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=600',0,1,28,'curry,chicken','2026-09-26 06:36:20','2026-09-26 06:36:20'),(117,108,70,'Garlic Naan','Tandoor-baked bread topped with garlic and butter.',80.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',1,1,10,'bread,tandoor','2026-09-26 06:36:20','2026-09-26 06:36:20'),(118,108,70,'Jeera Rice','Basmati rice tempered with cumin.',140.00,NULL,'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600',1,1,15,'rice,veg','2026-09-26 06:36:20','2026-09-26 06:36:20'),(119,108,71,'Mango Sorbet','Refreshing mango sorbet, served chilled.',150.00,NULL,'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=600',1,1,5,'dessert,cold','2026-09-26 06:36:20','2026-09-26 06:36:20'),(120,108,72,'Mango Smoothie','Fresh mango blended with yogurt.',180.00,NULL,'https://images.unsplash.com/photo-1546173159-315724a31696?w=600',1,1,8,'smoothie,cold','2026-09-26 06:36:20','2026-09-26 06:36:20'),(121,108,72,'Cappuccino','Espresso with steamed milk foam.',160.00,NULL,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600',1,1,8,'coffee,hot','2026-09-26 06:36:20','2026-09-26 06:36:20'),(122,111,73,'Chicken Sandheko','Spiced, tossed chicken salad with herbs and lime.',260.00,NULL,'https://images.unsplash.com/photo-1598515213692-5f252f4dc22b?w=600',0,1,15,'spicy,chicken,starter','2026-09-26 06:36:22','2026-09-26 06:36:22'),(123,111,73,'Chicken Momo','Steamed dumplings with a spicy tomato achar.',240.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,18,'momo,steamed','2026-09-26 06:36:22','2026-09-26 06:36:22'),(124,111,74,'Chicken Biryani','Fragrant, spice-packed biryani with tender chicken.',340.00,NULL,'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600',0,1,30,'biryani,rice,chicken','2026-09-26 06:36:22','2026-09-26 06:36:22'),(125,111,74,'Timur Chicken','Chicken tossed in a zesty Szechwan-pepper sauce.',360.00,NULL,'https://images.unsplash.com/photo-1610057099431-d73a1c9d2ef7?w=600',0,1,25,'spicy,chicken','2026-09-26 06:36:22','2026-09-26 06:36:22'),(126,111,74,'Mutton Curry','Slow-cooked goat meat in a rich masala gravy.',480.00,NULL,'https://images.unsplash.com/photo-1585937421612-70a008356c36?w=600',0,1,35,'curry,mutton','2026-09-26 06:36:22','2026-09-26 06:36:22'),(127,111,75,'Chicken Chowmein','Stir-fried noodles with chicken and vegetables.',260.00,NULL,'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=600',0,1,18,'noodles,chicken','2026-09-26 06:36:22','2026-09-26 06:36:22'),(128,111,76,'Gulab Jamun (2 pcs)','Deep-fried milk dumplings in sugar syrup.',90.00,NULL,'https://images.unsplash.com/photo-1601303516361-b0a4c0bd6f1e?w=600',1,1,5,'dessert,sweet','2026-09-26 06:36:22','2026-09-26 06:36:22'),(129,111,77,'Masala Chiya','Spiced Nepali milk tea.',60.00,NULL,'https://images.unsplash.com/photo-1571934811356-5cc061b6821f?w=600',1,1,5,'tea,hot','2026-09-26 06:36:22','2026-09-26 06:36:22'),(130,111,77,'Fresh Lime Soda','Chilled lime soda, sweet or salted.',90.00,NULL,'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=600',1,1,5,'cold,drink','2026-09-26 06:36:22','2026-09-26 06:36:22'),(131,122,78,'Chicken Wings','Crispy fried wings tossed in house sauce.',300.00,NULL,'https://images.unsplash.com/photo-1608039755401-742074f0548d?w=600',0,1,18,'fried,chicken,starter','2026-09-26 06:36:25','2026-09-26 06:36:25'),(132,122,78,'Veg Spring Rolls','Crispy rolls stuffed with mixed vegetables.',220.00,NULL,'https://images.unsplash.com/photo-1548507200-64a1c2a30a66?w=600',1,1,12,'fried,veg,starter','2026-09-26 06:36:25','2026-09-26 06:36:25'),(133,122,79,'Cheese Burger','Grilled patty with melted cheese and salad.',280.00,NULL,'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600',0,1,15,'burger,fastfood','2026-09-26 06:36:25','2026-09-26 06:36:25'),(134,122,79,'Loaded Fries','Crispy fries topped with cheese sauce and jalapenos.',240.00,NULL,'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=600',1,1,12,'fries,fastfood','2026-09-26 06:36:25','2026-09-26 06:36:25'),(135,122,80,'Chicken Biryani','Layered rice with spiced chicken.',340.00,NULL,'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600',0,1,30,'biryani,rice','2026-09-26 06:36:25','2026-09-26 06:36:25'),(136,122,80,'Grilled Chicken Steak','Pan-grilled chicken breast with pepper sauce.',420.00,NULL,'https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=600',0,1,25,'grill,chicken,continental','2026-09-26 06:36:25','2026-09-26 06:36:25'),(137,122,81,'Chocolate Brownie','Warm fudge brownie with a scoop of ice cream.',220.00,NULL,'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=600',1,1,10,'dessert,sweet','2026-09-26 06:36:25','2026-09-26 06:36:25'),(138,122,82,'Iced Tea','Chilled black tea with lemon.',120.00,NULL,'https://images.unsplash.com/photo-1499638673689-79a0b5115d87?w=600',1,1,6,'tea,cold','2026-09-26 06:36:25','2026-09-26 06:36:25'),(139,131,83,'Juicy Momo','Steamed momo with a rich, juicy filling.',240.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,18,'momo,steamed','2026-09-26 06:36:27','2026-09-26 06:36:27'),(140,131,83,'Chicken Wings','Crispy fried wings tossed in house sauce.',300.00,NULL,'https://images.unsplash.com/photo-1608039755401-742074f0548d?w=600',0,1,18,'fried,chicken,starter','2026-09-26 06:36:27','2026-09-26 06:36:27'),(141,131,84,'Margherita Pizza','Classic tomato, mozzarella and basil pizza.',480.00,NULL,'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600',1,1,25,'pizza,veg','2026-09-26 06:36:27','2026-09-26 06:36:27'),(142,131,84,'Pepperoni Pizza','Wood-fired pizza topped with pepperoni.',550.00,NULL,'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=600',0,1,25,'pizza,chicken','2026-09-26 06:36:27','2026-09-26 06:36:27'),(143,131,84,'California Roll','Crab stick, avocado and cucumber sushi roll.',420.00,NULL,'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=600',0,1,20,'sushi,seafood','2026-09-26 06:36:27','2026-09-26 06:36:27'),(144,131,85,'Grilled Chicken Steak','Pan-grilled chicken breast with pepper sauce.',450.00,NULL,'https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=600',0,1,25,'grill,chicken,continental','2026-09-26 06:36:27','2026-09-26 06:36:27'),(145,131,86,'Iced Americano','Chilled espresso over ice.',180.00,NULL,'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=600',1,1,6,'coffee,cold','2026-09-26 06:36:27','2026-09-26 06:36:27'),(146,131,86,'Fresh Lime Soda','Chilled lime soda, sweet or salted.',90.00,NULL,'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=600',1,1,5,'cold,drink','2026-09-26 06:36:27','2026-09-26 06:36:27'),(147,139,87,'Hot Wings','Crispy chicken wings tossed in a hot glaze.',280.00,NULL,'https://images.unsplash.com/photo-1608039755401-742074f0548d?w=600',0,1,18,'fried,chicken,spicy','2026-09-26 06:36:29','2026-09-26 06:36:29'),(148,139,87,'Nachos','Crispy tortilla chips with cheese sauce and salsa.',240.00,NULL,'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?w=600',1,1,12,'snack,veg','2026-09-26 06:36:29','2026-09-26 06:36:29'),(149,139,88,'Veg Pizza','Loaded vegetable pizza on a thin crust.',380.00,NULL,'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600',1,1,22,'pizza,veg','2026-09-26 06:36:29','2026-09-26 06:36:29'),(150,139,88,'Chicken Sandwich','Grilled chicken breast sandwich with veggies.',260.00,NULL,'https://images.unsplash.com/photo-1521305916504-4a1121188589?w=600',0,1,15,'sandwich,chicken','2026-09-26 06:36:29','2026-09-26 06:36:29'),(151,139,88,'Mushroom Pasta','Creamy penne pasta with sauteed mushrooms.',320.00,NULL,'https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?w=600',1,1,20,'pasta,veg','2026-09-26 06:36:29','2026-09-26 06:36:29'),(152,139,89,'Chocolate Muffin','Rich chocolate chip muffin.',120.00,NULL,'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=600',1,1,5,'bakery,dessert','2026-09-26 06:36:29','2026-09-26 06:36:29'),(153,139,90,'Peach Iced Tea','Chilled tea with peach syrup.',150.00,NULL,'https://images.unsplash.com/photo-1499638673689-79a0b5115d87?w=600',1,1,6,'tea,cold','2026-09-26 06:36:29','2026-09-26 06:36:29'),(154,147,91,'Veg Momo','Steamed vegetable momo with achar.',200.00,NULL,'https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?w=600',1,1,15,'momo,veg','2026-09-26 06:36:31','2026-09-26 06:36:31'),(155,147,91,'Paneer Pakoda','Cottage cheese fritters, crispy fried.',220.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',1,1,15,'veg,fried,snack','2026-09-26 06:36:31','2026-09-26 06:36:31'),(156,147,92,'Veg Biryani','Mixed-vegetable biryani, no onion or garlic option available.',280.00,NULL,'https://images.unsplash.com/photo-1633945274309-2a991dd7cf20?w=600',1,1,25,'biryani,veg','2026-09-26 06:36:31','2026-09-26 06:36:31'),(157,147,92,'Chukauni Set','Potato salad in a mustard-yogurt dressing with rice.',220.00,NULL,'https://images.unsplash.com/photo-1547592180-85f173990554?w=600',1,1,18,'veg,nepali','2026-09-26 06:36:31','2026-09-26 06:36:31'),(158,147,92,'Dal Bhat Set','Rice, lentils, veg curry, pickle and papad.',240.00,NULL,'https://images.unsplash.com/photo-1547592180-85f173990554?w=600',1,1,20,'thali,rice,veg','2026-09-26 06:36:31','2026-09-26 06:36:31'),(159,147,93,'Sel Roti (2 pcs)','Traditional Nepali sweet rice-flour ring bread.',80.00,NULL,'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600',1,1,10,'dessert,sweet,nepali','2026-09-26 06:36:31','2026-09-26 06:36:31'),(160,147,94,'Fresh Lime Soda','Chilled lime soda, sweet or salted.',90.00,NULL,'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=600',1,1,5,'cold,drink','2026-09-26 06:36:31','2026-09-26 06:36:31'),(161,147,94,'Masala Chiya','Spiced Nepali milk tea.',60.00,NULL,'https://images.unsplash.com/photo-1571934811356-5cc061b6821f?w=600',1,1,5,'tea,hot','2026-09-26 06:36:31','2026-09-26 06:36:31'),(162,154,95,'Veg Bytz Sekuwa','Plant-based grilled skewers with house spices.',260.00,NULL,'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=600',1,1,18,'vegan,grill,starter','2026-09-26 06:36:33','2026-09-26 06:36:33'),(163,154,95,'Vegan Spring Rolls','Crispy rolls stuffed with mixed vegetables.',220.00,NULL,'https://images.unsplash.com/photo-1548507200-64a1c2a30a66?w=600',1,1,12,'vegan,fried,starter','2026-09-26 06:36:33','2026-09-26 06:36:33'),(164,154,96,'Buddha Bowl','Mixed grains, greens and roasted vegetables.',300.00,NULL,'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600',1,1,15,'vegan,healthy,bowl','2026-09-26 06:36:33','2026-09-26 06:36:33'),(165,154,96,'Vegan Burger','Plant-based patty with vegan mayo and greens.',320.00,NULL,'https://images.unsplash.com/photo-1520072959219-c595dc870360?w=600',1,1,18,'vegan,burger','2026-09-26 06:36:33','2026-09-26 06:36:33'),(166,154,96,'Tofu Stir Fry','Pan-fried tofu and vegetables in a soy-ginger sauce.',280.00,NULL,'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600',1,1,18,'vegan,tofu,stirfry','2026-09-26 06:36:33','2026-09-26 06:36:33'),(167,154,97,'Vegan Chocolate Cake','Rich cocoa cake made without dairy or eggs.',220.00,NULL,'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=600',1,1,10,'vegan,dessert,sweet','2026-09-26 06:36:33','2026-09-26 06:36:33'),(168,154,98,'Green Detox Juice','Cold-pressed spinach, cucumber and apple juice.',160.00,NULL,'https://images.unsplash.com/photo-1622597467836-f3285f2131b8?w=600',1,1,8,'vegan,juice,cold','2026-09-26 06:36:33','2026-09-26 06:36:33'),(169,162,99,'Iced Latte','Espresso with cold milk over ice.',180.00,NULL,'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=600',1,1,6,'coffee,cold','2026-09-26 06:36:35','2026-09-26 06:36:35'),(170,162,99,'Cappuccino','Espresso with steamed milk foam.',160.00,NULL,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600',1,1,8,'coffee,hot','2026-09-26 06:36:35','2026-09-26 06:36:35'),(171,162,100,'Chicken Wrap','Grilled chicken, veggies and sauce in a soft tortilla.',260.00,NULL,'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=600',0,1,15,'wrap,chicken','2026-09-26 06:36:35','2026-09-26 06:36:35'),(172,162,100,'Stuffed Mushroom','Baked mushrooms stuffed with cheese and herbs.',220.00,NULL,'https://images.unsplash.com/photo-1547181093-4d84c2af9c9c?w=600',1,1,15,'veg,snack','2026-09-26 06:36:35','2026-09-26 06:36:35'),(173,162,100,'Veg Wrap','Grilled vegetables and hummus in a soft tortilla.',220.00,NULL,'https://images.unsplash.com/photo-1553909489-cd47e0907980?w=600',1,1,12,'wrap,veg','2026-09-26 06:36:35','2026-09-26 06:36:35'),(174,162,101,'Chocolate Muffin','Rich chocolate chip muffin.',120.00,NULL,'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=600',1,1,5,'bakery,dessert','2026-09-26 06:36:35','2026-09-26 06:36:35'),(175,169,102,'Strawberry Matcha Latte','Matcha latte layered with strawberry syrup.',220.00,NULL,'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=600',1,1,8,'matcha,cold','2026-09-26 06:36:37','2026-09-26 06:36:37'),(176,169,102,'Red Velvet Boba','Red velvet milk tea with tapioca pearls.',200.00,NULL,'https://images.unsplash.com/photo-1558857563-b371033873b8?w=600',1,1,8,'boba,cold','2026-09-26 06:36:37','2026-09-26 06:36:37'),(177,169,102,'Watermelon Mojito','Fresh watermelon juice with mint and lime.',190.00,NULL,'https://images.unsplash.com/photo-1546171753-97d7676e4602?w=600',1,1,8,'mocktail,cold','2026-09-26 06:36:37','2026-09-26 06:36:37'),(178,169,103,'Healthy Smoothie Bowl','Mixed berries, granola and banana over smoothie base.',260.00,NULL,'https://images.unsplash.com/photo-1490474504059-bf2db5ab2348?w=600',1,1,12,'healthy,bowl','2026-09-26 06:36:37','2026-09-26 06:36:37'),(179,169,103,'Chicken Sliders (3 pcs)','Mini burgers with grilled chicken patties.',280.00,NULL,'https://images.unsplash.com/photo-1550317138-10000687a72b?w=600',0,1,15,'sliders,chicken','2026-09-26 06:36:37','2026-09-26 06:36:37'),(180,169,103,'Club Sandwich','Triple-decker sandwich with chicken, egg and veggies.',260.00,NULL,'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=600',0,1,15,'sandwich,chicken','2026-09-26 06:36:37','2026-09-26 06:36:37'),(181,169,104,'French Toast','Golden pan-fried bread with maple syrup.',220.00,NULL,'https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=600',1,1,12,'breakfast,sweet','2026-09-26 06:36:37','2026-09-26 06:36:37'),(182,175,105,'Dopio Espresso','Double shot of rich espresso.',140.00,NULL,'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=600',1,1,5,'coffee,hot','2026-09-26 06:36:39','2026-09-26 06:36:39'),(183,175,105,'Cappuccino','Espresso with steamed milk foam.',160.00,NULL,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600',1,1,8,'coffee,hot','2026-09-26 06:36:39','2026-09-26 06:36:39'),(184,175,105,'Iced Americano','Chilled espresso over ice.',170.00,NULL,'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=600',1,1,6,'coffee,cold','2026-09-26 06:36:39','2026-09-26 06:36:39'),(185,175,106,'Chocolate Muffin','Rich chocolate chip muffin.',120.00,NULL,'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=600',1,1,5,'bakery,dessert','2026-09-26 06:36:39','2026-09-26 06:36:39'),(186,175,106,'Butter Croissant','Flaky, buttery French croissant.',140.00,NULL,'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600',1,1,5,'bakery,pastry','2026-09-26 06:36:39','2026-09-26 06:36:39'),(187,175,107,'Grilled Cheese Sandwich','Melted cheese between toasted bread.',190.00,NULL,'https://images.unsplash.com/photo-1528736235302-52922df5c122?w=600',1,1,10,'sandwich,cheese','2026-09-26 06:36:39','2026-09-26 06:36:39');
/*!40000 ALTER TABLE `menu_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `order_items`
--

DROP TABLE IF EXISTS `order_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_items` (
  `id` int NOT NULL AUTO_INCREMENT,
  `order_id` int NOT NULL,
  `menu_item_id` int NOT NULL,
  `item_name` varchar(150) NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `quantity` int NOT NULL DEFAULT '1',
  `addons_json` json DEFAULT NULL,
  `item_subtotal` decimal(10,2) NOT NULL,
  `notes` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `order_id` (`order_id`),
  KEY `menu_item_id` (`menu_item_id`),
  CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_items`
--

LOCK TABLES `order_items` WRITE;
/*!40000 ALTER TABLE `order_items` DISABLE KEYS */;
INSERT INTO `order_items` VALUES (1,1,19,'Chicken Chilli',300.00,3,NULL,900.00,NULL),(2,2,99,'Vegan Burger',320.00,3,NULL,960.00,NULL),(3,3,99,'Vegan Burger',320.00,3,NULL,960.00,NULL),(4,4,83,'Chicken Biryani',340.00,1,NULL,340.00,NULL),(5,5,110,'Chocolate Muffin',120.00,2,NULL,240.00,NULL),(6,6,11,'Iced Lemon Tea',80.00,2,NULL,160.00,NULL),(7,7,107,'Chicken Sliders (3 pcs)',280.00,3,NULL,840.00,NULL);
/*!40000 ALTER TABLE `order_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `order_status_log`
--

DROP TABLE IF EXISTS `order_status_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_status_log` (
  `id` int NOT NULL AUTO_INCREMENT,
  `order_id` int NOT NULL,
  `status` varchar(30) NOT NULL,
  `note` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `order_id` (`order_id`),
  CONSTRAINT `order_status_log_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_status_log`
--

LOCK TABLES `order_status_log` WRITE;
/*!40000 ALTER TABLE `order_status_log` DISABLE KEYS */;
INSERT INTO `order_status_log` VALUES (1,1,'placed','Order placed — waiting for kitchen','2026-09-26 06:22:13'),(2,2,'placed','Order placed — waiting for kitchen','2026-09-26 07:01:12'),(3,2,'accepted','Accepted by kitchen','2026-09-26 07:03:33'),(4,2,'accepted','Rider #1 assigned','2026-09-26 07:03:35'),(5,1,'accepted','Accepted by kitchen','2026-09-26 07:03:49'),(6,2,'on_the_way','Rider picked up the order','2026-09-26 07:36:29'),(7,2,'delivered','Order delivered to customer','2026-09-26 07:36:33'),(8,3,'placed','Order placed — waiting for kitchen','2026-09-26 07:38:06'),(9,4,'placed','Order placed — waiting for kitchen','2026-09-26 09:01:40'),(10,4,'accepted','Accepted by kitchen','2026-09-26 09:04:09'),(11,4,'accepted','Rider #1 assigned','2026-09-26 09:04:14'),(12,3,'accepted','Accepted by kitchen','2026-09-26 09:04:34'),(13,4,'on_the_way','Rider picked up the order','2026-09-26 09:06:31'),(14,4,'delivered','Order delivered to customer','2026-09-27 02:12:43'),(15,5,'placed','Order placed — waiting for kitchen','2026-09-27 02:14:48'),(16,6,'placed','Order placed — waiting for kitchen','2026-09-27 02:16:34'),(17,6,'accepted','Accepted by kitchen','2026-09-27 02:18:17'),(18,7,'placed','Order placed — waiting for kitchen','2026-09-28 13:46:09');
/*!40000 ALTER TABLE `order_status_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `order_number` varchar(20) NOT NULL,
  `business_id` int NOT NULL,
  `user_id` int NOT NULL,
  `order_type` enum('delivery','pickup','dine_in') NOT NULL DEFAULT 'delivery',
  `status` enum('placed','accepted','cooking','on_the_way','delivered','cancelled') NOT NULL DEFAULT 'placed',
  `subtotal` decimal(10,2) NOT NULL DEFAULT '0.00',
  `delivery_fee` decimal(10,2) NOT NULL DEFAULT '0.00',
  `tax_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `discount_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `total_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `payment_method` enum('esewa','khalti','cod') NOT NULL DEFAULT 'cod',
  `payment_status` enum('unpaid','pending','paid','failed','refunded') NOT NULL DEFAULT 'unpaid',
  `delivery_address_id` int DEFAULT NULL,
  `delivery_latitude` decimal(10,7) DEFAULT NULL,
  `delivery_longitude` decimal(10,7) DEFAULT NULL,
  `delivery_instructions` varchar(255) DEFAULT NULL,
  `table_id` int DEFAULT NULL,
  `rider_id` int DEFAULT NULL,
  `special_instructions` varchar(255) DEFAULT NULL,
  `estimated_delivery_time` datetime DEFAULT NULL,
  `placed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `accepted_at` timestamp NULL DEFAULT NULL,
  `ready_at` timestamp NULL DEFAULT NULL,
  `picked_up_at` timestamp NULL DEFAULT NULL,
  `delivered_at` timestamp NULL DEFAULT NULL,
  `cancelled_reason` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid` (`uuid`),
  UNIQUE KEY `order_number` (`order_number`),
  KEY `delivery_address_id` (`delivery_address_id`),
  KEY `idx_orders_business_status` (`business_id`,`status`),
  KEY `idx_orders_user` (`user_id`),
  KEY `idx_orders_rider` (`rider_id`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`),
  CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `orders_ibfk_3` FOREIGN KEY (`delivery_address_id`) REFERENCES `user_addresses` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `orders`
--

LOCK TABLES `orders` WRITE;
/*!40000 ALTER TABLE `orders` DISABLE KEYS */;
INSERT INTO `orders` VALUES (1,'3308c5ac-55c0-4f45-8265-75c6c12bf045','ORD037329993612',7,12,'delivery','accepted',900.00,60.00,117.00,0.00,1077.00,'cod','unpaid',4,27.6275508,83.4758808,NULL,NULL,NULL,NULL,NULL,'2026-09-26 06:22:13','2026-09-26 07:03:48',NULL,NULL,NULL,NULL,'2026-09-26 06:22:13','2026-09-26 07:03:48'),(2,'e3e5f82a-1d15-4364-940d-60b3d6139a6d','ORD060722128408',23,12,'delivery','delivered',960.00,250.00,124.80,0.00,1334.80,'esewa','unpaid',4,27.6275508,83.4758808,NULL,NULL,1,NULL,NULL,'2026-09-26 07:01:12','2026-09-26 07:03:32',NULL,'2026-09-26 07:36:29','2026-09-26 07:36:33',NULL,'2026-09-26 07:01:12','2026-09-26 07:36:33'),(3,'d75cca34-8157-4650-972d-3b68fe59128b','ORD082866128288',23,12,'delivery','accepted',960.00,150.00,124.80,0.00,1234.80,'cod','unpaid',5,27.6483047,83.4677765,NULL,NULL,NULL,NULL,NULL,'2026-09-26 07:38:06','2026-09-26 09:04:34',NULL,NULL,NULL,NULL,'2026-09-26 07:38:06','2026-09-26 09:04:34'),(4,'db668181-981b-4956-9a21-555cd6d3fc53','ORD132999485326',19,12,'delivery','delivered',340.00,50.00,44.20,0.00,434.20,'cod','paid',5,27.6483047,83.4677765,NULL,NULL,1,NULL,NULL,'2026-09-26 09:01:40','2026-09-26 09:04:08',NULL,'2026-09-26 09:06:31','2026-09-27 02:12:43',NULL,'2026-09-26 09:01:40','2026-09-27 02:12:43'),(5,'279f3c0f-2d90-47e1-bcd6-8dee1f3dc6fb','ORD752876912828',26,12,'delivery','placed',240.00,150.00,31.20,0.00,421.20,'esewa','paid',5,27.6483047,83.4677765,NULL,NULL,NULL,'ring the bell',NULL,'2026-09-27 02:14:47',NULL,NULL,NULL,NULL,NULL,'2026-09-27 02:14:47','2026-09-27 02:15:17'),(6,'ed0bbbdb-1c66-4b81-9219-6f517b396081','ORD753941451295',2,12,'delivery','accepted',160.00,350.00,20.80,0.00,530.80,'khalti','unpaid',5,27.6483047,83.4677765,NULL,NULL,NULL,NULL,NULL,'2026-09-27 02:16:34','2026-09-27 02:18:16',NULL,NULL,NULL,NULL,'2026-09-27 02:16:34','2026-09-27 02:18:16'),(7,'03b5df1c-9039-4cdc-bbcd-7ac295880679','ORD031693089895',25,12,'delivery','placed',840.00,150.00,109.20,0.00,1099.20,'cod','unpaid',5,27.6483047,83.4677765,NULL,NULL,NULL,'imahe',NULL,'2026-09-28 13:46:09',NULL,NULL,NULL,NULL,NULL,'2026-09-28 13:46:09','2026-09-28 13:46:09');
/*!40000 ALTER TABLE `orders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payments`
--

DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `reference_type` enum('order','room_booking') NOT NULL,
  `reference_id` int NOT NULL,
  `user_id` int NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `method` enum('esewa','khalti','cod') NOT NULL,
  `gateway_txn_id` varchar(100) DEFAULT NULL,
  `gateway_ref_id` varchar(100) DEFAULT NULL,
  `status` enum('initiated','pending','success','failed','refunded') NOT NULL DEFAULT 'initiated',
  `raw_response` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid` (`uuid`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payments`
--

LOCK TABLES `payments` WRITE;
/*!40000 ALTER TABLE `payments` DISABLE KEYS */;
INSERT INTO `payments` VALUES (1,'0d32a2c2-7166-4db6-bca7-b48ed432356a','order',2,12,1334.80,'esewa',NULL,NULL,'initiated',NULL,'2026-09-26 07:01:13','2026-09-26 07:01:13'),(2,'d48a19de-e0a5-4f50-a8ce-c8e1524929da','order',5,12,421.20,'esewa','000H7E1','d48a19de-e0a5-4f50-a8ce-c8e1524929da','success','{\"status\": \"COMPLETE\", \"signature\": \"eTcfKiExI5mDsbZAMv/7idahUZwImXlG4IjQMCWNGPo=\", \"product_code\": \"EPAYTEST\", \"total_amount\": \"421.2\", \"transaction_code\": \"000H7E1\", \"transaction_uuid\": \"d48a19de-e0a5-4f50-a8ce-c8e1524929da\", \"signed_field_names\": \"transaction_code,status,total_amount,transaction_uuid,product_code,signed_field_names\"}','2026-09-27 02:14:48','2026-09-27 02:15:17'),(3,'9264a08b-4cb3-4652-8c83-cb481674d1bd','order',6,12,530.80,'khalti',NULL,NULL,'initiated',NULL,'2026-09-27 02:16:35','2026-09-27 02:16:35');
/*!40000 ALTER TABLE `payments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `restaurant_tables`
--

DROP TABLE IF EXISTS `restaurant_tables`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `restaurant_tables` (
  `id` int NOT NULL AUTO_INCREMENT,
  `business_id` int NOT NULL,
  `table_number` varchar(20) NOT NULL,
  `capacity` int NOT NULL DEFAULT '2',
  `location_note` varchar(100) DEFAULT NULL,
  `status` enum('available','reserved','occupied','inactive') DEFAULT 'available',
  PRIMARY KEY (`id`),
  KEY `business_id` (`business_id`),
  CONSTRAINT `restaurant_tables_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `restaurant_tables`
--

LOCK TABLES `restaurant_tables` WRITE;
/*!40000 ALTER TABLE `restaurant_tables` DISABLE KEYS */;
/*!40000 ALTER TABLE `restaurant_tables` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reviews`
--

DROP TABLE IF EXISTS `reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reviews` (
  `id` int NOT NULL AUTO_INCREMENT,
  `business_id` int NOT NULL,
  `user_id` int NOT NULL,
  `order_id` int DEFAULT NULL,
  `rating` tinyint NOT NULL,
  `comment` varchar(500) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `business_id` (`business_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reviews`
--

LOCK TABLES `reviews` WRITE;
/*!40000 ALTER TABLE `reviews` DISABLE KEYS */;
/*!40000 ALTER TABLE `reviews` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rider_location_pings`
--

DROP TABLE IF EXISTS `rider_location_pings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rider_location_pings` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `rider_id` int NOT NULL,
  `order_id` int DEFAULT NULL,
  `latitude` decimal(10,7) NOT NULL,
  `longitude` decimal(10,7) NOT NULL,
  `recorded_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `rider_id` (`rider_id`),
  KEY `order_id` (`order_id`),
  CONSTRAINT `rider_location_pings_ibfk_1` FOREIGN KEY (`rider_id`) REFERENCES `riders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `rider_location_pings_ibfk_2` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rider_location_pings`
--

LOCK TABLES `rider_location_pings` WRITE;
/*!40000 ALTER TABLE `rider_location_pings` DISABLE KEYS */;
INSERT INTO `rider_location_pings` VALUES (1,1,NULL,27.6272352,83.4758228,'2026-09-26 07:03:15'),(2,1,NULL,27.6272374,83.4758200,'2026-09-26 07:03:34'),(3,1,2,27.6272315,83.4758234,'2026-09-26 07:03:49'),(4,1,2,27.6272349,83.4758218,'2026-09-26 07:04:04'),(5,1,2,27.6272327,83.4758202,'2026-09-26 07:04:19'),(6,1,2,27.6272318,83.4758204,'2026-09-26 07:04:34'),(7,1,2,27.6272322,83.4758200,'2026-09-26 07:04:49'),(8,1,2,27.6272347,83.4758150,'2026-09-26 07:05:04'),(9,1,2,27.6272328,83.4758183,'2026-09-26 07:05:19'),(10,1,2,27.6272340,83.4758218,'2026-09-26 07:05:34'),(11,1,2,27.6272399,83.4758193,'2026-09-26 07:05:49'),(12,1,2,27.6272277,83.4758247,'2026-09-26 07:06:41'),(13,1,2,27.6272317,83.4758225,'2026-09-26 07:06:56'),(14,1,2,27.6272258,83.4758265,'2026-09-26 07:07:11'),(15,1,2,27.6272329,83.4758194,'2026-09-26 07:07:26'),(16,1,2,27.6272377,83.4758087,'2026-09-26 07:07:41'),(17,1,2,27.6272337,83.4758211,'2026-09-26 07:07:56'),(18,1,2,27.6272284,83.4758200,'2026-09-26 07:08:11'),(19,1,2,27.6272314,83.4758197,'2026-09-26 07:08:26'),(20,1,2,27.6272284,83.4758229,'2026-09-26 07:36:25'),(21,1,NULL,27.6272309,83.4758220,'2026-09-26 09:03:47'),(22,1,4,27.6272309,83.4758220,'2026-09-26 09:04:21'),(23,1,4,27.6272329,83.4758252,'2026-09-26 09:04:50'),(24,1,4,27.6266277,83.4754689,'2026-09-26 09:05:03'),(25,1,4,27.6266981,83.4754013,'2026-09-26 09:05:18'),(26,1,4,27.6269700,83.4755697,'2026-09-26 09:06:19'),(27,1,4,27.6269867,83.4755596,'2026-09-26 09:06:34'),(28,1,4,27.6269823,83.4755551,'2026-09-26 09:06:49'),(29,1,4,27.6271231,83.4757040,'2026-09-26 09:07:14'),(30,1,4,27.6271231,83.4757040,'2026-09-26 09:07:18'),(31,1,NULL,27.6272355,83.4758197,'2026-09-26 10:18:59'),(32,1,4,27.6272417,83.4758130,'2026-09-26 10:19:18'),(33,1,4,27.6272325,83.4757880,'2026-09-26 10:19:32'),(34,1,4,27.6272357,83.4758210,'2026-09-26 10:19:56'),(35,1,4,27.6272357,83.4758210,'2026-09-26 10:20:00'),(36,1,4,27.6272295,83.4757943,'2026-09-26 10:20:17'),(37,1,4,27.6272307,83.4757946,'2026-09-26 10:20:31'),(38,1,4,27.6272415,83.4758174,'2026-09-26 10:20:56'),(39,1,4,27.6272415,83.4758174,'2026-09-26 10:21:00'),(40,1,NULL,27.6272282,83.4758244,'2026-09-26 14:17:34'),(41,1,4,27.6272971,83.4759047,'2026-09-26 14:20:31'),(42,1,4,27.6272469,83.4758169,'2026-09-26 14:20:49'),(43,1,4,27.6272303,83.4758228,'2026-09-26 14:21:04'),(44,1,4,27.6272335,83.4758163,'2026-09-26 14:21:19'),(45,1,4,27.6272294,83.4758191,'2026-09-26 14:21:34'),(46,1,NULL,27.6272695,83.4758197,'2026-09-27 02:12:19'),(47,1,4,27.6272767,83.4758240,'2026-09-27 02:12:38');
/*!40000 ALTER TABLE `rider_location_pings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `riders`
--

DROP TABLE IF EXISTS `riders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `riders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `vehicle_type` enum('bike','scooter','bicycle','car') DEFAULT 'bike',
  `vehicle_number` varchar(30) DEFAULT NULL,
  `license_number` varchar(50) DEFAULT NULL,
  `status` enum('offline','available','busy') NOT NULL DEFAULT 'offline',
  `current_latitude` decimal(10,7) DEFAULT NULL,
  `current_longitude` decimal(10,7) DEFAULT NULL,
  `rating` decimal(3,2) DEFAULT '5.00',
  `total_deliveries` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  KEY `idx_riders_status` (`status`),
  CONSTRAINT `riders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `riders`
--

LOCK TABLES `riders` WRITE;
/*!40000 ALTER TABLE `riders` DISABLE KEYS */;
INSERT INTO `riders` VALUES (1,38,'bike','112233',NULL,'offline',27.6272767,83.4758240,5.00,2,'2026-09-26 07:02:34'),(2,39,'bike','112233',NULL,'offline',NULL,NULL,5.00,0,'2026-09-26 07:06:11');
/*!40000 ALTER TABLE `riders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `room_bookings`
--

DROP TABLE IF EXISTS `room_bookings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `room_bookings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `business_id` int NOT NULL,
  `room_id` int NOT NULL,
  `user_id` int NOT NULL,
  `guest_name` varchar(150) NOT NULL,
  `guest_phone` varchar(20) NOT NULL,
  `check_in` date NOT NULL,
  `check_out` date NOT NULL,
  `num_guests` int DEFAULT '1',
  `nights` int NOT NULL,
  `price_per_night` decimal(10,2) NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `payment_method` enum('esewa','khalti','cod') NOT NULL DEFAULT 'cod',
  `payment_status` enum('unpaid','pending','paid','failed','refunded') NOT NULL DEFAULT 'unpaid',
  `status` enum('pending','confirmed','checked_in','checked_out','cancelled') DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid` (`uuid`),
  KEY `business_id` (`business_id`),
  KEY `user_id` (`user_id`),
  KEY `idx_room_bookings_room_dates` (`room_id`,`check_in`,`check_out`),
  CONSTRAINT `room_bookings_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`),
  CONSTRAINT `room_bookings_ibfk_2` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`),
  CONSTRAINT `room_bookings_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `room_bookings`
--

LOCK TABLES `room_bookings` WRITE;
/*!40000 ALTER TABLE `room_bookings` DISABLE KEYS */;
/*!40000 ALTER TABLE `room_bookings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rooms`
--

DROP TABLE IF EXISTS `rooms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rooms` (
  `id` int NOT NULL AUTO_INCREMENT,
  `business_id` int NOT NULL,
  `room_number` varchar(20) NOT NULL,
  `room_type` varchar(50) NOT NULL DEFAULT 'Standard',
  `description` text,
  `price_per_night` decimal(10,2) NOT NULL,
  `capacity` int DEFAULT '2',
  `image_url` varchar(255) DEFAULT NULL,
  `amenities` varchar(255) DEFAULT NULL,
  `status` enum('available','maintenance','inactive') DEFAULT 'available',
  PRIMARY KEY (`id`),
  KEY `business_id` (`business_id`),
  CONSTRAINT `rooms_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rooms`
--

LOCK TABLES `rooms` WRITE;
/*!40000 ALTER TABLE `rooms` DISABLE KEYS */;
INSERT INTO `rooms` VALUES (1,3,'101','Standard','Cozy room with a queen bed and city view.',2200.00,2,'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600','WiFi,TV,AC,Hot water','available'),(2,3,'102','Deluxe','Spacious room with river view and mini fridge.',3200.00,2,'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=600','WiFi,TV,AC,Mini-fridge,River view','available'),(3,3,'201','Suite','Suite with a separate living area and balcony.',5500.00,4,'https://images.unsplash.com/photo-1591088398332-8a7791972843?w=600','WiFi,TV,AC,Balcony,Bathtub','available'),(4,5,'G1','Standard','Simple room with a double bed, shared bathroom.',1200.00,2,'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600','WiFi,Fan,Shared bath','available'),(5,5,'G2','Family','Larger room with two beds, attached bathroom.',1800.00,4,'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600','WiFi,Fan,Attached bath','available'),(6,9,'101','Standard','Comfortable room with garden view.',2500.00,2,'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600','WiFi,TV,AC,Hot water','available'),(7,9,'102','Deluxe Lake View','Room with a private balcony facing Phewa Lake.',4200.00,2,'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=600','WiFi,TV,AC,Balcony,Lake view','available'),(8,9,'201','Family Suite','Two-room suite for families, sleeps 4.',6500.00,4,'https://images.unsplash.com/photo-1591088398332-8a7791972843?w=600','WiFi,TV,AC,Bathtub,Kitchenette','available'),(9,10,'G1','Standard','Simple room with a double bed, shared bathroom.',1000.00,2,'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600','WiFi,Fan,Shared bath','available'),(10,10,'G2','Single','Compact room with a single bed.',700.00,1,'https://images.unsplash.com/photo-1505692794403-34d4982f88aa?w=600','WiFi,Fan','available'),(11,10,'G3','Family','Larger room with two beds, attached bathroom.',1600.00,4,'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600','WiFi,Fan,Attached bath','available'),(12,55,'101','Standard','Comfortable room with garden view.',2500.00,2,'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600','WiFi,TV,AC,Hot water','available'),(13,55,'102','Deluxe Lake View','Room with a private balcony facing Phewa Lake.',4200.00,2,'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=600','WiFi,TV,AC,Balcony,Lake view','available'),(14,55,'201','Family Suite','Two-room suite for families, sleeps 4.',6500.00,4,'https://images.unsplash.com/photo-1591088398332-8a7791972843?w=600','WiFi,TV,AC,Bathtub,Kitchenette','available'),(15,12,'G1','Standard','Simple room with a double bed, shared bathroom.',1000.00,2,'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600','WiFi,Fan,Shared bath','available'),(16,12,'G2','Single','Compact room with a single bed.',700.00,1,'https://images.unsplash.com/photo-1505692794403-34d4982f88aa?w=600','WiFi,Fan','available'),(17,12,'G3','Family','Larger room with two beds, attached bathroom.',1600.00,4,'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600','WiFi,Fan,Attached bath','available');
/*!40000 ALTER TABLE `rooms` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `table_bookings`
--

DROP TABLE IF EXISTS `table_bookings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `table_bookings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `business_id` int NOT NULL,
  `table_id` int DEFAULT NULL,
  `user_id` int NOT NULL,
  `guest_name` varchar(150) NOT NULL,
  `guest_phone` varchar(20) NOT NULL,
  `party_size` int NOT NULL DEFAULT '2',
  `booking_date` date NOT NULL,
  `booking_time` time NOT NULL,
  `status` enum('pending','confirmed','seated','completed','cancelled','no_show') DEFAULT 'pending',
  `special_request` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid` (`uuid`),
  KEY `table_id` (`table_id`),
  KEY `user_id` (`user_id`),
  KEY `idx_table_bookings_biz_date` (`business_id`,`booking_date`),
  CONSTRAINT `table_bookings_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`),
  CONSTRAINT `table_bookings_ibfk_2` FOREIGN KEY (`table_id`) REFERENCES `restaurant_tables` (`id`) ON DELETE SET NULL,
  CONSTRAINT `table_bookings_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `table_bookings`
--

LOCK TABLES `table_bookings` WRITE;
/*!40000 ALTER TABLE `table_bookings` DISABLE KEYS */;
/*!40000 ALTER TABLE `table_bookings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_addresses`
--

DROP TABLE IF EXISTS `user_addresses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_addresses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `label` varchar(50) DEFAULT 'Home',
  `address_line` varchar(255) NOT NULL,
  `city` varchar(100) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `is_default` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `user_addresses_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_addresses`
--

LOCK TABLES `user_addresses` WRITE;
/*!40000 ALTER TABLE `user_addresses` DISABLE KEYS */;
INSERT INTO `user_addresses` VALUES (4,12,'Home','Kedarnath Path, Tilottama-05, Manigram, Tilottama, Rupandehi, Lumbini Province, 32903, Nepal','Manigram',27.6275508,83.4758808,0,'2026-09-26 06:22:08'),(5,12,'Home','Drivertole','Butwal',27.6483047,83.4677765,1,'2026-09-26 07:38:02');
/*!40000 ALTER TABLE `user_addresses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `email` varchar(150) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('customer','business_owner','staff','rider','super_admin') NOT NULL DEFAULT 'customer',
  `avatar_url` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `is_verified` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid` (`uuid`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `phone` (`phone`)
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'6f09b5ab-b96e-11f1-8789-9696ace701e2','Himalayan Spice Owner','owner.himalayanspice@example.com','9800000001','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:52:18','2026-09-26 05:52:18'),(2,'c5410c3a-b96e-11f1-8789-9696ace701e2','Spice Junction Owner','owner.spicejunction@example.com','9800000002','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:54:43','2026-09-26 05:54:43'),(3,'c6b614dc-b96e-11f1-8789-9696ace701e2','Ganga Vista Owner','owner.gangavista@example.com','9800000003','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:54:45','2026-09-26 05:54:45'),(4,'c7594079-b96e-11f1-8789-9696ace701e2','Bean & Brew Owner','owner.beanbrew@example.com','9800000004','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:54:46','2026-09-26 05:54:46'),(5,'c893de15-b96e-11f1-8789-9696ace701e2','Mountain View Owner','owner.mountainview@example.com','9800000005','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:54:48','2026-09-26 05:54:48'),(6,'c97e8358-b96e-11f1-8789-9696ace701e2','Everest Bites Owner','owner.everestbites@example.com','9800000006','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:54:50','2026-09-26 05:54:50'),(7,'3462513e-b96f-11f1-8789-9696ace701e2','Butwal Bazaar Owner','owner.butwalbazaar@example.com','9800000007','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:57:49','2026-09-26 05:57:49'),(8,'36812f57-b96f-11f1-8789-9696ace701e2','Thamel Coffee Owner','owner.thamelcoffee@example.com','9800000008','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:57:53','2026-09-26 05:57:53'),(9,'38750b37-b96f-11f1-8789-9696ace701e2','Lakeside Heritage Owner','owner.lakesideheritage@example.com','9800000009','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:57:56','2026-09-26 05:57:56'),(10,'392d9b8f-b96f-11f1-8789-9696ace701e2','Rapti Guest House Owner','owner.raptiguesthouse@example.com','9800000010','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:57:57','2026-09-26 05:57:57'),(11,'39ea5d2a-b96f-11f1-8789-9696ace701e2','Koshi Delights Owner','owner.koshidelights@example.com','9800000011','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:57:58','2026-09-26 05:57:58'),(12,'c2831ff6-52f1-4462-84d0-3758b91b8bbd','Image User','image@gmail.com','9879645263','$2a$10$VeKh6yT2z2i5uTwoevQpOuGoPnr/lY42V2dm9xYBfmSGnTEA23LTu','customer',NULL,1,0,'2026-09-26 05:59:57','2026-09-26 05:59:57'),(18,'ceb56750-b973-11f1-8789-9696ace701e2','El Dorado Owner','owner.eldorado@example.com','9800000012','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:30:46','2026-09-26 06:30:46'),(19,'cfde1b6c-b973-11f1-8789-9696ace701e2','Soulmate Restaurant Owner','owner.soulmate@example.com','9800000013','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:30:48','2026-09-26 06:30:48'),(20,'d105b4cb-b973-11f1-8789-9696ace701e2','Daddys Kitchen Owner','owner.daddyskitchen@example.com','9800000014','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:30:50','2026-09-26 06:30:50'),(21,'d24eaa4f-b973-11f1-8789-9696ace701e2','Grassland Nepal Owner','owner.grassland@example.com','9800000015','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:30:52','2026-09-26 06:30:52'),(22,'d3763ff1-b973-11f1-8789-9696ace701e2','Hide Out Restro Owner','owner.hideout@example.com','9800000016','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:30:54','2026-09-26 06:30:54'),(23,'d49daa1e-b973-11f1-8789-9696ace701e2','Butwal Veg Vegan Owner','owner.butwalveg@example.com','9800000017','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:30:56','2026-09-26 06:30:56'),(24,'d5c3008b-b973-11f1-8789-9696ace701e2','Good DO Owner','owner.gooddo@example.com','9800000018','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:30:58','2026-09-26 06:30:58'),(25,'d6e9154b-b973-11f1-8789-9696ace701e2','Cloud 9 Cafe Owner','owner.cloud9@example.com','9800000019','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:31:00','2026-09-26 06:31:00'),(26,'d7f1ee20-b973-11f1-8789-9696ace701e2','Papaya Butwal Owner','owner.papaya@example.com','9800000020','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:31:02','2026-09-26 06:31:02'),(27,'d8faa869-b973-11f1-8789-9696ace701e2','Caffeine Cup Owner','owner.caffeinecup@example.com','9800000021','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:31:03','2026-09-26 06:31:03'),(38,'e430e370-c2a6-4c3c-ab3f-f3668c28eb1a','Test Ryder','ryder@gmail.com','98707557589','$2a$10$jyCqoPNxQ0QALiHj4fK6CuSuVzDEHXQiyV7xVk76Bp5tyowd7KZ6a','rider',NULL,1,0,'2026-09-26 07:02:34','2026-09-26 07:02:34'),(39,'67903c0c-5047-428a-a28f-5da1f262ca63','Ram Ryder','ryderram@gmail.com','997769689698','$2a$10$oCenBkmHm8c1yVIkp6WMVuS7etp5ZEvFcKYLTYuGsdOWl7HuGRp26','rider',NULL,1,0,'2026-09-26 07:06:11','2026-09-26 07:06:11'),(45,'6c6d870e-b97b-11f1-8789-9696ace701e2','Super Admin','admin@gmail.com','9800000000','$2b$10$fxDEsjMqryl8jktSAl2Qi.NvL20U1jB2XMFDXla50p1Q/3U8LruYy','super_admin',NULL,1,1,'2026-09-26 07:25:17','2026-09-26 07:25:17'),(46,'3d0a14c9-be87-40dc-bcfe-b70102f9bbcf','Basil Bashyal','lilhappyhelper@gmail.com','9826425806','$2a$10$nSsOA9uyVyL7k2ewzKhVlOqUhut4Hi0Qi8TzDWDk/JVxtNawEQOxm','customer',NULL,1,0,'2026-09-28 13:35:48','2026-09-28 13:35:48');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-28 20:04:56
-- MySQL dump 10.13  Distrib 8.0.41, for Win64 (x86_64)
--
-- Host: mysql-314cb117-hpimage10-6228.g.aivencloud.com    Database: hotel_management_app
-- ------------------------------------------------------
-- Server version	8.4.8

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ 'd478eb5d-b34b-11f1-a45a-9696ace701e2:1-1630,
faf6b5a4-b27e-11f1-9be3-de34fd1b8d4d:1-250';

--
-- Table structure for table `business_staff`
--

DROP TABLE IF EXISTS `business_staff`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `business_staff` (
  `id` int NOT NULL AUTO_INCREMENT,
  `business_id` int NOT NULL,
  `user_id` int NOT NULL,
  `role` enum('manager','kitchen','front_desk','waiter') NOT NULL DEFAULT 'manager',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_biz_user` (`business_id`,`user_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `business_staff_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `business_staff_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `business_staff`
--

LOCK TABLES `business_staff` WRITE;
/*!40000 ALTER TABLE `business_staff` DISABLE KEYS */;
/*!40000 ALTER TABLE `business_staff` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `businesses`
--

DROP TABLE IF EXISTS `businesses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `businesses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `owner_id` int NOT NULL,
  `name` varchar(150) NOT NULL,
  `slug` varchar(170) NOT NULL,
  `type` enum('hotel','restaurant','cafe','guest_house') NOT NULL,
  `description` text,
  `logo_url` varchar(255) DEFAULT NULL,
  `cover_image_url` varchar(255) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `has_food_ordering` tinyint(1) DEFAULT '1',
  `has_table_booking` tinyint(1) DEFAULT '1',
  `has_room_booking` tinyint(1) DEFAULT '0',
  `delivery_radius_km` decimal(5,2) DEFAULT '5.00',
  `base_delivery_fee` decimal(10,2) DEFAULT '50.00',
  `min_order_amount` decimal(10,2) DEFAULT '0.00',
  `avg_prep_time_mins` int DEFAULT '20',
  `commission_percent` decimal(5,2) DEFAULT '15.00',
  `status` enum('pending','approved','suspended','rejected') NOT NULL DEFAULT 'pending',
  `is_open` tinyint(1) DEFAULT '1',
  `opens_at` time DEFAULT '08:00:00',
  `closes_at` time DEFAULT '22:00:00',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid` (`uuid`),
  UNIQUE KEY `slug` (`slug`),
  KEY `owner_id` (`owner_id`),
  KEY `idx_businesses_type_status` (`type`,`status`),
  CONSTRAINT `businesses_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `businesses`
--

LOCK TABLES `businesses` WRITE;
/*!40000 ALTER TABLE `businesses` DISABLE KEYS */;
INSERT INTO `businesses` VALUES (1,'6f4b108e-b96e-11f1-8789-9696ace701e2',1,'Himalayan Spice Kitchen','himalayan-spice-kitchen','restaurant','Authentic Nepali & Indian cuisine - momos, thakali sets, curries and tandoori grills.','https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400','https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1200','9800000001','contact.himalayanspice@example.com','New Road','Dhangadhi',28.6944000,80.5992000,1,1,0,8.00,50.00,200.00,25,15.00,'approved',1,'08:00:00','22:00:00','2026-09-26 05:52:18','2026-09-26 05:52:18'),(2,'c58d2f1f-b96e-11f1-8789-9696ace701e2',2,'Spice Junction','spice-junction','restaurant','Indo-Chinese favorites - chowmein, chilli chicken, fried rice and more.','https://images.unsplash.com/photo-1585032226651-759b368d7246?w=400','https://images.unsplash.com/photo-1585032226651-759b368d7246?w=1200','9800000002','contact.spicejunction@example.com','Attariya Road','Dhangadhi',28.6981000,80.6012000,1,1,0,7.00,50.00,150.00,25,15.00,'approved',1,'10:00:00','21:30:00','2026-09-26 05:54:43','2026-09-26 06:35:53'),(3,'c6f70f91-b96e-11f1-8789-9696ace701e2',3,'Ganga Vista Hotel','ganga-vista-hotel','hotel','Comfortable rooms with river views, in-house restaurant and room service.','https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400','https://images.unsplash.com/photo-1566073771259-6a8506099945?w=1200','9800000003','contact.gangavista@example.com','Hasanpur Road','Dhangadhi',28.7015000,80.5940000,1,0,1,0.00,0.00,0.00,35,15.00,'approved',1,'00:00:00','23:59:00','2026-09-26 05:54:46','2026-09-26 06:35:53'),(4,'c7a0709b-b96e-11f1-8789-9696ace701e2',4,'Bean & Brew Cafe','bean-and-brew-cafe','cafe','Specialty coffee, fresh pastries and a cozy spot to work or hang out.','https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400','https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1200','9800000004','contact.beanbrew@example.com','Tikapur Chowk','Dhangadhi',28.6905000,80.6050000,1,1,0,5.00,40.00,100.00,25,15.00,'approved',1,'07:00:00','20:00:00','2026-09-26 05:54:47','2026-09-26 06:35:54'),(5,'c8e8d7ee-b96e-11f1-8789-9696ace701e2',5,'Mountain View Guest House','mountain-view-guest-house','guest_house','Budget-friendly guest house with home-style meals on request.','https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400','https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=1200','9800000005','contact.mountainview@example.com','Godavari Marg','Dhangadhi',28.7050000,80.6100000,0,0,1,0.00,0.00,0.00,25,15.00,'approved',1,'00:00:00','23:59:00','2026-09-26 05:54:49','2026-09-26 06:35:54'),(6,'c9d84767-b96e-11f1-8789-9696ace701e2',6,'Everest Bites','everest-bites','restaurant','Newari specialties, momos and traditional thali sets.','https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400','https://images.unsplash.com/photo-1601050690597-df0568f70950?w=1200','9800000006','contact.everestbites@example.com','Lamki Road','Dhangadhi',28.6870000,80.5975000,1,1,0,8.00,50.00,200.00,25,15.00,'approved',1,'09:00:00','22:00:00','2026-09-26 05:54:50','2026-09-26 06:35:55'),(7,'34cb9550-b96f-11f1-8789-9696ace701e2',7,'Butwal Bazaar Kitchen','butwal-bazaar-kitchen','restaurant','Local favorite for Nepali thali, Indian curries and tandoori grills.','https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400','https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1200','9800000007','contact.butwalbazaar@example.com','Traffic Chowk','Butwal',27.7000000,83.4486000,1,1,0,8.00,60.00,200.00,25,15.00,'approved',1,'09:00:00','22:00:00','2026-09-26 05:57:50','2026-09-26 06:35:55'),(8,'36f7aa9a-b96f-11f1-8789-9696ace701e2',8,'Thamel Coffee House','thamel-coffee-house','cafe','Specialty coffee, all-day breakfast, pastries and light bites.','https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400','https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1200','9800000008','contact.thamelcoffee@example.com','Thamel Marg','Kathmandu',27.7172000,85.3240000,1,1,0,6.00,60.00,150.00,25,15.00,'approved',1,'07:00:00','21:00:00','2026-09-26 05:57:53','2026-09-26 06:35:55'),(9,'38bdb4f4-b96f-11f1-8789-9696ace701e2',9,'Lakeside Heritage Hotel','lakeside-heritage-hotel','hotel','Lakeside views, in-house restaurant, and easy access to boating & paragliding.','https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400','https://images.unsplash.com/photo-1566073771259-6a8506099945?w=1200','9800000009','contact.lakesideheritage@example.com','Lakeside Road','Pokhara',28.2096000,83.9856000,1,0,1,0.00,0.00,0.00,25,15.00,'approved',1,'00:00:00','23:59:00','2026-09-26 05:57:56','2026-09-26 06:35:56'),(10,'39749f17-b96f-11f1-8789-9696ace701e2',10,'Rapti Guest House','rapti-guest-house','guest_house','Simple, clean rooms near the bus park, with home-cooked meals on request.','https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400','https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=1200','9800000010','contact.raptiguesthouse@example.com','Surkhet Road','Nepalgunj',28.1000000,81.6167000,0,0,1,0.00,0.00,0.00,25,15.00,'approved',1,'00:00:00','23:59:00','2026-09-26 05:57:58','2026-09-26 06:35:56'),(11,'3a31684d-b96f-11f1-8789-9696ace701e2',11,'Koshi Delights','koshi-delights','restaurant','Family restaurant serving Nepali, Indian and Chinese cuisine.','https://images.unsplash.com/photo-1543353071-873f17a7a088?w=400','https://images.unsplash.com/photo-1543353071-873f17a7a088?w=1200','9800000011','contact.koshidelights@example.com','Main Road','Biratnagar',26.4525000,87.2718000,1,1,0,8.00,60.00,200.00,25,15.00,'approved',1,'10:00:00','22:00:00','2026-09-26 05:57:59','2026-09-26 06:35:57'),(17,'cef698d3-b973-11f1-8789-9696ace701e2',18,'El Dorado Avenue','el-dorado-avenue','restaurant','Fine-dining restaurant known for momo, matka biryani and sekuwa.','https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400','https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=1200','9800000012','contact.eldorado@example.com','Kalikanagar 11, Horizon Chowk','Butwal',27.6784517,83.4621997,1,1,0,8.00,70.00,250.00,25,15.00,'approved',1,'07:00:00','23:30:00','2026-09-26 06:30:46','2026-09-26 06:30:46'),(18,'d01fd752-b973-11f1-8789-9696ace701e2',19,'Soulmate Restaurant Butwal','soulmate-restaurant-butwal','restaurant','Cozy family restaurant known for chicken biryani and timur chicken.','https://images.unsplash.com/photo-1552566626-52f8b828add9?w=400','https://images.unsplash.com/photo-1552566626-52f8b828add9?w=1200','9800000013','contact.soulmate@example.com','Kalikanagar Butwal-11','Butwal',27.6764449,83.4626109,1,1,0,8.00,60.00,200.00,25,15.00,'approved',1,'08:00:00','22:00:00','2026-09-26 06:30:48','2026-09-26 06:35:57'),(19,'d147b55f-b973-11f1-8789-9696ace701e2',20,'Daddy\'s Kitchen','daddys-kitchen-butwal','restaurant','Lively family restaurant with a big menu of Nepali, fast-food and continental dishes.','https://images.unsplash.com/photo-1550547660-d9450f859349?w=400','https://images.unsplash.com/photo-1550547660-d9450f859349?w=1200','9800000014','contact.daddyskitchen@example.com','Butwal','Butwal',27.6669015,83.4609114,1,1,0,8.00,60.00,200.00,25,15.00,'approved',1,'07:00:00','23:00:00','2026-09-26 06:30:50','2026-09-26 06:35:58'),(20,'d28ff625-b973-11f1-8789-9696ace701e2',21,'Grassland Nepal','grassland-nepal','restaurant','Restaurant, bar and cafe combo with live music, sushi and wood-fired pizza.','https://images.unsplash.com/photo-1544148103-0773bf10d330?w=400','https://images.unsplash.com/photo-1544148103-0773bf10d330?w=1200','9800000015','contact.grassland@example.com','Butwal','Butwal',27.6856134,83.4626004,1,1,0,8.00,60.00,250.00,25,15.00,'approved',1,'10:00:00','23:00:00','2026-09-26 06:30:53','2026-09-26 06:30:53'),(21,'d3b7b086-b973-11f1-8789-9696ace701e2',22,'Hide Out Restro','hide-out-restro','restaurant','Green, quiet outdoor restaurant surrounded by nature.','https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400','https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=1200','9800000016','contact.hideout@example.com','Butwal','Butwal',27.7017324,83.4530679,1,1,0,8.00,60.00,200.00,25,15.00,'approved',1,'08:00:00','22:00:00','2026-09-26 06:30:54','2026-09-26 06:35:58'),(22,'d4ded557-b973-11f1-8789-9696ace701e2',23,'Butwal Veg & Vegan Restaurant','butwal-veg-vegan-restaurant','restaurant','Pure vegetarian and vegan restaurant, including onion-and-garlic-free options.','https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400','https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=1200','9800000017','contact.butwalveg@example.com','Traffic Chowk','Butwal',27.7021861,83.4668620,1,1,0,8.00,60.00,150.00,25,15.00,'approved',1,'07:00:00','22:00:00','2026-09-26 06:30:56','2026-09-26 06:35:58'),(23,'d604b901-b973-11f1-8789-9696ace701e2',24,'Good DO, The Vegan Kitchen','good-do-vegan-kitchen','restaurant','Creative, wholesome vegan kitchen with a cozy outdoor view.','https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400','https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=1200','9800000018','contact.gooddo@example.com','Traffic Chowk','Butwal',27.7015075,83.4664875,1,1,0,8.00,60.00,150.00,25,15.00,'approved',1,'10:00:00','22:00:00','2026-09-26 06:30:58','2026-09-26 06:35:59'),(24,'d72aebdb-b973-11f1-8789-9696ace701e2',25,'Cloud 9 Cafe','cloud-9-cafe','cafe','Cozy cafe known for its chicken wraps and relaxed hookah lounge vibe.','https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400','https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1200','9800000019','contact.cloud9@example.com','Devinagar','Butwal',27.6821325,83.4581235,1,1,0,6.00,60.00,150.00,25,15.00,'approved',1,'07:00:00','22:00:00','2026-09-26 06:31:00','2026-09-26 06:35:59'),(25,'d833e8ef-b973-11f1-8789-9696ace701e2',26,'Papaya Butwal','papaya-butwal','cafe','Cozy cafe and bakery known for smoothie bowls, sliders and bubble tea.','https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400','https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=1200','9800000020','contact.papaya@example.com','Kalika Path','Butwal',27.6843715,83.4624088,1,1,0,6.00,60.00,150.00,25,15.00,'approved',1,'07:00:00','22:00:00','2026-09-26 06:31:02','2026-09-26 06:36:00'),(26,'d93c324b-b973-11f1-8789-9696ace701e2',27,'Caffeine Cup Cafe & Restaurant','caffeine-cup-cafe','cafe','Small, top-rated coffee spot on Moti Path with a relaxed atmosphere.','https://images.unsplash.com/photo-1445116572660-236099ec97a0?w=400','https://images.unsplash.com/photo-1445116572660-236099ec97a0?w=1200','9800000021','contact.caffeinecup@example.com','Moti Path','Butwal',27.6867868,83.4624920,1,1,0,6.00,60.00,150.00,25,15.00,'approved',1,'07:00:00','22:00:00','2026-09-26 06:31:04','2026-09-26 06:36:00');
/*!40000 ALTER TABLE `businesses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `menu_categories`
--

DROP TABLE IF EXISTS `menu_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `menu_categories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `business_id` int NOT NULL,
  `name` varchar(100) NOT NULL,
  `sort_order` int DEFAULT '0',
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `business_id` (`business_id`),
  CONSTRAINT `menu_categories_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=108 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `menu_categories`
--

LOCK TABLES `menu_categories` WRITE;
/*!40000 ALTER TABLE `menu_categories` DISABLE KEYS */;
INSERT INTO `menu_categories` VALUES (1,1,'Momo & Starters',1,1),(2,1,'Main Course',2,1),(3,1,'Tandoori & Grill',3,1),(4,1,'Beverages',4,1),(5,2,'Starters',1,1),(6,2,'Noodles & Rice',2,1),(7,2,'Beverages',3,1),(8,4,'Coffee',1,1),(9,4,'Bakery',2,1),(10,6,'Momo & Newari',1,1),(11,6,'Thali Sets',2,1),(12,7,'Starters',1,1),(13,7,'Main Course',2,1),(14,7,'Breads & Rice',3,1),(15,7,'Desserts',4,1),(16,7,'Beverages',5,1),(17,8,'Coffee',1,1),(18,8,'Breakfast',2,1),(19,8,'Bakery',3,1),(20,8,'Sandwiches',4,1),(21,11,'Starters',1,1),(22,11,'Main Course',2,1),(23,11,'Noodles & Rice',3,1),(24,11,'Desserts',4,1),(25,11,'Beverages',5,1),(26,37,'Starters',1,1),(27,37,'Main Course',2,1),(28,37,'Breads & Rice',3,1),(29,37,'Desserts',4,1),(30,37,'Beverages',5,1),(31,45,'Coffee',1,1),(32,45,'Breakfast',2,1),(33,45,'Bakery',3,1),(34,45,'Sandwiches',4,1),(35,15,'Starters',1,1),(36,15,'Main Course',2,1),(37,15,'Noodles & Rice',3,1),(38,15,'Desserts',4,1),(39,15,'Beverages',5,1),(40,17,'Starters',1,1),(41,17,'Main Course',2,1),(42,17,'Beverages',3,1),(43,18,'Starters',1,1),(44,18,'Main Course',2,1),(45,18,'Beverages',3,1),(46,19,'Starters',1,1),(47,19,'Fast Food',2,1),(48,19,'Main Course',3,1),(49,19,'Beverages',4,1),(50,20,'Starters',1,1),(51,20,'Pizza & Sushi',2,1),(52,20,'Beverages',3,1),(53,21,'Starters',1,1),(54,21,'Main Course',2,1),(55,21,'Beverages',3,1),(56,22,'Starters',1,1),(57,22,'Main Course',2,1),(58,22,'Beverages',3,1),(59,23,'Starters',1,1),(60,23,'Main Course',2,1),(61,23,'Beverages',3,1),(62,24,'Coffee',1,1),(63,24,'Wraps & Snacks',2,1),(64,25,'Beverages',1,1),(65,25,'Snacks & Bowls',2,1),(66,26,'Coffee',1,1),(67,26,'Snacks',2,1),(68,108,'Starters',1,1),(69,108,'Main Course',2,1),(70,108,'Breads & Rice',3,1),(71,108,'Desserts',4,1),(72,108,'Beverages',5,1),(73,111,'Starters',1,1),(74,111,'Main Course',2,1),(75,111,'Noodles & Rice',3,1),(76,111,'Desserts',4,1),(77,111,'Beverages',5,1),(78,122,'Starters',1,1),(79,122,'Fast Food',2,1),(80,122,'Main Course',3,1),(81,122,'Desserts',4,1),(82,122,'Beverages',5,1),(83,131,'Starters',1,1),(84,131,'Pizza & Sushi',2,1),(85,131,'Main Course',3,1),(86,131,'Beverages',4,1),(87,139,'Starters',1,1),(88,139,'Main Course',2,1),(89,139,'Desserts',3,1),(90,139,'Beverages',4,1),(91,147,'Starters',1,1),(92,147,'Main Course',2,1),(93,147,'Desserts',3,1),(94,147,'Beverages',4,1),(95,154,'Starters',1,1),(96,154,'Main Course',2,1),(97,154,'Desserts',3,1),(98,154,'Beverages',4,1),(99,162,'Coffee',1,1),(100,162,'Wraps & Snacks',2,1),(101,162,'Bakery',3,1),(102,169,'Beverages',1,1),(103,169,'Snacks & Bowls',2,1),(104,169,'Bakery',3,1),(105,175,'Coffee',1,1),(106,175,'Snacks',2,1),(107,175,'Sandwiches',3,1);
/*!40000 ALTER TABLE `menu_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `menu_item_addons`
--

DROP TABLE IF EXISTS `menu_item_addons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `menu_item_addons` (
  `id` int NOT NULL AUTO_INCREMENT,
  `menu_item_id` int NOT NULL,
  `name` varchar(100) NOT NULL,
  `price` decimal(10,2) NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`id`),
  KEY `menu_item_id` (`menu_item_id`),
  CONSTRAINT `menu_item_addons_ibfk_1` FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `menu_item_addons`
--

LOCK TABLES `menu_item_addons` WRITE;
/*!40000 ALTER TABLE `menu_item_addons` DISABLE KEYS */;
/*!40000 ALTER TABLE `menu_item_addons` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `menu_items`
--

DROP TABLE IF EXISTS `menu_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `menu_items` (
  `id` int NOT NULL AUTO_INCREMENT,
  `business_id` int NOT NULL,
  `category_id` int DEFAULT NULL,
  `name` varchar(150) NOT NULL,
  `description` text,
  `price` decimal(10,2) NOT NULL,
  `discount_percent` decimal(5,2) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `is_veg` tinyint(1) DEFAULT '1',
  `is_available` tinyint(1) DEFAULT '1',
  `prep_time_mins` int DEFAULT '15',
  `tags` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `category_id` (`category_id`),
  KEY `idx_menu_items_business` (`business_id`,`is_available`),
  CONSTRAINT `menu_items_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `menu_items_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `menu_categories` (`id`) ON DELETE SET NULL,
  CONSTRAINT `chk_menu_items_discount_percent` CHECK (((`discount_percent` is null) or ((`discount_percent` >= 5) and (`discount_percent` <= 90))))
) ENGINE=InnoDB AUTO_INCREMENT=188 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `menu_items`
--

LOCK TABLES `menu_items` WRITE;
/*!40000 ALTER TABLE `menu_items` DISABLE KEYS */;
INSERT INTO `menu_items` VALUES (1,1,1,'Chicken Momo','Steamed dumplings with spicy tomato achar.',220.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,15,'momo,steamed,spicy','2026-09-26 05:52:20','2026-09-26 05:52:20'),(2,1,1,'Veg Momo','Steamed veg dumplings with sesame achar.',180.00,NULL,'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=600',1,1,15,'momo,veg,steamed','2026-09-26 05:52:20','2026-09-26 05:52:20'),(3,1,2,'Chicken Thakali Set','Traditional Thakali thali with chicken curry, rice, dal, sides.',450.00,NULL,'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=600',0,1,25,'thakali,set,rice','2026-09-26 05:52:20','2026-09-26 05:52:20'),(4,1,2,'Paneer Butter Masala','Cottage cheese in a rich buttery tomato gravy.',340.00,NULL,'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=600',1,1,20,'paneer,curry,veg','2026-09-26 05:52:20','2026-09-26 05:52:20'),(5,1,3,'Tandoori Chicken (Half)','Char-grilled chicken marinated in yogurt & spices.',380.00,NULL,'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=600',0,1,30,'tandoori,grill,chicken','2026-09-26 05:52:20','2026-09-26 05:52:20'),(6,1,4,'Masala Chiya','Spiced Nepali milk tea.',60.00,NULL,'https://images.unsplash.com/photo-1571934811356-5cc061b6821f?w=600',1,1,5,'tea,hot,drink','2026-09-26 05:52:20','2026-09-26 05:52:20'),(7,1,4,'Fresh Lime Soda','Chilled lime soda, sweet or salted.',90.00,NULL,'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=600',1,1,5,'cold,drink,refreshing','2026-09-26 05:52:20','2026-09-26 05:52:20'),(8,2,5,'Chilli Chicken','Crispy chicken tossed in a spicy chilli-soy sauce.',320.00,NULL,'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600',0,1,20,'spicy,chicken,starter','2026-09-26 05:54:45','2026-09-26 05:54:45'),(9,2,6,'Veg Chowmein','Stir-fried noodles with fresh vegetables.',220.00,NULL,'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=600',1,1,15,'noodles,veg','2026-09-26 05:54:45','2026-09-26 05:54:45'),(10,2,6,'Chicken Fried Rice','Wok-tossed rice with chicken and egg.',260.00,NULL,'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=600',0,1,18,'rice,chicken','2026-09-26 05:54:45','2026-09-26 05:54:45'),(11,2,7,'Iced Lemon Tea','Chilled lemon tea, lightly sweetened.',80.00,NULL,'https://images.unsplash.com/photo-1499638673689-79a0b5115d87?w=600',1,1,5,'cold,tea','2026-09-26 05:54:45','2026-09-26 05:54:45'),(12,4,8,'Cappuccino','Espresso with steamed milk foam.',150.00,NULL,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600',1,1,8,'coffee,hot','2026-09-26 05:54:48','2026-09-26 05:54:48'),(13,4,8,'Cold Brew','Slow-steeped, smooth cold coffee.',180.00,NULL,'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=600',1,1,5,'coffee,cold','2026-09-26 05:54:48','2026-09-26 05:54:48'),(14,4,9,'Butter Croissant','Flaky, buttery French croissant.',130.00,NULL,'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600',1,1,5,'bakery,pastry','2026-09-26 05:54:48','2026-09-26 05:54:48'),(15,4,9,'Chocolate Muffin','Rich chocolate chip muffin.',110.00,NULL,'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=600',1,1,5,'bakery,dessert','2026-09-26 05:54:48','2026-09-26 05:54:48'),(16,6,10,'Buff Momo (Jhol)','Buffalo momos in spicy soupy achar.',240.00,NULL,'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=600',0,1,18,'momo,newari,spicy','2026-09-26 05:54:51','2026-09-26 05:54:51'),(17,6,10,'Chatamari','Rice-flour crepe topped with egg and minced meat.',200.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,15,'newari,snack','2026-09-26 05:54:51','2026-09-26 05:54:51'),(18,6,11,'Dal Bhat Set','Rice, lentils, seasonal veg curry, pickle and papad.',260.00,NULL,'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=600',1,1,20,'thali,rice,veg','2026-09-26 05:54:51','2026-09-26 05:54:51'),(19,7,12,'Chicken Chilli','Wok-tossed chicken in spicy chilli sauce.',300.00,NULL,'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600',0,1,18,'spicy,chicken,starter','2026-09-26 05:57:52','2026-09-26 05:57:52'),(20,7,12,'Paneer Pakoda','Cottage cheese fritters, crispy fried.',220.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',1,1,15,'veg,fried,snack','2026-09-26 05:57:52','2026-09-26 05:57:52'),(21,7,13,'Chicken Curry','Home-style bone-in chicken curry.',340.00,NULL,'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=600',0,1,25,'curry,chicken','2026-09-26 05:57:52','2026-09-26 05:57:52'),(22,7,13,'Mutton Curry','Slow-cooked goat meat in a rich masala gravy.',480.00,NULL,'https://images.unsplash.com/photo-1585937421612-70a008356c36?w=600',0,1,35,'curry,mutton','2026-09-26 05:57:52','2026-09-26 05:57:52'),(23,7,13,'Paneer Butter Masala','Cottage cheese in a buttery tomato gravy.',320.00,NULL,'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=600',1,1,20,'paneer,veg,curry','2026-09-26 05:57:52','2026-09-26 05:57:52'),(24,7,13,'Dal Bhat Set','Rice, lentils, veg curry, pickle and papad.',260.00,NULL,'https://images.unsplash.com/photo-1547592180-85f173990554?w=600',1,1,20,'thali,rice,veg','2026-09-26 05:57:52','2026-09-26 05:57:52'),(25,7,14,'Butter Naan','Soft tandoor-baked bread with butter.',60.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',1,1,10,'bread,tandoor','2026-09-26 05:57:52','2026-09-26 05:57:52'),(26,7,14,'Steamed Rice','Plain steamed basmati rice.',100.00,NULL,'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600',1,1,15,'rice,plain','2026-09-26 05:57:52','2026-09-26 05:57:52'),(27,7,15,'Gulab Jamun (2 pcs)','Deep-fried milk dumplings in sugar syrup.',90.00,NULL,'https://images.unsplash.com/photo-1601303516361-b0a4c0bd6f1e?w=600',1,1,5,'dessert,sweet','2026-09-26 05:57:52','2026-09-26 05:57:52'),(28,7,16,'Masala Chiya','Spiced Nepali milk tea.',60.00,NULL,'https://images.unsplash.com/photo-1571934811356-5cc061b6821f?w=600',1,1,5,'tea,hot','2026-09-26 05:57:52','2026-09-26 05:57:52'),(29,8,17,'Cappuccino','Espresso with steamed milk foam.',160.00,NULL,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600',1,1,8,'coffee,hot','2026-09-26 05:57:56','2026-09-26 05:57:56'),(30,8,17,'Americano','Espresso shots topped with hot water.',140.00,NULL,'https://images.unsplash.com/photo-1497935586047-9242eb4fc339?w=600',1,1,6,'coffee,hot','2026-09-26 05:57:56','2026-09-26 05:57:56'),(31,8,17,'Iced Latte','Espresso with cold milk over ice.',180.00,NULL,'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=600',1,1,6,'coffee,cold','2026-09-26 05:57:56','2026-09-26 05:57:56'),(32,8,18,'Pancake Stack','Fluffy pancakes with maple syrup.',250.00,NULL,'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=600',1,1,15,'breakfast,sweet','2026-09-26 05:57:56','2026-09-26 05:57:56'),(33,8,18,'Veg Omelette','Three-egg omelette with mixed vegetables.',200.00,NULL,'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=600',0,1,10,'breakfast,egg','2026-09-26 05:57:56','2026-09-26 05:57:56'),(34,8,19,'Butter Croissant','Flaky, buttery French croissant.',140.00,NULL,'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600',1,1,5,'bakery,pastry','2026-09-26 05:57:56','2026-09-26 05:57:56'),(35,8,19,'Chocolate Muffin','Rich chocolate chip muffin.',120.00,NULL,'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=600',1,1,5,'bakery,dessert','2026-09-26 05:57:56','2026-09-26 05:57:56'),(36,8,20,'Grilled Cheese Sandwich','Melted cheese between toasted bread.',190.00,NULL,'https://images.unsplash.com/photo-1528736235302-52922df5c122?w=600',1,1,10,'sandwich,cheese','2026-09-26 05:57:56','2026-09-26 05:57:56'),(37,11,21,'Chicken Momo','Steamed dumplings with spicy tomato achar.',220.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,15,'momo,steamed','2026-09-26 05:58:01','2026-09-26 05:58:01'),(38,11,21,'Veg Spring Rolls','Crispy rolls stuffed with veggies.',180.00,NULL,'https://images.unsplash.com/photo-1548507200-64a1c2a30a66?w=600',1,1,12,'fried,veg,starter','2026-09-26 05:58:01','2026-09-26 05:58:01'),(39,11,22,'Chicken Chowmein','Stir-fried noodles with chicken.',260.00,NULL,'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=600',0,1,18,'noodles,chicken','2026-09-26 05:58:01','2026-09-26 05:58:01'),(40,11,22,'Fish Curry','Freshwater fish in a tangy Nepali-style curry.',380.00,NULL,'https://images.unsplash.com/photo-1626200926749-4585f8e8ffc0?w=600',0,1,30,'fish,curry','2026-09-26 05:58:01','2026-09-26 05:58:01'),(41,11,23,'Chicken Fried Rice','Wok-tossed rice with chicken and egg.',260.00,NULL,'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=600',0,1,18,'rice,chicken','2026-09-26 05:58:01','2026-09-26 05:58:01'),(42,11,23,'Veg Fried Rice','Wok-tossed rice with mixed vegetables.',200.00,NULL,'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600',1,1,15,'rice,veg','2026-09-26 05:58:01','2026-09-26 05:58:01'),(43,11,24,'Rasbari (2 pcs)','Soft milk-based sweet in sugar syrup.',90.00,NULL,'https://images.unsplash.com/photo-1601303516361-b0a4c0bd6f1e?w=600',1,1,5,'dessert,sweet','2026-09-26 05:58:01','2026-09-26 05:58:01'),(44,11,25,'Fresh Lime Soda','Chilled lime soda, sweet or salted.',90.00,NULL,'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=600',1,1,5,'cold,drink','2026-09-26 05:58:01','2026-09-26 05:58:01'),(45,37,26,'Chicken Chilli','Wok-tossed chicken in spicy chilli sauce.',300.00,NULL,'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600',0,1,18,'spicy,chicken,starter','2026-09-26 06:26:55','2026-09-26 06:26:55'),(46,37,26,'Paneer Pakoda','Cottage cheese fritters, crispy fried.',220.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',1,1,15,'veg,fried,snack','2026-09-26 06:26:55','2026-09-26 06:26:55'),(47,37,27,'Chicken Curry','Home-style bone-in chicken curry.',340.00,NULL,'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=600',0,1,25,'curry,chicken','2026-09-26 06:26:55','2026-09-26 06:26:55'),(48,37,27,'Mutton Curry','Slow-cooked goat meat in a rich masala gravy.',480.00,NULL,'https://images.unsplash.com/photo-1585937421612-70a008356c36?w=600',0,1,35,'curry,mutton','2026-09-26 06:26:55','2026-09-26 06:26:55'),(49,37,27,'Paneer Butter Masala','Cottage cheese in a buttery tomato gravy.',320.00,NULL,'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=600',1,1,20,'paneer,veg,curry','2026-09-26 06:26:55','2026-09-26 06:26:55'),(50,37,27,'Dal Bhat Set','Rice, lentils, veg curry, pickle and papad.',260.00,NULL,'https://images.unsplash.com/photo-1547592180-85f173990554?w=600',1,1,20,'thali,rice,veg','2026-09-26 06:26:55','2026-09-26 06:26:55'),(51,37,28,'Butter Naan','Soft tandoor-baked bread with butter.',60.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',1,1,10,'bread,tandoor','2026-09-26 06:26:55','2026-09-26 06:26:55'),(52,37,28,'Steamed Rice','Plain steamed basmati rice.',100.00,NULL,'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600',1,1,15,'rice,plain','2026-09-26 06:26:55','2026-09-26 06:26:55'),(53,37,29,'Gulab Jamun (2 pcs)','Deep-fried milk dumplings in sugar syrup.',90.00,NULL,'https://images.unsplash.com/photo-1601303516361-b0a4c0bd6f1e?w=600',1,1,5,'dessert,sweet','2026-09-26 06:26:55','2026-09-26 06:26:55'),(54,37,30,'Masala Chiya','Spiced Nepali milk tea.',60.00,NULL,'https://images.unsplash.com/photo-1571934811356-5cc061b6821f?w=600',1,1,5,'tea,hot','2026-09-26 06:26:55','2026-09-26 06:26:55'),(55,45,31,'Cappuccino','Espresso with steamed milk foam.',160.00,NULL,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600',1,1,8,'coffee,hot','2026-09-26 06:26:57','2026-09-26 06:26:57'),(56,45,31,'Americano','Espresso shots topped with hot water.',140.00,NULL,'https://images.unsplash.com/photo-1497935586047-9242eb4fc339?w=600',1,1,6,'coffee,hot','2026-09-26 06:26:57','2026-09-26 06:26:57'),(57,45,31,'Iced Latte','Espresso with cold milk over ice.',180.00,NULL,'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=600',1,1,6,'coffee,cold','2026-09-26 06:26:57','2026-09-26 06:26:57'),(58,45,32,'Pancake Stack','Fluffy pancakes with maple syrup.',250.00,NULL,'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=600',1,1,15,'breakfast,sweet','2026-09-26 06:26:57','2026-09-26 06:26:57'),(59,45,32,'Veg Omelette','Three-egg omelette with mixed vegetables.',200.00,NULL,'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=600',0,1,10,'breakfast,egg','2026-09-26 06:26:57','2026-09-26 06:26:57'),(60,45,33,'Butter Croissant','Flaky, buttery French croissant.',140.00,NULL,'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600',1,1,5,'bakery,pastry','2026-09-26 06:26:57','2026-09-26 06:26:57'),(61,45,33,'Chocolate Muffin','Rich chocolate chip muffin.',120.00,NULL,'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=600',1,1,5,'bakery,dessert','2026-09-26 06:26:57','2026-09-26 06:26:57'),(62,45,34,'Grilled Cheese Sandwich','Melted cheese between toasted bread.',190.00,NULL,'https://images.unsplash.com/photo-1528736235302-52922df5c122?w=600',1,1,10,'sandwich,cheese','2026-09-26 06:26:57','2026-09-26 06:26:57'),(63,15,35,'Chicken Momo','Steamed dumplings with spicy tomato achar.',220.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,15,'momo,steamed','2026-09-26 06:27:02','2026-09-26 06:27:02'),(64,15,35,'Veg Spring Rolls','Crispy rolls stuffed with veggies.',180.00,NULL,'https://images.unsplash.com/photo-1548507200-64a1c2a30a66?w=600',1,1,12,'fried,veg,starter','2026-09-26 06:27:02','2026-09-26 06:27:02'),(65,15,36,'Chicken Chowmein','Stir-fried noodles with chicken.',260.00,NULL,'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=600',0,1,18,'noodles,chicken','2026-09-26 06:27:02','2026-09-26 06:27:02'),(66,15,36,'Fish Curry','Freshwater fish in a tangy Nepali-style curry.',380.00,NULL,'https://images.unsplash.com/photo-1626200926749-4585f8e8ffc0?w=600',0,1,30,'fish,curry','2026-09-26 06:27:02','2026-09-26 06:27:02'),(67,15,37,'Chicken Fried Rice','Wok-tossed rice with chicken and egg.',260.00,NULL,'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=600',0,1,18,'rice,chicken','2026-09-26 06:27:02','2026-09-26 06:27:02'),(68,15,37,'Veg Fried Rice','Wok-tossed rice with mixed vegetables.',200.00,NULL,'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600',1,1,15,'rice,veg','2026-09-26 06:27:02','2026-09-26 06:27:02'),(69,15,38,'Rasbari (2 pcs)','Soft milk-based sweet in sugar syrup.',90.00,NULL,'https://images.unsplash.com/photo-1601303516361-b0a4c0bd6f1e?w=600',1,1,5,'dessert,sweet','2026-09-26 06:27:02','2026-09-26 06:27:02'),(70,15,39,'Fresh Lime Soda','Chilled lime soda, sweet or salted.',90.00,NULL,'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=600',1,1,5,'cold,drink','2026-09-26 06:27:02','2026-09-26 06:27:02'),(71,17,40,'Chicken Sekuwa','Grilled marinated chicken skewers, smoky and spiced.',380.00,NULL,'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=600',0,1,22,'grill,chicken,starter','2026-09-26 06:30:48','2026-09-26 06:30:48'),(72,17,40,'Steam Momo','Classic steamed dumplings with tomato achar.',240.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,18,'momo,steamed','2026-09-26 06:30:48','2026-09-26 06:30:48'),(73,17,41,'Matka Biryani','Slow-cooked biryani sealed and served in a clay pot.',450.00,NULL,'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600',0,1,35,'biryani,rice','2026-09-26 06:30:48','2026-09-26 06:30:48'),(74,17,41,'Mustang Aloo','Spiced boiled potatoes, Mustang-style.',220.00,NULL,'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=600',1,1,15,'veg,potato,spicy','2026-09-26 06:30:48','2026-09-26 06:30:48'),(75,17,42,'Mango Smoothie','Fresh mango blended with yogurt.',180.00,NULL,'https://images.unsplash.com/photo-1546173159-315724a31696?w=600',1,1,8,'smoothie,cold','2026-09-26 06:30:48','2026-09-26 06:30:48'),(76,17,42,'Cappuccino','Espresso with steamed milk foam.',160.00,NULL,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600',1,1,8,'coffee,hot','2026-09-26 06:30:48','2026-09-26 06:30:48'),(77,18,43,'Chicken Sandheko','Spiced, tossed chicken salad with herbs and lime.',260.00,NULL,'https://images.unsplash.com/photo-1598515213692-5f252f4dc22b?w=600',0,1,15,'spicy,chicken,starter','2026-09-26 06:30:50','2026-09-26 06:30:50'),(78,18,44,'Chicken Biryani','Fragrant, spice-packed biryani with tender chicken.',340.00,NULL,'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600',0,1,30,'biryani,rice,chicken','2026-09-26 06:30:50','2026-09-26 06:30:50'),(79,18,44,'Timur Chicken','Chicken tossed in a zesty Szechwan-pepper sauce.',360.00,NULL,'https://images.unsplash.com/photo-1610057099431-d73a1c9d2ef7?w=600',0,1,25,'spicy,chicken','2026-09-26 06:30:50','2026-09-26 06:30:50'),(80,18,45,'Masala Chiya','Spiced Nepali milk tea.',60.00,NULL,'https://images.unsplash.com/photo-1571934811356-5cc061b6821f?w=600',1,1,5,'tea,hot','2026-09-26 06:30:50','2026-09-26 06:30:50'),(81,19,46,'Chicken Wings','Crispy fried wings tossed in house sauce.',300.00,NULL,'https://images.unsplash.com/photo-1608039755401-742074f0548d?w=600',0,1,18,'fried,chicken,starter','2026-09-26 06:30:52','2026-09-26 06:30:52'),(82,19,47,'Cheese Burger','Grilled patty with melted cheese and salad.',280.00,NULL,'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600',0,1,15,'burger,fastfood','2026-09-26 06:30:52','2026-09-26 06:30:52'),(83,19,48,'Chicken Biryani','Layered rice with spiced chicken.',340.00,NULL,'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600',0,1,30,'biryani,rice','2026-09-26 06:30:52','2026-09-26 06:30:52'),(84,19,49,'Iced Tea','Chilled black tea with lemon.',120.00,NULL,'https://images.unsplash.com/photo-1499638673689-79a0b5115d87?w=600',1,1,6,'tea,cold','2026-09-26 06:30:52','2026-09-26 06:30:52'),(85,20,50,'Juicy Momo','Steamed momo with a rich, juicy filling.',240.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,18,'momo,steamed','2026-09-26 06:30:54','2026-09-26 06:30:54'),(86,20,51,'Margherita Pizza','Classic tomato, mozzarella and basil pizza.',480.00,NULL,'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600',1,1,25,'pizza,veg','2026-09-26 06:30:54','2026-09-26 06:30:54'),(87,20,51,'California Roll','Crab stick, avocado and cucumber sushi roll.',420.00,NULL,'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=600',0,1,20,'sushi,seafood','2026-09-26 06:30:54','2026-09-26 06:30:54'),(88,20,52,'Iced Americano','Chilled espresso over ice.',180.00,NULL,'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=600',1,1,6,'coffee,cold','2026-09-26 06:30:54','2026-09-26 06:30:54'),(89,21,53,'Hot Wings','Crispy chicken wings tossed in a hot glaze.',280.00,NULL,'https://images.unsplash.com/photo-1608039755401-742074f0548d?w=600',0,1,18,'fried,chicken,spicy','2026-09-26 06:30:56','2026-09-26 06:30:56'),(90,21,54,'Veg Pizza','Loaded vegetable pizza on a thin crust.',380.00,NULL,'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600',1,1,22,'pizza,veg','2026-09-26 06:30:56','2026-09-26 06:30:56'),(91,21,54,'Chicken Sandwich','Grilled chicken breast sandwich with veggies.',260.00,NULL,'https://images.unsplash.com/photo-1521305916504-4a1121188589?w=600',0,1,15,'sandwich,chicken','2026-09-26 06:30:56','2026-09-26 06:30:56'),(92,21,55,'Peach Iced Tea','Chilled tea with peach syrup.',150.00,NULL,'https://images.unsplash.com/photo-1499638673689-79a0b5115d87?w=600',1,1,6,'tea,cold','2026-09-26 06:30:56','2026-09-26 06:30:56'),(93,22,56,'Veg Momo','Steamed vegetable momo with achar.',200.00,NULL,'https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?w=600',1,1,15,'momo,veg','2026-09-26 06:30:58','2026-09-26 06:30:58'),(94,22,57,'Veg Biryani','Mixed-vegetable biryani, no onion or garlic option available.',280.00,NULL,'https://images.unsplash.com/photo-1633945274309-2a991dd7cf20?w=600',1,1,25,'biryani,veg','2026-09-26 06:30:58','2026-09-26 06:30:58'),(95,22,57,'Chukauni Set','Potato salad in a mustard-yogurt dressing with rice.',220.00,NULL,'https://images.unsplash.com/photo-1547592180-85f173990554?w=600',1,1,18,'veg,nepali','2026-09-26 06:30:58','2026-09-26 06:30:58'),(96,22,58,'Fresh Lime Soda','Chilled lime soda, sweet or salted.',90.00,NULL,'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=600',1,1,5,'cold,drink','2026-09-26 06:30:58','2026-09-26 06:30:58'),(97,23,59,'Veg Bytz Sekuwa','Plant-based grilled skewers with house spices.',260.00,NULL,'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=600',1,1,18,'vegan,grill,starter','2026-09-26 06:31:00','2026-09-26 06:31:00'),(98,23,60,'Buddha Bowl','Mixed grains, greens and roasted vegetables.',300.00,NULL,'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600',1,1,15,'vegan,healthy,bowl','2026-09-26 06:31:00','2026-09-26 06:31:00'),(99,23,60,'Vegan Burger','Plant-based patty with vegan mayo and greens.',320.00,NULL,'https://images.unsplash.com/photo-1520072959219-c595dc870360?w=600',1,1,18,'vegan,burger','2026-09-26 06:31:00','2026-09-26 06:31:00'),(100,23,61,'Green Detox Juice','Cold-pressed spinach, cucumber and apple juice.',160.00,NULL,'https://images.unsplash.com/photo-1622597467836-f3285f2131b8?w=600',1,1,8,'vegan,juice,cold','2026-09-26 06:31:00','2026-09-26 06:31:00'),(101,24,62,'Iced Latte','Espresso with cold milk over ice.',180.00,NULL,'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=600',1,1,6,'coffee,cold','2026-09-26 06:31:01','2026-09-26 06:31:01'),(102,24,63,'Chicken Wrap','Grilled chicken, veggies and sauce in a soft tortilla.',260.00,NULL,'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=600',0,1,15,'wrap,chicken','2026-09-26 06:31:01','2026-09-26 06:31:01'),(103,24,63,'Stuffed Mushroom','Baked mushrooms stuffed with cheese and herbs.',220.00,NULL,'https://images.unsplash.com/photo-1547181093-4d84c2af9c9c?w=600',1,1,15,'veg,snack','2026-09-26 06:31:01','2026-09-26 06:31:01'),(104,25,64,'Strawberry Matcha Latte','Matcha latte layered with strawberry syrup.',220.00,NULL,'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=600',1,1,8,'matcha,cold','2026-09-26 06:31:03','2026-09-26 06:31:03'),(105,25,64,'Red Velvet Boba','Red velvet milk tea with tapioca pearls.',200.00,NULL,'https://images.unsplash.com/photo-1558857563-b371033873b8?w=600',1,1,8,'boba,cold','2026-09-26 06:31:03','2026-09-26 06:31:03'),(106,25,65,'Healthy Smoothie Bowl','Mixed berries, granola and banana over smoothie base.',260.00,NULL,'https://images.unsplash.com/photo-1490474504059-bf2db5ab2348?w=600',1,1,12,'healthy,bowl','2026-09-26 06:31:03','2026-09-26 06:31:03'),(107,25,65,'Chicken Sliders (3 pcs)','Mini burgers with grilled chicken patties.',280.00,NULL,'https://images.unsplash.com/photo-1550317138-10000687a72b?w=600',0,1,15,'sliders,chicken','2026-09-26 06:31:03','2026-09-26 06:31:03'),(108,26,66,'Dopio Espresso','Double shot of rich espresso.',140.00,NULL,'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=600',1,1,5,'coffee,hot','2026-09-26 06:31:05','2026-09-26 06:31:05'),(109,26,66,'Cappuccino','Espresso with steamed milk foam.',160.00,NULL,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600',1,1,8,'coffee,hot','2026-09-26 06:31:05','2026-09-26 06:31:05'),(110,26,67,'Chocolate Muffin','Rich chocolate chip muffin.',120.00,NULL,'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=600',1,1,5,'bakery,dessert','2026-09-26 06:31:05','2026-09-26 06:31:05'),(111,108,68,'Chicken Sekuwa','Grilled marinated chicken skewers, smoky and spiced.',380.00,NULL,'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=600',0,1,22,'grill,chicken,starter','2026-09-26 06:36:20','2026-09-26 06:36:20'),(112,108,68,'Steam Momo','Classic steamed dumplings with tomato achar.',240.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,18,'momo,steamed','2026-09-26 06:36:20','2026-09-26 06:36:20'),(113,108,68,'Paneer Tikka','Char-grilled cottage cheese cubes in tandoori spice.',300.00,NULL,'https://images.unsplash.com/photo-1631515243349-e0cb75fb8d3a?w=600',1,1,20,'paneer,veg,grill','2026-09-26 06:36:20','2026-09-26 06:36:20'),(114,108,69,'Matka Biryani','Slow-cooked biryani sealed and served in a clay pot.',450.00,NULL,'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600',0,1,35,'biryani,rice','2026-09-26 06:36:20','2026-09-26 06:36:20'),(115,108,69,'Mustang Aloo','Spiced boiled potatoes, Mustang-style.',220.00,NULL,'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=600',1,1,15,'veg,potato,spicy','2026-09-26 06:36:20','2026-09-26 06:36:20'),(116,108,69,'Butter Chicken','Creamy tomato-based chicken curry.',420.00,NULL,'https://images.unsplash.com/photo-1603894584373-5ac82b2ae398?w=600',0,1,28,'curry,chicken','2026-09-26 06:36:20','2026-09-26 06:36:20'),(117,108,70,'Garlic Naan','Tandoor-baked bread topped with garlic and butter.',80.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',1,1,10,'bread,tandoor','2026-09-26 06:36:20','2026-09-26 06:36:20'),(118,108,70,'Jeera Rice','Basmati rice tempered with cumin.',140.00,NULL,'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600',1,1,15,'rice,veg','2026-09-26 06:36:20','2026-09-26 06:36:20'),(119,108,71,'Mango Sorbet','Refreshing mango sorbet, served chilled.',150.00,NULL,'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=600',1,1,5,'dessert,cold','2026-09-26 06:36:20','2026-09-26 06:36:20'),(120,108,72,'Mango Smoothie','Fresh mango blended with yogurt.',180.00,NULL,'https://images.unsplash.com/photo-1546173159-315724a31696?w=600',1,1,8,'smoothie,cold','2026-09-26 06:36:20','2026-09-26 06:36:20'),(121,108,72,'Cappuccino','Espresso with steamed milk foam.',160.00,NULL,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600',1,1,8,'coffee,hot','2026-09-26 06:36:20','2026-09-26 06:36:20'),(122,111,73,'Chicken Sandheko','Spiced, tossed chicken salad with herbs and lime.',260.00,NULL,'https://images.unsplash.com/photo-1598515213692-5f252f4dc22b?w=600',0,1,15,'spicy,chicken,starter','2026-09-26 06:36:22','2026-09-26 06:36:22'),(123,111,73,'Chicken Momo','Steamed dumplings with a spicy tomato achar.',240.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,18,'momo,steamed','2026-09-26 06:36:22','2026-09-26 06:36:22'),(124,111,74,'Chicken Biryani','Fragrant, spice-packed biryani with tender chicken.',340.00,NULL,'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600',0,1,30,'biryani,rice,chicken','2026-09-26 06:36:22','2026-09-26 06:36:22'),(125,111,74,'Timur Chicken','Chicken tossed in a zesty Szechwan-pepper sauce.',360.00,NULL,'https://images.unsplash.com/photo-1610057099431-d73a1c9d2ef7?w=600',0,1,25,'spicy,chicken','2026-09-26 06:36:22','2026-09-26 06:36:22'),(126,111,74,'Mutton Curry','Slow-cooked goat meat in a rich masala gravy.',480.00,NULL,'https://images.unsplash.com/photo-1585937421612-70a008356c36?w=600',0,1,35,'curry,mutton','2026-09-26 06:36:22','2026-09-26 06:36:22'),(127,111,75,'Chicken Chowmein','Stir-fried noodles with chicken and vegetables.',260.00,NULL,'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=600',0,1,18,'noodles,chicken','2026-09-26 06:36:22','2026-09-26 06:36:22'),(128,111,76,'Gulab Jamun (2 pcs)','Deep-fried milk dumplings in sugar syrup.',90.00,NULL,'https://images.unsplash.com/photo-1601303516361-b0a4c0bd6f1e?w=600',1,1,5,'dessert,sweet','2026-09-26 06:36:22','2026-09-26 06:36:22'),(129,111,77,'Masala Chiya','Spiced Nepali milk tea.',60.00,NULL,'https://images.unsplash.com/photo-1571934811356-5cc061b6821f?w=600',1,1,5,'tea,hot','2026-09-26 06:36:22','2026-09-26 06:36:22'),(130,111,77,'Fresh Lime Soda','Chilled lime soda, sweet or salted.',90.00,NULL,'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=600',1,1,5,'cold,drink','2026-09-26 06:36:22','2026-09-26 06:36:22'),(131,122,78,'Chicken Wings','Crispy fried wings tossed in house sauce.',300.00,NULL,'https://images.unsplash.com/photo-1608039755401-742074f0548d?w=600',0,1,18,'fried,chicken,starter','2026-09-26 06:36:25','2026-09-26 06:36:25'),(132,122,78,'Veg Spring Rolls','Crispy rolls stuffed with mixed vegetables.',220.00,NULL,'https://images.unsplash.com/photo-1548507200-64a1c2a30a66?w=600',1,1,12,'fried,veg,starter','2026-09-26 06:36:25','2026-09-26 06:36:25'),(133,122,79,'Cheese Burger','Grilled patty with melted cheese and salad.',280.00,NULL,'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600',0,1,15,'burger,fastfood','2026-09-26 06:36:25','2026-09-26 06:36:25'),(134,122,79,'Loaded Fries','Crispy fries topped with cheese sauce and jalapenos.',240.00,NULL,'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=600',1,1,12,'fries,fastfood','2026-09-26 06:36:25','2026-09-26 06:36:25'),(135,122,80,'Chicken Biryani','Layered rice with spiced chicken.',340.00,NULL,'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600',0,1,30,'biryani,rice','2026-09-26 06:36:25','2026-09-26 06:36:25'),(136,122,80,'Grilled Chicken Steak','Pan-grilled chicken breast with pepper sauce.',420.00,NULL,'https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=600',0,1,25,'grill,chicken,continental','2026-09-26 06:36:25','2026-09-26 06:36:25'),(137,122,81,'Chocolate Brownie','Warm fudge brownie with a scoop of ice cream.',220.00,NULL,'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=600',1,1,10,'dessert,sweet','2026-09-26 06:36:25','2026-09-26 06:36:25'),(138,122,82,'Iced Tea','Chilled black tea with lemon.',120.00,NULL,'https://images.unsplash.com/photo-1499638673689-79a0b5115d87?w=600',1,1,6,'tea,cold','2026-09-26 06:36:25','2026-09-26 06:36:25'),(139,131,83,'Juicy Momo','Steamed momo with a rich, juicy filling.',240.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',0,1,18,'momo,steamed','2026-09-26 06:36:27','2026-09-26 06:36:27'),(140,131,83,'Chicken Wings','Crispy fried wings tossed in house sauce.',300.00,NULL,'https://images.unsplash.com/photo-1608039755401-742074f0548d?w=600',0,1,18,'fried,chicken,starter','2026-09-26 06:36:27','2026-09-26 06:36:27'),(141,131,84,'Margherita Pizza','Classic tomato, mozzarella and basil pizza.',480.00,NULL,'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600',1,1,25,'pizza,veg','2026-09-26 06:36:27','2026-09-26 06:36:27'),(142,131,84,'Pepperoni Pizza','Wood-fired pizza topped with pepperoni.',550.00,NULL,'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=600',0,1,25,'pizza,chicken','2026-09-26 06:36:27','2026-09-26 06:36:27'),(143,131,84,'California Roll','Crab stick, avocado and cucumber sushi roll.',420.00,NULL,'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=600',0,1,20,'sushi,seafood','2026-09-26 06:36:27','2026-09-26 06:36:27'),(144,131,85,'Grilled Chicken Steak','Pan-grilled chicken breast with pepper sauce.',450.00,NULL,'https://images.unsplash.com/photo-1432139555190-58524dae6a55?w=600',0,1,25,'grill,chicken,continental','2026-09-26 06:36:27','2026-09-26 06:36:27'),(145,131,86,'Iced Americano','Chilled espresso over ice.',180.00,NULL,'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=600',1,1,6,'coffee,cold','2026-09-26 06:36:27','2026-09-26 06:36:27'),(146,131,86,'Fresh Lime Soda','Chilled lime soda, sweet or salted.',90.00,NULL,'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=600',1,1,5,'cold,drink','2026-09-26 06:36:27','2026-09-26 06:36:27'),(147,139,87,'Hot Wings','Crispy chicken wings tossed in a hot glaze.',280.00,NULL,'https://images.unsplash.com/photo-1608039755401-742074f0548d?w=600',0,1,18,'fried,chicken,spicy','2026-09-26 06:36:29','2026-09-26 06:36:29'),(148,139,87,'Nachos','Crispy tortilla chips with cheese sauce and salsa.',240.00,NULL,'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?w=600',1,1,12,'snack,veg','2026-09-26 06:36:29','2026-09-26 06:36:29'),(149,139,88,'Veg Pizza','Loaded vegetable pizza on a thin crust.',380.00,NULL,'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600',1,1,22,'pizza,veg','2026-09-26 06:36:29','2026-09-26 06:36:29'),(150,139,88,'Chicken Sandwich','Grilled chicken breast sandwich with veggies.',260.00,NULL,'https://images.unsplash.com/photo-1521305916504-4a1121188589?w=600',0,1,15,'sandwich,chicken','2026-09-26 06:36:29','2026-09-26 06:36:29'),(151,139,88,'Mushroom Pasta','Creamy penne pasta with sauteed mushrooms.',320.00,NULL,'https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?w=600',1,1,20,'pasta,veg','2026-09-26 06:36:29','2026-09-26 06:36:29'),(152,139,89,'Chocolate Muffin','Rich chocolate chip muffin.',120.00,NULL,'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=600',1,1,5,'bakery,dessert','2026-09-26 06:36:29','2026-09-26 06:36:29'),(153,139,90,'Peach Iced Tea','Chilled tea with peach syrup.',150.00,NULL,'https://images.unsplash.com/photo-1499638673689-79a0b5115d87?w=600',1,1,6,'tea,cold','2026-09-26 06:36:29','2026-09-26 06:36:29'),(154,147,91,'Veg Momo','Steamed vegetable momo with achar.',200.00,NULL,'https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?w=600',1,1,15,'momo,veg','2026-09-26 06:36:31','2026-09-26 06:36:31'),(155,147,91,'Paneer Pakoda','Cottage cheese fritters, crispy fried.',220.00,NULL,'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600',1,1,15,'veg,fried,snack','2026-09-26 06:36:31','2026-09-26 06:36:31'),(156,147,92,'Veg Biryani','Mixed-vegetable biryani, no onion or garlic option available.',280.00,NULL,'https://images.unsplash.com/photo-1633945274309-2a991dd7cf20?w=600',1,1,25,'biryani,veg','2026-09-26 06:36:31','2026-09-26 06:36:31'),(157,147,92,'Chukauni Set','Potato salad in a mustard-yogurt dressing with rice.',220.00,NULL,'https://images.unsplash.com/photo-1547592180-85f173990554?w=600',1,1,18,'veg,nepali','2026-09-26 06:36:31','2026-09-26 06:36:31'),(158,147,92,'Dal Bhat Set','Rice, lentils, veg curry, pickle and papad.',240.00,NULL,'https://images.unsplash.com/photo-1547592180-85f173990554?w=600',1,1,20,'thali,rice,veg','2026-09-26 06:36:31','2026-09-26 06:36:31'),(159,147,93,'Sel Roti (2 pcs)','Traditional Nepali sweet rice-flour ring bread.',80.00,NULL,'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600',1,1,10,'dessert,sweet,nepali','2026-09-26 06:36:31','2026-09-26 06:36:31'),(160,147,94,'Fresh Lime Soda','Chilled lime soda, sweet or salted.',90.00,NULL,'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=600',1,1,5,'cold,drink','2026-09-26 06:36:31','2026-09-26 06:36:31'),(161,147,94,'Masala Chiya','Spiced Nepali milk tea.',60.00,NULL,'https://images.unsplash.com/photo-1571934811356-5cc061b6821f?w=600',1,1,5,'tea,hot','2026-09-26 06:36:31','2026-09-26 06:36:31'),(162,154,95,'Veg Bytz Sekuwa','Plant-based grilled skewers with house spices.',260.00,NULL,'https://images.unsplash.com/photo-1529193591184-b1d58069ecdd?w=600',1,1,18,'vegan,grill,starter','2026-09-26 06:36:33','2026-09-26 06:36:33'),(163,154,95,'Vegan Spring Rolls','Crispy rolls stuffed with mixed vegetables.',220.00,NULL,'https://images.unsplash.com/photo-1548507200-64a1c2a30a66?w=600',1,1,12,'vegan,fried,starter','2026-09-26 06:36:33','2026-09-26 06:36:33'),(164,154,96,'Buddha Bowl','Mixed grains, greens and roasted vegetables.',300.00,NULL,'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600',1,1,15,'vegan,healthy,bowl','2026-09-26 06:36:33','2026-09-26 06:36:33'),(165,154,96,'Vegan Burger','Plant-based patty with vegan mayo and greens.',320.00,NULL,'https://images.unsplash.com/photo-1520072959219-c595dc870360?w=600',1,1,18,'vegan,burger','2026-09-26 06:36:33','2026-09-26 06:36:33'),(166,154,96,'Tofu Stir Fry','Pan-fried tofu and vegetables in a soy-ginger sauce.',280.00,NULL,'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600',1,1,18,'vegan,tofu,stirfry','2026-09-26 06:36:33','2026-09-26 06:36:33'),(167,154,97,'Vegan Chocolate Cake','Rich cocoa cake made without dairy or eggs.',220.00,NULL,'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=600',1,1,10,'vegan,dessert,sweet','2026-09-26 06:36:33','2026-09-26 06:36:33'),(168,154,98,'Green Detox Juice','Cold-pressed spinach, cucumber and apple juice.',160.00,NULL,'https://images.unsplash.com/photo-1622597467836-f3285f2131b8?w=600',1,1,8,'vegan,juice,cold','2026-09-26 06:36:33','2026-09-26 06:36:33'),(169,162,99,'Iced Latte','Espresso with cold milk over ice.',180.00,NULL,'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=600',1,1,6,'coffee,cold','2026-09-26 06:36:35','2026-09-26 06:36:35'),(170,162,99,'Cappuccino','Espresso with steamed milk foam.',160.00,NULL,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600',1,1,8,'coffee,hot','2026-09-26 06:36:35','2026-09-26 06:36:35'),(171,162,100,'Chicken Wrap','Grilled chicken, veggies and sauce in a soft tortilla.',260.00,NULL,'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=600',0,1,15,'wrap,chicken','2026-09-26 06:36:35','2026-09-26 06:36:35'),(172,162,100,'Stuffed Mushroom','Baked mushrooms stuffed with cheese and herbs.',220.00,NULL,'https://images.unsplash.com/photo-1547181093-4d84c2af9c9c?w=600',1,1,15,'veg,snack','2026-09-26 06:36:35','2026-09-26 06:36:35'),(173,162,100,'Veg Wrap','Grilled vegetables and hummus in a soft tortilla.',220.00,NULL,'https://images.unsplash.com/photo-1553909489-cd47e0907980?w=600',1,1,12,'wrap,veg','2026-09-26 06:36:35','2026-09-26 06:36:35'),(174,162,101,'Chocolate Muffin','Rich chocolate chip muffin.',120.00,NULL,'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=600',1,1,5,'bakery,dessert','2026-09-26 06:36:35','2026-09-26 06:36:35'),(175,169,102,'Strawberry Matcha Latte','Matcha latte layered with strawberry syrup.',220.00,NULL,'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=600',1,1,8,'matcha,cold','2026-09-26 06:36:37','2026-09-26 06:36:37'),(176,169,102,'Red Velvet Boba','Red velvet milk tea with tapioca pearls.',200.00,NULL,'https://images.unsplash.com/photo-1558857563-b371033873b8?w=600',1,1,8,'boba,cold','2026-09-26 06:36:37','2026-09-26 06:36:37'),(177,169,102,'Watermelon Mojito','Fresh watermelon juice with mint and lime.',190.00,NULL,'https://images.unsplash.com/photo-1546171753-97d7676e4602?w=600',1,1,8,'mocktail,cold','2026-09-26 06:36:37','2026-09-26 06:36:37'),(178,169,103,'Healthy Smoothie Bowl','Mixed berries, granola and banana over smoothie base.',260.00,NULL,'https://images.unsplash.com/photo-1490474504059-bf2db5ab2348?w=600',1,1,12,'healthy,bowl','2026-09-26 06:36:37','2026-09-26 06:36:37'),(179,169,103,'Chicken Sliders (3 pcs)','Mini burgers with grilled chicken patties.',280.00,NULL,'https://images.unsplash.com/photo-1550317138-10000687a72b?w=600',0,1,15,'sliders,chicken','2026-09-26 06:36:37','2026-09-26 06:36:37'),(180,169,103,'Club Sandwich','Triple-decker sandwich with chicken, egg and veggies.',260.00,NULL,'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=600',0,1,15,'sandwich,chicken','2026-09-26 06:36:37','2026-09-26 06:36:37'),(181,169,104,'French Toast','Golden pan-fried bread with maple syrup.',220.00,NULL,'https://images.unsplash.com/photo-1484723091739-30a097e8f929?w=600',1,1,12,'breakfast,sweet','2026-09-26 06:36:37','2026-09-26 06:36:37'),(182,175,105,'Dopio Espresso','Double shot of rich espresso.',140.00,NULL,'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=600',1,1,5,'coffee,hot','2026-09-26 06:36:39','2026-09-26 06:36:39'),(183,175,105,'Cappuccino','Espresso with steamed milk foam.',160.00,NULL,'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=600',1,1,8,'coffee,hot','2026-09-26 06:36:39','2026-09-26 06:36:39'),(184,175,105,'Iced Americano','Chilled espresso over ice.',170.00,NULL,'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=600',1,1,6,'coffee,cold','2026-09-26 06:36:39','2026-09-26 06:36:39'),(185,175,106,'Chocolate Muffin','Rich chocolate chip muffin.',120.00,NULL,'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=600',1,1,5,'bakery,dessert','2026-09-26 06:36:39','2026-09-26 06:36:39'),(186,175,106,'Butter Croissant','Flaky, buttery French croissant.',140.00,NULL,'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600',1,1,5,'bakery,pastry','2026-09-26 06:36:39','2026-09-26 06:36:39'),(187,175,107,'Grilled Cheese Sandwich','Melted cheese between toasted bread.',190.00,NULL,'https://images.unsplash.com/photo-1528736235302-52922df5c122?w=600',1,1,10,'sandwich,cheese','2026-09-26 06:36:39','2026-09-26 06:36:39');
/*!40000 ALTER TABLE `menu_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `order_items`
--

DROP TABLE IF EXISTS `order_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_items` (
  `id` int NOT NULL AUTO_INCREMENT,
  `order_id` int NOT NULL,
  `menu_item_id` int NOT NULL,
  `item_name` varchar(150) NOT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `quantity` int NOT NULL DEFAULT '1',
  `addons_json` json DEFAULT NULL,
  `item_subtotal` decimal(10,2) NOT NULL,
  `notes` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `order_id` (`order_id`),
  KEY `menu_item_id` (`menu_item_id`),
  CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`menu_item_id`) REFERENCES `menu_items` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_items`
--

LOCK TABLES `order_items` WRITE;
/*!40000 ALTER TABLE `order_items` DISABLE KEYS */;
INSERT INTO `order_items` VALUES (1,1,19,'Chicken Chilli',300.00,3,NULL,900.00,NULL),(2,2,99,'Vegan Burger',320.00,3,NULL,960.00,NULL),(3,3,99,'Vegan Burger',320.00,3,NULL,960.00,NULL),(4,4,83,'Chicken Biryani',340.00,1,NULL,340.00,NULL),(5,5,110,'Chocolate Muffin',120.00,2,NULL,240.00,NULL),(6,6,11,'Iced Lemon Tea',80.00,2,NULL,160.00,NULL),(7,7,107,'Chicken Sliders (3 pcs)',280.00,3,NULL,840.00,NULL);
/*!40000 ALTER TABLE `order_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `order_status_log`
--

DROP TABLE IF EXISTS `order_status_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_status_log` (
  `id` int NOT NULL AUTO_INCREMENT,
  `order_id` int NOT NULL,
  `status` varchar(30) NOT NULL,
  `note` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `order_id` (`order_id`),
  CONSTRAINT `order_status_log_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_status_log`
--

LOCK TABLES `order_status_log` WRITE;
/*!40000 ALTER TABLE `order_status_log` DISABLE KEYS */;
INSERT INTO `order_status_log` VALUES (1,1,'placed','Order placed — waiting for kitchen','2026-09-26 06:22:13'),(2,2,'placed','Order placed — waiting for kitchen','2026-09-26 07:01:12'),(3,2,'accepted','Accepted by kitchen','2026-09-26 07:03:33'),(4,2,'accepted','Rider #1 assigned','2026-09-26 07:03:35'),(5,1,'accepted','Accepted by kitchen','2026-09-26 07:03:49'),(6,2,'on_the_way','Rider picked up the order','2026-09-26 07:36:29'),(7,2,'delivered','Order delivered to customer','2026-09-26 07:36:33'),(8,3,'placed','Order placed — waiting for kitchen','2026-09-26 07:38:06'),(9,4,'placed','Order placed — waiting for kitchen','2026-09-26 09:01:40'),(10,4,'accepted','Accepted by kitchen','2026-09-26 09:04:09'),(11,4,'accepted','Rider #1 assigned','2026-09-26 09:04:14'),(12,3,'accepted','Accepted by kitchen','2026-09-26 09:04:34'),(13,4,'on_the_way','Rider picked up the order','2026-09-26 09:06:31'),(14,4,'delivered','Order delivered to customer','2026-09-27 02:12:43'),(15,5,'placed','Order placed — waiting for kitchen','2026-09-27 02:14:48'),(16,6,'placed','Order placed — waiting for kitchen','2026-09-27 02:16:34'),(17,6,'accepted','Accepted by kitchen','2026-09-27 02:18:17'),(18,7,'placed','Order placed — waiting for kitchen','2026-09-28 13:46:09');
/*!40000 ALTER TABLE `order_status_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `order_number` varchar(20) NOT NULL,
  `business_id` int NOT NULL,
  `user_id` int NOT NULL,
  `order_type` enum('delivery','pickup','dine_in') NOT NULL DEFAULT 'delivery',
  `status` enum('placed','accepted','cooking','on_the_way','delivered','cancelled') NOT NULL DEFAULT 'placed',
  `subtotal` decimal(10,2) NOT NULL DEFAULT '0.00',
  `delivery_fee` decimal(10,2) NOT NULL DEFAULT '0.00',
  `tax_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `discount_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `total_amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `payment_method` enum('esewa','khalti','cod') NOT NULL DEFAULT 'cod',
  `payment_status` enum('unpaid','pending','paid','failed','refunded') NOT NULL DEFAULT 'unpaid',
  `delivery_address_id` int DEFAULT NULL,
  `delivery_latitude` decimal(10,7) DEFAULT NULL,
  `delivery_longitude` decimal(10,7) DEFAULT NULL,
  `delivery_instructions` varchar(255) DEFAULT NULL,
  `table_id` int DEFAULT NULL,
  `rider_id` int DEFAULT NULL,
  `special_instructions` varchar(255) DEFAULT NULL,
  `estimated_delivery_time` datetime DEFAULT NULL,
  `placed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `accepted_at` timestamp NULL DEFAULT NULL,
  `ready_at` timestamp NULL DEFAULT NULL,
  `picked_up_at` timestamp NULL DEFAULT NULL,
  `delivered_at` timestamp NULL DEFAULT NULL,
  `cancelled_reason` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid` (`uuid`),
  UNIQUE KEY `order_number` (`order_number`),
  KEY `delivery_address_id` (`delivery_address_id`),
  KEY `idx_orders_business_status` (`business_id`,`status`),
  KEY `idx_orders_user` (`user_id`),
  KEY `idx_orders_rider` (`rider_id`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`),
  CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `orders_ibfk_3` FOREIGN KEY (`delivery_address_id`) REFERENCES `user_addresses` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `orders`
--

LOCK TABLES `orders` WRITE;
/*!40000 ALTER TABLE `orders` DISABLE KEYS */;
INSERT INTO `orders` VALUES (1,'3308c5ac-55c0-4f45-8265-75c6c12bf045','ORD037329993612',7,12,'delivery','accepted',900.00,60.00,117.00,0.00,1077.00,'cod','unpaid',4,27.6275508,83.4758808,NULL,NULL,NULL,NULL,NULL,'2026-09-26 06:22:13','2026-09-26 07:03:48',NULL,NULL,NULL,NULL,'2026-09-26 06:22:13','2026-09-26 07:03:48'),(2,'e3e5f82a-1d15-4364-940d-60b3d6139a6d','ORD060722128408',23,12,'delivery','delivered',960.00,250.00,124.80,0.00,1334.80,'esewa','unpaid',4,27.6275508,83.4758808,NULL,NULL,1,NULL,NULL,'2026-09-26 07:01:12','2026-09-26 07:03:32',NULL,'2026-09-26 07:36:29','2026-09-26 07:36:33',NULL,'2026-09-26 07:01:12','2026-09-26 07:36:33'),(3,'d75cca34-8157-4650-972d-3b68fe59128b','ORD082866128288',23,12,'delivery','accepted',960.00,150.00,124.80,0.00,1234.80,'cod','unpaid',5,27.6483047,83.4677765,NULL,NULL,NULL,NULL,NULL,'2026-09-26 07:38:06','2026-09-26 09:04:34',NULL,NULL,NULL,NULL,'2026-09-26 07:38:06','2026-09-26 09:04:34'),(4,'db668181-981b-4956-9a21-555cd6d3fc53','ORD132999485326',19,12,'delivery','delivered',340.00,50.00,44.20,0.00,434.20,'cod','paid',5,27.6483047,83.4677765,NULL,NULL,1,NULL,NULL,'2026-09-26 09:01:40','2026-09-26 09:04:08',NULL,'2026-09-26 09:06:31','2026-09-27 02:12:43',NULL,'2026-09-26 09:01:40','2026-09-27 02:12:43'),(5,'279f3c0f-2d90-47e1-bcd6-8dee1f3dc6fb','ORD752876912828',26,12,'delivery','placed',240.00,150.00,31.20,0.00,421.20,'esewa','paid',5,27.6483047,83.4677765,NULL,NULL,NULL,'ring the bell',NULL,'2026-09-27 02:14:47',NULL,NULL,NULL,NULL,NULL,'2026-09-27 02:14:47','2026-09-27 02:15:17'),(6,'ed0bbbdb-1c66-4b81-9219-6f517b396081','ORD753941451295',2,12,'delivery','accepted',160.00,350.00,20.80,0.00,530.80,'khalti','unpaid',5,27.6483047,83.4677765,NULL,NULL,NULL,NULL,NULL,'2026-09-27 02:16:34','2026-09-27 02:18:16',NULL,NULL,NULL,NULL,'2026-09-27 02:16:34','2026-09-27 02:18:16'),(7,'03b5df1c-9039-4cdc-bbcd-7ac295880679','ORD031693089895',25,12,'delivery','placed',840.00,150.00,109.20,0.00,1099.20,'cod','unpaid',5,27.6483047,83.4677765,NULL,NULL,NULL,'imahe',NULL,'2026-09-28 13:46:09',NULL,NULL,NULL,NULL,NULL,'2026-09-28 13:46:09','2026-09-28 13:46:09');
/*!40000 ALTER TABLE `orders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payments`
--

DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `reference_type` enum('order','room_booking') NOT NULL,
  `reference_id` int NOT NULL,
  `user_id` int NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `method` enum('esewa','khalti','cod') NOT NULL,
  `gateway_txn_id` varchar(100) DEFAULT NULL,
  `gateway_ref_id` varchar(100) DEFAULT NULL,
  `status` enum('initiated','pending','success','failed','refunded') NOT NULL DEFAULT 'initiated',
  `raw_response` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid` (`uuid`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payments`
--

LOCK TABLES `payments` WRITE;
/*!40000 ALTER TABLE `payments` DISABLE KEYS */;
INSERT INTO `payments` VALUES (1,'0d32a2c2-7166-4db6-bca7-b48ed432356a','order',2,12,1334.80,'esewa',NULL,NULL,'initiated',NULL,'2026-09-26 07:01:13','2026-09-26 07:01:13'),(2,'d48a19de-e0a5-4f50-a8ce-c8e1524929da','order',5,12,421.20,'esewa','000H7E1','d48a19de-e0a5-4f50-a8ce-c8e1524929da','success','{\"status\": \"COMPLETE\", \"signature\": \"eTcfKiExI5mDsbZAMv/7idahUZwImXlG4IjQMCWNGPo=\", \"product_code\": \"EPAYTEST\", \"total_amount\": \"421.2\", \"transaction_code\": \"000H7E1\", \"transaction_uuid\": \"d48a19de-e0a5-4f50-a8ce-c8e1524929da\", \"signed_field_names\": \"transaction_code,status,total_amount,transaction_uuid,product_code,signed_field_names\"}','2026-09-27 02:14:48','2026-09-27 02:15:17'),(3,'9264a08b-4cb3-4652-8c83-cb481674d1bd','order',6,12,530.80,'khalti',NULL,NULL,'initiated',NULL,'2026-09-27 02:16:35','2026-09-27 02:16:35');
/*!40000 ALTER TABLE `payments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `restaurant_tables`
--

DROP TABLE IF EXISTS `restaurant_tables`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `restaurant_tables` (
  `id` int NOT NULL AUTO_INCREMENT,
  `business_id` int NOT NULL,
  `table_number` varchar(20) NOT NULL,
  `capacity` int NOT NULL DEFAULT '2',
  `location_note` varchar(100) DEFAULT NULL,
  `status` enum('available','reserved','occupied','inactive') DEFAULT 'available',
  PRIMARY KEY (`id`),
  KEY `business_id` (`business_id`),
  CONSTRAINT `restaurant_tables_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `restaurant_tables`
--

LOCK TABLES `restaurant_tables` WRITE;
/*!40000 ALTER TABLE `restaurant_tables` DISABLE KEYS */;
/*!40000 ALTER TABLE `restaurant_tables` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reviews`
--

DROP TABLE IF EXISTS `reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reviews` (
  `id` int NOT NULL AUTO_INCREMENT,
  `business_id` int NOT NULL,
  `user_id` int NOT NULL,
  `order_id` int DEFAULT NULL,
  `rating` tinyint NOT NULL,
  `comment` varchar(500) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `business_id` (`business_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE,
  CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reviews`
--

LOCK TABLES `reviews` WRITE;
/*!40000 ALTER TABLE `reviews` DISABLE KEYS */;
/*!40000 ALTER TABLE `reviews` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rider_location_pings`
--

DROP TABLE IF EXISTS `rider_location_pings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rider_location_pings` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `rider_id` int NOT NULL,
  `order_id` int DEFAULT NULL,
  `latitude` decimal(10,7) NOT NULL,
  `longitude` decimal(10,7) NOT NULL,
  `recorded_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `rider_id` (`rider_id`),
  KEY `order_id` (`order_id`),
  CONSTRAINT `rider_location_pings_ibfk_1` FOREIGN KEY (`rider_id`) REFERENCES `riders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `rider_location_pings_ibfk_2` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rider_location_pings`
--

LOCK TABLES `rider_location_pings` WRITE;
/*!40000 ALTER TABLE `rider_location_pings` DISABLE KEYS */;
INSERT INTO `rider_location_pings` VALUES (1,1,NULL,27.6272352,83.4758228,'2026-09-26 07:03:15'),(2,1,NULL,27.6272374,83.4758200,'2026-09-26 07:03:34'),(3,1,2,27.6272315,83.4758234,'2026-09-26 07:03:49'),(4,1,2,27.6272349,83.4758218,'2026-09-26 07:04:04'),(5,1,2,27.6272327,83.4758202,'2026-09-26 07:04:19'),(6,1,2,27.6272318,83.4758204,'2026-09-26 07:04:34'),(7,1,2,27.6272322,83.4758200,'2026-09-26 07:04:49'),(8,1,2,27.6272347,83.4758150,'2026-09-26 07:05:04'),(9,1,2,27.6272328,83.4758183,'2026-09-26 07:05:19'),(10,1,2,27.6272340,83.4758218,'2026-09-26 07:05:34'),(11,1,2,27.6272399,83.4758193,'2026-09-26 07:05:49'),(12,1,2,27.6272277,83.4758247,'2026-09-26 07:06:41'),(13,1,2,27.6272317,83.4758225,'2026-09-26 07:06:56'),(14,1,2,27.6272258,83.4758265,'2026-09-26 07:07:11'),(15,1,2,27.6272329,83.4758194,'2026-09-26 07:07:26'),(16,1,2,27.6272377,83.4758087,'2026-09-26 07:07:41'),(17,1,2,27.6272337,83.4758211,'2026-09-26 07:07:56'),(18,1,2,27.6272284,83.4758200,'2026-09-26 07:08:11'),(19,1,2,27.6272314,83.4758197,'2026-09-26 07:08:26'),(20,1,2,27.6272284,83.4758229,'2026-09-26 07:36:25'),(21,1,NULL,27.6272309,83.4758220,'2026-09-26 09:03:47'),(22,1,4,27.6272309,83.4758220,'2026-09-26 09:04:21'),(23,1,4,27.6272329,83.4758252,'2026-09-26 09:04:50'),(24,1,4,27.6266277,83.4754689,'2026-09-26 09:05:03'),(25,1,4,27.6266981,83.4754013,'2026-09-26 09:05:18'),(26,1,4,27.6269700,83.4755697,'2026-09-26 09:06:19'),(27,1,4,27.6269867,83.4755596,'2026-09-26 09:06:34'),(28,1,4,27.6269823,83.4755551,'2026-09-26 09:06:49'),(29,1,4,27.6271231,83.4757040,'2026-09-26 09:07:14'),(30,1,4,27.6271231,83.4757040,'2026-09-26 09:07:18'),(31,1,NULL,27.6272355,83.4758197,'2026-09-26 10:18:59'),(32,1,4,27.6272417,83.4758130,'2026-09-26 10:19:18'),(33,1,4,27.6272325,83.4757880,'2026-09-26 10:19:32'),(34,1,4,27.6272357,83.4758210,'2026-09-26 10:19:56'),(35,1,4,27.6272357,83.4758210,'2026-09-26 10:20:00'),(36,1,4,27.6272295,83.4757943,'2026-09-26 10:20:17'),(37,1,4,27.6272307,83.4757946,'2026-09-26 10:20:31'),(38,1,4,27.6272415,83.4758174,'2026-09-26 10:20:56'),(39,1,4,27.6272415,83.4758174,'2026-09-26 10:21:00'),(40,1,NULL,27.6272282,83.4758244,'2026-09-26 14:17:34'),(41,1,4,27.6272971,83.4759047,'2026-09-26 14:20:31'),(42,1,4,27.6272469,83.4758169,'2026-09-26 14:20:49'),(43,1,4,27.6272303,83.4758228,'2026-09-26 14:21:04'),(44,1,4,27.6272335,83.4758163,'2026-09-26 14:21:19'),(45,1,4,27.6272294,83.4758191,'2026-09-26 14:21:34'),(46,1,NULL,27.6272695,83.4758197,'2026-09-27 02:12:19'),(47,1,4,27.6272767,83.4758240,'2026-09-27 02:12:38');
/*!40000 ALTER TABLE `rider_location_pings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `riders`
--

DROP TABLE IF EXISTS `riders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `riders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `vehicle_type` enum('bike','scooter','bicycle','car') DEFAULT 'bike',
  `vehicle_number` varchar(30) DEFAULT NULL,
  `license_number` varchar(50) DEFAULT NULL,
  `status` enum('offline','available','busy') NOT NULL DEFAULT 'offline',
  `current_latitude` decimal(10,7) DEFAULT NULL,
  `current_longitude` decimal(10,7) DEFAULT NULL,
  `rating` decimal(3,2) DEFAULT '5.00',
  `total_deliveries` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  KEY `idx_riders_status` (`status`),
  CONSTRAINT `riders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `riders`
--

LOCK TABLES `riders` WRITE;
/*!40000 ALTER TABLE `riders` DISABLE KEYS */;
INSERT INTO `riders` VALUES (1,38,'bike','112233',NULL,'offline',27.6272767,83.4758240,5.00,2,'2026-09-26 07:02:34'),(2,39,'bike','112233',NULL,'offline',NULL,NULL,5.00,0,'2026-09-26 07:06:11');
/*!40000 ALTER TABLE `riders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `room_bookings`
--

DROP TABLE IF EXISTS `room_bookings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `room_bookings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `business_id` int NOT NULL,
  `room_id` int NOT NULL,
  `user_id` int NOT NULL,
  `guest_name` varchar(150) NOT NULL,
  `guest_phone` varchar(20) NOT NULL,
  `check_in` date NOT NULL,
  `check_out` date NOT NULL,
  `num_guests` int DEFAULT '1',
  `nights` int NOT NULL,
  `price_per_night` decimal(10,2) NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `payment_method` enum('esewa','khalti','cod') NOT NULL DEFAULT 'cod',
  `payment_status` enum('unpaid','pending','paid','failed','refunded') NOT NULL DEFAULT 'unpaid',
  `status` enum('pending','confirmed','checked_in','checked_out','cancelled') DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid` (`uuid`),
  KEY `business_id` (`business_id`),
  KEY `user_id` (`user_id`),
  KEY `idx_room_bookings_room_dates` (`room_id`,`check_in`,`check_out`),
  CONSTRAINT `room_bookings_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`),
  CONSTRAINT `room_bookings_ibfk_2` FOREIGN KEY (`room_id`) REFERENCES `rooms` (`id`),
  CONSTRAINT `room_bookings_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `room_bookings`
--

LOCK TABLES `room_bookings` WRITE;
/*!40000 ALTER TABLE `room_bookings` DISABLE KEYS */;
/*!40000 ALTER TABLE `room_bookings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rooms`
--

DROP TABLE IF EXISTS `rooms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rooms` (
  `id` int NOT NULL AUTO_INCREMENT,
  `business_id` int NOT NULL,
  `room_number` varchar(20) NOT NULL,
  `room_type` varchar(50) NOT NULL DEFAULT 'Standard',
  `description` text,
  `price_per_night` decimal(10,2) NOT NULL,
  `capacity` int DEFAULT '2',
  `image_url` varchar(255) DEFAULT NULL,
  `amenities` varchar(255) DEFAULT NULL,
  `status` enum('available','maintenance','inactive') DEFAULT 'available',
  PRIMARY KEY (`id`),
  KEY `business_id` (`business_id`),
  CONSTRAINT `rooms_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rooms`
--

LOCK TABLES `rooms` WRITE;
/*!40000 ALTER TABLE `rooms` DISABLE KEYS */;
INSERT INTO `rooms` VALUES (1,3,'101','Standard','Cozy room with a queen bed and city view.',2200.00,2,'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600','WiFi,TV,AC,Hot water','available'),(2,3,'102','Deluxe','Spacious room with river view and mini fridge.',3200.00,2,'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=600','WiFi,TV,AC,Mini-fridge,River view','available'),(3,3,'201','Suite','Suite with a separate living area and balcony.',5500.00,4,'https://images.unsplash.com/photo-1591088398332-8a7791972843?w=600','WiFi,TV,AC,Balcony,Bathtub','available'),(4,5,'G1','Standard','Simple room with a double bed, shared bathroom.',1200.00,2,'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600','WiFi,Fan,Shared bath','available'),(5,5,'G2','Family','Larger room with two beds, attached bathroom.',1800.00,4,'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600','WiFi,Fan,Attached bath','available'),(6,9,'101','Standard','Comfortable room with garden view.',2500.00,2,'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600','WiFi,TV,AC,Hot water','available'),(7,9,'102','Deluxe Lake View','Room with a private balcony facing Phewa Lake.',4200.00,2,'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=600','WiFi,TV,AC,Balcony,Lake view','available'),(8,9,'201','Family Suite','Two-room suite for families, sleeps 4.',6500.00,4,'https://images.unsplash.com/photo-1591088398332-8a7791972843?w=600','WiFi,TV,AC,Bathtub,Kitchenette','available'),(9,10,'G1','Standard','Simple room with a double bed, shared bathroom.',1000.00,2,'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600','WiFi,Fan,Shared bath','available'),(10,10,'G2','Single','Compact room with a single bed.',700.00,1,'https://images.unsplash.com/photo-1505692794403-34d4982f88aa?w=600','WiFi,Fan','available'),(11,10,'G3','Family','Larger room with two beds, attached bathroom.',1600.00,4,'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600','WiFi,Fan,Attached bath','available'),(12,55,'101','Standard','Comfortable room with garden view.',2500.00,2,'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600','WiFi,TV,AC,Hot water','available'),(13,55,'102','Deluxe Lake View','Room with a private balcony facing Phewa Lake.',4200.00,2,'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=600','WiFi,TV,AC,Balcony,Lake view','available'),(14,55,'201','Family Suite','Two-room suite for families, sleeps 4.',6500.00,4,'https://images.unsplash.com/photo-1591088398332-8a7791972843?w=600','WiFi,TV,AC,Bathtub,Kitchenette','available'),(15,12,'G1','Standard','Simple room with a double bed, shared bathroom.',1000.00,2,'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600','WiFi,Fan,Shared bath','available'),(16,12,'G2','Single','Compact room with a single bed.',700.00,1,'https://images.unsplash.com/photo-1505692794403-34d4982f88aa?w=600','WiFi,Fan','available'),(17,12,'G3','Family','Larger room with two beds, attached bathroom.',1600.00,4,'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600','WiFi,Fan,Attached bath','available');
/*!40000 ALTER TABLE `rooms` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `table_bookings`
--

DROP TABLE IF EXISTS `table_bookings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `table_bookings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `business_id` int NOT NULL,
  `table_id` int DEFAULT NULL,
  `user_id` int NOT NULL,
  `guest_name` varchar(150) NOT NULL,
  `guest_phone` varchar(20) NOT NULL,
  `party_size` int NOT NULL DEFAULT '2',
  `booking_date` date NOT NULL,
  `booking_time` time NOT NULL,
  `status` enum('pending','confirmed','seated','completed','cancelled','no_show') DEFAULT 'pending',
  `special_request` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid` (`uuid`),
  KEY `table_id` (`table_id`),
  KEY `user_id` (`user_id`),
  KEY `idx_table_bookings_biz_date` (`business_id`,`booking_date`),
  CONSTRAINT `table_bookings_ibfk_1` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`),
  CONSTRAINT `table_bookings_ibfk_2` FOREIGN KEY (`table_id`) REFERENCES `restaurant_tables` (`id`) ON DELETE SET NULL,
  CONSTRAINT `table_bookings_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `table_bookings`
--

LOCK TABLES `table_bookings` WRITE;
/*!40000 ALTER TABLE `table_bookings` DISABLE KEYS */;
/*!40000 ALTER TABLE `table_bookings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_addresses`
--

DROP TABLE IF EXISTS `user_addresses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_addresses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `label` varchar(50) DEFAULT 'Home',
  `address_line` varchar(255) NOT NULL,
  `city` varchar(100) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `is_default` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `user_addresses_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_addresses`
--

LOCK TABLES `user_addresses` WRITE;
/*!40000 ALTER TABLE `user_addresses` DISABLE KEYS */;
INSERT INTO `user_addresses` VALUES (4,12,'Home','Kedarnath Path, Tilottama-05, Manigram, Tilottama, Rupandehi, Lumbini Province, 32903, Nepal','Manigram',27.6275508,83.4758808,0,'2026-09-26 06:22:08'),(5,12,'Home','Drivertole','Butwal',27.6483047,83.4677765,1,'2026-09-26 07:38:02');
/*!40000 ALTER TABLE `user_addresses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `uuid` char(36) NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `email` varchar(150) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('customer','business_owner','staff','rider','super_admin') NOT NULL DEFAULT 'customer',
  `avatar_url` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `is_verified` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uuid` (`uuid`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `phone` (`phone`)
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'6f09b5ab-b96e-11f1-8789-9696ace701e2','Himalayan Spice Owner','owner.himalayanspice@example.com','9800000001','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:52:18','2026-09-26 05:52:18'),(2,'c5410c3a-b96e-11f1-8789-9696ace701e2','Spice Junction Owner','owner.spicejunction@example.com','9800000002','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:54:43','2026-09-26 05:54:43'),(3,'c6b614dc-b96e-11f1-8789-9696ace701e2','Ganga Vista Owner','owner.gangavista@example.com','9800000003','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:54:45','2026-09-26 05:54:45'),(4,'c7594079-b96e-11f1-8789-9696ace701e2','Bean & Brew Owner','owner.beanbrew@example.com','9800000004','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:54:46','2026-09-26 05:54:46'),(5,'c893de15-b96e-11f1-8789-9696ace701e2','Mountain View Owner','owner.mountainview@example.com','9800000005','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:54:48','2026-09-26 05:54:48'),(6,'c97e8358-b96e-11f1-8789-9696ace701e2','Everest Bites Owner','owner.everestbites@example.com','9800000006','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:54:50','2026-09-26 05:54:50'),(7,'3462513e-b96f-11f1-8789-9696ace701e2','Butwal Bazaar Owner','owner.butwalbazaar@example.com','9800000007','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:57:49','2026-09-26 05:57:49'),(8,'36812f57-b96f-11f1-8789-9696ace701e2','Thamel Coffee Owner','owner.thamelcoffee@example.com','9800000008','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:57:53','2026-09-26 05:57:53'),(9,'38750b37-b96f-11f1-8789-9696ace701e2','Lakeside Heritage Owner','owner.lakesideheritage@example.com','9800000009','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:57:56','2026-09-26 05:57:56'),(10,'392d9b8f-b96f-11f1-8789-9696ace701e2','Rapti Guest House Owner','owner.raptiguesthouse@example.com','9800000010','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:57:57','2026-09-26 05:57:57'),(11,'39ea5d2a-b96f-11f1-8789-9696ace701e2','Koshi Delights Owner','owner.koshidelights@example.com','9800000011','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 05:57:58','2026-09-26 05:57:58'),(12,'c2831ff6-52f1-4462-84d0-3758b91b8bbd','Image User','image@gmail.com','9879645263','$2a$10$VeKh6yT2z2i5uTwoevQpOuGoPnr/lY42V2dm9xYBfmSGnTEA23LTu','customer',NULL,1,0,'2026-09-26 05:59:57','2026-09-26 05:59:57'),(18,'ceb56750-b973-11f1-8789-9696ace701e2','El Dorado Owner','owner.eldorado@example.com','9800000012','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:30:46','2026-09-26 06:30:46'),(19,'cfde1b6c-b973-11f1-8789-9696ace701e2','Soulmate Restaurant Owner','owner.soulmate@example.com','9800000013','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:30:48','2026-09-26 06:30:48'),(20,'d105b4cb-b973-11f1-8789-9696ace701e2','Daddys Kitchen Owner','owner.daddyskitchen@example.com','9800000014','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:30:50','2026-09-26 06:30:50'),(21,'d24eaa4f-b973-11f1-8789-9696ace701e2','Grassland Nepal Owner','owner.grassland@example.com','9800000015','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:30:52','2026-09-26 06:30:52'),(22,'d3763ff1-b973-11f1-8789-9696ace701e2','Hide Out Restro Owner','owner.hideout@example.com','9800000016','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:30:54','2026-09-26 06:30:54'),(23,'d49daa1e-b973-11f1-8789-9696ace701e2','Butwal Veg Vegan Owner','owner.butwalveg@example.com','9800000017','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:30:56','2026-09-26 06:30:56'),(24,'d5c3008b-b973-11f1-8789-9696ace701e2','Good DO Owner','owner.gooddo@example.com','9800000018','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:30:58','2026-09-26 06:30:58'),(25,'d6e9154b-b973-11f1-8789-9696ace701e2','Cloud 9 Cafe Owner','owner.cloud9@example.com','9800000019','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:31:00','2026-09-26 06:31:00'),(26,'d7f1ee20-b973-11f1-8789-9696ace701e2','Papaya Butwal Owner','owner.papaya@example.com','9800000020','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:31:02','2026-09-26 06:31:02'),(27,'d8faa869-b973-11f1-8789-9696ace701e2','Caffeine Cup Owner','owner.caffeinecup@example.com','9800000021','$2b$10$CwTycUXWue0Thq9StjUM0uJ8v2f/PMBWXi4V4mHtCSFY7ZTqK.6Vu','business_owner',NULL,1,1,'2026-09-26 06:31:03','2026-09-26 06:31:03'),(38,'e430e370-c2a6-4c3c-ab3f-f3668c28eb1a','Test Ryder','ryder@gmail.com','98707557589','$2a$10$jyCqoPNxQ0QALiHj4fK6CuSuVzDEHXQiyV7xVk76Bp5tyowd7KZ6a','rider',NULL,1,0,'2026-09-26 07:02:34','2026-09-26 07:02:34'),(39,'67903c0c-5047-428a-a28f-5da1f262ca63','Ram Ryder','ryderram@gmail.com','997769689698','$2a$10$oCenBkmHm8c1yVIkp6WMVuS7etp5ZEvFcKYLTYuGsdOWl7HuGRp26','rider',NULL,1,0,'2026-09-26 07:06:11','2026-09-26 07:06:11'),(45,'6c6d870e-b97b-11f1-8789-9696ace701e2','Super Admin','admin@gmail.com','9800000000','$2b$10$fxDEsjMqryl8jktSAl2Qi.NvL20U1jB2XMFDXla50p1Q/3U8LruYy','super_admin',NULL,1,1,'2026-09-26 07:25:17','2026-09-26 07:25:17'),(46,'3d0a14c9-be87-40dc-bcfe-b70102f9bbcf','Basil Bashyal','lilhappyhelper@gmail.com','9826425806','$2a$10$nSsOA9uyVyL7k2ewzKhVlOqUhut4Hi0Qi8TzDWDk/JVxtNawEQOxm','customer',NULL,1,0,'2026-09-28 13:35:48','2026-09-28 13:35:48');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-28 20:04:56

-- Push notification device tokens (FCM). One user can have many devices.
CREATE TABLE IF NOT EXISTS `device_tokens` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `token` varchar(512) NOT NULL,
  `platform` enum('android','ios','web') NOT NULL DEFAULT 'android',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_token` (`token`(255)),
  KEY `idx_device_user` (`user_id`),
  CONSTRAINT `device_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
