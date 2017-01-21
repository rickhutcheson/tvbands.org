Development Process
===================

Prerequisites
-------------

* Any *nix-like system (for running Makefiles)
* PHP installation satisfying:
    * Add of [Bolt's requirements][bolt-req]
    * Running "phar" files (The "phar" extension must be enabled or able to be configured)

Release Process
===============

Dreamhost Setup
---------------

1. Your PHP CLI must use the same version as the website. Update your
   .bash_profile to include the following lines. (Assuming PHP 5.6)

        # Inside /home/<username>/.bash_profile
        export PATH=/usr/local/php56/bin:$PATH

2. The "phar" extension must be enabled in
   your `phprc` file.

        # Inside /home/<username>/.php/<version>/phprc
        extension = phar.so
        suhosin.executor.include.whitelist = phar


Environment
-----------

* After cloning repository, directories `database` and `files` should be added.

Work to Do
==========

Release Process
---------------

* Need way to backup `files/` directory remotely.
* Should use `relpath` instead of hardcodeded relative paths for symbolic links.
  See [this SO post for relpath implementation][so-relpath].



[bolt-req]: https://docs.bolt.cm/3.2/getting-started/requirements
[so-relpath]: http://stackoverflow.com/a/12498485
