# An example puppet function, as opposed to a ruby custom function
#
# @example Declaring the class
#   $test = defaultmodule::puppetfunc('true')
#
# @param arg The first parameter for this function.
function defaultmodule::puppetfunc(Variant[String, Boolean] $arg) >> String {
  case $arg {
    false, undef, /(?i:false)/ : { 'Off' }
    true, /(?i:true)/          : { 'On' }
    default               : { "$arg" }
  }
}
