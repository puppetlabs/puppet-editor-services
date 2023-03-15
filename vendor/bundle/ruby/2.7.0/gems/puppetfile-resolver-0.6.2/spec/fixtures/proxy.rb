require 'webrick'
require 'webrick/httpproxy'

proxy = WEBrick::HTTPProxyServer.new Port: (ARGV[0].nil? ? 32768 : ARGV[0])

trap 'INT'  do proxy.shutdown end
trap 'TERM' do proxy.shutdown end

proxy.start
