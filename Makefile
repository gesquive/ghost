#
#  Makefile
#
#  A kickass golang v1.10.x makefile
#  v1.0.0

GOCC := go

# Program version
VERSION := $(shell git describe --always --tags)

# Grab the current commit
GIT_COMMIT := $(shell git rev-parse HEAD)

# Check if there are uncommited changes
GIT_DIRTY := $(shell test -n "`git status --porcelain`" && echo "+CHANGES" || true)

PKG_NAME := ${REPO_HOST_URL}/${OWNER}/${PROJECT_NAME}
INSTALL_PATH := ${GOPATH}/src/${PKG_NAME}

DIST_OS ?= "linux darwin windows"
DIST_ARCH ?= "amd64 386"
DIST_FILES ?= "LICENSE README.md"

LOCAL_DIST ?= dist
LOCAL_BIN ?= bin
GOTEMP := $(shell mktemp -d)
PKG_LIST := ./...

export SHELL ?= /bin/bash
export PATH := ${PWD}/${LOCAL_BIN}:${PATH}

include make.cfg
default: test build

.PHONY: help
help:
	@echo 'Management commands for $(PROJECT_NAME):'
	@grep -Eh '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
	 awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: ## Compile the project
	@echo "building ${OWNER} ${BIN_NAME} ${VERSION}"
	@echo "GOPATH=${GOPATH}"
	${GOCC} build -ldflags "-X main.version=${VERSION} -X main.dirty=${GIT_DIRTY}" -o ${BIN_NAME}

.PHONY: install
install: build ## Install the binary
	install -d ${DESTDIR}/usr/local/bin/
	install -m 755 ./${BIN_NAME} ${DESTDIR}/usr/local/bin/${BIN_NAME}

.PHONY: link
link: $(INSTALL_PATH) ## Symlink this project into the GOPATH
$(INSTALL_PATH):
	@mkdir -p `dirname $(INSTALL_PATH)`
	@ln -s $(PWD) $(INSTALL_PATH) >/dev/null 2>&1

.PHONY: path # Returns the project path
path:
	@echo $(INSTALL_PATH)

.PHONY: deps
deps: glide ## Download project dependencies
	glide install

.PHONY: test
test: ## Run golang tests
	${GOCC} test ${PKG_LIST}

.PHONY: bench
bench: ## Run golang benchmarks
	${GOCC} test -benchmem -bench=. ${PKG_LIST}

.PHONY: cover
cover: ## Run coverage report
	${GOCC} test -v -cover ${PKG_LIST}

.PHONY: cover-report
cover-report: ## Generate global code coverage report
	${GOCC} test -v -coverprofile coverage.dat ${PKG_LIST}
	${GOCC} tool cover -html=coverage.dat -o coverage.html

.PHONY: race
race: ## Run data race detector
	${GOCC} test -race ${PKG_LIST}

.PHONY: clean
clean: ## Clean the directory tree
	${GOCC} clean
	rm -f ./${BIN_NAME}.test
	rm -f ./${BIN_NAME}
	rm -rf ./${LOCAL_BIN}
	rm -rf ./${LOCAL_DIST}

.PHONY: build-dist
build-dist: gox
	gox -verbose \
	-ldflags "-X main.version=${VERSION} -X main.dirty=${GIT_DIRTY}" \
	-os="${DIST_OS}" \
	-arch="${DIST_ARCH}" \
	-output="${LOCAL_DIST}/{{.OS}}-{{.Arch}}/{{.Dir}}" .

.PHONY: package-dist
package-dist: gop
	gop --delete \
	--os="${DIST_OS}" \
	--arch="${DIST_ARCH}" \
	--archive="tar.gz" \
	--files="${DIST_FILES}" \
	--input="${LOCAL_DIST}/{{.OS}}-{{.Arch}}/{{.Dir}}" \
	--output="${LOCAL_DIST}/{{.Dir}}-${VERSION}-{{.OS}}-{{.Arch}}.{{.Archive}}" .

.PHONY: dist
dist: build-dist package-dist ## Cross compile and package the full distribution

.PHONY: fmt
fmt: ## Reformat the source tree with gofmt
	find . -name '*.go' -not -path './.vendor/*' -exec gofmt -w=true {} ';'

${LOCAL_BIN}: 
	@mkdir -p ${LOCAL_BIN}

.PHONY: glide
glide: bin/glide
	@glide --version
bin/glide: ${LOCAL_BIN}
	@echo "Installing glide"
	@export GOPATH=${GOTEMP} && ${GOCC} get -u github.com/Masterminds/glide
	@cp ${GOTEMP}/bin/glide ${LOCAL_BIN}
	@rm -rf ${GOTEMP}

.PHONY: gox
gox: bin/gox
bin/gox: ${LOCAL_BIN}
	@echo "Installing gox"
	@GOPATH=${GOTEMP} ${GOCC} get -u github.com/mitchellh/gox
	@cp ${GOTEMP}/bin/gox ${LOCAL_BIN}
	@rm -rf ${GOTEMP}

.PHONY: gop
gop: bin/gop
	@gop --version
bin/gop: ${LOCAL_BIN}
	@echo "Installing gop"
	@export GOPATH=${GOTEMP} && ${GOCC} get -u github.com/gesquive/gop
	@cp ${GOTEMP}/bin/gop ${LOCAL_BIN}
	@rm -rf ${GOTEMP}

