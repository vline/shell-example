# vLine Shell Example


## Setup

WebRTC javascript APIs do not work when a site is served from a `file://` url, 
so even when developing locally, you _must_ serve your html from a web server. Here's how:

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

## Running

* Create a video chat service with the [vLine Developer Console](https://vline.com/developer).
* This example will use two users, one of which will be logged in to the Web Client and the other which
will be logged in to the shell.
* Navigate to the `Users` page in the Developer Console and make sure you
have two users. If you need to create new users, you can click the `Add User` button. This example will assume that
you have created one user called `Test User` and another called `My Name`.
* On the `Users` page in the Developer Console, click on `Test User` and make note of the `User ID`. (It
will have the form `YOUR_SERVICE_ID:RANDOM_STRING`.)
* Log into your service's Web Client by opening a new browser window and navigating to https://YOUR_SERVICE_ID.vline
.com. Sign in with the `Test User` credentials.
* Open `source/index.html` in this example and replace the string `'YOUR_SERVICE_ID'` with the ID of the service you
created.
* In a separate browser window, open up the shell example by navigating to the localhost link described in
`Setup`.
* Log in to the shell example by entering the command `login`. Log in as the `Your Name` user.
* From the shell, send a message from your `Your Name` to `Test User` by entering command `write USERID
hello!`, where `USERID` is `Test User`'s ID that you made a note of in the previous steps. If everything works as
expected, you should see your test message in the Web Client browser window.
* From the shell, make a video call to `Test User` by entering the command `start-media USERID`. You should accept
the call in the Web Client, at which point you should see two images of yourself in the Web Client window and two
images in the shell window.
* To end the call from the shell, enter the command `stop-media`.

## Next Steps

You can get a list of all available commands by typing `help` at the prompt. To get more details for a specific
command, type `help command`. For example, to see the syntax for the `start-media` command type `help
start-media`.

This example only demonstrates a subset of the vLine JavaScript API. Explore the [documentation](https://vline.com/developer/docs/vline.js/) to learn about all the
 features.
