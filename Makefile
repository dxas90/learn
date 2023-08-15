SHELL=/bin/bash -o pipefail
APP_NAME = learn
export SELF ?= $(MAKE)
export DOCKER_REPO ?= dxas90

# This version-strategy uses git tags to set the version string
git_branch	   := $(shell git rev-parse --abbrev-ref HEAD)
git_tag		  := $(shell git describe --exact-match --abbrev=0 2>/dev/null || echo "")
commit_hash	  := $(shell git rev-parse --verify HEAD)
commit_timestamp := $(shell date --date="@$$(git show -s --format=%ct)" --utc +%FT%T)

VERSION		  := $(shell git describe --tags --always --dirty)
version_strategy := commit_hash
ifdef git_tag
	VERSION := $(git_tag)
	version_strategy := tag
else
	ifeq (,$(findstring $(git_branch),develop HEAD))
		ifneq (,$(patsubst release-%,,$(git_branch)))
			VERSION := $(git_branch)
			version_strategy := branch
		endif
	endif
endif

define assert-set
        @[ -n "$($1)" ] || (echo "$(1) not defined in $(@)"; exit 1)
endef

.PHONY: version

clean:
	@rm -rf ${APP_NAME}-${VERSION}

container-build:
	@docker build -t $(DOCKER_REPO)/$(APP_NAME):${VERSION} -f Dockerfile .

container-push:
	@docker push $(DOCKER_REPO)/$(APP_NAME):${VERSION}

build-%:
	@go build -a -installsuffix cgo -ldflags '-extldflags "-static"' -o $*-${VERSION} .

build: clean
	@${SELF} build-${APP_NAME}

kaniko:
	@mkdir -p /kaniko/.docker
	@echo "{\"auths\":{\"$HARBOR_HOST\":{\"auth\":\"$(echo -n ${HARBOR_USERNAME}:${HARBOR_PASSWORD} | base64 | tr -d '\n')\"},\"$CI_REGISTRY\":{\"auth\":\"$(echo -n ${CI_REGISTRY_USER}:${CI_REGISTRY_PASSWORD} | base64 | tr -d '\n')\"}}}" > /kaniko/.docker/config.json
	@/kaniko/executor --context $KANIKO_BUILD_CONTEXT --dockerfile $DOCKERFILE_PATH --destination $IMAGE_TAG --destination "${HARBOR_HOST}/${HARBOR_PROJECT}/${CI_PROJECT_NAME}:${VERSION}" ${KANIKO_ARGS}

test:
	go test -v -json ./... ; exit 0

version:
	@echo "name=$(VERSION)" | tee  ${GITHUB_OUTPUT}
	@echo "version_strategy=$(version_strategy)" | tee  ${GITHUB_OUTPUT}
	@echo "git_tag=$(git_tag)" | tee  ${GITHUB_OUTPUT}
	@echo "git_branch=$(git_branch)" | tee  ${GITHUB_OUTPUT}
	@echo "commit_hash=$(commit_hash)" | tee  ${GITHUB_OUTPUT}
	@echo "commit_timestamp=$(commit_timestamp)" | tee  ${GITHUB_OUTPUT}
