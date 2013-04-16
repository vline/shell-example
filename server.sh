#!/bin/bash

#
# Default config values
#
HTTPD=$(which httpd)
if [ "x$HTTP" = "x" ]; then
  HTTPD=/usr/sbin/httpd
fi

MODULE_DIR=libexec/apache2
PORT=4567

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
  echo "Could not find Apache. Do you have it installed?" >&2
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

LoadModule dir_module $MODULE_DIR/mod_dir.so
LoadModule log_config_module $MODULE_DIR/mod_log_config.so
LoadModule mime_module $MODULE_DIR/mod_mime.so

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
