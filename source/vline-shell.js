/* ==========================================================
 * vline-shell.js
 * ==========================================================
 * Copyright 2013 vline, inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ========================================================== */

function vlineShell(serviceId, elem) {
  var $client, $session;

  $client = vline.Client.create(serviceId);

  // if we have a saved session, use it
  if ($client.isLoggedIn()) {
    $session = $client.getDefaultSession();
  }

  //
  // COMMANDS
  //
  function loginCmd(opt_identityProviderId) {
    if ($client.isLoggedIn()) {
      // vline.js supports multiple simultaneous logins, but this sample app does not
      this.error('Already logged in');
      return;
    }
    // use service's configured identity provider if none is provided
    var providerId = opt_identityProviderId || serviceId
    return $client.login(providerId).
        done(function(session) {
          $session = session;
          this.echo(formatLoginMessage_());
        }, this);
  }

  function logoutCmd() {
    $session = null;
    return $client.logout();
  }

  function fingerCmd(opt_userId) {
    var userId = opt_userId || $session.getLocalPersonId();
    return $session.getPerson(userId).
        done(function(person) {
          echoProfile_(this, person);
          person.release();
        }, this);
  }

  function writeCmd(userId, msg) {
    return $session.postMessage(userId, msg);
  }

  function startMediaCmd(userId) {
    return $session.startMedia(userId).
        done(addMediaSession_);
  }

  function stopMediaCmd(opt_userId) {
    if (opt_userId) {
      return $session.stopMedia(userId);
    } else {
      $client.stopMediaSessions();
    }
  }

  function helpCmd(opt_cmd) {
    if (opt_cmd) {
      var options = commands[opt_cmd];
      if (!options) {
        echoCmdNotFound_(this, opt_cmd);
        return;
      }
      this.echo(formatUsageMessage_(opt_cmd));
      if (options.help) {
        this.echo('    ' + options.help);
      }
    } else {
      this.echo(formatUsageMessage_('help'));
      this.echo('\nCommands:');
      for (var cmd in commands) {
        this.echo(' ' + cmd);
      }
    }
  }

  //
  // TERMINAL CALLBACKS
  //
  function onInit(term) {
    $client.on('recv:im', onIm, term);
  }

  //
  // VLINE EVENT HANDLERS
  //
  function onIm(event) {
    var msg = event.message,
        sender = msg.getSender();
    // format message in the style of the unix write command
    this.echo('\n[[;#FFF;]Message from ' + sender.getDisplayName() + ' at ' +
        new Date(msg.getCreationTime()).toLocaleTimeString() + ' ...]' +
        '\n[[;#0F0;]'+  msg.getBody(false) + ']' +
        '\n[[;#FFF;]EOF]');
  }

  //
  // HELPERS
  //
  function addMediaSession_(mediaSession) {
    // add event handler for add stream events
    mediaSession.on('mediaSession:addLocalStream mediaSession:addRemoteStream', function(event) {
      var stream = event.stream;

      // guard against adding a local video stream twice if it is attached to two media sessions
      if ($('#' + stream.getId()).length) {
        return;
      }

      // create video or audio element
      var elem = $(event.stream.createMediaElement());
      elem.prop('id', stream.getId());

      $('#video-wrapper').append(elem);
    });
    // add event handler for remove stream events
    mediaSession.on('mediaSession:removeLocalStream mediaSession:removeRemoteStream', function(event) {
      $('#' + event.stream.getId()).remove();
    });
  }

  function echoProfile_(term, person) {
    echoField_(term, 'Id', person.getId());
    echoField_(term, 'Login', person.getUsername());
    echoField_(term, 'Name', person.getDisplayName());
    echoUrlField_(term, 'Profile', person.getProfileUrl());
    echoUrlField_(term, 'Thumbnail', person.getThumbnailUrl());
  }

  function echoField_(term, label, value) {
    if (value) {
      term.echo(label + ': ' + value);
    }
  }

  function echoUrlField_(term, label, value) {
    if (value) {
      term.echo(label + ': <' + value + '>');
    }
  }

  function echoCmdNotFound_(term, cmd) {
    term.error("Command '" + cmd + "' not found");
  }

  function formatLoginMessage_() {
    var person = $session.getLocalPerson();
    return 'Logged in as ' + person.getDisplayName() +
        ' (' + (person.getUsername() || person.getId()) + ')';
  }

  function formatCompletionMessage_(cmd, startTime, msg) {
    var elapsedTime = new Date().getTime() - startTime;
    return '[' + cmd + ' ' + msg + ' - ' + elapsedTime + 'ms]';
  }

  function formatUsageMessage_(cmd) {
    var usageMsg = 'usage: ' + cmd,
        argsInfo = commands[cmd].usage;
    if (argsInfo) {
      usageMsg += ' ' + argsInfo;
    }
    return usageMsg;
  }

  function formatGreeting_() {
    var greeting =
        ("=====================================================\n"   +
            "         _     _              ____  _          _ _   \n"   +
            "  __   _| |   (_)_ __   ___  / ___|| |__   ___| | |  \n"   +
            "  % % / / |   | | '_ % / _ % %___ %| '_ % / _ % | |  \n"   +
            "   % V /| |___| | | | |  __/  ___) | | | |  __/ | |  \n"   +
            "    %_/ |_____|_|_| |_|%___| |____/|_| |_|%___|_|_|  \n\n" +
            "         An Example App for the vLine Cloud          \n\n" +
            "=====================================================\n\n"
            ).replace(/%/g, '\\');

    if ($client.isLoggedIn()) {
      greeting += formatLoginMessage_() + '\n';
    } else {
      greeting += "Type 'help' for a list of commands.\n";
    }
    return greeting;
  }

  //
  // TERMINAL COMMAND DISPATCHING
  //
  function execCmd_(term, cmd, args) {
    var startTime = new Date().getTime();

    // find handler and validate args
    var handler = getHandler_(term, cmd, args);
    if (!handler) return;

    // invoke callback
    var promise = handler.apply(term, args);
    if (promise) {
      // A promise will be returned by commands the execute asynchronously.
      // Add callbacks to output success or failure and elapsed time
      promise.
          done(function() {
            term.echo(formatCompletionMessage_(cmd, startTime, 'succeeded'));
          }).
          fail(function(err) {
            term.error(formatCompletionMessage_(cmd, startTime, 'failed: ' + err.message));
          });
    }
  }

  function getHandler_(term, cmd, args) {
    var config = commands[cmd];

    // validate login state
    if (config.login && !$client.isLoggedIn()) {
      term.error('Not logged in');
      return;
    }

    // validate number of args
    var minArgs = (config.args && config.args[0]) || 0,
        maxArgs = (config.args && config.args[1]) || minArgs;
    if (args.length < minArgs || args.length > maxArgs) {
      term.error(formatUsageMessage_(cmd));
      return;
    }

    // return callback
    return config.cb;
  }

  function makeExecutor_(cmd) {
    return (function() {
      execCmd_(this, cmd, arguments);
    });
  }

  var commands = {
    help: {
      cb: helpCmd
      ,args: [0,1]
      ,usage: 'command'
      ,help: 'Print help message for command.'
    }
    ,login: {
      cb: loginCmd
      ,args: [0,1]
      ,usage: '[identityProvider]'
      ,help: 'Create a new login session using specified identityProvider.'
    }
    ,logout: {
      cb: logoutCmd
      ,login: true
      ,help: 'Logout of all login sessions.'
    }
    ,finger: {
      cb: fingerCmd
      ,args: [0,1]
      ,login: true
      ,usage: '[userId]'
      ,help: 'Print profile for user. If no userId is specified, print the profile for the local user.'
    }
    ,write: {
      cb: writeCmd
      ,args: [2]
      ,login: true
      ,usage: 'userId message'
      ,help: 'Send instant message.'
    }
    ,'start-media': {
      cb: startMediaCmd
      ,args: [1]
      ,usage: 'userId'
    }
    ,'stop-media': {
      cb: stopMediaCmd
      ,args: [0,1]
      ,usage: 'userId'
    }
  };

  var termCommands = (function() {
    var obj = {};
    for (var k in commands) {
      obj[k] = makeExecutor_(k);
    }
    return obj;
  })();

  var termOptions = {
    tabcompletion: true
    ,prompt: 'vsh-0.1$ '
    ,onInit: onInit
    ,greetings: formatGreeting_
    ,onBlur: function() {return false;}
  };

  $(elem).terminal(termCommands, termOptions);
}