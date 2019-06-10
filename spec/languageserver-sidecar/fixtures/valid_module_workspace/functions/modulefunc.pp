# An example puppet function in a module, as opposed to a ruby custom function
#
# @example Declaring the class
#   $test = valid::modulefunc('true')
#
# @param p1 The first parameter for this function.
function valid::modulefunc(Variant[String, Boolean] $p1) >> String {
  case $p1 {
    false, undef, /(?i:false)/ : { 'Off' }
    true, /(?i:true)/          : { 'On' }
    default               : { "$p1" }
  }
}
