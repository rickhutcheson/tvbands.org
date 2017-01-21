Development Process
===================

Prerequisites
-------------

* Any *nix-like system (for running Makefiles)
* PHP installation satisfying [Bolt's requirements][bolt-req]

Release Process
===============

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
