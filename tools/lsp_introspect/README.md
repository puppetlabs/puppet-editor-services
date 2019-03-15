## Node LSP introspector

Downloads the associated LSP node modules and generates the Ruby
LSP types and enumerations for the Puppet Language Server


### Prerequisites

* NodeJS install (10.0+)


## Generate Types

1. Modify the versions of `vscode-languageserver-protocol` and `vscode-languageserver-types` in the package.json file located at `/tools/lsp_introspect/package.json`.  Note that dependencies must be specified explicitly, do not depend on npm to do that for you.

2. Run `npm install` to download the required node modules

3. Run `node index.js` to generate the ruby types

4. Commit the changes and raise a Pull Request