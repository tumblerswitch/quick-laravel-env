#export ROOT_DIR=$(PWD)
#export CURRENT_UID=$(shell id -u)
#export CURRENT_GID=$(shell id -g)

up:
	docker-compose up -d

down:
	docker-compose down

install-dev:
	composer create-project laravel/laravel src
	cp -a ./src/. ./
	rm -rf ./src
	sudo chown -R $USER:$USER ./
	cp .env.dev ./src/.env
	#docker run --rm -u=$(CURRENT_UID):$(CURRENT_GID) -v=$(ROOT_DIR):/src --workdir=/app composer:2.1 install
	docker-compose build --no-cache
	docker-compose up -d
	docker-compose exec app composer install
	sudo chmod -R 777 ./storage/logs
	sudo chmod -R 777 ./storage/framework
	docker-compose exec app php artisan key:generate
	docker-compose exec app php artisan migrate
