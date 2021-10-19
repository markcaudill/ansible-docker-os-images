SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --jobs=$(shell nproc)
MAKEFLAGS += --load-average=$(shell nproc)

# Directories for Make state
IMAGE_DIR = image
LINT_DIR = lint
PUSH_DIR = push
STATE_DIRS = $(IMAGE_DIR) $(LINT_DIR) $(PUSH_DIR)

IMAGES := $(shell dirname */*/Dockerfile)

# Commands
CAT = cat
DOCKER = docker
LINT = $(DOCKER) run --rm -i hadolint/hadolint hadolint - --ignore DL3008 --ignore DL3033 --ignore DL3041
HASH = sha256sum

REPO = markcaudill
MKDIR = mkdir -p


help :  ## This message
	@echo IMAGE_DIR = $(IMAGE_DIR)
	@echo LINT_DIR = $(LINT_DIR)
	@echo PUSH_DIR = $(PUSH_DIR)
	@echo REPO = $(REPO)
	@echo IMAGES =
	for i in $(IMAGES); do
		@echo "    $$i"
	done
	@echo
	@grep -E '^[^>]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "Dockerfiles are expected to be in a directory structured like"
	@echo "./<image>/<tag>/Dockerfile"
.PHONY: help


$(STATE_DIRS) :
	@echo "+ $@"
	$(MKDIR) $@


$(IMAGE_DIR)/% : %/Dockerfile $(LINT_DIR)/% | $(IMAGE_DIR)  ## Build an image
	@echo "+ $@"
	$(DOCKER) build -t $(REPO)/$(word 2,$(subst /, ,$@)):$(word 3,$(subst /, ,$@)) $(<D)
	$(MKDIR) $(@D)
	$(HASH) $< > $@

$(LINT_DIR)/% : %/Dockerfile | $(LINT_DIR)  ## Lint an Dockerfile (e.g. $(LINT_DIR)/htop/latest)
	@echo "+ $@"
	$(CAT) $< | $(LINT)
	$(MKDIR) $(@D)
	$(HASH) $< > $@

$(PUSH_DIR)/% : $(IMAGE_DIR)/% | $(PUSH_DIR)  ## Push an image
	@echo "+ $@"
	$(DOCKER) push $(REPO)/$(word 2,$(subst /, ,$@)):$(word 3,$(subst /, ,$@))
	$(MKDIR) $(@D)
	$(HASH) $< > $@


image-all : $(addprefix $(IMAGE_DIR)/,$(IMAGES))  ## Build all images
	@echo "+ $@"

lint-all : $(addprefix $(LINT_DIR)/,$(IMAGES))  ## Lint all Dockerfile
	@echo "+ $@"

push-all : $(addprefix $(PUSH_DIR)/,$(IMAGES))  ## Push all images
	@echo "+ $@"
	@echo $*

clean :
	rm -rf $(STATE_DIRS)
