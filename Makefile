export ROOT_DIR=$(shell pwd)
export CURRENT_UID=$(shell id -u)
export CURRENT_GID=$(shell id -g)
export CPU_COUNT=$(nproc)

ifneq (,$(wildcard ./.env))
    include .env
    export
endif

up:
	docker-compose up -d

down:
	docker-compose down

install-local:
	composer create-project laravel/laravel src
	cp -a ./src/. ./
	rm -rf ./src
	cp .env.dev .env
	docker-compose build --no-cache
	docker-compose up -d
	docker-compose exec app composer install
	sudo chown -R $USER:$USER ./
	sudo chmod -R 777 ./storage/logs
	sudo chmod -R 777 ./storage/framework
	docker-compose exec app php artisan key:generate
	docker-compose exec app php artisan migrate

install-local-without-compose:
	docker run --rm -u=$(CURRENT_UID):$(CURRENT_GID) -v=$(ROOT_DIR):/app --workdir=/app composer:latest create-project laravel/laravel src
	cp -a ./src/. ./
	rm -rf ./src
	cp .env.dev .env
	docker run --rm -v=$(ROOT_DIR):/app --workdir=/app composer:2.1 install
	sudo chown -R $USER:$USER ./
	docker network create qle
	#- PHP8
	docker build -t --no-cache qle/app:v1.0 -f ./.docker/app.dockerfile ./.docker
	docker run -d --name app -ti --network qle --workdir=/var/www/ -v $(ROOT_DIR):/var/www qle/app:v1.0
	# - Nginx
	docker run -d --name web -ti --network qle -p 8000:80 -v $(ROOT_DIR)/.docker/vhost.conf:/etc/nginx/conf.d/default.conf  -v $(ROOT_DIR):/var/www nginx:stable-alpine
	#- Redis 6
	docker run -d --name redis --network qle -p 6379:6379 -ti -d redis:6.0-alpine
	#- Mysql 5.7
	docker run -d --name db -ti --network qle \
 		-e MYSQL_DATABASE=$(DB_DATABASE) \
 		-e MYSQL_ROOT_PASSWORD=$(DB_ROOT_PASSWORD) \
 		-e MYSQL_PASSWORD=$(DB_PASSWORD) \
 		-e MYSQL_USER=$(DB_USERNAME) \
 		 mysql:5.7
	#firs init
	sudo chown -R $(CURRENT_UID):$(CURRENT_GID) ./
	sudo chmod -R 777 ./storage/logs
	sudo chmod -R 777 ./storage/framework
	docker exec app php artisan key:generate
