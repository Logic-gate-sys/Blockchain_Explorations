# ---------------------------------------------------
# Load environment variables from .env if present
# ---------------------------------------------------
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

# ---------------------------------------------------
# Default target when you just run `make`
# ---------------------------------------------------
.DEFAULT_GOAL := help

# ---------------------------------------------------
# Variables (override in your .env if needed)
# ---------------------------------------------------
RPC_URL       ?= https://sepolia.infura.io/v3/YOUR_KEY
PRIVATE_KEY   ?= 0xyourprivatekey
DEPLOY_SCRIPT ?= script/Deploy.s.sol

# ---------------------------------------------------
# Targets
# ---------------------------------------------------

## format: Format Solidity code using forge fmt
format:
	forge fmt

## build: Compile the contracts
build:
	forge build

## test: Run all tests with verbosity
test:
	forge test -vvv

## deploy: Run the deployment script
deploy:
	forge script $(DEPLOY_SCRIPT) \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast

## clean: Clean the build artifacts
clean:
	forge clean

## help: Show available commands
help:
	@echo ""
	@echo "Available commands:"
	@grep -E '^##' Makefile | sed 's/## //'
	@echo ""


