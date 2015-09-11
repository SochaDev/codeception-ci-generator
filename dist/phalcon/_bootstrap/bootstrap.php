<?php
// This file will be used by Codeception to bootstrap your Phalcon app.
//
// The application bootstrap file must return Application object but not
// call its handle() method.
// @see http://codeception.com/docs/modules/Phalcon1
defined('BASE_DIR') || define('BASE_DIR', realpath(__DIR__ . '/../..'));
defined('APP_DIR') || define('APP_DIR', BASE_DIR . '/app');

// Include code coverage support for Codeception test suite.
include BASE_DIR . '/c3.php';

$config = include APP_DIR . '/config/config.php';
include APP_DIR . '/config/loader.php';
include APP_DIR . '/config/services.php';

$application = new \Phalcon\Mvc\Application($di);

// Autoload all classes in TestPROJECT_CAMEL namespace.
\Codeception\Util\Autoload::addNamespace('TestPROJECT_CAMEL', BASE_DIR . '/tests/PROJECT');

return $application;
