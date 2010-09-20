####################################################################
#
# LinkList plugin for blurt 1.0
#
##               by Matthijs de Jonge (matthijs@rommelhok.com)
#
# setup: let the plugin know where it can find your link list.
#        you can also set the html that gets shown before and
#        after the link list, before and after each link and
#        before and after each link title
#
####################################################################
package LinkList;
use strict;
####################################################################
#
# configuration. change these:
# 
####################################################################
# where is the file containing your links located?
my $LinkFile = '/path/to/your/plugins/LinkList.txt';
# do you want to shuffle your link list (1) or not (0) ?
my $ShuffleList = '1';
# any text you want to put before a link goes here
my $LinkPreText = '<li>';
# any text you want to put after a link goes here
my $LinkPostText = ' </li>';
# any text you want to put before a link title goes here
my $LinkTitlePreText = '- ';
# any text you want to put after a link title goes here
my $LinkTitlePostText = '';
# any text you want to put before the entire link list goes here
my $LinkListPreText = '<ul>';
# any text you want to put after the entire link list goes here
my $LinkListPostText = '</ul>';
####################################################################
#
# the script itself. don't touch
# 
####################################################################
our $LinkList = '';

my @Links = &GetLinks($LinkFile);
if($ShuffleList) {
    &fisher_yates_shuffle(\@Links);
};

foreach my $Link (@Links) {
    (my $Title) = keys %$Link;
    my $URL = $Link->{$Title};
    $LinkList .= "$LinkPreText<a href=\"$URL\">$LinkTitlePreText$Title$LinkTitlePostText</a>$LinkPostText";
};
$LinkList = "$LinkListPreText$LinkList$LinkListPostText";
sub ProcessPost {
    return 1;
};


####################################################################
#
# Return the links in a given link file
#
# Input: the path to a link file (a link file has link names and 
#        urls on one line, separated by semicolons. lines beginning 
#        with # are ignored, as are empty lines 
# Output: an array of links. Each element is a hash {'name'=>'url'}
#
####################################################################
sub GetLinks {
    my $LinkFile = shift;
    my @Links;
    open(LINKFILE, "<$LinkFile");
    while(<LINKFILE>) {
        next if(/^\s*$/);
        next if(/^\s*#/);
        s/^\s*(.+?)\s*/$1/;
        (my $LinkTitle, my $LinkURL) = split(/;/, $_);
        
        $LinkTitle =~ s/^\s*(.+?)\s*/$1/;
        $LinkURL =~ s/^\s*(.+?)\s*/$1/;
        push(@Links, {$LinkTitle => $LinkURL});
    };
    close LINKFILE;
    return @Links;
};

# shuffle a list. ripped straight from the perl docs
sub fisher_yates_shuffle {
    my $list = shift;   
    my $i = @{$list};
    return unless $i;
    while ( --$i ) {
        my $j = int rand( $i + 1 );
        @{$list}[$i,$j] = @{$list}[$j,$i];
    }
}
                                        

1;
