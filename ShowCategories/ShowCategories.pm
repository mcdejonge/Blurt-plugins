############################################################
#
# ShowCategories plugin for blurt 1.0
#            
#                by Matthijs de Jonge (matthijs@rommelhok.com)
#
# no configuration necessary!
#
package ShowCategories;
use strict;

our $display = '';

my @Directories;
my $StartDir = $main::PostsDir;
opendir(POSTS, $StartDir);
my @rawentries = readdir POSTS;
foreach my $entry (@rawentries) {
    next unless( -d "$StartDir/$entry");
    next if($entry =~ /^\./);
    push(@Directories, $entry);
};
foreach my $Directory (@Directories) {
    my $CatLink = $main::BlogPath."/$Directory";
    $display .= "<li><a href=\"$CatLink\">$Directory</a></li>\n";
};
$display = "<ul>\n$display\n</ul>";
        

closedir POSTS;

sub ProcessPost() {
  return 1;
};
1;
