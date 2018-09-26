[![AppVeyor Build status](https://ci.appveyor.com/api/projects/status/github/lingua-pupuli/puppet-editor-services?branch=master&svg=true)](https://ci.appveyor.com/project/jpogran/puppet-editor-services) [![Travis Build Status](https://travis-ci.org/lingua-pupuli/puppet-editor-services.svg?branch=master)](https://travis-ci.org/lingua-pupuli/puppet-editor-services.svg?branch=master)

# Puppet Editor Services

A ruby based implementation of a [Language Server](https://github.com/Microsoft/language-server-protocol) and [Debug Server](TODO) for the Puppet Langauge.

**Note** - This project is experimental until 1.0 is released

## Setting up editor services for development

* Ensure a modern ruby is installed (2.1+)

  The editor services support Puppet 4.10.12 and above

* Clone this repository

```
> git clone https://github.com/lingua-pupuli/puppet-editor-services.git

> cd puppet-editor-services
```

* Bundle the development gems

```
> bundle install

  ... < lots of text >
```

# Language Server

## How to run the Language Server for Development

By default the language server will stop if no connection is made within 10 seconds and will also stop after a client disconnects.  Adding `--debug=stdout` will log messages to the console

```
> bundle exec ruby ./puppet-languageserver --debug=stdout
I, [2018-04-17T14:21:56.696632 #16656]  INFO -- : Language Server is v0.10.0
I, [2018-04-17T14:21:56.697136 #16656]  INFO -- : Using Puppet v5.5.0
I, [2018-04-17T14:21:56.697632 #16656]  INFO -- : Initializing Puppet Helper Cache...
I, [2018-04-17T14:21:56.697632 #16656]  INFO -- : Initializing settings...
I, [2018-04-17T14:21:56.699633 #16656]  INFO -- : Starting RPC Server...
D, [2018-04-17T14:21:56.703638 #16656] DEBUG -- : TCPSRV: Services running. Press ^C to stop
D, [2018-04-17T14:21:56.703638 #16656] DEBUG -- : TCPSRV: Will stop the server in 10 seconds if no connection is made.
D, [2018-04-17T14:21:56.704135 #16656] DEBUG -- : TCPSRV: Will stop the server when client disconnects
LANGUAGE SERVER RUNNING 127.0.0.1:8081
D, [2018-04-17T14:21:56.707632 #16656] DEBUG -- : TCPSRV: Started listening on 127.0.0.1:8081.
I, [2018-04-17T14:21:56.717634 #16656]  INFO -- : Using Facter v2.5.1
I, [2018-04-17T14:21:56.718632 #16656]  INFO -- : Preloading Puppet Types (Sync)...
...
D, [2018-04-17T14:22:06.814835 #16656] DEBUG -- : TCPSRV: No connection has been received in 10 seconds.  Shutting down server.
D, [2018-04-17T14:22:06.815337 #16656] DEBUG -- : TCPSRV: Stopping services
D, [2018-04-17T14:22:06.816336 #16656] DEBUG -- : TCPSRV: Stopped listening on 127.0.0.1:8081
D, [2018-04-17T14:22:06.816833 #16656] DEBUG -- : TCPSRV: Started shutdown process. Press ^C to force quit.
D, [2018-04-17T14:22:06.817333 #16656] DEBUG -- : TCPSRV: Stopping services
D, [2018-04-17T14:22:06.817333 #16656] DEBUG -- : TCPSRV: Waiting for workers to cycle down
I, [2018-04-17T14:22:06.876334 #16656]  INFO -- : Language Server exited.
```

To make the server run continuously add `--timeout=0` and `--no-stop` to the command line. For example;

```
> bundle exec ruby ./puppet-languageserver --debug=stdout --timeout=0 --no-stop
I, [2018-04-17T14:23:11.286842 #16548]  INFO -- : Language Server is v0.10.0
I, [2018-04-17T14:23:11.287342 #16548]  INFO -- : Using Puppet v5.5.0
I, [2018-04-17T14:23:11.288843 #16548]  INFO -- : Initializing Puppet Helper Cache...
I, [2018-04-17T14:23:11.289343 #16548]  INFO -- : Initializing settings...
I, [2018-04-17T14:23:11.291841 #16548]  INFO -- : Starting RPC Server...
D, [2018-04-17T14:23:11.295343 #16548] DEBUG -- : TCPSRV: Services running. Press ^C to stop
LANGUAGE SERVER RUNNING 127.0.0.1:8081
D, [2018-04-17T14:23:11.299841 #16548] DEBUG -- : TCPSRV: Started listening on 127.0.0.1:8081.
I, [2018-04-17T14:23:11.313841 #16548]  INFO -- : Using Facter v2.5.1
I, [2018-04-17T14:23:11.318343 #16548]  INFO -- : Preloading Puppet Types (Sync)...
D, [2018-04-17T14:23:11.319842 #16548] DEBUG -- : [PuppetHelper::_load_default_types] Starting
...
I, [2018-04-17T14:23:22.869985 #16548]  INFO -- : Preloading Facter (Async)...
I, [2018-04-17T14:23:22.870489 #16548]  INFO -- : Preloading Functions (Async)...
I, [2018-04-17T14:23:22.870985 #16548]  INFO -- : Preloading Classes (Async)...
D, [2018-04-17T14:23:22.875987 #16548] DEBUG -- : [PuppetHelper::_load_default_functions] Starting
D, [2018-04-17T14:23:22.876985 #16548] DEBUG -- : [PuppetHelper::_load_default_classes] Starting
...
```

## How to run the Language Server in Production

* Ensure that Puppet Agent is installed

[Linux](https://docs.puppet.com/puppet/4.10/install_linux.html)

[Windows](https://docs.puppet.com/puppet/4.10/install_windows.html)

[MacOSX](https://docs.puppet.com/puppet/4.10/install_osx.html)


* Run the `puppet-languageserver` with ruby

> On Windows you need to run ruby with the `Puppet Command Prompt` which can be found in the Start Menu.  This enables the Puppet Agent ruby environment.

```
> ruby puppet-languageserver
LANGUAGE SERVER RUNNING 127.0.0.1:8081
```

Note the language server will stop after 10 seconds if no client connection is made.

## Command line arguments

```
Usage: puppet-languageserver.rb [options]
    -p, --port=PORT                  TCP Port to listen on.  Default is random port
    -i, --ip=ADDRESS                 IP Address to listen on (0.0.0.0 for all interfaces).  Default is localhost
    -c, --no-stop                    Do not stop the language server once a client disconnects.  Default is to stop
    -t, --timeout=TIMEOUT            Stop the language server if a client does not connection within TIMEOUT seconds.  A value of zero will not timeout.  Default is 10 seconds
    -d, --no-preload                 ** DEPRECATED ** Do not preload Puppet information when the language server starts.  Default is to preload
        --debug=DEBUG                Output debug information.  Either specify a filename or 'STDOUT'.  Default is no debug output
    -s, --slow-start                 Delay starting the Language Server until Puppet initialisation has completed.  Default is to start fast
        --stdio                      Runs the server in stdio mode, without a TCP listener
        --enable-file-cache          Enables the file system cache for Puppet Objects (types, class etc.)
        --local-workspace=PATH       The workspace or file path that will be used to provide module-specific functionality. Default is no workspace path.
    -h, --help                       Prints this help
    -v, --version                    Prints the Langauge Server version
```

# Debug Server

## How to run the Debug Server for Development

By default the language server will stop if no connection is made within 10 seconds and will also stop after a client disconnects.  Adding `--debug=stdout` will log messages to the console

```
> bundle exec ruby ./puppet-debugserver --debug=stdout
I, [2018-04-17T14:19:24.131869 #6940]  INFO -- : Debug Server is v0.10.0
I, [2018-04-17T14:19:24.132871 #6940]  INFO -- : Starting RPC Server...
D, [2018-04-17T14:19:24.135373 #6940] DEBUG -- : TCPSRV: Services running. Press ^C to stop
D, [2018-04-17T14:19:24.135870 #6940] DEBUG -- : TCPSRV: Will stop the server in 10 seconds if no connection is made.
D, [2018-04-17T14:19:24.135870 #6940] DEBUG -- : TCPSRV: Will stop the server when client disconnects
DEBUG SERVER RUNNING 127.0.0.1:8082
D, [2018-04-17T14:19:24.136871 #6940] DEBUG -- : TCPSRV: Started listening on 127.0.0.1:8082.
D, [2018-04-17T14:19:34.140900 #6940] DEBUG -- : TCPSRV: No connection has been received in 10 seconds.  Shutting down server.
D, [2018-04-17T14:19:34.140900 #6940] DEBUG -- : TCPSRV: Stopping services
D, [2018-04-17T14:19:34.141400 #6940] DEBUG -- : TCPSRV: Stopped listening on 127.0.0.1:8082
D, [2018-04-17T14:19:34.141900 #6940] DEBUG -- : TCPSRV: Started shutdown process. Press ^C to force quit.
D, [2018-04-17T14:19:34.141900 #6940] DEBUG -- : TCPSRV: Stopping services
D, [2018-04-17T14:19:34.142401 #6940] DEBUG -- : TCPSRV: Waiting for workers to cycle down
I, [2018-04-17T14:19:34.150402 #6940]  INFO -- : Debug Server exited.
```

To make the server run continuously add `--timeout=0` to the command line. For example;

```
> bundle exec ruby ./puppet-debugserver --debug=stdout --timeout=0
I, [2018-04-17T14:21:10.542332 #12424]  INFO -- : Debug Server is v0.10.0
I, [2018-04-17T14:21:10.543334 #12424]  INFO -- : Starting RPC Server...
D, [2018-04-17T14:21:10.545836 #12424] DEBUG -- : TCPSRV: Services running. Press ^C to stop
D, [2018-04-17T14:21:10.546336 #12424] DEBUG -- : TCPSRV: Will stop the server when client disconnects
DEBUG SERVER RUNNING 127.0.0.1:8082
D, [2018-04-17T14:21:10.546834 #12424] DEBUG -- : TCPSRV: Started listening on 127.0.0.1:8082.
...
```

## How to run the Debug Server for Production

* Ensure that Puppet Agent is installed

[Linux](https://docs.puppet.com/puppet/4.10/install_linux.html)

[Windows](https://docs.puppet.com/puppet/4.10/install_windows.html)

[MacOSX](https://docs.puppet.com/puppet/4.10/install_osx.html)


* Run the `puppet-debugserver` with ruby

> On Windows you need to run ruby with the `Puppet Command Prompt` which can be found in the Start Menu.  This enables the Puppet Agent ruby environment.

```
> ruby puppet-debugserver
DEBUG SERVER RUNNING 127.0.0.1:8082
```

Note the debug server will stop after 10 seconds if no client connection is made.

## Command line arguments

```
Usage: puppet-debugserver.rb [options]
    -p, --port=PORT                  TCP Port to listen on.  Default is random port}
    -i, --ip=ADDRESS                 IP Address to listen on (0.0.0.0 for all interfaces).  Default is localhost
    -t, --timeout=TIMEOUT            Stop the Debug Server if a client does not connection within TIMEOUT seconds.  A value of zero will not timeout.  Default is 10 seconds
        --debug=DEBUG                Output debug information.  Either specify a filename or 'STDOUT'.  Default is no debug output
    -h, --help                       Prints this help
    -v, --version                    Prints the Debug Server version
```

# Other information

## Why are there vendored gems and why only native ruby

When used by editors this language server will be running using the Ruby runtime provided by Puppet Agent.  That means no native extensions and no bundler.  Also, only the gems provided by Puppet Agent would be available by default.  To work around this limitation all runtime dependencies should be re-vendored and then the load path modified appropriately.

## Known Issues

* [PUP-7668](https://tickets.puppetlabs.com/browse/PUP-7668) Due to incorrect offsets, hover documentation can be displayed when the user is not actually hovering over the resource that the documentation is for.
