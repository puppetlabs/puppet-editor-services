'use strict';

var tsparser = require('typescript-parser');
var fs = require('fs');
var path = require('path');

var lsptypes = require('vscode-languageserver-types')
var lspproto = require('vscode-languageserver-protocol');

const parser = new tsparser.TypescriptParser();
const lspOutputPath = path.resolve(__dirname, '..', '..', 'lib', 'lsp');

// We can't introspect enums easily so just use a list
// of types to "treat" as enums
const enumList = {
  // Enums from the vscode-languageserver-types module
  'DiagnosticSeverity': lsptypes.DiagnosticSeverity,
  'MarkupKind': lsptypes.MarkupKind,
  'CompletionItemKind': lsptypes.CompletionItemKind,
  'InsertTextFormat': lsptypes.InsertTextFormat,
  'DocumentHighlightKind': lsptypes.DocumentHighlightKind,
  'SymbolKind': lsptypes.SymbolKind,
  'CodeActionKind': lsptypes.CodeActionKind,
  'TextDocumentSaveReason': lsptypes.TextDocumentSaveReason,
  // Enums from the vscode-languageserver-protocol module
  'ResourceOperationKind': lspproto.ResourceOperationKind,
  'FailureHandlingKind': lspproto.FailureHandlingKind,
  'TextDocumentSyncKind': lspproto.TextDocumentSyncKind,
  'MessageType': lspproto.MessageType,
  'FileChangeType': lspproto.FileChangeType,
  'CompletionTriggerKind': lspproto.CompletionTriggerKind
}

// Some property names are reserved names in ruby, so mutate them
const propertyNameMunging = ['method'];

function GenerateRubyFromInterfaceProperties(iface) {
  var rubyText = '';

  var properties = [];

  var rubyAccessors = '';
  var optionalProperties = [];
  iface.properties.forEach( (item) => {
    var property = {}

    switch (item.constructor.name) {
      case 'PropertyDeclaration':
        var itemTypeText = item.type
        // If there's no type information, ignore it
        if (itemTypeText === undefined) { break; }
        var itemType = item.type
        itemTypeText = itemTypeText.replace(/\r/g, "");
        itemTypeText = itemTypeText.replace(/\n/g, "\n    #");

        if (itemTypeText.endsWith("'") && itemTypeText.startsWith("'")) {
          // This is a literal string type
          itemTypeText = 'string with value ' + itemTypeText;
          itemType = 'string_literal';
        }

        property.name = item.name;
        property.rubyname = property.name;

        if (propertyNameMunging.includes(item.name)) {
          property.rubyname = property.rubyname + "__lsp";
        }
        property.typetext = itemTypeText;
        property.type = itemType;
        property.optional = item.isOptional;
        properties.push(property)
        break;

      default:
        console.log("Ignoring property [" + item.constructor.name + "] " + item.name);
        break;
    }
  });
  return properties;
}

function GenerateRubyFromProperty(prop, allTypes) {
  const prefix = "      self." + prop.rubyname + " = "
  const defaultText      = prefix + "value['" + prop.name + "']\n"
  const defaultArrayText = prefix + "value['" + prop.name + "'].map { |val| val } unless value['" + prop.name + "'].nil?" + "\n"

  if (prop.type.endsWith('[]') && !prop.type.match(/\|/)) {
    // Array Type
    const propName = prop.type.substring(0, prop.type.length - 2);
    if (propName == 'any') { return defaultArrayText; }
    if (propName == 'string') { return defaultArrayText; }
    if (propName == 'number') { return defaultArrayText; }

    const thatType = allTypes[propName];
    if (thatType != null) {
      return prefix + "to_typed_aray(value['" + prop.name + "'], " + propName + ")\n"
    }

    return defaultArrayText.replace(/\n/, " # Unknown array type\n");
  } else {
    if (prop.type == 'any') { return defaultText; }
    if (prop.type == 'string') { return defaultText; }
    if (prop.type == 'number') { return defaultText; }

    const thatType = allTypes[prop.type];
    if (thatType != null) {
      return prefix + prop.type + ".new(value['" + prop.name + "']) unless value['" + prop.name + "'].nil?\n"
    }

    return defaultText.replace(/\n/, " # Unknown type\n");
  }
}

