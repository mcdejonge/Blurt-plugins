#############################################################
#
# AutoBR.pm  a plugin for blurt 1.0 that automatically turns 
#            double new lines into <br /><br />
#            
package AutoBR;
use strict;


sub ProcessPost() {
    unless($main::PostContent =~ /<\s*br\s*\/*>/i) {
        $main::PostContent =~ s/\n\n+/\n<br \/><br\/>\n/g;
    };
  return 1;
};
1;
