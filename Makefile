.PHONY: build
build:
	@docker build --platform linux/amd64 -t nasa-nex .

.PHONY: dev
dev:
	@docker compose watch

.PHONY: up
up:
	@docker compose up -d

.PHONY: down
down:
	@docker compose down -v
