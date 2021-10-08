[![Editor Services CI](https://github.com/puppetlabs/puppet-editor-services/actions/workflows/editor-services-ci.yml/badge.svg)](https://github.com/puppetlabs/puppet-editor-services/actions/workflows/editor-services-ci.yml)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/puppetlabs/puppet-editor-services)

# Puppet Editor Services

A ruby based implementation of a [Language Server](https://github.com/Microsoft/language-server-protocol) and [Debug Server](TODO) for the Puppet Language.

## Requirements

* Puppet 5 or above

* Ruby 2.4 or above

**Note** that Puppet 4 (Ruby 2.1) is not supported

## Setting up editor services for development

* Ensure a modern ruby is installed (2.4+)

  The editor services support Puppet 5.0.0 and above

* Clone this repository

```
> git clone https://github.com/puppetlabs/puppet-editor-services.git

> cd puppet-editor-services
```

* Bundle the development gems

```
> bundle install

  ... < lots of text >
```

* Installed vendored gems

```
> bundle exec rake gem_revendor

  ... < lots of text >
```

# Language Server

## How to run the Language Server for Development

By default the language server will stop if no connection is made within 10 seconds and will also stop after a client disconnects.  Adding `--debug=stdout` will log messages to the console

```
> bundle exec ruby ./puppet-languageserver --debug=stdout
I, [2018-12-05T15:19:51.853802 #28756]  INFO -- : Language Server is v0.16.0
I, [2018-12-05T15:19:51.854809 #28756]  INFO -- : Using Puppet v5.5.8
D, [2018-12-05T15:19:51.856726 #28756] DEBUG -- : Detected additional puppet settings []
I, [2018-12-05T15:19:51.867798 #28756]  INFO -- : Initializing Puppet Helper...
D, [2018-12-05T15:19:51.867798 #28756] DEBUG -- : Initializing Document Store...
I, [2018-12-05T15:19:51.868726 #28756]  INFO -- : Initializing settings...
I, [2018-12-05T15:19:51.870728 #28756]  INFO -- : Starting RPC Server...
D, [2018-12-05T15:19:51.870728 #28756] DEBUG -- : Using Simple TCP
I, [2018-12-05T15:19:51.871729 #28756]  INFO -- : Using Facter v2.5.1
I, [2018-12-05T15:19:51.871729 #28756]  INFO -- : Preloading Puppet Types (Async)...
I, [2018-12-05T15:19:51.872728 #28756]  INFO -- : Preloading Facter (Async)...
I, [2018-12-05T15:19:51.873727 #28756]  INFO -- : Preloading Functions (Async)...
I, [2018-12-05T15:19:51.876727 #28756]  INFO -- : Preloading Classes (Async)...
D, [2018-12-05T15:19:51.876727 #28756] DEBUG -- : SidecarQueue Thread: Running sidecar ["ruby", "C:/Source/puppet-editor-services/puppet-languageserver-sidecar", "--action", "default_types", "--feature-flags="]
D, [2018-12-05T15:19:51.899795 #28756] DEBUG -- : SidecarQueue Thread: Running sidecar ["ruby", "C:/Source/puppet-editor-services/puppet-languageserver-sidecar", "--action", "default_functions", "--feature-flags="]
D, [2018-12-05T15:19:51.919794 #28756] DEBUG -- : TCPSRV: Services running. Press ^C to stop
D, [2018-12-05T15:19:51.920795 #28756] DEBUG -- : TCPSRV: Will stop the server in 10 seconds if no connection is made.
D, [2018-12-05T15:19:51.921809 #28756] DEBUG -- : TCPSRV: Will stop the server when client disconnects
LANGUAGE SERVER RUNNING localhost:55087
D, [2018-12-05T15:19:51.923800 #28756] DEBUG -- : TCPSRV: Started listening on localhost:55087.
A, [2018-12-05T15:19:54.520501 #28756]   ANY -- : SidecarQueue Thread: Calling sidecar with --action default_functions --feature-flags= returned exitcode 0,
D, [2018-12-05T15:19:54.532525 #28756] DEBUG -- : SidecarQueue Thread: default_functions returned 270 items
D, [2018-12-05T15:19:54.533522 #28756] DEBUG -- : SidecarQueue Thread: Running sidecar ["ruby", "C:/Source/puppet-editor-services/puppet-languageserver-sidecar", "--action", "default_classes", "--feature-flags="]
A, [2018-12-05T15:19:54.576503 #28756]   ANY -- : SidecarQueue Thread: Calling sidecar with --action default_types --feature-flags= returned exitcode 0,
D, [2018-12-05T15:19:54.638503 #28756] DEBUG -- : SidecarQueue Thread: default_types returned 81 items
A, [2018-12-05T15:19:56.732112 #28756]   ANY -- : SidecarQueue Thread: Calling sidecar with --action default_classes --feature-flags= returned exitcode 0,
D, [2018-12-05T15:19:56.732112 #28756] DEBUG -- : SidecarQueue Thread: default_classes returned 0 items
...
D, [2018-12-05T15:20:03.319045 #28756] DEBUG -- : TCPSRV: No connection has been received in 10 seconds.  Shutting down server.
D, [2018-12-05T15:20:03.320049 #28756] DEBUG -- : TCPSRV: Stopping services
D, [2018-12-05T15:20:03.377052 #28756] DEBUG -- : TCPSRV: Stopped listening on localhost:55087
D, [2018-12-05T15:20:03.377052 #28756] DEBUG -- : TCPSRV: Started shutdown process. Press ^C to force quit.
D, [2018-12-05T15:20:03.378052 #28756] DEBUG -- : TCPSRV: Stopping services
D, [2018-12-05T15:20:03.379050 #28756] DEBUG -- : TCPSRV: Waiting for workers to cycle down
I, [2018-12-05T15:20:03.632011 #28756]  INFO -- : Language Server exited.
```

To make the server run continuously add `--timeout=0` and `--no-stop` to the command line. For example;

```
> bundle exec ruby ./puppet-languageserver --debug=stdout --timeout=0 --no-stop
I, [2018-12-05T15:20:56.302414 #29752]  INFO -- : Language Server is v0.16.0
I, [2018-12-05T15:20:56.303391 #29752]  INFO -- : Using Puppet v5.5.8
D, [2018-12-05T15:20:56.306343 #29752] DEBUG -- : Detected additional puppet settings []
I, [2018-12-05T15:20:56.318333 #29752]  INFO -- : Initializing Puppet Helper...
D, [2018-12-05T15:20:56.318333 #29752] DEBUG -- : Initializing Document Store...
I, [2018-12-05T15:20:56.319346 #29752]  INFO -- : Initializing settings...
I, [2018-12-05T15:20:56.321337 #29752]  INFO -- : Starting RPC Server...
D, [2018-12-05T15:20:56.321337 #29752] DEBUG -- : Using Simple TCP
I, [2018-12-05T15:20:56.322332 #29752]  INFO -- : Using Facter v2.5.1
I, [2018-12-05T15:20:56.323335 #29752]  INFO -- : Preloading Puppet Types (Async)...
I, [2018-12-05T15:20:56.325337 #29752]  INFO -- : Preloading Facter (Async)...
I, [2018-12-05T15:20:56.326335 #29752]  INFO -- : Preloading Functions (Async)...
I, [2018-12-05T15:20:56.327333 #29752]  INFO -- : Preloading Classes (Async)...
...
D, [2018-12-05T15:20:56.365334 #29752] DEBUG -- : TCPSRV: Services running. Press ^C to stop
LANGUAGE SERVER RUNNING localhost:55180
D, [2018-12-05T15:20:56.374333 #29752] DEBUG -- : TCPSRV: Started listening on localhost:55180.
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
LANGUAGE SERVER RUNNING 127.0.0.1:55086
```

> Note the language server will stop after 10 seconds if no client connection is made.

Note that the Language Server will use TCP as the default transport on `localhost` at a random port.  The IP Address and Port can be changed using the `--ip` and `--port` arguments respectively.  For example to listen on all interfaces on port 9000;

```
> ruby ./puppet-languageserver --ip=0.0.0.0 --port=9000
```

To change the protocol to STDIO, that is using STDOUT and STDIN, use the `--stdio` argument.

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
        --enable-file-cache          ** DEPRECATED ** Enables the file system cache for Puppet Objects (types, class etc.)
        --[no-]cache                 Enable or disable all caching inside the sidecar. By default caching is enabled.
        --feature-flags=FLAGS        A list of comma delimited feature flags
        --puppet-settings=TEXT       Comma delimited list of settings to pass into Puppet e.g. --vardir,/opt/test-fixture
        --local-workspace=PATH       The workspace or file path that will be used to provide module-specific functionality. Default is no workspace path.
    -h, --help                       Prints this help
    -v, --version                    Prints the Langauge Server version
```

# Language Server Sidecar

## How to run the Language Server for Development

The Language Server Sidecar is a process used by the Language Server to get information about Puppet's environment, for example, all available functions, classes, and custom types. This tool is typically only run by the Language Server itself, but it can be used to diagnose issues.

The sidecar is told to perform an action (using the `action`) parameter and then, by default, outputs the JSON encoded result to STDOUT.  This can be changed to a text file using the `--output=PATH` argument.

Note that using the `--debug=STDOUT` option without directing the output to a text file will generate output on STDOUT which cannot be deserialized correctly. Typically this only used by a developer to inspect what the Sidecar is doing.

### Example usage

#### Confirm that the Sidecar loads correctly

The `noop` action just outputs an empty JSON array but can be used to confirm that the Sidecar does not error while loading Puppet.

```
> bundle exec ruby ./puppet-languageserver-sidecar --action=noop
[]
```

#### Output all default Puppet Types

```
> bundle exec ruby ./puppet-languageserver-sidecar --action=default_types
[{"key":"anchor","calling_source":"puppet/cache/lib/puppet/type/anchor.rb","sou ...
```

#### Output all default Puppet Functions with a different puppet configuration, and debug information

```
> bundle exec ruby ./puppet-languageserver-sidecar --action=default_types --puppet-settings=--vardir,./test/vardir,--confdir,./test/confdir --debug=STDOUT
I, [2018-12-05T15:42:56.679837 #51864]  INFO -- : Language Server Sidecar is v0.16.0
I, [2018-12-05T15:42:56.679837 #51864]  INFO -- : Using Puppet v5.5.8
D, [2018-12-05T15:42:56.680820 #51864] DEBUG -- : Detected additional puppet settings ["--vardir", "./test/vardir", "--confdir", "./test/confdir"]
D, [2018-12-05T15:42:56.690876 #51864] DEBUG -- : [PuppetHelper::load_functions] Starting
D, [2018-12-05T15:42:56.752804 #51864] DEBUG -- : [PuppetLanguageServerSidecar::load] Loading lib/puppet/parser/functions/assert_type.rb from cache
...
[{"key":"debug","calling_source":"lib/puppet/parser/functions.rb", ...
```

#### Output all Puppet Classes in a workspace directory

```
> bundle exec ruby ./puppet-languageserver-sidecar --action=workspace_classes --local-workspace=C:\source\puppetlabs-sqlserver
[{"key":"sqlserver::config","calling_source":"C:/Source/puppetlabs-sqlserver/manifests/config.pp","source":"C:/Source/puppetlabs-sqlserver/manifests/config.pp","line":25,"ch...
```

## Command line arguments

```
Usage: puppet-languageserver-sidecar.rb [options]
    -a, --action=NAME                The action for the sidecar to take. Expected ["noop", "default_classes", "default_functions", "default_types", "node_graph", "resource_list", "workspace_classes", "workspace_functions", "workspace_types"]
    -c, --action-parameters=JSON     JSON Encoded string containing the parameters for the sidecar action
    -w, --local-workspace=PATH       The workspace or file path that will be used to provide module-specific functionality. Default is no workspace path
    -o, --output=PATH                The file to save the output from the sidecar. Default is output to STDOUT
    -p, --puppet-settings=TEXT       Comma delimited list of settings to pass into Puppet e.g. --vardir,/opt/test-fixture
    -f, --feature-flags=FLAGS        A list of comma delimited feature flags to pass the the sidecar
    -n, --[no-]cache                 Enable or disable all caching inside the sidecar. By default caching is enabled.
        --debug=DEBUG                Output debug information.  Either specify a filename or 'STDOUT'. Default is no debug output
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
  * [Linux](https://puppet.com/docs/puppet/7/install_agents.html#install_nix_agents)
  * [Windows](https://puppet.com/docs/puppet/7/install_agents.html#install_windows_agents)
  * [MacOSX](https://puppet.com/docs/puppet/7/install_agents.html#install_mac_agents)


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
