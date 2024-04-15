SHELL := /bin/bash

help:
	@grep -E '^[ a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

ifndef LIGO
#LIGO=docker run --platform linux/amd64 -u $(id -u):$(id -g) --rm -v "$(PWD)":"$(PWD)" -w "$(PWD)" ligolang/ligo:1.2.0
LIGO=ligo
endif
# ^ use LIGO en var bin if configured, otherwise use docker

compile = $(LIGO) compile contract  --project-root ./src ./src/$(1) -o ./compiled/$(2) $(3) 
# ^ Compile contracts to Michelson or Micheline

test = @$(LIGO) run test $(project_root) ./test/$(1) --no-warn
# ^ run given test file


.PHONY: test compile
compile: ## compile contracts to Michelson
	@mkdir -p compiled
	@$(call compile, vesting.mligo, vesting.tz)
	@$(call compile, token.mligo, token.tz)


test: ## run tests (SUITE=asset_approve make test)
ifndef SUITE


else
	@$(call test,$(SUITE).test.mligo)
endif


deploy: deploy_deps deploy.js

deploy.js:
	@echo "Running deploy script\n"
	@cd deploy && npm i && npm run deploy

deploy_deps:
	@echo "Installing deploy script dependencies"
	@cd deploy && npm install
	@echo ""