#!/usr/bin/perl -w
use strict;

use ZMQ;
use ZMQ::Constants qw(:all);
use Data::MessagePack;

my $cxt = new ZMQ::Context or die( "Error creating ZMQ Context!" );
my $sock = $cxt->socket( ZMQ_DEALER ) or die( "Error creating ZMQ Socket!" );
die( "Error connecting to server!" ) if $sock->connect( "ipc:///tmp/modbusd-test.socket" ) != 0;

# Send targeting-config requests
my $mp = new Data::MessagePack;
my $msg = new ZMQ::Message( $mp->pack( {
    "command" => 'call',
    "body" => {
        module => 'targeting-config',
        function => 'select',
        parameters => { appid => '1001'},
        sequence => 1,
        seqno => 1
    },
    "actionid" => '1000000'
} ) );
$sock->sendmsg( $msg );

$msg = new ZMQ::Message( $mp->pack( {
    "command" => 'call',
    "body" => {
        module => 'targeting-config',
        function => 'select',
        parameters => { appid => '1001'},
        sequence => 1,
        seqno => 2
    },
    "actionid" => '1000000'
} ) );
$sock->sendmsg( $msg );

$msg = $sock->recvmsg();
my $resp = $mp->unpack( $msg->data() );
$msg->close();
