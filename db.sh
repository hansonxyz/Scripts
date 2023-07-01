#!/bin/bash

if [ -z "${BASH_ARGV[0]}" ]; then
  cat <<EOF

DB tool

creds               - prints the database connection credentials
shell               - open a mysql shell of the current project / pipe stdin to mysql
dump                - dump the database (using lock-tables=false) - pipe to stdout
backup              - dump the database (using lock-tables=false) - creates a file for you
set-domain (domain) - renames a domain in the db
killall             - executes a kill command on all running mysql connections to the domain
publish             - generates a copy and pastable command that installs this db script on another computer

EOF
  exit 1
fi

# exit on error
set -e

if [ "${BASH_ARGV[0]}" = "publish" ]; then
  _S=$(cat $(which db) | gzip | base64 -w 0)
  echo echo $_S "| base64 -d | gunzip > /usr/bin/db; chmod +x /usr/bin/db"
  exit
fi

# initialize configuration variables
FILELOC=""
DBUSER=""
DBPASS=""
DBNAME=""
DBHOST=""

if [ -e "wp-config.php" ]; then
  # wp
  FILELOC="wp-config.php"
  DBUSER=$(grep -m 1 DB_USER $FILELOC | cut -d \' -f 4)
  DBPASS=$(grep -m 1 DB_PASSWORD $FILELOC | cut -d \' -f 4)
  DBNAME=$(grep -m 1 DB_NAME $FILELOC | cut -d \' -f 4)
  DBHOST=$(grep -m 1 DB_HOST $FILELOC | cut -d \' -f 4 | cut -f1 -d":")
elif [ -e ".env" ]; then
  # laravel env file
  FILELOC=".env"
  DBUSER=$(grep -m 1 "DB_USERNAME" $FILELOC | cut -d \= -f 2)
  DBPASS=$(grep -m 1 "DB_PASSWORD" $FILELOC | cut -d \= -f 2)
  DBNAME=$(grep -m 1 "DB_DATABASE" $FILELOC | cut -d \= -f 2)
  DBHOST=$(grep -m 1 "DB_HOST" $FILELOC | cut -d \= -f 2)
elif [ -e "config/database.php" ]; then
  # laravel
  FILELOC="config/database.php"
  DBUSER=$(cat $FILELOC | php -w | grep -o "username.*" -m 1 | cut -d \' -f 3)
  DBPASS=$(cat $FILELOC | php -w | grep -o "password.*" -m 1 | cut -d \' -f 3)
  DBNAME=$(cat $FILELOC | php -w | grep -o "database.*" -m 1 | cut -d \' -f 3)
  DBHOST=$(cat $FILELOC | php -w | grep -o "host.*" -m 1 | cut -d \' -f 3 | cut -f1 -d":")
else
  echo -e "Unrecognized website"
  exit 1
fi

MYSQLDUMP=$(which mysqldump)
mysqldump --version | grep MariaDB > /dev/null || MYSQLDUMP="$MYSQLDUMP --column-statistics=0 --no-tablespaces"

case "${BASH_ARGV[0]}" in
  "shell")
    if readlink /proc/$$/fd/0 | grep -q "^pipe:"; then
        pv <&0 | sed -E 's/DEFINER=`[^`]+`@`[^`]+`/DEFINER=CURRENT_USER/g' | mysql -h $DBHOST -u$DBUSER -p$DBPASS $DBNAME
    else
        mysql -h $DBHOST -u$DBUSER -p$DBPASS $DBNAME -A
    fi
    ;;
  "dump")
    $MYSQLDUMP --lock-tables=false -h $DBHOST -u$DBUSER -p$DBPASS $DBNAME | sed -E 's/DEFINER=`[^`]+`@`[^`]+`/DEFINER=CURRENT_USER/g'
    ;;
  "creds")
    echo
    printf 'mysql -u%q -p%q -h%q %q\n' $DBUSER $DBPASS $DBHOST $DBNAME
    echo
    echo "host: $DBHOST"
    echo "user: $DBUSER"
    echo "pass: $DBPASS"
    echo "name: $DBNAME"
    echo
    ;;
  "killall")
    echo "SELECT CONCAT('KILL ',id,';') FROM information_schema.processlist" | db shell | grep -v CONCAT |  db shell
    ;;
  "backup")
    DATE=$(date +%Y%m%d)
    $MYSQLDUMP --lock-tables=false -h $DBHOST -u$DBUSER -p$DBPASS $DBNAME | sed -E 's/DEFINER=`[^`]+`@`[^`]+`/DEFINER=CURRENT_USER/g' | pv | gzip > $DBNAME-$DATE.sql.gz
    echo "Saved to $DBNAME-$DATE.sql.gz"
    ;;
  "set-domain")
    # Other code...
    ;;
  *)
    echo "Invalid command"
    ;;
esac
