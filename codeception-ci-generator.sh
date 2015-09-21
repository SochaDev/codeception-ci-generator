#!/bin/bash

# Set color codes.
  Color_Off='\033[0m';
  Black='\033[0;30m';
  Red='\033[0;31m';
  Green='\033[0;32m';
  Yellow='\033[0;33m';
  Blue='\033[0;34m';
  Purple='\033[0;35m';
  Cyan='\033[0;36m';
  White='\033[0;37m';

# Begin setup stuff.
echo -e $Green"
This script will create a stub PHP project with Codeception tests, TravisCI
and/or CircleCI continuous integration in the directory provided."$Color_Off;

if [[ $1 = "--testing" ]]; then
  TYPE=$2;
  case $2 in
    # Set up a generic project.
    1)
      PROJECT="generic";
      ;;
    # Set up a Drupal 7.x project.
    2)
      PROJECT="drupal7";
      ;;
    # Set up a Drupal 8.x project.
    3)
      PROJECT="drupal8";
      ;;
    # Set up a Phalcon 1.x project.
    4)
      PROJECT="phalcon1";
      ;;
    *)
      echo -e $Red"Invalid option...exiting"$Color_Off;
      exit;
      ;;
  esac;
else
  read -p "
Do you want to proceed? (y|n): " CONFIRM;
  if [ $CONFIRM != "y" ]; then
    exit;
  fi;
fi;
echo -e $Color_Off;

# Prompt for project name.
DIRECTORY="";
if [[ $1 != "--testing" ]]; then
  read -p "Project/test suite name (clean lowercase string, please): " PROJECT;
  PROJECT=`php -r "print str_replace(' ', '-', strtolower('$PROJECT'));"`;
  # Prompt for target directory.
  read -p "
Target directory (<Enter> for $(pwd)/"$PROJECT"): " DIRECTORY;
fi;

PROJECT_CAMEL=`php -r "print str_replace(' ', '', ucfirst(str_replace('-', ' ', '$PROJECT')));"`;

# Check target directory.
if [[ $DIRECTORY = "" ]]; then
  DIRECTORY=$(pwd)/$PROJECT;
  rm -rf $DIRECTORY;
fi;
if [ ! -d "$DIRECTORY" ]; then
  mkdir -p $DIRECTORY;
fi;
cd $DIRECTORY;
if [ `ls -1A . | wc -l` -ne 0 ]; then
  echo -e $Red"
Target directory is not empty!";
  echo -e $Color_Off;
  exit;
fi;

