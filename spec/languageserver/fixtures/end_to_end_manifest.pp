
class end_to_end {
  $foo = 'something'

  user { "bar":
    ensure => present,
    auth_membership => minimum,
    comment => 'A good comment',
  }

  $sig = split('something', 'pattern')
}

include end_to_end
