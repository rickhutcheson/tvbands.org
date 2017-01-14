################################################################################
#
# Makefile: tvbands.org build/deployment process
#
################################################################################

#
# Variable Setup
#

NOW := $(shell date +%s)

#
# Environment-Specific Setup
#

# SRV_DIR
ifeq ($(ENV), dev)
	BASE_DIR = .
endif
ifeq ($(ENV), prod)
	BASE_DIR = releases/$(NOW)
endif

SRV_DIR = $(BASE_DIR)/srv


ifndef ENV
	$error("ENV must be specified.")
endif

.PHONY:	db-update
db-update:
	php $(SRV_DIR)/vendor/bolt/bolt/app/nut database:update

.PHONY: dev-srv-setup
dev-srv-setup: base-srv-setup
	mkdir -p $(SRV_DIR)/app/database
	mkdir -p $(SRV_DIR)/public/files

.PHONY: prod-srv-setup
prod-srv-setup: base-srv-setup
	cd $(SRV_DIR)/app && ln -s ../../../../database	 database
	cd $(SRV_DIR)/public && ln -s ../../../../files files


.PHONY: base-srv-setup
base-srv-setup:
	@echo "Setting up server directory..."
	mkdir -p $(SRV_DIR)
	cp src/setup/composer.json $(SRV_DIR)/
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
		&& ${CURDIR}/setup/bin/composer.phar run-script post-create-project-cmd  \
		&& ${CURDIR}/setup/bin/composer.phar run-script post-install-cmd

	cd $(SRV_DIR) && rm -rf .bolt.yml && ln -s ../../src/config/base.yml .bolt.yml
	cd $(SRV_DIR)/app && rm -rf config && ln -s ../../src/config config
	cd $(SRV_DIR)/public && rm -rf theme/tvbands \
		&& ln -s ../../../src/theme theme/tvbands

.PHONY: app-setup
dev-app-setup: base-app-setup
	cp src/setup/dev_server.php $(SRV_DIR)/public/
	cp src/setup/public_index.php $(SRV_DIR)/public/index.php


.PHONY: app-setup
prod-app-setup: base-app-setup
	cp -r src $(BASE_DIR)/


.PHONY: app-setup
app-setup: $(ENV)-app-setup


.PHONY: dev-server
dev-server:
	php -S localhost:8000 -t $(SRV_DIR)/public/ $(SRV_DIR)/public/dev_server.php


setup/bin/composer.phar:
	@echo "Installing composer..."
	./src/setup/make_composer.sh
	mkdir -p setup/bin
	mv composer.phar setup/bin
