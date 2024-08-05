IMAGE_NAME ?= camptocamp/nominatim
IMAGE_TAG ?= latest
export IMAGE_TAG
CONTAINER_NAME ?= nominatim
ROOT = $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: help
help: ## Display this help message
	@echo "Usage: make <target>"
	@echo
	@echo "Available targets:"
	@grep --extended-regexp --no-filename '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "	%-20s%s\n", $$1, $$2}'

.PHONY: pull
pull:
	for image in `find -name Dockerfile | xargs grep --no-filename FROM | awk '{print $$2}'`; do docker pull $$image; done

.PHONY: build
build:
	docker build --tag=$(IMAGE_NAME):$(IMAGE_TAG) .

acceptance: build
	(cd acceptance_tests/ && docker compose down)
	(cd acceptance_tests/ && docker compose up -d --build)
	(cd acceptance_tests/ && docker compose exec -T nominatim nominatim import --continue import-from-file --osm-file /nominatim/data/liechtenstein-latest.osm.pbf)
	(cd acceptance_tests/ && docker compose exec -T acceptance py.test -vv --color=yes --junitxml /tmp/junitxml/results.xml)
	(cd acceptance_tests/ && docker compose down -t1)

.PHONY: run
run: ## Run the Docker container.
	docker run --rm -d -p 8000:8080 --name $(CONTAINER_NAME) $(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: clean
clean: ## Remove the Docker container and image.
	docker rm -f $(CONTAINER_NAME)
	docker rmi $(IMAGE_NAME):$(IMAGE_TAG)
