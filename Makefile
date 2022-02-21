export ROOT_DIR=$(PWD)
export CURRENT_UID=$(shell id -u)
export CURRENT_GID=$(shell id -g)
#export APP_NAME=env('APP_NAME')

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
	composer create-project laravel/laravel src
	#сделать APP_KEY в env
	cp -a ./src/. ./
	rm -rf ./src
	cp .env.dev .env
	docker run --rm -v $(pwd):/app --workdir=/app composer:2.1 install
	#docker run --rm -v /home/tumbler/PhpstormProjects/quick-laravel-env210222:/app --workdir=/app composer:2.1 install
	sudo chown -R $USER:$USER ./
	docker network create qle
	#- PHP 8 (Laravel 8)
	docker run -d --name app -ti --network qle -e MYSQL_ROOT_PASSWORD=drowpass --workdir=/app -v /home/tumbler/PhpstormProjects/quick-laravel-env210222:/app php:8.0-fpm
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
	docker exec app docker-php-ext-install pdo_mysql -j 4 gd
	#- Mysql 5.7
	docker run -d --name db -ti --network qle -e MYSQL_ROOT_PASSWORD=drowpass -v dbdata:/var/lib/mysql mysql:5.7
	#docker exec app php artisan migrate
	# - Nginx
	docker run -d --name web -ti --network qle -p 8000:80 -v /home/tumbler/PhpstormProjects/quick-laravel-env210222/.docker/vhost.conf:/etc/nginx/conf.d/default.conf  -v /home/tumbler/PhpstormProjects/quick-laravel-env210222:/var/www --workdir=/var/www nginx:stable-alpine
	#- Redis 6
	#docker run -d --name redis -p 6379:6379-ti -d redis:6.0-alpine

