#export ROOT_DIR=$(PWD)
#export CURRENT_UID=$(shell id -u)
#export CURRENT_GID=$(shell id -g)

up:
	docker-compose up -d

down:
	docker-compose down

install-dev:
	sudo chown -R $USER:$USER ./
	cp .env.dev .env
	docker-compose build
	#docker run --rm -u=$(CURRENT_UID):$(CURRENT_GID) -v=$(ROOT_DIR):/app --workdir=/app composer:2.1 install
	docker-compose exec app composer install
