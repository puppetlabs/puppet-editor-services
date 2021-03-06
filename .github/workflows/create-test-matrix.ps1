#Requires -Version 7
param([Switch]$Raw)
$Jobs = @()

# All default OSes we test on
$OSList =@('ubuntu-latest', 'windows-latest')
# All default Ruby and Puppet combinations
$RubyPuppet = @(
  @{ ruby = '2.7'; puppet_gem_version = '~> 7.0' }
  @{ ruby = '2.5'; puppet_gem_version = '~> 6.0' }
  @{ ruby = '2.4'; puppet_gem_version = '~> 5.0' }
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

  # Add Version specific Tests
  $Jobs += @{
    job_name = 'Puppet 5.1.0 Unit Test'
    os = $OS
    ruby = "2.4"
    puppet_gem_version = "5.1.0"
    rake_tasks = 'gem_revendor test_languageserver'
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
  Write-Host "::set-output name=matrix::$($Jobs | ConvertTo-JSON -Compress))"
}
