#
#  Makefile
#
#  A kickass golang v1.13.x makefile
#  v1.0.5

export SHELL ?= /bin/bash
include make.cfg

GOCC := go

# Program version
MK_VERSION := $(shell git describe --always --tags --dirty)
MK_HASH := $(shell git rev-parse --short HEAD)
MK_DATE := $(shell date -u +%Y-%m-%dT%H:%M:%SZ)

PKG_NAME := ${REPO_HOST_URL}/${OWNER}/${PROJECT_NAME}
INSTALL_PATH := ${GOPATH}/src/${PKG_NAME}

DIST_OS ?= "linux darwin windows"
DIST_ARCH ?= "amd64 386"
DIST_ARCHIVE ?= "tar.gz"
DIST_FILES ?= "LICENSE README.md"

COVER_PATH := coverage
DIST_PATH ?= dist
INSTALL_PATH ?= "/usr/local/bin"
PKG_LIST := ./...

IMAGE_NAME := ${REGISTRY_URL}/${OWNER}/${PROJECT_NAME}
IMAGE_TAG := ${IMAGE_NAME}:${MK_HASH}
RELEASE_TAG := ${IMAGE_NAME}:${MK_VERSION}
LATEST_TAG := ${IMAGE_NAME}:latest

BIN ?= ${GOPATH}/bin
GOLINT ?= ${BIN}/golint
GORELEASER ?= ${BIN}/goreleaser
DOCKER ?= docker

export CGO_ENABLED = 0

default: test build

.PHONY: help
help:
	@echo 'Management commands for $(PROJECT_NAME):'
	@grep -Eh '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	 awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: ## Compile the project
	@echo "building ${OWNER} ${BIN_NAME} ${MK_VERSION}"
	@echo "GOPATH=${GOPATH}"
	${GOCC} build -a -ldflags "-X main.buildVersion=${MK_VERSION} -X main.buildDate=${MK_DATE}" -o ${BIN_NAME}

.PHONY: install
install: build ## Install the binary
	install -d ${DESTDIR}
	install -m 755 ./${BIN_NAME} ${DESTDIR}/${BIN_NAME}

.PHONY: link
link: $(INSTALL_PATH) ## Symlink this project into the GOPATH
$(INSTALL_PATH):
	@mkdir -p `dirname $(INSTALL_PATH)`
	@ln -s $(PWD) $(INSTALL_PATH) >/dev/null 2>&1

.PHONY: path # Returns the project path
path:
	@echo $(INSTALL_PATH)

.PHONY: deps
deps: ## Download project dependencies
	${GOCC} mod download
	${GOCC} mod verify

.PHONY: lint
lint: ${GOLINT} ## Lint the source code
	${GOLINT} -set_exit_status ${PKG_LIST}

.PHONY: test
test: ## Run golang tests
	${GOCC} test ${PKG_LIST}

.PHONY: bench
bench: ## Run golang benchmarks
	${GOCC} test -benchmem -bench=. ${PKG_LIST}

.PHONY: coverage
coverage: ## Run coverage report
	${GOCC} test -v -cover ${PKG_LIST}

.PHONY: coverage-report
coverage-report: ## Generate global code coverage report
	mkdir -p "${COVER_PATH}"
	${GOCC} test -v -coverprofile "${COVER_PATH}/coverage.dat" ${PKG_LIST}
	${GOCC} tool cover -html="${COVER_PATH}/coverage.dat" -o "${COVER_PATH}/coverage.html"

.PHONY: race
race: ## Run data race detector
	${GOCC} test -race ${PKG_LIST}

.PHONY: clean
clean: ## Clean the directory tree
	${GOCC} clean
	rm -f ./${BIN_NAME}.test
	rm -f ./${BIN_NAME}
	rm -rf "${DIST_PATH}"
	rm -f "${COVER_PATH}"

.PHONY: local-release
local-release: ${GORELEASER} ## Cross compile and package to a local disk
	echo ${GORELEASER}
	${GORELEASER} release --skip-publish --rm-dist --snapshot

.PHONY: release
release: ${GORELEASER} ## Cross compile and package the full distribution
	${GORELEASER} release

.PHONY: fmt
fmt: ## Reformat the source tree with gofmt
	find . -name '*.go' -not -path './.vendor/*' -exec gofmt -w=true {} ';'

# Install golang dependencies here
${BIN}/%: 
	@echo "Installing ${PACKAGE} to ${BIN}"
	@mkdir -p ${BIN}
	@tmp=$$(mktemp -d); \
       env GO111MODULE=on GOPATH=$$tmp GOBIN=${BIN} ${GOCC} get ${PACKAGE} \
        || ret=$$?; \
       rm -rf $$tmp ; exit $$ret

${BIN}/golint:     PACKAGE=golang.org/x/lint/golint
${BIN}/goreleaser: PACKAGE=github.com/goreleaser/goreleaser


.PHONY: build-docker
build-docker: ## Build the docker image
	@echo "building ${IMAGE_TAG}"
	${DOCKER} info
	${DOCKER} build  --pull -t ${IMAGE_TAG} .

.PHONY: release-docker
release-docker: ## Tag and release the docker image
	@echo "release ${IMAGE_TAG}"
	${DOCKER} push ${IMAGE_TAG}

	@echo "tag and release ${RELEASE_TAG}"
	${DOCKER} pull ${IMAGE_TAG}
	${DOCKER} tag ${IMAGE_TAG} ${RELEASE_TAG}
	${DOCKER} push ${RELEASE_TAG}

	@echo "tag and release ${LATEST_TAG}"
	${DOCKER} pull ${IMAGE_TAG}
	${DOCKER} tag ${IMAGE_TAG} ${LATEST_TAG}
	${DOCKER} push ${LATEST_TAG}

.PHONY: release-docker-version
release-docker-version: ## Release a versioned docker image
	@echo "tag and release ${RELEASE_TAG}"
	${DOCKER} pull ${IMAGE_TAG}
	${DOCKER} tag ${IMAGE_TAG} ${RELEASE_TAG}
	${DOCKER} push ${RELEASE_TAG}
