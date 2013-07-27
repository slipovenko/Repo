package ReachMedia::Targeting;

use strict;
use Data::Dumper;
use ReachMedia::DBRedis;
use ReachMedia::ModuleRuntime;

our @ISA = ("ReachMedia::ModuleRuntime");
our @INTERFACE = qw(targeting);

@PARENT::ISA = @ISA;

sub new
{
	my $class = shift;
	my (%params) = @_;
	my $self = $class->PARENT::new(name=>'targeting', desc=>'Targeting', debug=> $params{debug} || 0);

	bless($self, $class);

	# Define interface functions
	foreach my $i (@INTERFACE) {
        $self->{function_table}->{$i} = sub { $self->$i(@_);};
	}

    return $self;
}

sub targeting {
     my $self = shift;
     my $params = shift;
     my $response = [];
     return $response;
 }

1;
