source ENV['GEM_SOURCE'] || "https://rubygems.org"

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
  gem 'puppet-lint', '~> 3.3',            :require => false
  gem 'puppetfile-resolver', '~> 0.6.2',  :require => false
  gem 'yard', '~> 0.9.28',                :require => false

  gem "rubocop", '= 1.6.1',                            require: false
  gem "rubocop-performance", '= 1.9.1',                require: false
  gem "rubocop-rspec", '= 2.0.1',                      require: false

  if ENV['PUPPET_GEM_VERSION']
    gem 'puppet', ENV['PUPPET_GEM_VERSION'], :require => false
  else
    gem 'puppet',                            :require => false
  end

  case RUBY_PLATFORM
  when /darwin/
    gem 'CFPropertyList'
  end

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
if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}.local"), binding)
end

# Evaluate ~/.gemfile if it exists
if File.exists?(File.join(Dir.home, '.gemfile'))
  eval(File.read(File.join(Dir.home, '.gemfile')), binding)
end
