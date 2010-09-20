####################################################################
#
# ShowLastPosts plugin for blurt 1.0
#
#               by Matthijs de Jonge (matthijs@rommelhok.com)
#
# setup: set the value of $NumPosts to the number of posts you
#        want to display
#
####################################################################
package ShowLastPosts;
use strict;
use global;
use Data::Dumper;

####################################################################
#
# Configuration:
#
# 
####################################################################
# set this to the number of posts you want to show
my $NumPosts = 5;

####################################################################
#
# the script itself. don't touch
# 
####################################################################



our $display;


my $Path = $main::RequestURI;
$Path =~ s/\/\w+?\.\w+?$//;
my $URLBase = $main::BlogPath;
my $PostsBasePath = $main::PostsDir;
my $PostsWantedPath = "$PostsBasePath/$Path";
my $CurrentFlavor = $main::Flavor;
my @AllPosts = &GetPosts($PostsWantedPath);
for (my $i = 0; $i < $NumPosts;$i++) {
    my $PostPath = $AllPosts[$i];
    my $PostURL = $PostPath;
    $PostURL =~ s/^$PostsBasePath/$URLBase/;
    $PostURL =~ s/\.txt$/.$CurrentFlavor/i;
    my $Title = '';
    open(POST, "<:utf8", $PostPath);
    while(<POST>) {
        if($_) {
            $Title = $_;
            last;
        };
    };
    $Title =~ s/^\s*(.+?)\s*$/$1/;
    close POST;
    if($PostURL) {
        #hack: get rid of double slashes the fast and ugly way
        $PostURL =~ s/\/\/*/\//g;
        $PostURL =~ s/^http:\//http:\/\//;
      $display .= "<li>- <a href=\"$PostURL\">$Title</a></li>\n";
    };
};
$display = "<ul>$display</ul>";


sub ProcessPost() {
  return 1;
};

1;