function GenerateRubyFile(parsed, fileContent, ignoreInterfaces = []) {
  var rubyContent = '';
  const extensionReg = /export interface \w+ extends ([\w,\s]+) {/;

  var interfaceList = {}

  for (var index = 0; index < parsed.declarations.length; index++ ) {
    const item = parsed.declarations[index];
    switch (item.constructor.name) {
      case 'InterfaceDeclaration':
      case 'ClassDeclaration':
        if (ignoreInterfaces.includes(item.name)) {
          console.log("Explicitly ignoring item [" + item.constructor.name + "] " + item.name);
          break;
        }

        var iface = {
          rubyincludes: []
        }
        // TODO Extract the documentation text?

        // Find the EOL character
        var endOfLineIndex = item.end
        while (endOfLineIndex < fileContent.length && fileContent[endOfLineIndex] != "\n" && fileContent[endOfLineIndex] != "\r") { endOfLineIndex++; }
        const doc = fileContent.slice(item.start, endOfLineIndex).toString();
        // Strip carriage returns
        iface.doc = doc.replace(/\r/g, '');
        // Strip leading linefeeds
        iface.doc = iface.doc.replace(/^[\n]+/g, '');
        // Strip trailing linefeeds
        iface.doc = iface.doc.replace(/[\n]+$/g, '');

        // Check for "extends" in interface definition
        // The textmate-parser DOESN'T get this information :-( so have to resort to regex
        const ifaceExtensions = doc.match(extensionReg);
        if (ifaceExtensions != null) {
          ifaceExtensions[1].split(',').forEach( (extName) => {
            iface.rubyincludes.push(extName.trim());
          });
        }

        iface.properties = GenerateRubyFromInterfaceProperties(item);
        interfaceList[item.name] = iface;
        break;

      default:
        console.log("Ignoring item [" + item.constructor.name + "] " + item.name);
        break;
    }
  };

  // Second Pass
  // Add in any included classes.
  // Only add properties that don't already exist
  Object.keys(interfaceList).forEach( (itemName) => {
    var thisIface = interfaceList[itemName];
    var thisProperties = thisIface.properties.map( (item) => { return item.name; });

    thisIface.rubyincludes.forEach( (thatName) => {
      var thatIface = interfaceList[thatName];
      thatIface.properties.forEach( (thatProp) => {
        if (!thisProperties.includes(thatProp.name)) {
          thisIface.properties.push(thatProp);
        }
      });
    })
  });

  // Export all of the interfaces into Ruby code.
  rubyContent = '';
  var firstItem = true;
  Object.keys(interfaceList).forEach( (itemName) => {
    iface = interfaceList[itemName];
    if (!firstItem) { rubyContent += "\n"; } else { firstItem = false; }
    // Spit out the documentation
    var docs = iface.doc;
    docs = docs.replace(/\n/g, "\n  # ");
    // Remove trailing whitespace
    docs = docs.replace(/  # \n/, "  #\n");
    rubyContent += "  # " + docs + "\n";
    rubyContent += '  class ' + itemName + " < LSPBase\n"

    // Spit out the property declarations.
    iface.properties.forEach( (item) => {
      rubyContent += "    attr_accessor :" + item.rubyname + " # type: " + item.typetext + "\n";
    })

    // Create the class initializer
    var rubyInitialize = '';
    const optionalProperties = iface.properties.filter( (item) => { return item.optional; })
                                               .map( (item) => { return item.rubyname; });
    if (optionalProperties.length > 0) {
      rubyInitialize = "      @optional_method_names = %i[" + optionalProperties.join(" ") + "]\n";
    }
    if (rubyInitialize != '') { rubyContent += "\n    def initialize(initial_hash = nil)\n      super\n" + rubyInitialize + "    end\n"; }

    // Create the hash deserializer
    rubyContent += "\n    def from_h!(value)\n      value = {} if value.nil?\n"
    iface.properties.forEach( (prop) => {
      rubyContent += GenerateRubyFromProperty(prop, interfaceList);
    });
    rubyContent += "      self\n    end\n";

    rubyContent += "  end\n";
  });

  return rubyContent;
}

function GenerateRubyEnums(enumList) {
  var rubyText = '';
  var firstItem = true;

  Object.keys(enumList).forEach( (enumName, itemIndex) => {
    var enumType = enumList[enumName];
    if (itemIndex > 0) { rubyText += "\n" }

    rubyText += "  module " + enumName + "\n";

    Object.getOwnPropertyNames(enumType).forEach( (enumItemName) => {
      var rubyValue = enumType[enumItemName];
      switch (rubyValue.constructor.name) {
        case 'String':
          rubyValue = "'" + rubyValue + "'"
          break;
        case 'Function':
          // Ignore function constants.
          rubyValue = '';
          break;
      }

      if (rubyValue != '') {
        rubyText += "    " + enumItemName.toUpperCase() + " = " + rubyValue + "\n"
      }
    })
    rubyText += "  end\n";
  })

  return rubyText;
}

function GenerateRubyFileHeader(description) {
  return "# frozen_string_literal: true\n\n" +
         "# DO NOT MODIFY. This file is built automatically\n# " + description + "\n\n" +
         "# rubocop:disable Layout/EmptyLinesAroundClassBody\n" +
         "# rubocop:disable Lint/UselessAssignment\n" +
         "# rubocop:disable Style/AsciiComments\n" +
         "\nmodule LSP\n";
}

function GenerateRubyFileFooter() {
  return "end\n\n" +
         "# rubocop:enable Layout/EmptyLinesAroundClassBody\n" +
         "# rubocop:enable Lint/UselessAssignment\n" +
         "# rubocop:enable Style/AsciiComments\n";
}

// ----------------------------

var rubyFileList = ['lsp_base', 'lsp_custom'];

rubyFileList.push('lsp_types');
parser.parseFile('./node_modules/vscode-languageserver-types/lib/esm/main.d.ts', 'workspace root').then(
  (value) => {
    const fileContent = fs.readFileSync(value.filePath, { encoding: 'UTF8'});
    fs.writeFileSync(path.join(lspOutputPath, 'lsp_types.rb'),
      GenerateRubyFileHeader('LSP Protocol: vscode-languageserver-types/lib/esm/main.d.ts') +
      GenerateRubyFile(value, fileContent, [
        'TextEditChange'
      ]) +
      GenerateRubyFileFooter(), { encoding: 'UTF8'});
  }
);

rubyFileList.push('lsp_enums');
// Export Enums
fs.writeFileSync(path.join(lspOutputPath, 'lsp_enums.rb'),
  GenerateRubyFileHeader('LSP Enumerations') +
  GenerateRubyEnums(enumList) +
  GenerateRubyFileFooter(), { encoding: 'UTF8'});

// TODO: This is far from perfect due to type imports e.g. `TextDocumentIdentifier` appears as "Unknown Type"
// because it's defined in a different file.  Ideally we should be following the imports (value.import) and keeping a global
// cache of all the parsed types. But it will do for now at least.
const protocolDir = './node_modules/vscode-languageserver-protocol/lib'
fs.readdirSync(protocolDir).forEach((item) => {
  if (item.startsWith('protocol.') && item.endsWith('.d.ts')) {
    var rubyFilename = "lsp_" + item.slice(0, -5).replace(".", "_").toLowerCase();
    rubyFileList.push(rubyFilename);
    rubyFilename += ".rb";

    parser.parseFile(protocolDir + '/' + item, 'workspace root').then(
      (value) => {
        const fileContent = fs.readFileSync(value.filePath, { encoding: 'UTF8'});
        fs.writeFileSync(path.join(lspOutputPath, rubyFilename),
          GenerateRubyFileHeader('LSP Protocol: vscode-languageserver-protocol/lib/' + item) +
          // Unfortunately the protocol here splits out the client and server capabilities into separate objects
          // In this case we'll ignore them for automagic generation and manually create the ruby classes
          GenerateRubyFile(value, fileContent, [
            '_ClientCapabilities',
            'TextDocumentClientCapabilities',
            'WorkspaceClientCapabilities',
            '_InitializeParams',
            '_ServerCapabilities'
          ]) +
          GenerateRubyFileFooter(), { encoding: 'UTF8'});
      }
    );
  }
});

// Write out lsp.rb which loads in all of the other files
var content =
`# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# See tools/lsp_introspect/index.js

%w[${rubyFileList.join(' ')}].each do |lib|
  begin
    require "lsp/#{lib}"
  rescue LoadError
    require File.expand_path(File.join(File.dirname(__FILE__), lib))
  end
end
`
fs.writeFileSync(path.join(lspOutputPath, 'lsp.rb'), content, { encoding: 'UTF8'});