# Clone dist files and clean up.
git clone --quiet https://github.com/SochaDev/codeception-ci-generator.git;
rm -rf codeception-ci-generator/.git;
mv codeception-ci-generator/* ./ && rm -rf codeception-ci-generator;

# Prompt for project type.
if [[ $1 != "--testing" ]]; then
  echo "
What type of project is this? (1|2|3|4):

    1) Generic PHP
    2) Drupal 7.x
    3) Drupal 8.x
    4) Phalcon 1.3.x (using Vökuró sample)";

  read TYPE;
fi;

# Set dist and clone stuff per project type.
CLONE="";
case $TYPE in
  # Set up a generic project.
  1)
    printf "
Installing generic PHP \"%s\" project...
" $PROJECT;
    mv dist/drupal/* tests/;
    mv dist/drupal/.[!.]* tests/;
    ;;
  # Set up a Drupal 7.x project.
  2)
    printf "
Installing Drupal 7.x \"%s\" project...
" $PROJECT;
    CLONE="git clone --quiet --depth 1 --branch 7.x http://git.drupal.org/project/drupal.git app";
    mv dist/drupal/* tests/;
    mv dist/drupal/.[!.]* tests/;
    ;;
  # Set up a Drupal 8.x project.
  3)
    printf "
Installing Drupal 8.x \"%s\" project...
" $PROJECT;
    echo -e $Yellow"
Please note that Drush 8.x site install support is limited
at this point. When this script completes, you will need to
manually install via GUI and then dump your database to:

  tests/_bootstrap/$PROJECT.sql";
    echo -e $Color_Off;
    CLONE="git clone --quiet --depth 1 --branch 8.0.x http://git.drupal.org/project/drupal.git app";
    mv dist/drupal/* tests/;
    mv dist/drupal/.[!.]* tests/;
    ;;
  # Set up a Phalcon 1.x project.
  4)
    printf "
Installing Vökuró Phalcon \"%s\" project...
" $PROJECT;
    CLONE="git clone --quiet --depth 1 https://github.com/phalcon/vokuro.git";
    mv dist/phalcon/* tests/;
    mv dist/phalcon/.[!.]* tests/;
    ;;
  *)
    echo -e $Red"Invalid option...exiting"$Color_Off;
    exit;
    ;;
esac;

# Set database creds.
if [[ $1 = "--testing" ]]; then
  MYSQL_USER_NAME="root";
  MYSQL_USER_PASS="";
else
  echo "
Provide database credentials for your project:";
  read -p "MySQL username: " MYSQL_USER_NAME;
  read -p "MySQL password: " MYSQL_USER_PASS;
fi;

# Find placeholders in dist and make them project-specific.
find ./tests -type f -name '*' | xargs sed -i 's/PROJECT_CAMEL/'$PROJECT_CAMEL'/g';
find ./tests -type f -name '*' | xargs sed -i 's/PROJECT/'$PROJECT'/g';
find ./tests -type f -name '*' | xargs sed -i 's/MYSQL_USER_NAME/'$MYSQL_USER_NAME'/g';
find ./tests -type f -name '*' | xargs sed -i 's/MYSQL_USER_PASS/'$MYSQL_USER_PASS'/g';
# Move dist stuff around.
mv tests/project.suite.yml tests/$PROJECT.suite.yml;
if [[ -f "tests/_bootstrap/bootstrap.php" ]]; then
  mv tests/_bootstrap/bootstrap.php tests/_bootstrap/$PROJECT.php;
fi;
mv tests/composer.json ./;
mv tests/circle.yml ./;
mv tests/circle.vhost ./;
mv tests/.travis.yml ./;
mv tests/suite tests/$PROJECT;
# Create app dir.
mkdir app && echo "Your app goes here." > app/README.md;
echo "# Composer stuff.
composer.phar
composer.lock
" > .gitignore;

# Fetch project dependencies.
echo "
Fetching dependencies...";
curl -s http://getcomposer.org/installer | php;
php composer.phar install --quiet --no-ansi;

# Clone a repo to app directory.
if [[ $CLONE != "" ]]; then

  echo "
Cloning from:" $CLONE;
  rm -rf app/*;
  $CLONE;

  # Do auto post-clone stuff.
  case $TYPE in
    # Set up a Drupal 7.x project.
    2)
      cd app && rm -rf .git;
      cp sites/default/default.settings.php sites/default/settings.php;
      chmod a+w sites/default/settings.php;
      mkdir sites/default/files && chmod -R 0775 sites/default/files;

      # Set up database.
      ./../vendor/bin/drush site-install \
        standard \
        --db-url="mysql://$MYSQL_USER_NAME:$MYSQL_USER_PASS@127.0.0.1/$PROJECT" \
        --site-name="$PROJECT" \
        --yes;
      ;;
    # Set up a Drupal 8.x project.
    3)
      cd app;

      # Developer settings.
      cp sites/example.settings.local.php sites/default/settings.local.php;
      # Everyone settings.
      cp sites/default/default.settings.php sites/default/settings.php;
      cp sites/default/default.services.yml sites/default/services.yml;
      chmod 0666 sites/default/settings.php sites/default/services.yml;
      mkdir sites/default/files &&  chmod -R 0775 sites/default/files;

      # Removing auto install entirely for now...using drush 8.x to install
      # seems to be pretty buggy still.
      #
      # Set up database.
      # ./../vendor/bin/drush site-install \
      #   standard \
      #   --db-url="mysql://$MYSQL_USER_NAME:$MYSQL_USER_PASS@127.0.0.1/$PROJECT" \
      #   --site-name="$PROJECT" \
      #  --yes

      # Temp workaround:
      if [[ $1 != "--testing" ]]; then
        mysql -u$MYSQL_USER_NAME -p$MYSQL_USER_PASS -e "CREATE DATABASE $PROJECT;";
      fi;
      ;;
    # Set up a Phalcon 1.x project.
    4)
      mv vokuro/.htaccess ./;
      rm -f vokuro/*.json vokuro/*.md vokuro/*.html vokuro/.gitattributes vokuro/.gitignore;
      mv vokuro/* ./;
      rm -rf vokuro;
      mv schemas/vokuro.sql schemas/$PROJECT.sql;

      # Set up database.
      if [[ $1 != "--testing" ]]; then
        mysql -u$MYSQL_USER_NAME -p$MYSQL_USER_PASS -e "CREATE DATABASE $PROJECT;";
        mysql -u$MYSQL_USER_NAME -p$MYSQL_USER_PASS $PROJECT < schemas/$PROJECT.sql;
      else
        mysql -u$MYSQL_USER_NAME $PROJECT < schemas/$PROJECT.sql;
      fi;

      cd app;
      ;;
  esac

else

  # Set up a generic project.
  if [[ $1 != "--testing" ]]; then
    read -p "
Do you want to clone a repo to the \"app\" directory? (y|n): " CONFIRM;
    if [ $CONFIRM = "y" ]; then
      read -p "Please provide the repo to clone: " CLONE;
      echo "
Cloning from:" $CLONE;
      rm -rf app/*;
      git clone --quiet --depth 1 $CLONE app;
      rm -rf app/.git;
    fi;

    # Set up database.
    mysql -u$MYSQL_USER_NAME -p$MYSQL_USER_PASS -e "CREATE DATABASE $PROJECT;";
  fi;

  cd app;
fi;

# Clean up after ourselves.
cd ../ && rm -rf $0 dist *.phar *.lock *.md;

# Create Codeception Db module fixtures dump.
if [[ $1 != "--testing" ]]; then
  mysqldump -u$MYSQL_USER_NAME -p$MYSQL_USER_PASS $PROJECT > tests/_bootstrap/$PROJECT.sql;
else
  mysqldump -u$MYSQL_USER_NAME $PROJECT > tests/_bootstrap/$PROJECT.sql;
fi;

# Build and run Codeception project tests.
printf "
Building Codeception suite and running \"%s\" tests...

" $PROJECT;
./vendor/bin/codecept build;
if [[ $TYPE = 2 ]] || [[ $TYPE = 3 ]]; then
  ./vendor/bin/drush status --root=./app --uri=localhost && ./vendor/bin/drush cc all --root=./app --uri=localhost;
fi;
./vendor/bin/codecept --steps run $PROJECT;

# Print confirmation.
echo -e $Green;
printf "Great, you're all set to use Codeception, TravisCI and/or CircleCI in
your new \"%s\" project! To re-run the Codeception test suite:

  cd %s && ./vendor/bin/codecept --steps run %s
" $PROJECT $PROJECT $PROJECT;
echo -e $Color_Off;
printf "Your \"%s\" project looks like this:
" $PROJECT;

echo -e $Cyan;
pwd && ls -la;
echo -e $Color_Off;

# Clean up after ourselves.
if [[ $1 != "--testing" ]]; then
  rm -f ../$0;
fi;
