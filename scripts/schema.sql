/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `device_types` (
  `id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `description` varchar(255) DEFAULT NULL,
  `features` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `firmware` (
  `id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `description` varchar(255) NOT NULL,
  `hash` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nodes` (
  `id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `location` varchar(255) DEFAULT NULL,
  `device_type_id` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_device_type_id` (`device_type_id`),
  CONSTRAINT `fk_device_type_id` FOREIGN KEY (`device_type_id`) REFERENCES `device_types` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sensor_data` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `node_id` smallint(5) unsigned NOT NULL,
  `node_ms` int(10) unsigned NOT NULL,
  `light` tinyint(3) unsigned DEFAULT '0',
  `humidity` float(4,1) DEFAULT NULL,
  `temperature` float(4,1) DEFAULT NULL,
  `battery` float(3,2) DEFAULT '0.00',
  `status` tinyint(3) unsigned NOT NULL,
  `msg_id` int(10) unsigned DEFAULT '0',
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `node_id` (`node_id`),
  CONSTRAINT `sensor_data_ibfk_1` FOREIGN KEY (`node_id`) REFERENCES `nodes` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1982909 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stations` (
  `id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `code` varchar(8) DEFAULT NULL,
  `name` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `weather_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `last_updated` varchar(24) NOT NULL,
  `temperature` tinyint(4) NOT NULL,
  `humidity` tinyint(3) unsigned NOT NULL,
  `visibility` float(4,1) NOT NULL,
  `pressure` float(6,2) NOT NULL,
  `feels_like` tinyint(4) NOT NULL,
  `direction` smallint(6) NOT NULL,
  `speed` tinyint(3) unsigned NOT NULL,
  `gust` tinyint(3) unsigned NOT NULL,
  `icon` tinyint(3) unsigned NOT NULL,
  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `station_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `fk_station_id` (`station_id`),
  CONSTRAINT `fk_station_id` FOREIGN KEY (`station_id`) REFERENCES `stations` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4178 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
CREATE TABLE `batteries` (
  `id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `description` varchar(64) NOT NULL,
  `type` varchar(16) NOT NULL,
  `first_id` int(10) unsigned NOT NULL,
  `last_id` int(10) unsigned NOT NULL,
  `count` int(10) NOT NULL,
  `firmware_id` smallint(5) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_first_id` (`first_id`),
  KEY `fk_last_id` (`last_id`),
  KEY `fk_firmware_id` (`firmware_id`),
  CONSTRAINT `fk_first_id` FOREIGN KEY (`first_id`) REFERENCES `sensor_data` (`id`),
  CONSTRAINT `fk_last_id` FOREIGN KEY (`last_id`) REFERENCES `sensor_data` (`id`),
  CONSTRAINT `fk_firmware_id` FOREIGN KEY (`firmware_id`) REFERENCES `firmware` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
