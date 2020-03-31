# The end-to-end testing file starts a langauge server as part of the testing.  This class is used
# to send and receive messages to the server.
#
# By setting the `SPEC_DEBUG` environment variable, it will display debug information to the console
# while the tests are being run.  This can be useful when figuring out why tests have failed

require 'socket'
require 'json'
require 'puppet-languageserver/uri_helper'

# Custom RSpec Matchers

RSpec::Matchers.define :receive_message_with_request_id_within_timeout do |request_seq_id, timeout = 5|
  match do |client|
    client.wait_for_message_with_request_id(request_seq_id, timeout)
  end

  failure_message do |client|
    message =  "expected that client would event with request id '#{request_seq_id}' event within #{timeout} seconds\n"
    message += "Last 5 messages\n"
    client.received_messages.last(5).each { |item| message += "#{item}\n" }
    message
  end
end

RSpec::Matchers.define :receive_notification_within_timeout do |notification_name, timeout = 5|
  match do |client|
    client.wait_for_message_with_notification(notification_name, timeout)
  end

  failure_message do |client|
    message = "expected that client would recieve '#{notification_name}' notification within #{timeout} seconds\n"
    message += "Last 5 messages\n"
    client.received_messages.last(5).each { |item| message += "#{item}\n" }
    message
  end
end

RSpec::Matchers.define :close_within_timeout do |timeout = 5|
  match do |client|
    client.wait_close_within_timeout(timeout)
  end

  failure_message do |client|
    message = "expected that client close the socket within #{timeout} seconds\n"
    message
  end
end

