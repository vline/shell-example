#!/bin/bash

HTTPD=$(which httpd)
MODULE_DIR=libexec/apache2
PORT=4567

if [ "x$HTTP" = "x" ]; then
  if [ -x '/usr/sbin/httpd' ]; then
    HTTPD=/usr/sbin/httpd
  else
    echo "Could not find Apache. Do you have it installed?"
    exit
  fi
fi

# find project dir
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

CONF=$DIR/server/httpd.conf
ROOT=$DIR/source

# create conf file
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

# run apache
echo 'Starting server at http://localhost:$PORT ...';echo
$HTTPD -f $CONF -DNO_DETACH -DFOREGROUND
