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
open FILE, "$Bin/targeting.t" or die "Couldn't open file: $!";
my $tests = decode_json(<FILE>);
close FILE;

# Send targeting requests
foreach my $t (@{$tests}) {
    my @attr;
    push(@attr, sprintf("%s=%s", $_, join(',', @{$t->{attr}->{$_}}))) foreach keys %{$t->{attr}};
    printf(">> app:%d, amount:%d, attr:{%s}\n", $t->{appid}, $t->{amount}, join('&', @attr) );
    my $resp = call(
                sock => $sock,
                module => 'targeting',
                function => 'targeting',
                parameters => $t);
    printf("<< %s:%s\n", $_, $resp->{body}->{result}->{$_}) foreach sort(keys %{$resp->{body}->{result}});
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