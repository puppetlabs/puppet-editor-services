gemsource_default = ENV['GEM_SOURCE'] || "https://rubygems.org"
source gemsource_default

# Puppet 9 is only published via puppetcore, not public RubyGems.
gemsource_puppetcore = if ENV['PUPPET_FORGE_TOKEN'] && !ENV['PUPPET_FORGE_TOKEN'].empty?
                          'https://rubygems-puppetcore.puppet.com'
                        else
                          ENV['GEM_SOURCE_PUPPETCORE'] || gemsource_default
                        end

# facter has no Ruby-4.0-compatible build on public RubyGems, so Ruby4 lanes must source it
# from puppetcore. Kept conditional so older Ruby lanes keep pulling facter's public build
# rather than puppetcore's latest (possibly untested for that lane).
gemsource_facter = if Gem.ruby_version >= Gem::Version.new('4.0')
                      gemsource_puppetcore
                    else
                      gemsource_default
                    end

# -=-=-=-=-=- WARNING -=-=-=-=-=-
# There should be NO runtime gem dependencies here.  In production this code will be running using the Ruby
# runtime provided by Puppet.  That means no native extensions and NO BUNDLER.  All runtime dependences should
# be re-vendored and then the load path modified appropriately.
#
# This gemfile only exists to help when developing the language server and running tests
# -=-=-=-=-=- WARNING -=-=-=-=-=-

group :development do
  gem 'rake', '>= 10.4',                  :require => false
  gem 'rspec', '>= 3.2',                  :require => false
  # logger moved from a Ruby default gem to a bundled gem; Bundler won't expose it
  # under Ruby 4.0 unless it's declared explicitly. lib/puppet_languageserver.rb
  # requires it directly.
  gem 'logger',                           :require => false
  gem 'puppet-lint', '~> 5.0',            :require => false
  gem 'puppetfile-resolver', '~> 0.6.2',  :require => false
  gem 'yard', '~> 0.9.28',                :require => false
  gem "rubocop", '~> 1.73.0',             :require => false
  gem "rubocop-performance", '~> 1.24.0', :require => false
  gem "rubocop-rspec", '~> 3.5.0',        :require => false
  gem 'rubocop-rspec_rails', '~> 2.31.0', :require => false
  gem 'rubocop-factory_bot', '~> 2.27.0', :require => false
  gem 'rubocop-capybara', '~> 2.22.0',    :require => false
  gem 'simplecov',                        :require => false
  gem 'simplecov-console',                :require => false
  gem 'json', "< 2.8.0",                  :require => false

  if ENV['PUPPET_GEM_VERSION']
    gem 'puppet', ENV['PUPPET_GEM_VERSION'], :require => false, :source => gemsource_puppetcore
  else
    gem 'puppet',                            :require => false, :source => gemsource_puppetcore
  end
  gem 'facter', :require => false, :source => gemsource_facter

  case RUBY_PLATFORM
  when /darwin/
    gem 'CFPropertyList'
  end

  # facter's Windows fact-gathering needs ffi at runtime, but it's only ever a facter dev
  # dependency -- declare it explicitly so it isn't silently missing on Windows lanes.
  gem "ffi",                        :require => false, :platforms => ["mswin", "mingw", "x64_mingw"]
  gem "win32-dir", "<= 0.4.9",      :require => false, :platforms => ["mswin", "mingw", "x64_mingw"]
  gem "win32-eventlog", "<= 0.6.5", :require => false, :platforms => ["mswin", "mingw", "x64_mingw"]
  gem "win32-process", "<= 0.7.5",  :require => false, :platforms => ["mswin", "mingw", "x64_mingw"]
  gem "win32-security", "<= 0.2.5", :require => false, :platforms => ["mswin", "mingw", "x64_mingw"]
  gem "win32-service", "<= 0.8.8",  :require => false, :platforms => ["mswin", "mingw", "x64_mingw"]

  # Gems for building release tarballs etc.
  gem "archive-zip", :require => false
  gem "minitar"    , :require => false
end

# Evaluate Gemfile.local if it exists
if File.exist? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end

# Evaluate ~/.gemfile if it exists
if File.exist?(File.join(Dir.home, '.gemfile'))
  eval(File.read(File.join(Dir.home, '.gemfile')), binding)
end
