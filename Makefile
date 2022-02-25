export ROOT_DIR=$(shell pwd)
export CURRENT_UID=$(shell id -u)
export CURRENT_GID=$(shell id -g)
export CPU_COUNT=$(nproc)

ifneq (,$(wildcard ./.env))
    include .env
    export
endif

test:
	docker stop quick-laravel-env
	docker rm quick-laravel-env
	docker run -d --name quick-laravel-env -ti -v "$PWD":/app --workdir=/app --network host ubuntu:20.04
	docker exec quick-laravel-env apt update
	docker exec quick-laravel-env apt install -y software-properties-common
	docker exec quick-laravel-env add-apt-repository ppa:ondrej/php
	docker exec quick-laravel-env apt update
	docker exec quick-laravel-env apt install -y php8.0
	docker exec quick-laravel-env php artisan key:generate
	docker exec quick-laravel-env php artisan serve

test2:
	docker build -t qle/app:v1.0 -f ./.docker/app.dockerfile ./.docker
	docker build -t qle/app:v1.0 -f ./.docker/app.dockerfile ./.docker
	docker build -t qle/nginx:v1.0 -f ./.docker/web.dockerfile ./.docker

up:
	docker-compose up -d

down:
	docker-compose down

install-dev:
	composer create-project laravel/laravel src
	cp -a ./src/. ./
	rm -rf ./src
	cp .env.dev .env
	#docker run --rm -u=$(CURRENT_UID):$(CURRENT_GID) -v=$(ROOT_DIR):/src --workdir=/app composer:2.1 install
	docker-compose build --no-cache
	docker-compose up -d
	docker-compose exec app composer install
	sudo chown -R $USER:$USER ./
	sudo chmod -R 777 ./storage/logs
	sudo chmod -R 777 ./storage/framework
	docker-compose exec app php artisan key:generate
	docker-compose exec app php artisan migrate

install-without-compose:
	docker run --rm -u=$(CURRENT_UID):$(CURRENT_GID) -v=$(ROOT_DIR):/app --workdir=/app composer:latest create-project laravel/laravel src
	cp -a ./src/. ./
	rm -rf ./src
	cp .env.dev .env
	docker run --rm -v=$(ROOT_DIR):/app --workdir=/app composer:2.1 install
	sudo chown -R $USER:$USER ./
	docker network create qle
	#- PHP8
	docker run -d --name app -ti --network qle --workdir=/var/www/ -v $(ROOT_DIR):/var/www php:8.0-fpm
	docker exec app apt update
	docker exec app apt install -y  \
    	git \
    	libfreetype6-dev \
    	libjpeg-dev \
    	libpng-dev \
    	libwebp-dev \
    	libwebp-dev \
		--no-install-recommends
	docker exec app docker-php-ext-configure gd --with-freetype --with-jpeg
	docker exec app docker-php-ext-install pdo_mysql --jobs=$(CPU_COUNT) gd
	#- Mysql 5.7
	docker run -d --name db -ti --network qle -e MYSQL_ROOT_PASSWORD=$(DB_ROOT_PASSWORD) -v dbdata:/var/lib/mysql mysql:5.7
	# - Nginx
	docker run -d --name web -ti --network qle -p 8000:80 -v $(ROOT_DIR)/.docker/vhost.conf:/etc/nginx/conf.d/default.conf  -v $(ROOT_DIR):/var/www nginx:stable-alpine
	#- Redis 6
	docker run -d --name redis --network qle -p 6379:6379 -ti -d redis:6.0-alpine
	#init
	sudo chown -R $(CURRENT_UID):$(CURRENT_GID) ./
	sudo chmod -R 777 ./storage/logs
	sudo chmod -R 777 ./storage/framework
	docker exec app php artisan key:generate
	#db don't working
	#docker exec app php artisan migrate

db:
	docker stop db2
	docker rm db2
	docker run -d --name db2 -ti --network qle -e MYSQL_ROOT_PASSWORD=$(DB_ROOT_PASSWORD) -v dbdata:/var/lib/mysql mysql:5.7
	docker exec -ti db2 CREATE DATABASE $(DB_DATABASE);
	docker exec -ti db2 CREATE USER $(DB_USER) WITH PASSWORD $(DB_PASSWORD);
	docker exec -ti db2 GRANT ALL PRIVILEGES ON $(DB_DATABASE).* TO $(DB_USER)@'localhost';
	docker exec -ti db2 FLUSH PRIVILEGES