class EditorClient
  attr_reader :received_messages
  attr_accessor :debug
  attr_accessor :client_settings
  attr_accessor :document_list

  def initialize(host = nil, port = nil)
    # TODO: Add connection attempt retries
    @socket = TCPSocket.open(host, port) unless host.nil? || port.nil?
    @buffer = []
    @received_messages = []
    @new_messages = false
    @tx_seq_id = 0
    debug = false
    @client_settings = default_client_settings
    @document_list = {}
  end

  def default_client_settings
    {
      'puppet' => {
        'editorService'    => {
          'enable'        => true,
          'debugFilePath' => '',
          'featureFlags'  => [],
          'formatOnType'  => { 'enable' => false },
          'hover'         => { 'showMetadataInfo' => true },
          'loglevel'      => 'normal',
          'protocol'      => 'tcp', # Not the default but that's what we use in testing
          'puppet'        => {
            'confdir'     => '',
            'environment' => '',
            'modulePath'  => '',
            'vardir'      => '',
            'version'     => '',
          },
          'tcp'           => {
            'address' => nil,
            'port'    => nil
          },
          'timeout'       => 10,
        },
        'format'           => { 'enable' => true },
        'installDirectory' => nil,
        'installType'      => 'auto',
        'notification'     => {
          'nodeGraph'      => 'messagebox',
          'puppetResource' => 'messagebox'
        },
        'pdk'              => { 'checkVersion' => true },
        'titleBar'         => { 'pdkNewModule.enable' => true },
        'validate'         => { 'resolvePuppetfiles' => true }
      }
    }
  end

  # Have any new messages been received since data has been sent to the server
  def new_messages?
    @new_messages
  end

  # Send data to the server
  def send_data(json_string)
    size = json_string.bytesize
    @new_messages = false
    puts "... Sent: #{json_string}" if self.debug
    @socket.write("Content-Length: #{size}\r\n\r\n" + json_string)
  end

  # The current sequence ID.  Used when sending messages
  def current_seq_id
    @tx_seq_id
  end

  # Return the next sequence ID
  def next_seq_id
    @tx_seq_id += 1
  end

  # Find the first message received that has the specfied request_sequence ID
  # Used when trying to find responses to requests
  def data_from_request_seq_id(request_seq_id)
    received_messages.find { |item| item['id'] == request_seq_id}
  end

  # Find the first message received that has the specfied notification
  def data_from_notification_name(notification_name)
    received_messages.find { |item| item['seq'] == nil && item['method'] == notification_name}
  end

  # Drains and processes any data send from the server to the client
  def read_data
    output = []
    # Adapted from the PowerShell manager.  Need to change it
    read_from_stream(@socket, 0.5) { |s| output << s }

    # there's ultimately a bit of a race here
    # read one more time after signal is received
    read_from_stream(@socket, 0) { |s| output << s }

    # string has been binary up to this point, so force UTF-8 now
    receive_data(output.join('').force_encoding(Encoding::UTF_8)) unless output.empty?
  end

  # Closes the TCP connection
  def close
    @socket.close
  end

  # Is the conection closed?
  def closed?
    @socket.closed?
  end

  # Clear the received messages list
  def clear_messages!
    @received_messages = []
  end

  # Sends the client settings by the old legacy 'workspace/didChangeConfiguration' notification
  def send_client_settings
    content = ::JSON.generate({
      'jsonrpc' => '2.0',
      'method' => 'workspace/didChangeConfiguration',
      'params' => { 'settings' => client_settings }
    })
    send_data(content)
  end

  def document_content(file_path)
    uri = PuppetLanguageServer::UriHelper.build_file_uri(file_path)
    document_list[uri].nil? ? nil : document_list[uri][:content].dup
  end

  # ----------------------- LSP Messages
  def puppet_getversion_request(seq_id)
    ::JSON.generate({
      'jsonrpc' => '2.0',
      'id'      => seq_id,
      'method'  => 'puppet/getVersion',
      'params'  => {}
    })
  end

  def puppet_getresource_request(seq_id, type_name)
    ::JSON.generate({
      'jsonrpc' => '2.0',
      'id'      => seq_id,
      'method'  => 'puppet/getResource',
      'params'  => { 'typename' => type_name }
    })
  end

  def puppet_compilenodegraph_request(seq_id, uri)
    ::JSON.generate({
      'jsonrpc' => '2.0',
      'id'      => seq_id,
      'method'  => 'puppet/compileNodeGraph',
      'params'  => { 'external' => uri }
    })
  end

  def completion_request(seq_id, uri, line, char, trigger_kind = LSP::CompletionTriggerKind::INVOKED, trigger_character = nil)
    hash = {
      'jsonrpc' => '2.0',
      'id'      => seq_id,
      'method'  => 'textDocument/completion',
      'params'  => {
        'textDocument' => {
          'uri' => uri,
        },
        'position'     => {
          'line'      => line,
          'character' => char,
        },
        'context' => { 'triggerKind' => trigger_kind }
      }
    }
    hash['params']['context']['triggerCharacter'] = trigger_character unless trigger_character.nil? || trigger_kind != LSP::CompletionTriggerKind::TRIGGERCHARACTER
    ::JSON.generate(hash)
  end

  def completion_resolve_request(seq_id, item)
    ::JSON.generate({
      'jsonrpc' => '2.0',
      'id'      => seq_id,
      'method'  => 'completionItem/resolve',
      'params'  => item
    })
  end

  def did_change_notification(file_path, content)
    uri = PuppetLanguageServer::UriHelper.build_file_uri(file_path)
    raise "Document not yet opened #{file_path}" if document_list[uri].nil?
    document_list[uri][:content] = content
    document_list[uri][:version] += 1
    ::JSON.generate({
      'jsonrpc' => '2.0',
      'method'  => 'textDocument/didChange',
      'params'  => {
        'textDocument' => {
          'uri'        => uri,
          'version'    => document_list[uri][:version],
        },
        'contentChanges' => [{ 'text' => document_list[uri][:content] }] # Only use full document syncs
      }
    })
  end

  def did_open_notification(file_path, version)
    uri = PuppetLanguageServer::UriHelper.build_file_uri(file_path)
    document_list[uri] = {
      :content => File.open(file_path, 'rb:UTF-8') { |f| f.read },
      :version => version,
      :lang    => 'puppet',
    }
    ::JSON.generate({
      'jsonrpc' => '2.0',
      'method'  => 'textDocument/didOpen',
      'params'  => {
        'textDocument' => {
          'uri'        => uri,
          'languageId' => document_list[uri][:lang],
          'version'    => document_list[uri][:version],
          'text'       => document_list[uri][:content]
        }
      }
    })
  end

  def document_symbols_request(seq_id, uri)
    ::JSON.generate({
      'jsonrpc' => '2.0',
      'id'      => seq_id,
      'method'  => 'textDocument/documentSymbol',
      'params'  => {
        'textDocument' => {
          'uri' => uri,
        },
      }
    })
  end

  def exit_notification
    ::JSON.generate({
      'jsonrpc' => '2.0',
      'method' => 'exit'
    })
  end

  def formatting_request(seq_id, uri)
    ::JSON.generate({
      'jsonrpc' => '2.0',
      'id'      => seq_id,
      'method'  => 'textDocument/formatting',
      'params'  => {
        'textDocument' => { 'uri' => uri },
        'options'      => { 'tabSize' => 2, 'insertSpaces' => true }
      }
    })
  end

  def hover_request(seq_id, uri, line, char)
    ::JSON.generate({
      'jsonrpc' => '2.0',
      'id'      => seq_id,
      'method'  => 'textDocument/hover',
      'params'  => {
        'textDocument' => {
          'uri' => uri,
        },
        'position'     => {
          'line'      => line,
          'character' => char,
        }
      }
    })
  end

  def initialized_notification
    ::JSON.generate({
      'jsonrpc' => '2.0',
      'method' => 'initialized',
      'params' => {}
    })
  end

  def initialize_request(seq_id, workspace_path)
    # TODO: RootPath/RootUri
    # Based off of a VSCode 1.40.2 startup
    # Dynamic registration is turned off as it's too hard to mimic that.
    ::JSON.generate({
      'jsonrpc' => '2.0',
      'id' => seq_id,
      'method' => 'initialize',
      'params' => {
        'processId' => 26840,
        'rootPath' => workspace_path,
        'rootUri' => nil,
        'capabilities' => {
          'workspace' => {
            'applyEdit' => true,
            'workspaceEdit' => {
              'documentChanges' => true,
              'resourceOperations' => ['create', 'rename', 'delete'],
              'failureHandling' => 'textOnlyTransactional'
            },
            'didChangeConfiguration' => {
              'dynamicRegistration' => false
            },
            'didChangeWatchedFiles' => {
              'dynamicRegistration' => false
            },
            'symbol' => {
              'dynamicRegistration' => false,
              'symbolKind' => {
                'valueSet' => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26]
              }
            },
            'executeCommand' => {
              'dynamicRegistration' => false
            },
            'configuration' => true,
            'workspaceFolders' => true
          },
          'textDocument' => {
            'publishDiagnostics' => {
              'relatedInformation' => true
            },
            'synchronization' => {
              'dynamicRegistration' => false,
              'willSave' => true,
              'willSaveWaitUntil' => true,
              'didSave' => true
            },
            'completion' => {
              'dynamicRegistration' => false,
              'contextSupport' => true,
              'completionItem' => {
                'snippetSupport' => true,
                'commitCharactersSupport' => true,
                'documentationFormat' => ['markdown', 'plaintext'],
                'deprecatedSupport' => true,
                'preselectSupport' => true
              },
              'completionItemKind' => {
                'valueSet' => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]
              }
            },
            'hover' => {
              'dynamicRegistration' => false,
              'contentFormat' => ['markdown', 'plaintext']
            },
            'signatureHelp' => {
              'dynamicRegistration' => false,
              'signatureInformation' => {
                'documentationFormat' => ['markdown', 'plaintext'],
                'parameterInformation' => {
                  'labelOffsetSupport' => true
                }
              }
            },
            'definition' => {
              'dynamicRegistration' => false,
              'linkSupport' => true
            },
            'references' => {
              'dynamicRegistration' => false
            },
            'documentHighlight' => {
              'dynamicRegistration' => false
            },
            'documentSymbol' => {
              'dynamicRegistration' => false,
              'symbolKind' => {
                'valueSet' => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26]
              },
              'hierarchicalDocumentSymbolSupport' => true
            },
            'codeAction' => {
              'dynamicRegistration' => false,
              'codeActionLiteralSupport' => {
                'codeActionKind' => {
                  'valueSet' => ['', 'quickfix', 'refactor', 'refactor.extract', 'refactor.inline', 'refactor.rewrite', 'source', 'source.organizeImports']
                }
              }
            },
            'codeLens' => {
              'dynamicRegistration' => false
            },
            'formatting' => {
              'dynamicRegistration' => false
            },
            'rangeFormatting' => {
              'dynamicRegistration' => false
            },
            'onTypeFormatting' => {
              'dynamicRegistration' => false
            },
            'rename' => {
              'dynamicRegistration' => false,
              'prepareSupport' => true
            },
            'documentLink' => {
              'dynamicRegistration' => false
            },
            'typeDefinition' => {
              'dynamicRegistration' => false,
              'linkSupport' => true
            },
            'implementation' => {
              'dynamicRegistration' => false,
              'linkSupport' => true
            },
            'colorProvider' => {
              'dynamicRegistration' => false
            },
            'foldingRange' => {
              'dynamicRegistration' => false,
              'rangeLimit' => 5000,
              'lineFoldingOnly' => true
            },
            'declaration' => {
              'dynamicRegistration' => false,
              'linkSupport' => true
            }
          }
        },
        'trace' => 'off',
        'workspaceFolders' => nil
      }
    })
  end

  def ontype_format_request(seq_id, uri, line, char, character)
    ::JSON.generate({
      'jsonrpc' => '2.0',
      'id'      => seq_id,
      'method'  => 'textDocument/onTypeFormatting',
      'params'  => {
        'textDocument' => {
          'uri' => uri,
        },
        'position'     => {
          'line'      => line,
          'character' => char,
        },
        'ch'           => character,
        'options'      => { 'tabSize' => 2, 'insertSpaces' => true }
      }
    })
  end

  def range_formatting_request(seq_id, uri, from_line, from_char, to_line, to_char)
    ::JSON.generate({
      'jsonrpc' => '2.0',
      'id'      => seq_id,
      'method'  => 'textDocument/rangeFormatting',
      'params'  => {
        'textDocument' => { 'uri' => uri },
        'range' => {
          'start' => {
            'line'      => from_line,
            'character' => from_char
          },
          'end'   => {
            'line'      => to_line,
            'character' => to_char
          }
        },
        'options'      => { 'tabSize' => 2, 'insertSpaces' => true }
      }
    })
  end

  def shutdown_request(seq_id)
    ::JSON.generate({
      'jsonrpc' => '2.0',
      'id'      => seq_id,
      'method'  => 'shutdown',
    })
  end

  def signture_help_request(seq_id, uri, line, char)
    ::JSON.generate({
      'jsonrpc' => '2.0',
      'id'      => seq_id,
      'method'  => 'textDocument/signatureHelp',
      'params'  => {
        'textDocument' => {
          'uri' => uri,
        },
        'position'     => {
          'line'      => line,
          'character' => char,
        }
      }
    })
  end

  # Synchronously wait the language server to finish loading the default information
  def wait_for_puppet_loading(timeout = 5)
    exit_by = Time.now + timeout
    while exit_by > Time.now
      seq_id = next_seq_id
      send_data(puppet_getversion_request(seq_id))
      puts "... Waiting for puppet/getVersion response with everything loaded (timeout #{(exit_by - Time.now).truncate}s)" if self.debug
      return false unless wait_for_message_with_request_id(seq_id, 5)
      data = data_from_request_seq_id(seq_id)

      return true if data['result']['factsLoaded'] == true &&
                     data['result']['functionsLoaded'] == true &&
                     data['result']['typesLoaded'] == true &&
                     data['result']['classesLoaded'] == true

      sleep(5)
    end
    false
  end

  # Synchronously wait for a message with a specific request_id to appear
  def wait_for_message_with_request_id(request_seq_id, timeout = 5)
    exit_timeout = timeout
    while exit_timeout > 0 do
      puts "... Waiting for message with request id #{request_seq_id} (timeout #{exit_timeout}s)" if self.debug
      raise 'Client has been closed' if self.closed?
      self.read_data
      if self.new_messages?
        data = self.data_from_request_seq_id(request_seq_id)
        return true unless data.nil?
      end
      sleep(1)
      exit_timeout -= 1
    end
    false
  end

  # Synchronously wait for a message with a specific notification to appear
  def wait_for_message_with_notification(notification, timeout = 5)
    exit_timeout = timeout
    while exit_timeout > 0 do
      puts "... Waiting for message with notification '#{notification}' (timeout #{exit_timeout}s)" if self.debug
      raise 'Client has been closed' if self.closed?
      self.read_data
      if self.new_messages?
        data = self.data_from_notification_name(notification)
        return true unless data.nil?
      end
      sleep(1)
      exit_timeout -= 1
    end
    false
  end

  # Synchronously wait for the socket to be closed
  def wait_close_within_timeout(timeout = 5)
    exit_timeout = timeout
    while exit_timeout > 0 do
      puts "... Waiting for socket to close (timeout #{exit_timeout}s)" if self.debug
      return true unless is_stream_valid?(@socket)
      return true unless is_readable?(@socket)
      sleep(1)
      exit_timeout -= 1
    end

    false
  end

  private

  def parse_data(data)
    puts "... Received: #{data}" if self.debug
    @received_messages << JSON.parse(data)
    @new_messages = true
  end

  def extract_headers(raw_header)
    header = {}
    raw_header.split("\r\n").each do |item|
      name, value = item.split(':', 2)

      if name.casecmp('Content-Length').zero?
        header['Content-Length'] = value.strip.to_i
      elsif name.casecmp('Content-Type').zero?
        header['Content-Length'] = value.strip
      else
        raise("Unknown header #{name} in Language Server message")
      end
    end
    header
  end

  def receive_data(data)
    return if data.empty?
    return if @state == :ignore

    @buffer += data.bytes

    while @buffer.length > 4
      # Check if we have enough data for the headers
      # Need to find the first instance of '\r\n\r\n'
      offset = 0
      while offset < @buffer.length - 4
        break if @buffer[offset] == 13 && @buffer[offset + 1] == 10 && @buffer[offset + 2] == 13 && @buffer[offset + 3] == 10
        offset += 1
      end
      return unless offset < @buffer.length - 4

      # Extract the headers
      raw_header = @buffer.slice(0, offset).pack('C*').force_encoding('ASCII') # Note the headers are always ASCII encoded
      headers = extract_headers(raw_header)
      raise('Missing Content-Length header') if headers['Content-Length'].nil?

      # Now we have the headers and the content length, do we have enough data now
      minimum_buf_length = offset + 3 + headers['Content-Length'] + 1 # Need to add one as we're converting from offset (zero based) to length (1 based) arrays
      return if @buffer.length < minimum_buf_length

      # Extract the message content
      content = @buffer.slice(offset + 3 + 1, headers['Content-Length']).pack('C*').force_encoding('utf-8') # TODO: default is utf-8.  Need to enode based on Content-Type
      # Purge the buffer
      @buffer = @buffer.slice(minimum_buf_length, @buffer.length - minimum_buf_length)
      @buffer = [] if @buffer.nil?

      parse_data(content)
    end
  end

  def is_stream_valid?(stream)
    !stream.closed? && !stream.stat.nil?
  rescue # Ignore an errors
    false
  end

  def is_readable?(stream, timeout = 0.5)
    raise Errno::EPIPE if !is_stream_valid?(stream)
    read_ready = IO.select([stream], [], [], timeout)
    read_ready && stream == read_ready[0][0] && !stream.eof?
  end

  def read_from_stream(stream, timeout = 0.1, &block)
    if is_readable?(stream, timeout)
      data = stream.readpartial(4096)
      yield data unless data.nil?
    end

    nil
  end
end
