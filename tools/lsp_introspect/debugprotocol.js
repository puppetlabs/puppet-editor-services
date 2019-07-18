'use strict';

var tsparser = require('typescript-parser');
var fs = require('fs');
var path = require('path');

const parser = new tsparser.TypescriptParser();
const dspOutputPath = path.resolve(__dirname, '..', '..', 'lib', 'dsp');

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
        property.rubyname = ":" + item.name;
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
  const prefix = "      self." + prop.name + " = "
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
  const extensionReg = /interface \w+ extends ([\w,\s]+) {/;
  var interfaceList = {}

  var rootResource = parsed.resources[0];

  // Assume a 'export declare module DebugProtocol' so just use the first resource
  for (var index = 0; index < rootResource.declarations.length; index++ ) {
    const item = rootResource.declarations[index];
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
    rubyContent += '  class ' + itemName + " < DSPBase\n"

    // Spit out the property declarations.
    iface.properties.forEach( (item) => {
      rubyContent += "    attr_accessor :" + item.name + " # type: " + item.typetext + "\n";
    })

    // Create the class initializer
    var rubyInitialize = '';
    const optionalProperties = iface.properties.filter( (item) => { return item.optional; })
                                               .map( (item) => { return item.name; });
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

function GenerateRubyFileHeader(description) {
  return "# frozen_string_literal: true\n\n" +
         "# DO NOT MODIFY.This file is built automatically\n# " + description + "\n\n" +
         "# rubocop:disable Layout/EmptyLinesAroundClassBody\n" +
         "# rubocop:disable Lint/UselessAssignment\n" +
         "# rubocop:disable Style/AsciiComments\n" +
         "# rubocop:disable Layout/TrailingWhitespace\n" +
         "\nmodule DSP\n";
}

function GenerateRubyFileFooter() {
  return "end\n\n" +
         "# rubocop:enable Layout/EmptyLinesAroundClassBody\n" +
         "# rubocop:enable Lint/UselessAssignment\n" +
         "# rubocop:enable Style/AsciiComments\n" +
         "# rubocop:enable Layout/TrailingWhitespace\n";
}

parser.parseFile('./node_modules/vscode-debugprotocol/lib/debugProtocol.d.ts', 'workspace root').then(
  (value) => {
    const fileContent = fs.readFileSync(value.filePath, { encoding: 'UTF8'});
    fs.writeFileSync(path.join(dspOutputPath, 'dsp_protocol.rb'),
      GenerateRubyFileHeader('DSP Protocol: vscode-debugprotocol/lib/debugProtocol.d.ts') +
      GenerateRubyFile(value, fileContent, []) +
      GenerateRubyFileFooter(), { encoding: 'UTF8'});
  }
);
