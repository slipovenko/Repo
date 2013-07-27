package ReachMedia::node;

use strict;
use ZMQ;
use ZMQ::Constants qw(:all);
use Data::MessagePack;
use Data::Dumper;
use Time::HiRes;
use Switch;

sub new
{
	my($class) = shift;
	my $self =
	{
		_name => shift,
		_mp => new Data::MessagePack,
	};
	bless $self, $class;
    return $self;
}

sub connect
{
	my($self, $socket) = @_;
	$self->{_cxt} = new ZMQ::Context or die( "Error creating ZMQ Context!" );
    $self->{_sock} = $self->{_cxt}->socket( ZMQ_DEALER ) or die( "Error creating ZMQ Socket!" );
    die( "Error connecting to server!" )
        if $self->{_sock}->connect( $socket ) != 0;

    send_introduce();
}

sub send_introduce
{
	my($self) = @_;
    my $msg = new ZMQ::Message( $self->{_mp}->pack( {
                                "command"=>"introduce",
                                "debug"=>1,
                                "name"=>$self->{_name},
                                "pid"=>$$
                            } ) );
    $self->{_sock}->sendmsg( $msg );
    $msg->close();
}

sub run
{
	my($self) = @_;
    while(1) {
        my $msg = $self->{_sock}->recvmsg();
        my $cmd = $self->{_mp}->unpack( $msg->data() );
        $msg->close();

        unless( exists $cmd->{command} ) {
            printf( "No commands in message!\n" );
            next;
        }

    #
    # Тут обрабатываем запрос, находящийся $cmd
    #

    }
}

1;
