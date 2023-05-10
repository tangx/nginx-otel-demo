
restart: down up

up:
	docker-compose up -d

down:
	docker-compose down

ps:
	docker-compose ps

docker:
	docker build -t nginx-otel:v1.23.1 -f Dockerfile .
