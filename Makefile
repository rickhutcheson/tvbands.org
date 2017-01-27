################################################################################
#
# Makefile: tvbands.org build/deployment process
#
################################################################################


########################################################################
# Variable Setup & Configuration
#
# Releases on server are named (and stored) by timestamp, so we
# calculate NOW once at the beginning so that we have consistent
# directory names during execution.
########################################################################

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


.PHONY:	db-update
db-update:
	php $(SRV_DIR)/vendor/bolt/bolt/app/nut database:update

.PHONY:	backup-prod-db
backup-prod-db:
	scp tv:~/tvbands.org/database/bolt.db srv/app/database/bolt.db

.PHONY: dev-srv-setup
dev-srv-setup: base-srv-setup
	mkdir -p $(SRV_DIR)/app/database
	mkdir -p $(SRV_DIR)/public/files

	cd $(SRV_DIR) \
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
	@echo "Setting up server directory..."
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
	@echo "Installing Bolt CMS..."
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
dev-server:
	cp src/config/config_dev.yml src/config/config_local.yml
	php -S localhost:8000 -t $(SRV_DIR)/public/ $(SRV_DIR)/public/dev_server.php

.PHONY: dev-pre-release
dev-pre-release:

.PHONY: prod-pre-release
prod-pre-release:
	git pull
	cp database/bolt.db database/backup-$(NOW).db

.PHONY: pre-release
pre-release: $(ENV)-pre-release

.PHONY: dev-post-release
dev-post-release:

.PHONY: prod-post-release
prod-post-release:
	php $(SRV_DIR)/vendor/bolt/bolt/app/nut database:update
	php $(SRV_DIR)/vendor/bolt/bolt/app/nut cache:clear
	@echo 'Killing existing FastCGI processes.'
	killall php56.cgi

.PHONY: post-release
post-release: $(ENV)-post-release

.PHONY: release
release: pre-release app-setup post-release

setup/bin/composer.phar:
	@echo "Installing composer..."
	./src/setup/make_composer.sh
	mkdir -p setup/bin
	mv composer.phar setup/bin
