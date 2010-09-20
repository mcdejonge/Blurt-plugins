###########################################################################
#
# Comments.pm : Comments plugin for blurt 1.0 by matthijs de jonge
#               (matthijs@rommelhok.com).
#               
package Comments;
use strict;
use global;
use Data::Dumper;
##############################################################################
#
#
# Configure these:
#
# 
##############################################################################

# what's the directory on the server where you want to keep your comments?
# note that this directory needs to be world writable (chmod 777)
our $CommentsDir = '/home/the/path/to/your/comments';
# what is the oldest post for which we want to show a comment form in days?
# (set ridiculously high to allow comments for *all* posts - which you
# probably don't want to do as people commenting on year old posts are either
# clueless and confused or spammers)
my $MaxPostAge = 30;



##############################################################################
#
# the script itself. don't touch
#
##############################################################################

my $PostsDir = $main::PostsDir;
my $CurrentFlavor = $main::Flavor;
my $URI = $main::RequestURI;
# hack: URI is .txt. should be .$Flavor
$URI =~ s/\.txt/.$CurrentFlavor/i;
my $BlogURL = $main::BlogPath;

my $CommentFile = '';
our $count = 0;
our $display = '';
our $form = '';
my $LogLevel = -3;
my $CanComment = 0;

sub ProcessPost() {
    # dunno, but it seems our package name is the first argument
    shift;
    $count = 0;
    my $PostFile = shift;
    $CommentFile = &GetCommentFilePath($PostFile);
    $CanComment = &DetermineCanPostComment($PostFile);

    if($CurrentFlavor eq 'comments') {
        if($CanComment) {
            $form = &DisplayCommentForm();
            &AppendComment($CommentFile);
        };
        my @Comments = &GetComments($CommentFile);
        $display = '';
        if($Comments[0]) {
            $display = &DisplayComments(@Comments);
        };
    } else {
        $count = &CountComments($CommentFile);
        return 1;
    };
};

# check if we've got a query var CommentText (CommentURL and CommentName are optional)
# and if so, append the comment to the comment file (checking if we're actually
# allowed to post comments happens in ProcessPost();
sub AppendComment {
    my $CommentFile = shift;
    my $QueryVars = $main::QueryVars;
    &WriteLog($LogLevel, 3, "We've got the following query vars: ".Dumper($QueryVars));
    if($QueryVars->{'CommentText'}) {
        my $CommentText = $QueryVars->{'CommentText'};
        my $CommentName = $QueryVars->{'CommentName'};
        my $CommentURL = $QueryVars->{'CommentURL'};
        my @Comments = &GetComments($CommentFile);
        push(@Comments, {'name' => $CommentName, 'url'=>$CommentURL, 'comment'=>$CommentText});
        &WriteCommentFile($CommentFile, @Comments);
    };
};
# write an array of comments to a comments file
# input: the name of the comments file + the comments array
sub WriteCommentFile {
    my $CommentFile = shift;
    my @Comments = @_;
    # it might just be the directory we want doesn't exist yet. in that case, make it
    my $CommentDir = $CommentFile;
    $CommentDir =~ s/^(.+)\/.+?\..+?$/$1/;
    unless(-e $CommentDir) {
        &WriteLog($LogLevel, 2, "$CommentDir doesn't exist yet ... creating it");
        mkdir $CommentDir;
    };
    open(COMMENTFILE, ">$CommentFile") || &WriteLog($LogLevel, 1, "Unable to write to comment file $CommentFile : $!");
    foreach my $Comment (@Comments) {
        foreach my $Key (keys %$Comment) {
            my $Value = $Comment->{$Key};
            print COMMENTFILE "$Key: $Value\n";
        };
        print COMMENTFILE "-----\n";
    };
    close COMMENTFILE;
};


