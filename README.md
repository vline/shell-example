# vLine Shell Example

## Configure your service id

Open index.html and replace the string `'YOUR_SERVICE_ID'` with the id of a service created with the
[vLine Developer Console](https://vline.com/developer).

## Running

WebRTC javascript APIs do not work when a site is served from a `file://` url, 
so even when developing locally, you _must_ serve your html from web server. Here's how:

### Mac

The `server.sh` script will start a new instance of Apache, which should already be installed on your Mac. 
You can then access the app at [http://localhost:4567](http://localhost:4567).

### Linux

The `server.sh` script will start a new instance of Apache, which may already be installed on your system. 
If Apache is not installed, the script will prompt you with instructions on how to install it.
You can then access the app at [http://localhost:4567](http://localhost:4567).

### Windows

Download the [Mongoose web server](https://code.google.com/p/mongoose/downloads/detail?name=mongoose-3.7.exe)
and copy it to the example `source` directory. Double-click the executable to start
the server. You should now be able to access the app at [http://localhost:8080](http://localhost:8080).
