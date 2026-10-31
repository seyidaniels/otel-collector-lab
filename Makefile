# Usage: make up LAB=01 ; make traffic LAB=01 ; make verify LAB=01 ; make down LAB=01
LAB ?= 00
LAB_DIR := $(firstword $(wildcard labs/$(LAB)-*))
DC := docker compose --env-file .env
LAB_DC = $(DC) --project-directory $(LAB_DIR) -f $(LAB_DIR)/compose.yml

.PHONY: help backends backends-down up down traffic verify run logs validate validate-all clean check-lab

help:
	@echo "make backends              start Jaeger :16686, Prometheus :9090, Grafana :3000"
	@echo "make up      LAB=NN        start lab NN's collector(s) (stops any other lab, wipes Jaeger)"
	@echo "make traffic LAB=NN        send the lab's fake telemetry"
	@echo "make verify  LAB=NN        grade the result"
	@echo "make run     LAB=NN        up + traffic + verify"
	@echo "make logs    LAB=NN        tail collector logs"
	@echo "make validate LAB=NN       'otelcol validate' the lab's config(s) without starting anything"
	@echo "make down    LAB=NN        stop the lab"
	@echo "Labs:"; ls -1 labs | sed 's/^/  /'

check-lab:
	@test -n "$(LAB_DIR)" || { echo "No lab matching LAB=$(LAB)"; exit 1; }

backends:
	@$(DC) -f compose.backends.yml up -d

backends-down:
	@$(DC) -f compose.backends.yml down

# One lab at a time: they share host ports and Jaeger. Restarting Jaeger wipes
# its in-memory store so verify only sees this run's traces.
up: check-lab backends
	@for p in $$(docker compose ls -a --format json | jq -r '.[].Name | select(startswith("lab-"))'); do \
		docker compose -p $$p down --remove-orphans >/dev/null 2>&1; done
	@docker restart jaeger >/dev/null
	@mkdir -p $(LAB_DIR)/out && rm -rf $(LAB_DIR)/out/*
	@$(LAB_DC) up -d --force-recreate --remove-orphans
	@bash lib/wait-ready.sh "$(LAB_DIR)"

down: check-lab
	@$(LAB_DC) down --remove-orphans

traffic: check-lab
	@bash $(LAB_DIR)/traffic.sh

verify: check-lab
	@bash $(LAB_DIR)/verify.sh

run: up traffic verify

logs: check-lab
	@$(LAB_DC) logs -f --tail=100

validate: check-lab
	@bash lib/validate.sh $(LAB_DIR)

validate-all:
	@rc=0; for d in labs/*/; do bash lib/validate.sh $${d%/} || rc=1; done; exit $$rc

clean:
	@rm -rf labs/*/out
