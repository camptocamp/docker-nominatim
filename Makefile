## TODO this is just a rudimentary sceleton with a couple of commands that need to be implemented propery

IMAGE_NAME = camptocamp/nominatim
CONTAINER_NAME = nominatim

.PHONY: help
help: ## Display this help message
	@echo "Usage: make <target>"
	@echo
	@echo "Available targets:"
	@grep --extended-regexp --no-filename '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "	%-20s%s\n", $$1, $$2}'

.PHONY: build
build: ## Build the Docker image. --> FIXME: add a working command
	docker build --tag $(IMAGE_NAME) .

.PHONY: run
run: ## Run the Docker container. --> FIXME: run in the background, add port mapping
	docker run --rm -d -p 8000:8080 --name $(CONTAINER_NAME) $(IMAGE_NAME)

.PHONY: clean
clean: ## Remove the Docker container and image. --> FIXME: add a working command
	docker rm --force $(CONTAINER_NAME)
	docker rmi $(IMAGE_NAME)