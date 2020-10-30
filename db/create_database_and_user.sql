create database if not exists trackability;
create user if not exists 'trackability'@'localhost' IDENTIFIED BY 'N8XlkiQStUk7rZHoo1';
grant all privileges on trackability.* to 'trackability'@'localhost';
flush privileges;
