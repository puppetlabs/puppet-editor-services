# 1. Aggregation of file resource type definitions

Date: 2023-11-27

## Status

Accepted

## Context

In [this issue](https://github.com/puppetlabs/puppet-editor-services/issues/349) raised on the `puppet-editor-services` repo, it was noted that the file resource type had multiple missing parameters in the dropdown autocompletion list. After some investigation, it was discovered that the parameters were missing due to the way the file resource type is defined in the puppet source code, with having multiple definitions in separate files. puppet-editor-services was only designed to collect the parameters in the initial definition found in `lib/puppet/type/file.rb`, and collected all parameters from this type declaration as you would expect. However, it would ignore all other parameters which were defined in the files `lib/puppet/type/file/*.rb`, and thus exlcuding them from the autocompletion list. (see [here](https://github.com/puppetlabs/puppet/tree/main/lib/puppet/type/file)).

## Decision

A decision was taken in [this pr](https://github.com/puppetlabs/puppet-editor-services/pull/353) (later updated to write to a tempfile [here](https://github.com/puppetlabs/puppet-editor-services/pull/359)) to aggregate all seperate file type defintions and write these to a single file, this could then be used as a single point of reference for the language server. This allowed puppet-editor-services to collect all parameters of the file type as expected.

## Consequences

* `Go To Definition` will direct the user to the initial file type declaration at `/lib/puppet/type/file.rb`, not to the other type definitions.
