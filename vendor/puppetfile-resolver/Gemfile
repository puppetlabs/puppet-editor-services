source ENV['GEM_SOURCE'] || 'https://rubygems.org'

# Specify your gem's dependencies in pdk.gemspec
gemspec

group :development do
  gem 'rspec', '>= 3.2', :require => false

  if RUBY_VERSION =~ /^2\.1\./
    gem "rubocop", "<= 0.57.2", :require => false, :platforms => [:ruby, :x64_mingw]
    gem 'rake', '~> 12.3',      :require => false
  else
    gem "rubocop", ">= 0.80.1", :require => false, :platforms => [:ruby, :x64_mingw]
    gem 'rake', '>= 10.4',      :require => false
  end

  gem "yard",          :require => false
  gem 'redcarpet',     :require => false
  gem 'github-markup', :require => false
end

# Evaluate Gemfile.local and ~/.gemfile if they exist
extra_gemfiles = [
  "#{__FILE__}.local",
  File.join(Dir.home, '.gemfile'),
]

extra_gemfiles.each do |gemfile|
  if File.file?(gemfile) && File.readable?(gemfile)
    eval(File.read(gemfile), binding)
  end
end
# vim: syntax=ruby
