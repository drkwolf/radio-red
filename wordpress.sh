docker-compose exec libretime-core apt update
docker-compose exec libretime-core apt install -yq php-mysql

docker-compose exec libretime-core a2enmod substitute
docker-compose exec libretime-core /etc/init.d/apache2 restart

