####################################################################
#
# ShowPath plugin for blurt 1.0
#
#               by Matthijs de Jonge (matthijs@rommelhok.com)
#
# setup: if you want, you can set the separator before category
#        and post titles to something else than ' :: '
#
####################################################################
package ShowPath;
use strict;
####################################################################
#
# Configuration:
#
# 
####################################################################
# change this if you want a different separator
my $Separator = ' :: ';

####################################################################
#
# the script itself. don't touch
# 
####################################################################



our $Category = '';
our $PostName = '';


my $Request = $main::RequestURI;
my $PostDir = $main::PostsDir;
if($Request) {
    (my $Cat, my $File) = split(/\//, $Request);
    if($File){
        $File =~ s/\.+?$/.txt/;
        my $FilePath = "$PostDir/$Cat/$File";
        if(-e $FilePath) {
            my $Title = '';
            open(FILE, "<:utf8", $FilePath);
            while(<FILE>) {
                if(/\w/) {
                    s/^\s*(.+?)\s*$/$1/;
                    $Title = $_;
                    last;
                };
            };
            close FILE;
            $PostName = $Separator.$Title;
        };
    };

    $Category = $Separator.$Cat;
};
sub ProcessPost() {
  return 1;
};


1;
