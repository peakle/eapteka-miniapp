PROJECT=eapteka
GOOS=linux
GOARCH=amd64

export NOCACHE := $(if $(NOCACHE),"--no-cache")
export GO111MODULE := on

ifeq ($(shell test -f .env && echo yes), yes)
	include .env
	export $(shell sed 's/=.*//' .env)
endif

## Init
init: pre-install dep

pre-install:
	@echo "Installing git hooks..."
	@git config --global core.hooksPath ./git-hooks
	@echo "Installing golangci-lint..."
	@go get github.com/golangci/golangci-lint/cmd/golangci-lint

## Development
run:
	@echo "Running server..."
	go run cmd/main.go

dep:
	@echo "Loading dependencies..."
	go mod tidy

lint:
	@echo "Running golangci-lint..."
	@golangci-lint run --timeout 3m

test-short:

release: build deploy

build: generate
	@echo "build ..."
	@ CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} \
		go build -o ./$(PROJECT) cmd/main.go
	@chmod +x $(PROJECT)

deploy:
	@echo "deploy..."
	@rsync -ve ssh --progress ./$(PROJECT) $(USERNAME)@$(HOSTNAME):$(REMOTE_PROJECT_DIR)
	@ssh ${USERNAME}@${HOSTNAME} 'supervisorctl restart eapteka'

generate: generate-client generate-server

generate-server:
	@rm -rf ./generated/server
	@mkdir -p ./generated/server
	@swagger generate client -f ./swagger/swagger-server.yml -t ./generated/server --template-dir ./templates ## todo change to server

generate-client:
	@rm -rf ./generated/client
	@mkdir -p ./generated/client
	@swagger generate client -f ./swagger/external/swagger-*.yml -t ./generated/client --template-dir ./templates ## todo change to server
