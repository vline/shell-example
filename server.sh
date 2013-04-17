#!/bin/bash

#
# Default config values
#
HTTPD=$(which httpd 2>/dev/null || which apache2 2>/dev/null)
if [ "x$HTTPD" = "x" ]; then
  HTTPD=/usr/sbin/httpd
fi

TYPES_CONFIG=
PORT=4567

#
# Attempt to find the modules dir
#
MODULE_DIR=libexec/apache2
if [ `uname` = "Linux" ]; then
  TYPES_CONFIG="TypesConfig \"/etc/mime.types\""
  MODULE_DIR=/usr/lib/apache2/modules
  if [ ! -d $MODULE_DIR ]; then
    MODULE_DIR=/usr/lib/httpd/modules
  fi
  if [ ! -d $MODULE_DIR ]; then
    MODULE_DIR=/usr/lib64/httpd/modules
  fi
fi

DIR_MODULE="LoadModule dir_module $MODULE_DIR/mod_dir.so"
LOG_CONFIG_MODULE="LoadModule log_config_module $MODULE_DIR/mod_log_config.so"
MIME_MODULE="LoadModule mime_module $MODULE_DIR/mod_mime.so"

#
# Check existing modules and don't load the built-in modules
#
if [ `uname` = "Linux" ]; then
  if [ ! -f "$MODULE_DIR/mod_dir.so" ]; then
    DIR_MODULE=""
  fi

  if [ ! -f "$MODULE_DIR/mod_log_config.so" ]; then
    LOG_CONFIG_MODULE=""
  fi
  
  if [ ! -f "$MODULE_DIR/mod_mime.so" ]; then
    MIME_MODULE=""
  fi
fi


#
# Print usage
#
function usage() {
  echo "usage: server.sh [-h] [-p PORT] [-e HTTPD_EXECUTABLE] [-m APACHE_MODULE_DIR]"
}

#
# Parse args
#
while getopts ":e:p:m:h" opt; do
  case $opt in
    e)
      HTTPD=$OPTARG
      ;;
    p)
      PORT=$OPTARG
      ;;
    m)
      MODULE_DIR=$OPTARG
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      exit 1
      ;;
  esac
done

if [ ! -x "$HTTPD" ]; then
  if [ `uname` = "Linux" ]; then
    echo "If you are running Ubuntu or Debian, install Apache with: sudo apt-get update && sudo apt-get install apache2" >&2
    echo "If you are running RedHat or CentOS, install Apache with: sudo yum install httpd" >&2
  else
    echo "Could not find Apache. Do you have it installed?" >&2
  fi
  echo "After installing Apache, please re-run this script." >&2
  exit 2
fi

#
# Find project dir
#
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

CONF=$DIR/server/httpd.conf
ROOT=$DIR/source

#
# Create conf file
#
mkdir -p server
cat > $CONF <<EOF
Listen 127.0.0.1:$PORT
ServerName localhost
DocumentRoot "$ROOT"
PidFile "$DIR/server/httpd.pid"
LockFile "$DIR/server/accept.lock"
ErrorLog |/bin/cat

$TYPES_CONFIG

$DIR_MODULE
$LOG_CONFIG_MODULE
$MIME_MODULE

<Directory "$ROOT">
  Options Indexes
</Directory>

<IfModule mime_module>
  AddType text/html .html .htm
  AddType application/javascript .js
  AddType text/css .css
  AddType image/png .png
</IfModule>

<IfModule log_config_module>
  LogFormat "%t \"%r\" %>s %b" custom
  CustomLog |/bin/cat custom
</IfModule>
EOF

#
# Run apache
#
echo "Starting server at http://localhost:$PORT ...";echo
$HTTPD -f $CONF -DNO_DETACH -DFOREGROUND
