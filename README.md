# Codeception + CI PHP project generator

[![Build Status](https://travis-ci.org/SochaDev/codeception-ci-generator.svg?branch=master)](https://travis-ci.org/natemow/codeception-ci-generator) [![Circle CI](https://circleci.com/gh/natemow/codeception-ci-generator.svg?style=svg)](https://circleci.com/gh/SochaDev/codeception-ci-generator)

This is a shell installer that will create a PHP stub project that has [Codeception](http://codeception.com/) testing, [TravisCI](https://travis-ci.org/) and/or [CircleCI](https://circleci.com/) continuous integration baked in. Just grab and run `codeception-ci-generator.sh` to experience the magic:

    git clone --quiet --depth 1 git@github.com:natemow/codeception-ci-generator.git
    mv c*/*.sh ./ && chmod +x ./*.sh
    rm -rf codeception-ci-generator
    ./codeception-ci-generator.sh

Supported project types:

* Generic PHP project
* [Drupal 7.x](https://www.drupal.org/project/drupal)
* [Drupal 8.x](https://www.drupal.org/project/drupal)
* [Phalcon 1.3.x (using Vökuró sample)](https://github.com/phalcon/vokuro)

### Tests

To make a new action available to `$I` (the test actor) across "cests", add your function to `tests/_support/ActorProject.php`:

    class ActorProject extends \Codeception\Actor {
      ...

      public function performSweetNewAction() {
        $I = $this;
        $I->assertEquals("Yay, it worked!", "Yay, it worked!");
      }

    }

And to use `performSweetNewAction` in a test, do this:

    namespace TestProject;

    class SampleCest {
      ...

      public function gonnaPerformSweetNewAction(\ActorProject $I) {
        $I->amGoingTo('perform sweet new action now');
        $I->performSweetNewAction();
      }

    }
