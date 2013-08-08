#!/usr/bin/perl -w
use strict;

use ZMQ;
use ZMQ::Constants qw(:all);
use Data::MessagePack;
use JSON::XS;
use Data::Dumper;
use FindBin qw($Bin);

# Custom libraries
use lib "$Bin/../lib";

my $cxt = new ZMQ::Context or die( "Error creating ZMQ Context!" );
my $sock = $cxt->socket( ZMQ_DEALER ) or die( "Error creating ZMQ Socket!" );
die( "Error connecting to server!" ) if $sock->connect( "ipc:///tmp/modbusd-test.socket" ) != 0;

# Load test sets
local $/=undef;
open FILE, "$Bin/targeting-config.t" or die "Couldn't open file: $!";
my $tests = decode_json(<FILE>);
close FILE;

# Send targeting-config requests
foreach my $t (@{$tests}) {
    printf(">> function:%s, app:%d\n", $t->{function}, $t->{parameters}->{appid} );
    my $resp = call(
                sock => $sock,
                module => 'targeting-config',
                function => $t->{function},
                parameters => $t->{parameters});
    printf("<< result:%s\n", $resp->{body}->{result});
    print "\n";
}

# Call subroutine for fabric
sub call {
	my (%opt) = @_;

	my $mp = new Data::MessagePack;
	my $msg = new ZMQ::Message( $mp->pack( {
		"command" => 'call',
		"body" => {
			module => $opt{module},
			function => $opt{function},
			parameters => $opt{parameters}
		},
		"actionid" => time().$$
	} ) );

	$opt{sock}->sendmsg( $msg );
	$msg = $opt{sock}->recvmsg();
	my $resp = $mp->unpack( $msg->data() );
	$msg->close();

	return $resp;
}