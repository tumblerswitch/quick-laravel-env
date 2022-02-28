# Quick laravel environment with docker
- PHP 8 (Laravel 8)
- Mysql 5.7
- Redis 6
- Nginx

## Requirements
1. Docker
2. Docker-compose
3. Composer

## Local install
1. git clone project
2. cd project
2. run ```make install-local``` (preferably) or ```install-local-without-compose```
3. run ```docker exec app php artisan migrate```

## Follow-up launch
1. cd project dir
2. ```docker-compose up -d```