sub DisplayCommentForm {
    #TODO: make this use a template instead of hardcoding it
    #
    #(yes, table. barf)
    my $ReturnString = '';
    $ReturnString = "<form action=\"$BlogURL/$URI\" method=\"post\">\n";
    $ReturnString .= '<table>';
    $ReturnString .= "\n";

    $ReturnString .= '<tr><td valign="top"><strong>Name:</strong></td><td><input type="text" name="CommentName" /></td></tr>';
    $ReturnString .= "\n";
    $ReturnString .= '<tr><td valign="top"><strong>URL/Email:</strong></td><td><input type="text" name="CommentURL" /></td></tr>';
    $ReturnString .= "\n";
    $ReturnString .= '<tr><td valign="top"><strong>Comment:</strong></td><td><textarea rows="5" cols="50" name="CommentText"></textarea></td></tr>';
    $ReturnString .= "\n";
    $ReturnString .= '<tr><td colspan="2"><input type="submit" value="Submit" /></td></tr>';
    $ReturnString .= "\n";
    $ReturnString .= '</table>';
    $ReturnString .= "\n";
    $ReturnString .= '</form>';
    return $ReturnString;
};

# input: the path to a post file (yes, post, not comment)
# output: 1 if the current time is within the time frame
# we'll allow comment posting for the given post, otherwise
# 0
sub DetermineCanPostComment {
    my $PostFile = shift;
    my $ReturnValue = 0;
    my $PostAge = (stat($PostFile))[9];
    my $CurrentTime = time();
    my $MaxPostCommentTime = $PostAge + ($MaxPostAge * 24 * 60 * 60);
    if($CurrentTime < $MaxPostCommentTime) {
        $ReturnValue = 1;
    };
    &WriteLog($LogLevel,1, "Checking if $PostFile with time stamp $PostAge allows us to post a comment at the current time $CurrentTime : $ReturnValue");
    return $ReturnValue;
};

# input: a comment array
# output: HTML formatted comments
# 
sub DisplayComments {
    my @Comments = @_;
    my $Output = "<br /><br />";
    foreach my $Comment (@Comments) {
        $Output .= "<strong>";
        if($Comment->{'url'}) {
            $Output .= '<a href="';
            $Output .= $Comment->{'url'};
            $Output .= '" rel="nofollow">';
        };
        $Output .= $Comment->{'name'};
        if($Comment->{'url'}) {
            $Output .= '</a>:';
        };
        $Output .= "</strong><br />";
        $Output .= "<p>";
        $Output .= $Comment->{'comment'};
        $Output .= "</p>";
    };
    return $Output;
};

# input: the path to the post file
# output: the path to the corresponding comments file
sub GetCommentFilePath {
    my $PostFile = shift;
    $PostFile =~ s/\.txt$/.comment/i;
    $PostFile =~ s/^$PostsDir/$CommentsDir/;
    return $PostFile;
};

# input: the path to a comments file
# output: the number of comments in the comments file
sub CountComments {
    my $CommentFile = shift;
    my $NumComments = 0;
    open(COMMENTFILE, "<$CommentFile") || WriteLog($LogLevel,3, "Unable to open $CommentFile : $!");
    while(<COMMENTFILE>) {
        if(/^\-\-\-\-\-\s*$/) {
            $NumComments++;
        };
    };
    close COMMENTFILE;
    return $NumComments;
};

# input: the path to a comment file
# output: an array of comments
# a comment is a ref to a hash name, url, comment, excerpt, blog_name
# (excerpt and blog_name exist because this code was
# writen to deal with comment files generated by the blosxom writeback
# plugin. this plugin does not do trackback so we don't use those fields)
sub GetComments {
    my $CommentFile = shift;
    my @Comments;
    my %fields = ('name'=> 1, 'url'=>1, 'comment'=>1, 'excerpt'=>1, 'blog_name'=>1);
    my $currentfield = '';
    my $currentcomment;
    open(COMMENTFILE, "<$CommentFile") || WriteLog($LogLevel,3, "Unable to open $CommentFile : $!");
    while(<COMMENTFILE>) {
        if(/^\-\-\-\-\-\s*$/) {
            push(@Comments, $currentcomment);
            $currentcomment = {};
        };
        if(s/^(.+?):\s*//) {
            if($fields{$1}) {
                $currentfield = $1;
            };
        };
        s/^\s*(.+?)\s*$/$1/;
        if($currentfield) {
            if($currentcomment->{$currentfield}) {
                $currentcomment->{$currentfield} .= $_;
            } else {
                $currentcomment->{$currentfield} = $_;
            };
        };
    };
    close COMMENTFILE;
    return @Comments;
};

1;
