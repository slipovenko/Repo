package ReachMedia::redis;

use strict;
use Redis::hiredis;
use Data::Dumper;

sub new
{
	my($class) = shift;
	my $self =	{};
	bless $self, $class;
    return $self;
}

sub connect
{
	my($self, $rhost, $rport) = @_;
	if(defined($rhost) && defined($rport))
	{
		$self->{_redis} = Redis::hiredis->new();
		$self->{_redis}->connect($rhost, $rport);
		return $self->{_redis};
	}
	else
	{
		return undef;
	}
}

sub flush
{
	my($self) = @_;
	my $redis = $self->{_redis};
	$redis->command('flushall');
}

1;
