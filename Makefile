################################################################################
#
# Makefile: tvbands.org build/deployment process
#
################################################################################

setup/bin/composer.phar:
	@echo "Installing composer..."
	./src/setup/make_composer.sh
	mkdir -p setup/bin
	mv composer.phar setup/bin

dev-setup: setup/bin/composer.phar
	@echo "Installing Bolt CMS..."
	mkdir -p srv
	cp src/setup/composer.json srv/
	mkdir -p srv/app/cache
	mkdir -p srv/app/config
	mkdir -p srv/app/database
	mkdir -p srv/public/theme
	mkdir -p srv/public/files
	mkdir -p srv/public/bolt-public/view
	mkdir -p srv/public/thumbs
	mkdir -p srv/public/extensions
	mkdir -p srv/extensions
	cd srv \
		&& ../setup/bin/composer.phar install --no-scripts \
		&& ../setup/bin/composer.phar run-script post-create-project-cmd  \
		&& ../setup/bin/composer.phar run-script post-install-cmd
	cp src/setup/dev_server.php srv/public/
	cd srv/app && rm -r config && ln -s ../../src/config config
	cd srv/public && rm -r theme/tvbands && ln -s ../../src/theme theme/tvbands

dev-server:
	php -S localhost:8000 -t srv/public/ srv/public/dev_server.php
