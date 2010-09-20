####################################################################
#
# MailToFriend plugin for blurt 1.0
#
#               by Matthijs de Jonge (matthijs@rommelhok.com)
#
# setup: fill in the host name of your mail server, the email
#        address of the web master, the host name of the
#        web server and change the footer text and the status
#        message to something nice
#
####################################################################
package MailToFriend;
use strict;
####################################################################
#
# Configuration:
#
# 
####################################################################
# enter the host name of your mail server (probably "localhost")
my $MailServer = "localhost";
# enter the e-mail address that should be attached to outgoing
# messages. probably youraddress@yourdomain would be fine.
# the important thing is that it's a *valid* e-mail address
# (BTW: @ symbols need to be prepended by a backward slash, like so:
# someone\@yourserver.com)
my $OurEmail = "nobody\@localhost";
# enter the host name of your web server. if your mail server is 
# running on the same site as your web server, the default ('localhost')
# is probably fine
my $OurHostName = 'localhost';
# if you want to add a custom footer to outgoing emails, do it here:
# (note: for a new line, type \n instead of a real new line)
my $Footer = "\n---------------------------\nhttp://yoururl\n";
# you can change the message that gets displayed if an e-mail is sent:
my $StatusOK = "<h2>Message sent</h2><p>Your message has been sent. If you want, you can tell someone else about this post</p><hr />";
####################################################################
#
# the script itself. don't touch
# 
####################################################################

our $StatusMessage;

my $URI = $main::RequestURI;
my $BlogURL = $main::BlogPath;
my $PostsDir = $main::PostsDir;
my $PostPath = "$PostsDir/$URI";
my $CurrentFlavor = $main::Flavor;


if($CurrentFlavor eq 'mailtofriend') {
    my $QueryVars = $main::QueryVars;
    my $mailtofriendfrom = $QueryVars->{'mailtofriendfrom'};
    my $mailtofriendto= $QueryVars->{'mailtofriendto'};
    my $mailtofriendcomment = $QueryVars->{'mailtofriendcomment'};
    if($mailtofriendfrom && $mailtofriendto) {
        (my $Title, my $PostData) = &GetPostData($PostPath);
        if($Title && $PostData) {
            # some rudimentary spam protection
            my $Referer  = $ENV{'HTTP_REFERER'};
            unless($Referer =~ /$BlogURL/) {
                my $Message = "From:$mailtofriendfrom\nSubject: $Title\n\n$mailtofriendcomment\n-----------------------------------\n\n$Title\n------------------------------------------\n\n$PostData\n\n$Footer";
                &SendEmail($mailtofriendto, $Message);
                $StatusMessage = $StatusOK;
            };
        };
    };
    

};

sub ProcessPost {
    return 1;
};

#------------------------------------------------------------------
#
# Fetch the title and the contents from a given post file
# 
# Input:	- the path to the post file
# 		
# Output:	- an array consisting of the title and the contents
#                 of the post
# 
#------------------------------------------------------------------
sub GetPostData {
    my $PostPath = shift;
    my $Title ='';
    my $Contents = '';
    open(POST, "<:utf8", $PostPath);
    while(<POST>) {
        unless($Title) {
            unless(/^\s*$/) {
                $Title = $_;
            };
        } else {
            $Contents .= $_;
        };
    };
 
    close POST;

    return ($Title, $Contents);
};
#------------------------------------------------------------------
#
# send a message to the mail server for a given recipient
#
# Input:	- the recipient
# 		- the message we wish to send
# 		
# Output:	none
# 
#------------------------------------------------------------------
sub SendEmail {
    my $Recipient = shift;
    my $Message = shift;

    &mailer($MailServer, $OurHostName, $OurEmail, $Recipient, $Message);
};
    



#------------------------------------------------------------------
#
# send a message to a given address using a given smtp server
#
# Input:	- the smtp server
#               - the name of the machine sending the email
#               - the sender
# 		- the address we wish to send to
# 		- the message we wish to send
# Output:	the smtp session. which has some flaws because
# 		we're dumping all commands into one string.
# 		never mind, it works.
# 
#------------------------------------------------------------------
sub mailer {
    my $server = shift;
    my $ourname = shift;
    my $sender = shift;
    my $recipient = shift;
    my $message = shift;

    my @output;

    use IO::Socket;

    my $socket = IO::Socket::INET->new(
	    Proto => 'tcp',
	    PeerAddr => $server,
	    PeerPort => '25',
	    Timeout => 10,
    );

    if ($socket) {
	$socket->autoflush(1);
	my $return = <$socket>;
	
	print $socket "HELO $ourname\n";
	$return = <$socket>;
	push (@output, $return);
        
	print $socket "MAIL FROM:$sender\n";
        $return = <$socket>;
	push (@output, $return);

	print $socket "RCPT TO: $recipient\n";
        $return = <$socket>;
	push (@output, $return);

	print $socket "DATA\n";
        $return = <$socket>;
	push (@output, $return);
	
	print $socket "$message\n\n.\n";
        $return = <$socket>;
	push (@output, $return);


	print $socket "QUIT\n";
        $return = <$socket>;
	push (@output, $return);
	
	$return = <$socket>;
	
	close($socket);
	
        return wantarray?@output:join(/\n/,@output);
    } else {
        return $@;
    };
};


1;
