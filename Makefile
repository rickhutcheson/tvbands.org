########################################################################
#
# Makefile: tvbands.org build/deployment process
#
########################################################################


########################################################################
# Variable Setup & Configuration
########################################################################

# Releases on server are named (and stored) by timestamp, so we
# calculate NOW once at the beginning so that we have consistent
# directory names during execution.
NOW := $(shell date +%m-%d-%y+%H.%M.%S)

# Variable: BASE_DIR
# In a given environment, this directory holds all

ifeq ($(ENV), dev)
	BASE_DIR = .
endif
ifeq ($(ENV), prod)
	BASE_DIR = releases/$(NOW)
endif

SRV_DIR = $(BASE_DIR)/srv

# We need to use our custom php.ini file for all commands
PHP_INI_FILE := php.$(ENV).ini
PHP_CMD := php -c $(BASE_DIR)/src/setup/$(PHP_INI_FILE)


########################################################################
# Output coloring
#
# Minimal pretty-printing so output is clearer
########################################################################
BLACK=0
RED=1
GREEN=2
YELLOW=3
BLUE=4
MAGENTA=5
CYAN=6

define colorecho
    @tput setaf $(1)
    @echo $(2)
    @tput sgr0
endef

define proclaim
    @echo
    @echo
    $(call colorecho, ${GREEN}, "╔══════════════════════════════════════════════════════════════════════")
    $(call colorecho, ${GREEN}, "║")
    $(call colorecho, ${GREEN}, "║ $(1)")
    $(call colorecho, ${GREEN}, "║")
    $(call colorecho, ${GREEN}, "╚══════════════════════════════════════════════════════════════════════")
    @echo
    @echo
endef


########################################################################
# Runtime Checks
#
# Ideally, these checks would be the first code in the file, but
# make requires these conditionals to be defined after some
# statements or variable definitions, so we place them here.
########################################################################

ifndef ENV
    $(error ENV must be specified)
endif


########################################################################
# Targets
########################################################################
.DEFAULT_GOAL := help

# From: https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@echo "tvbands.org build / setup / development tooling"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: pkg-update
pkg-update:  ## Update all packages to use compatible versions from composer.json
	$(call colorecho, ${CYAN}, "Updating composer packages to latest compatible versions...")
	cd ${SRV_DIR} \
	&& $(PHP_CMD) ${CURDIR}/setup/bin/composer.phar update

.PHONY:	db-update
db-update:  ## Update Bolt database to use latest configurations
	$(PHP_CMD) $(SRV_DIR)/vendor/bolt/bolt/app/nut database:update

.PHONY:	backup-prod
backup-prod:  ## Copy all production data into development environment
	$(call colorecho, ${RED}, "Backing up production data...")
	scp -p tv:~/tvbands.org/database/bolt.db $(SRV_DIR)/app/database/bolt.db
	scp -rp tv:~/tvbands.org/files/. $(SRV_DIR)/public/files/


.PHONY: dev-init
dev-init: dev-srv-setup dev-app-setup backup-prod  ## Create or reset development environment

.PHONY: dev-srv-setup
dev-srv-setup: base-srv-setup
	mkdir -p $(SRV_DIR)/app/database
	mkdir -p $(SRV_DIR)/public/files

	cd $(SRV_DIR) \
	&& rm -f composer.json composer.lock \
	&& ln -s ../src/setup/composer.json composer.json \
	&& ln -s ../src/setup/composer.lock composer.lock


.PHONY: prod-srv-setup
prod-srv-setup: base-srv-setup
	cp src/setup/composer.json $(SRV_DIR)/
	cp src/setup/composer.lock $(SRV_DIR)/
	cd $(SRV_DIR)/app && ln -s ../../../../database	database
	cd $(SRV_DIR)/public && ln -s ../../../../files files


.PHONY: base-srv-setup
base-srv-setup:
	$(call colorecho, ${CYAN}, "Setting up server directory...")
	mkdir -p $(SRV_DIR)
	mkdir -p $(SRV_DIR)/app/cache
	mkdir -p $(SRV_DIR)/app/config
	mkdir -p $(SRV_DIR)/public/theme
	mkdir -p $(SRV_DIR)/public/bolt-public/view
	mkdir -p $(SRV_DIR)/public/thumbs
	mkdir -p $(SRV_DIR)/public/extensions
	mkdir -p $(SRV_DIR)/extensions


.PHONY: base-app-setup
base-app-setup: setup/bin/composer.phar $(ENV)-srv-setup
	$(call proclaim, "Installing Application...")

	$(call colorecho, ${CYAN}, "Resetting & clearing packages...")
	- cd $(SRV_DIR) \
		&& ${CURDIR}/setup/bin/composer.phar selfupdate \
		&& ${CURDIR}/setup/bin/composer.phar clearcache \
		&& rm -rf vendor

	$(call colorecho, ${CYAN} "Installing Bolt CMS...")
	cd $(SRV_DIR) \
		&& ${CURDIR}/setup/bin/composer.phar install --no-scripts \
		&& ${CURDIR}/setup/bin/composer.phar run-script post-release-cmd

	cd $(SRV_DIR) && rm -rf .bolt.yml && ln -s ../../src/config/base.yml .bolt.yml
	cd $(SRV_DIR)/app && rm -rf config && ln -s ../../src/config config
	cd $(SRV_DIR)/public && rm -rf theme/tvbands \
		&& ln -s ../../../src/theme theme/tvbands
	cp src/setup/public_index.php $(SRV_DIR)/public/index.php


.PHONY: app-setup
dev-app-setup: base-app-setup
	cp src/setup/dev_server.php $(SRV_DIR)/public/



.PHONY: app-setup
prod-app-setup: base-app-setup
	cp -r src $(BASE_DIR)/
	cp src/setup/prod/dot-htaccess $(SRV_DIR)/public/.htaccess
	cd releases && rm -f current && ln -s $(NOW) current


.PHONY: app-setup
app-setup: $(ENV)-app-setup


.PHONY: dev-server
dev-server:  ## Start a dev server
	cp src/config/config_dev.yml src/config/config_local.yml
	$(PHP_CMD) -S localhost:8000 \
		-t $(SRV_DIR)/public/ \
		$(SRV_DIR)/public/dev_server.php

.PHONY: dev-pre-release
dev-pre-release:

.PHONY: prod-pre-release
prod-pre-release:
	$(call proclaim, "Beginning Release @ ${NOW}")
	$(call colorecho, ${GREEN}, "Backing up database to 'backup-${NOW}.db'...")
	cp database/bolt.db database/backup-$(NOW).db
	$(call colorecho, ${GREEN}, "Pulling latest copy of code...")
	git reset --hard HEAD
	git pull

.PHONY: pre-release
pre-release: $(ENV)-pre-release

.PHONY: dev-post-release
dev-post-release:

.PHONY: prod-post-release
prod-post-release:
	$(PHP_CMD) $(SRV_DIR)/vendor/bolt/bolt/app/nut database:update
	$(PHP_CMD) $(SRV_DIR)/vendor/bolt/bolt/app/nut cache:clear
	$(call colorecho, ${GREEN}, "Killing existing FastCGI processes...")
	killall -q php56.cgi
	$(call proclaim, "Release ${NOW} complete.")

.PHONY: post-release
post-release: $(ENV)-post-release

.PHONY: release
release: pre-release app-setup post-release  ## Release code into production server (does nothing in DEV)

setup/bin/composer.phar:
	$(call colorecho, ${GREEN}, "Installing composer...")
	./src/setup/make_composer.sh
	mkdir -p setup/bin
	mv composer.phar setup/bin
