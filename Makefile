ifeq (,$(wildcard .env))
$(error .env file not found)
endif

include .env
export $(shell sed 's/=.*//' .env)



build-and-push-dev:
	make build-and-push-auth-dev
	make build-and-push-events-dev
	make build-and-push-tickets-dev

build-and-push-auth-dev:
	IMAGE_TAG=dev PHP_IMAGE_TARGET=dev make build-and-push-auth

build-and-push-auth:
	docker build --file=../auth/docker/jobber/Dockerfile --tag=dzhuryn/ticketing-auth-jobber:${IMAGE_TAG} --platform linux/amd64 ../auth
	docker push dzhuryn/ticketing-auth-jobber:${IMAGE_TAG}

	docker build --file=../auth/docker/php/Dockerfile --tag=dzhuryn/ticketing-auth-php:${IMAGE_TAG} --platform linux/amd64 --target ${PHP_IMAGE_TARGET} ../auth
	docker push dzhuryn/ticketing-auth-php:${IMAGE_TAG}

	docker build --file=../auth/docker/nginx/Dockerfile --tag=dzhuryn/ticketing-auth-webserver:${IMAGE_TAG} --platform linux/amd64  --build-arg PHP_CONTAINER=dzhuryn/ticketing-auth-php:dev ../auth
	docker push dzhuryn/ticketing-auth-webserver:${IMAGE_TAG}

build-and-push-events-dev:
	IMAGE_TAG=dev PHP_IMAGE_TARGET=dev make build-and-push-events

build-and-push-events:
	docker build --file=../events/docker/jobber/Dockerfile --tag=dzhuryn/ticketing-events-jobber:${IMAGE_TAG} --platform linux/amd64 ../events
	docker push dzhuryn/ticketing-events-jobber:${IMAGE_TAG}

	docker build --file=../events/docker/php/Dockerfile --tag=dzhuryn/ticketing-events-php:${IMAGE_TAG} --platform linux/amd64 --target ${PHP_IMAGE_TARGET} ../events
	docker push dzhuryn/ticketing-events-php:${IMAGE_TAG}

	docker build --file=../events/docker/nginx/Dockerfile --tag=dzhuryn/ticketing-events-webserver:${IMAGE_TAG} --platform linux/amd64 --build-arg PHP_CONTAINER=dzhuryn/ticketing-events-php:${IMAGE_TAG} ../events
	docker push dzhuryn/ticketing-events-webserver:${IMAGE_TAG}

build-and-push-tickets-dev:
	IMAGE_TAG=dev PHP_IMAGE_TARGET=dev make build-and-push-tickets

build-and-push-tickets:
	docker build --file=../tickets/docker/jobber/Dockerfile --tag=dzhuryn/ticketing-tickets-jobber:${IMAGE_TAG} --platform linux/amd64 ../tickets
	docker push dzhuryn/ticketing-tickets-jobber:${IMAGE_TAG}

	docker build --file=../tickets/docker/php/Dockerfile --tag=dzhuryn/ticketing-tickets-php:${IMAGE_TAG} --platform linux/amd64 --target ${PHP_IMAGE_TARGET} ../tickets
	docker push dzhuryn/ticketing-tickets-php:${IMAGE_TAG}

	docker build --file=../tickets/docker/nginx/Dockerfile --tag=dzhuryn/ticketing-tickets-webserver:${IMAGE_TAG} --platform linux/amd64 --build-arg PHP_CONTAINER=dzhuryn/ticketing-tickets-php:${IMAGE_TAG} ../tickets
	docker push dzhuryn/ticketing-tickets-webserver:${IMAGE_TAG}

deploy-init:
	make deploy-init-auth
	make deploy-init-events
	make deploy-init-tickets

deploy-init-auth:
	docker-compose exec auth_php bin/console doctrine:database:create --no-interaction
deploy-init-events:
	docker-compose exec events_php bin/console doctrine:database:create --no-interaction

deploy-init-tickets:
	docker-compose exec tickets_php bin/console doctrine:database:create --no-interaction

deploy-dev:
	make deploy-auth-dev
	make deploy-events-dev
	make deploy-tickets-dev

deploy-dev-update:
	docker-compose pull
	docker-compose down gateway
	docker-compose up -d
deploy-auth-dev:
	make deploy-dev-update
	docker-compose exec auth_php bin/console doctrine:migrations:migrate --no-interaction
	docker-compose exec auth_php bin/console doctrine:fixtures:load --no-interaction

deploy-events-dev:
	make deploy-dev-update
	docker-compose exec events_php bin/console doctrine:migrations:migrate --no-interaction

deploy-tickets-dev:
	make deploy-dev-update
	docker-compose exec tickets_php bin/console doctrine:migrations:migrate --no-interaction

init-local:
	make generate-ssl
	make generate-jwt-keys
	bin/docker up -d
	make init-rabbitmq
	make init-auth
	make init-events
	make init-attendance
	make init-tickets

init-auth:
	docker-compose exec  auth_php bash -c "bin/console doctrine:database:create --if-not-exists && \
	bin/console doctrine:migrations:migrate --no-interaction && \
    bin/console doctrine:fixtures:load --no-interaction "

init-events:
	docker-compose exec  events_php bash -c "bin/console doctrine:database:create --if-not-exists && \
	bin/console doctrine:migrations:migrate --no-interaction "

init-attendance:
	docker-compose exec  attendance_php bash -c "bin/console doctrine:database:create --if-not-exists && \
	bin/console doctrine:migrations:migrate --no-interaction "

init-tickets:
	docker-compose exec  tickets_php bash -c "bin/console doctrine:database:create --if-not-exists && \
	bin/console doctrine:migrations:migrate --no-interaction "

generate-jwt-keys:
	bin/docker run --rm auth_php  bin/console lexik:jwt:generate-keypair

generate-ssl:
	mkdir .ssl
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout .ssl/nginx-selfsigned.key -out .ssl/nginx-selfsigned.crt -batch


init-rabbitmq:
	docker-compose exec rabbitmq bash -c " \
		rabbitmqctl add_user ${RABBITMQ_USER} ${RABBITMQ_PASSWORD}	 && \
		rabbitmqctl set_permissions -p / ${RABBITMQ_USER} ".*" ".*" ".*" && \
		rabbitmqctl set_user_tags ${RABBITMQ_USER} administrator  \
"