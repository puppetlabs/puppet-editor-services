# The end-to-end testing file starts a langauge server as part of the testing.  This class is used
# to send and receive messages to the server.
#
# By setting the `SPEC_DEBUG` environment variable, it will display debug information to the console
# while the tests are being run.  This can be useful when figuring out why tests have failed

require 'socket'
require 'json'
require 'puppet-languageserver/uri_helper'
require_relative 'editor_client'
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
