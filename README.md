
## Technologies
- JDK 11
- Maven 3
- MySQL 8
- Spring MVC
- Spring Security
- Spring Data JPA
- JSP
- Tomcat
- Memcached
- RabbitMQ
- ElasticSearch

# Database
Here, we used MySQL DB.  

SQL dump file:  
- `/src/main/resources/db_backup.sql`  

`db_backup.sql` is a MySQL dump file. We have to import this dump into the MySQL DB server:  
```bash
mysql -u <user_name> -p accounts < db_backup.sql
