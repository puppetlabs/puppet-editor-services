[![Build Status](https://travis-ci.com/lingua-pupuli/puppetfile-resolver.svg?branch=master)](https://travis-ci.com/lingua-pupuli/puppetfile-resolver)

# Puppetfile Resolver

The [Puppetfile](https://puppet.com/docs/pe/latest/puppetfile.html) is used by Puppet to manage the collection of modules used by a Puppet master. The Puppetfile is then used by tools like [R10K](https://github.com/puppetlabs/r10k) and [Code Manager](https://puppet.com/docs/pe/latest/code_mgr_how_it_works.html#how-code-manager-works) to download and install the required modules.

However, the Puppetfile is designed to have explicit dependencies, that is, **all** modules and **all** of the dependencies must be specified in Puppetfile. This is very different to formats like `Gemfile` (Ruby) or `package.json` (NodeJS) where dependencies are brought in as needed.

Using explicit dependencies is great in a configuration management system like Puppet, but it puts the burden on updates onto the user.

This library includes all of the code to parse a Puppetfile and then calculate a dependency graph to try and resolve all of the module dependencies and versions. The resolver can also restrict on Puppet version, for example, only Modules which support Puppet 6.

**Note** This is still in active development. Git history may be re-written until an initial version is released

## To Do

- Could do with more tests
- Add YARD documentation

## Why a library and not a CLI tool?

Due to all of the different needs of tool developers, this is offered as a library instead of full blown CLI tool. For example, the needs of a VSCode Extensions developer are very different than that of the Puppet Developer Kit developer.

Therefore this is a library which is intended to be used by tool developers to create useful tools for users, and not really for direct use by users.

Note that a CLI is included (`puppetfile-cli.rb`) only as an example of how to create a tool using this library.

## Architecture

``` text
                    +-----------------+   +-----------------+   +-----------------+
                    | Forge Searcher  |   | Github Searcher |   | Local Searcher  |
                    +-------+---------+   +--------+--------+   +-------+---------+
                            |                      |                    |
                            +----------------------+--------------------+
                                                   |
                                                   |
                                                   V
            +--------+                        +----------+                          +-------------------+
-- Text --> | Parser | -- Document Model -+-> | Resolver | -- Dependency Graph -+-> | Resolution Result |
            +--------+                    |   +----------+                      |   +-------------------+
                                          |                                     |
                                          |                                     |
                                          V                                     V
                                    +-----------+                         +------------+
                                    | Document  |                         | Resolution |
                                    | Validator |                         | Validator  |
                                    +-----------+                         +------------+
```

### Puppetfile Parser

The parser converts the content of a Puppetfile into a document model (`PuppetfileResolver::Puppetfile`).

Currently only one Parser is available, `R10KEval`, which uses the same parsing logic as the [R10K Parser](https://github.com/puppetlabs/r10k/blob/master/lib/r10k/puppetfile.rb). In the future other parsers may be added, such as a [Ruby AST based parser](https://github.com/puppetlabs/r10k/pull/885).

### Puppetfile Document Validation

Even though a Puppetfile can be parsed, doesn't mean it's valid. For example, defining a module twice.

### Puppetfile Resolution

Given a Puppetfile document model, the library can attempt to recursively resolve all of the modules and their dependencies. The resolver be default will not be strict, that is, missing dependencies will not throw an error, and will attempt to also be resolved. When in strict mode, any missing dependencies will throw errors.

### Module Searchers

The Puppetfile resolution needs information about all of the available modules and versions, and does this through calling various Specification Searchers. Currently Puppet Forge, Github and Local FileSystem searchers are implemented. Additional searchers could be added, for example GitLab or SVN.

The result is a dependency graph listing all of the modules, dependencies and version information.

### Resolution validation

Even though a Puppetfile can be resolved, doesn't mean it is valid. For example, missing module dependencies are not considered valid.

### Dependency Graph

The resolver uses the [Molinillo](https://github.com/CocoaPods/Molinillo) ruby gem for dependency resolution. Molinillo is used in Bundler, among other gems, so it's well used and maintained project.

### Example workflow

1. Load the contents of a Puppetfile from disk

2. Parse the Puppetfile into a document model

3. Verify that the document model is valid

4. Create a resolver object with the document model, and the required Puppet version (optional)

5. Start the resolution

6. Validate the resolution against the document model

### Example usage

``` ruby
puppetfile_path = '/path/to/Puppetfile'

# Parse the Puppetfile into an object model
content = File.open(puppetfile_path, 'rb') { |f| f.read }
require 'puppetfile-resolver/puppetfile/parser/r10k_eval'
puppetfile = ::PuppetfileResolver::Puppetfile::Parser::R10KEval.parse(content)

# Make sure the Puppetfile is valid
unless puppetfile.valid?
  puts 'Puppetfile is not valid'
  puppetfile.validation_errors.each { |err| puts err }
  exit 1
end

# Create the resolver
# - Use the document we just parsed (puppetfile)
# - Don't restrict by Puppet version (nil)
resolver = PuppetfileResolver::Resolver.new(puppetfile, nil)

# Configure the resolver
cache                 = nil  # Use the default inmemory cache
ui                    = nil  # Don't output any information
module_paths          = []   # List of paths to search for modules on the local filesystem
allow_missing_modules = true # Allow missing dependencies to be resolved
opts = { cache: cache, ui: ui, module_paths: module_paths, allow_missing_modules: allow_missing_modules }

# Resolve
result = resolver.resolve(opts)

# Output resolution validation errors
result.validation_errors.each { |err| puts "Resolution Validation Error: #{err}\n"}
```

## Known issues

- The Forge module searcher will only use the internet facing forge ([https://forge.puppet.com](https://forge.puppet.com/)). Self-hosted forges are not supported

- The Git module searcher will only search public Github based modules. Private repositories or other VCS systems are not supported
