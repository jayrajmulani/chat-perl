#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use IO::Socket;
use Term::ANSIColor qw(:constants);

my ($screenname, $ipaddress);
my $file = "contacts.dat";
my $i;
my $kpid;
my $in;
my $out;
my $host;
my $port = 8080;
my $name;
my $socket;
my $s;

MAIN:while (1) {

print `clear`;	
print <<"EOF";
\t\tWelcome to PerlChat

\t1. Chat
\t2. Create contact
\t3. View contacts
\t4. Search contact
\t5. Delete contact


Please make a selection [1-4] or press Q to quit the program: 
EOF

my $choice = <STDIN>;
chomp $choice;

if ($choice eq '2') {
	&create && next MAIN;
} elsif ($choice eq '3') {
	&view && next MAIN;
} elsif ($choice eq '4') {
	&search && next MAIN;
} elsif ($choice eq '5') {
	&delete && next MAIN;
} elsif ($choice eq '1') {
	&chat && next MAIN;
}elsif ($choice =~ /q/i) {
	&quit;
}  
else {
	&retry && next MAIN;
}

}

sub create {
	&clear;
	print "\n\nYou are about to create a new record\n";
	print "Please complete the appropriate fields\n\n";

	print "Screen Name: "; $screenname = <STDIN>;
	print "IP Address: "; $ipaddress = <STDIN>;
	
	chomp($screenname, $ipaddress);
	
	my @details = ($screenname, $ipaddress);
	my $output = join ":", @details;
	
	open NAMES, ">> $file" or die "Can't open $file: $!";
	print NAMES $output, "\n";
	close NAMES;
	
	print "\n\nA new record has been created.\n";
	print "Thank you for your input\n\n\n";
	
	print "Press any key to continue ";
	<STDIN>;
	return;
	
}

sub clear {
	print `clear`;
}

sub view {
	
&clear;
&output;
open NAMES, $file or die "Can't open $file: $!";
my @lines = <NAMES>;
close NAMES;
foreach (@lines) {
	chomp;
	($screenname, $ipaddress) = split /:/;
	write;
} 

print "\n\nPress <ENTER> to continue ";
<STDIN>;

return;

}

sub search {
	&clear;
	&output;
	
	print "\nPlease enter the search pattern: ";
	chomp(my $pattern = <STDIN>);
	print "\n\n\n";
	
	open RECORDS, $file or die "The file $file can't be opened: $!";
	my @lines = <RECORDS>;
	close RECORDS;
	
	foreach (@lines) {
		if (/$pattern/i) {
			chomp;
			($screenname, $ipaddress) = split /:/;
			write;
		}
	}
	
	print "\n\n\nPress <ENTER> to continue ";
	<STDIN>;
	
	return;
}

sub delete {
	&clear;
	print "\nNot implemented yet\n\n";
	print "Press <ENTER> to continue ";
	<STDIN>;
	return 0;
}

sub chat{

	&white("Please Enter your Screen Name...\n\nScreen Name: ");
	$name = <STDIN>;
	chomp $name;
	
	open RECORDS, $file or die "The file $file can't be opened: $!";
	my @lines = <RECORDS>;
	close RECORDS;
	my $pattern = $name;
	$ipaddress = "None";
	foreach (@lines) {
		if (/$pattern/i) {
			chomp;
			($screenname, $ipaddress) = split /:/;
			$host = $ipaddress;
			last;
		}
	}
	if ($ipaddress eq "None"){
		&white("The screen name is not found in the records ... Chatting on the local machine...");
		$host = "127.0.0.1";
	}
	
	$socket = IO::Socket::INET->new("$host:$port"); # Socket test for client connection.
	if ($socket) { # Connects, otherwise creates server.
		&client;
	} else {
		&server;
	}

}

sub ping {
    print STDERR BOLD, RED, "PING PING!!!\a\n", RESET;
}

sub white {
    print STDERR WHITE, "@_", RESET;
}

sub green {
    print STDERR GREEN, "@_", RESET;
}

sub red {
    print STDERR BOLD, RED, "@_", RESET;
}

sub client {
    die "Couldn't Start the Chat Program: $!\n" unless defined($kpid = fork());

    if ($kpid) {
        &clear;
        &green("Connection established client, Please Chat!\n\n");

        while (defined($in = <$socket>)) { # Listen on the socket.
            if ($in eq "/quit\n") {  # If received is equal to quit, quit.
                &red("\nChat Ended\n\n");
                kill 1, $kpid;
                exit;
            } elsif ($in eq "/ping\n") {
                &ping;
            }
            else {
                &white("#$in"); # Prints received information from socket.
            }
        }

        kill("TERM", $kpid); # Terminate the child process.
    }
    else {
        while (defined($out = <STDIN>)) { # Print too the socket.
            if ($out eq "/quit\n"){ # If output is equal to quit, send "quit" without the nickname and quit.
                print $socket "$out";
                &red("\nChat Ended\n\n");;
                close $socket;
                kill 1, $kpid;
            } elsif ($out eq "/ping\n") { # If received is equal to /ping, send "/ping" without the nickname.
                print $socket "$out";
            } else {
                print $socket "$name: $out"; # Prints through the socket.
            }
        }
    }
}

sub server {
    my $server = IO::Socket::INET->new( # Creates server.
        LocalAddr => $s,
        LocalPort => $port,
        Listen    => 1,
        Reuse     => 1
    );

    die "Could not create the chat session: $!\n" unless $server;

    &clear;
    &red("waiting for a connection on $port...\n\n");

    while ($socket = $server->accept()) {
        die "Can't fork: $!" unless defined($kpid = fork());

        if ($kpid) {
            &clear;
            &green("Connection established server, Please Chat!\n\n");

            while (defined($out = <STDIN>)) { # Print down the socket.
                if ($out eq "/quit\n") {
                    print $socket "$out";
                    &red("\nChat Ended\n\n");
                    close $socket;
                    kill 1, $kpid;
                    exit;
                } elsif ($out eq "/ping\n") {
                    print $socket "$out";
                } else {
                    print $socket "$name: $out";
                }
            }
        } else {
            while (defined($in = <$socket>)) { # Print from the socket.
                if ($in eq "/quit\n") {
                    &red("\nChat Ended\n\n");
                    close $socket;
                    kill 1, $kpid;
                    exit;
                } elsif ($in eq "/ping\n") {
                    &ping;
                } else {
                    &white("#$in");
                }
            }
            close $socket;
            exit;
        }
        close $socket;
    }
}


sub retry {
	&clear;
	print "\n\nYour input is invalid.\n\n\nPress <ENTER> to continue ";
	<STDIN>;
	return;
}
sub quit {
	print "\n\nThe program is exiting..\n";
	sleep 1;
	exit 0;
}

sub output {
	
	$= = 10;
    $i = 1;

format STDOUT_TOP =
Page @<
     $%
     
 No   ScreenName   IP Address 
+-----------------------------+
.
	
format STDOUT =
 @<<  @<<<<<<<<<   @<<<<<<<<<<<
 $i++,$screenname,  $ipaddress, 
.
	
}
