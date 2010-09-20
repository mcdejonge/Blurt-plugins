####################################################################
#
# ShowPostCategory plugin for blurt 1.0
#
#               by Matthijs de Jonge (matthijs@rommelhok.com)
#
# setup: none :-)
#
####################################################################
package ShowPostCategory;
use strict;

our $Category = '';
our $CategoryURL = '';

sub ProcessPost {
  shift;
  my $PostFile = shift;
  my @Elements = split(/\//, $PostFile);
  $Category = $Elements[scalar @Elements - 2];
  $CategoryURL = $main::BlogPath."/$Category";
  return 1;
};
1;
