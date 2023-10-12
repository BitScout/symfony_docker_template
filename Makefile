.PHONY: help install data-reset test php-static php-fix lint-twig shell-php shell-nginx infra-up infra-down, infra-nuke, deploy-prod

help: ## Show help
	@grep'^[^#[:space:]].*:' Makefile

db-reset: ## Nuke the database, recreate it and add fixtures
	@echo -n "DELETE THE DATABASE AND RECREATE WITH FIXTURES - Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	docker-compose exec php-fpm bin/console doctrine:database:drop --force
	docker-compose exec php-fpm bin/console doctrine:database:create
	docker-compose exec php-fpm bin/console doctrine:migrations:migrate --no-interaction
    # docker-compose exec php-fpm bin/console doctrine:fixtures:load --no-interaction

db-diff: ## Generate database migration
	docker-compose exec php-fpm bin/console doctrine:migration:diff

deploy-prod: ## Deploy to PROD env
	docker-compose exec php-fpm vendor/bin/dep deploy stage=prod -vv

install: ## Install packages
	docker-compose exec php-fpm composer install

cache-clear: ## Clear the cache
	docker-compose exec php-fpm bin/console cache:clear

lint-twig: ## Lint twig files
	docker-compose exec php-fpm bin/console lint:twig templates

shell-php: ## Open a shell in the PHP container
	docker exec -it my_symfony_project_php-fpm_1 /bin/bash

shell-nginx: ## Open a shell in the web server container
	docker exec -it my_symfony_project_nginx_1 /bin/sh

shell-db: ## Open a shell in the database server container
	docker exec -it my_symfony_project_database_1 /bin/sh

infra-up: ## Docker-compose UP
	docker-compose up -d

infra-down: ## Docker-compose DOWN
	docker-compose down

infra-nuke: ## DELETE ALL DOCKER CONTAINERS AND IMAGES
	@echo -n "DELETE ALL DOCKER CONTAINERS AND IMAGES - Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	docker stop $$(docker ps -a -q)
	docker rm $$(docker ps -a -q)
	docker rmi $$(docker images -a -q)

php-static: ## Run phpstan
	docker-compose exec php-fpm vendor/bin/phpstan analyse -l 5 src tests

php-fix: ## Fix PHP code style
	docker-compose exec php-fpm php tools/php-cs-fixer/vendor/bin/php-cs-fixer fix --allow-risky=yes

test: ## Run unit tests
	docker-compose exec php-fpm php ./vendor/bin/phpunit
