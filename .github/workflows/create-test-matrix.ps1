#Requires -Version 7
param([Switch]$Raw)
$Jobs = @()

# All default OSes we test on
$OSList =@('ubuntu-20.04', 'windows-2019')
# All default Ruby and Puppet combinations
# Pin to Ruby 2.5.8 due to
#  - https://github.com/chef/win32-dir/commit/cf3e31ec90e47d988840759e5d755a9460e192ff
#  - https://github.com/puppetlabs/puppet/pull/8577#issuecomment-823820255
#  - https://www.msys2.org/news/#2021-01-31-aslr-enabled-by-default
$RubyPuppet = @(
  @{ ruby = '2.7'; puppet_gem_version = '~> 7.0' }
)

$OSList | ForEach-Object {
  $OS = $_

  # Add Rubocop tests
  $Jobs += @{
    job_name = 'Lint'
    os = $OS
    ruby = $RubyPuppet[0].ruby
    puppet_gem_version = ">= 0.0"
    rake_tasks = 'rubocop'
  }

  # Add the generic unit tests for all Ruby Puppet combinations
  $RubyPuppet | ForEach-Object {
    $Jobs += @{
      job_name = 'Unit Test'
      os = $OS
      ruby = $_.ruby
      puppet_gem_version = $_.puppet_gem_version
      rake_tasks = 'gem_revendor test_languageserver test_languageserver_sidecar test_debugserver'
    }
  }


  # Add Acceptance tests
  $Jobs += @{
    job_name = 'Acceptance Test'
    os = $OS
    ruby = $RubyPuppet[0].ruby
    puppet_gem_version = $RubyPuppet[0].puppet_gem_version
    rake_tasks = 'gem_revendor acceptance_languageserver'
  }
}

if ($Raw) {
  Write-Host ($Jobs | ConvertTo-JSON)
} else {
  # Output the result for consumption by GH Actions
  Write-Host "{matrix}={$($Jobs | ConvertTo-JSON -Compress)}" >> $GITHUB_OUTPUT
}
