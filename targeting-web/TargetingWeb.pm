package TargetingWeb;

use strict;
use warnings;
use utf8;
use ZMQ;
use ZMQ::Constants qw(:all);
use Data::MessagePack;
use Time::HiRes qw( time );
use Data::Dumper;
use Plack::Response;
use FindBin qw($Bin);
use JSON::XS;
use Plack::Request;
use lib '../lib';
use ReachMedia::DBRedis;
use ReachMedia::EncodeUtils;

my $sock;

sub open_connection 
{
	my $cxt = new ZMQ::Context or die( "Error creating ZMQ Context!" );
	my $sock = $cxt->socket( ZMQ_DEALER ) or die( "Error creating ZMQ Socket!" );
	die( "Error connecting to fabric!" ) 
		if $sock->connect( "ipc:///tmp/modbusd-test.socket" ) != 0;
	return $sock;
}

sub callService {
# Send targeting requests
    my $params = shift;

    my $sock = open_connection(); 
    my $resp = call(
        sock => $sock,
        module => 'ModTargeting',
        function => 'targeting',
        parameters => $params,
        version => 1);

    print "message from service: ".Dumper($resp);
    return $resp;
}

# Call subroutine for fabric
sub call {
	my (%opt) = @_;
    print "call options: ".Dumper(%opt);

	my $mp = new Data::MessagePack;
	my $mess = $mp->pack( {
		"command" => 'call',
		"body" => {
			module => $opt{module},
			function => $opt{function},
			parameters => $opt{parameters},
			version => $opt{version}
		},
		"actionid" => time().$$
	} );
	my $msg = new ZMQ::Message( $mess );

    print "message to be send: " . Dumper( $mess );

	$opt{sock}->sendmsg( $msg );
	$msg = $opt{sock}->recvmsg();
    print "recieve message: ".Dumper($msg);
	my $resp = $mp->unpack( $msg->data() );
	$msg->close();

	return $resp;
}

#there must be 3 parameters: appId, userContext and amount
#userContext is a binary serialized hash (serialized with MessagePack)
#encoded in base64
sub parseRequest{
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $appId = $req->param('appId');
    my $userContext = decodeUserContext($req->param('userContext'));
    my $amount = $req->param('amount');
    my $request = {'appid' => $appId, 'amount' => $amount, 'attr' => $userContext};
    print Dumper($request);
    return $request;
}

sub makeResponse {
    my $redisResponse = shift;
    my $objs = [];
    my $uuidList = $redisResponse->{body}->{result};
    my $redis = new ReachMedia::DBRedis()->connect('localhost', '6379') or die "Can't connect to redis";
    print "uuidList : ".Dumper($uuidList);
    for my $uuid (values($uuidList)){
        my $object = getObjectFromRedisByUUID($redis, $uuid);
        print "object : ". Dumper($object);
        if (defined($object)){
            push($objs, convertObjectStoreToObjectResult($object));
        }
    }
    print "objs: ".Dumper($objs);
    return JSON::XS->new->latin1->space_after->encode($objs);
#    return encode_json($objs);
}

sub convertObjectStoreToObjectResult{
    my $obj = shift;
    return {'image' => $obj->{ilink}, 'link' => { 'url' => $obj->{flink}, 'text' => $obj->{link_text} }, 'text' => $obj->{short_description}};
}

sub getObjectFromRedisByUUID{
    my $redis = shift;
    my $uuid = shift;
    my $obj = $redis->hget('objs', $uuid); 
    print "uuid: ".$uuid." ; obj: ".Dumper($obj);
    if (!defined($obj)){
        return undef;
    }
    return decodeBase64MessagePack($obj);
}

sub run {
    my $env = shift;
    my $request = parseRequest($env);
    my $response = callService($request);
    print "respnse from service: ".Dumper($response);
    if (defined($response->{body}->{exception})){
        responseError('Exception in service request: '.$response->{body});
    }else{
        my $finalResp = makeResponse($response);
        print "response: ".Dumper($finalResp);
        responseOK($finalResp);
    }
} 

1;
