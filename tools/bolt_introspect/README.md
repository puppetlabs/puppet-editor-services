# Bolt Introspection

Bolt uses Puppet Modules to add functions and types to the Puppet language during Task and Plan execution.  This information is not available to Editor Services as it does not run in environments with the Bolt gem.  The introspection script can extract the metadata from the Bolt modules, using the Language Server Sidecar, and its serialisation protocol.

## Usage

Downloads a specific version of bolt and extracts the module metadata for caching into Editor Services

``` text
> bundle install

.... (lots of text)

> bundle exec ruby introspect_bolt.rb
```

This should regenerate all of the bolt files in `/lib/puppet-languageserver/static_data`

## Component Version Information

> This table is used by the introspection script

| Component       | Version |
| --------------- | ------- |
| Bolt            | 2.42.0  |
| Editor Services | 1.1.0   |
