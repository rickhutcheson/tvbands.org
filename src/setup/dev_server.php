<?php

/*
 * Support PHP's built-in server for development site (without .htaccess files).
 *
 * Retrieved from https://docs.bolt.cm/3.2/howto/using-php-built-in-web-server
 */

if (preg_match('/^\/(?:thumbs)/', $_SERVER['REQUEST_URI'])) {
    include __DIR__ . '/index.php';
} elseif (preg_match('/\.(?:png|jpg|jpeg|gif|css|js|ico|ttf|woff|woff2)$/', $_SERVER['REQUEST_URI'])) {
    return false;
} elseif (preg_match('/\.(?:ttf|woff|woff2)?/', $_SERVER['REQUEST_URI'])) {
    return false;
} else {
    include __DIR__ . '/index.php';
}