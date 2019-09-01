
Development Process
===================

Prerequisites
-------------

* Any *nix-like system (for running Makefiles)
* PHP installation satisfying:
    * All of [Bolt's requirements][bolt-req]
    * The `curl` extension
    * The `exif` extension
    * The `iconv` extension
    * The `zip` extension
    * The `openssl` extension
    * Running "phar" files (The `phar` extension must be enabled or able to be configured)


Getting Started
---------------

Run `make` in the repository for help; `make dev-init` is a good starting point.


Release Process
===============

Dreamhost Setup
---------------

1. Your PHP CLI must use the same version as the website. Update your
   .bash_profile to include the following lines. (Assuming PHP 7.3)

        # Inside /home/<username>/.bash_profile
        export PATH=/usr/local/php73/bin:$PATH

2. The `phprc` file (`/home/<username>/.php/<version>/phprc`) must be updated from
   the `src/setup/php.prod.ini` file

        # Inside /home/<username>/.php/<version>/phprc
        <contents of src/setup/php.ini>




Environment
-----------

* After cloning repository, directories `database` and `files` should be added.

Work to Do
==========

* Setup a separate php.ini for dev-server; timezone must be set

Release Process
---------------

* Need way to backup `files/` directory remotely.
* Should use `relpath` instead of hardcodeded relative paths for symbolic links.
  See [this SO post for relpath implementation][so-relpath].



[bolt-req]: https://docs.bolt.cm/3.6/getting-started/requirements
[so-relpath]: http://stackoverflow.com/a/12498485
