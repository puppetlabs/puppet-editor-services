# This is an example of how to document a Puppet class
#
# @example Declaring the class
#   include example_class
#
# @param first The first parameter for this class.
# @param second The second parameter for this class.
class defaultmodule (
  String $first   = 'firstparam',
  Integer $second = 2,
) {
}
