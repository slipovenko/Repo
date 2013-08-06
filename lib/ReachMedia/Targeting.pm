package ReachMedia::Targeting;

use strict;
use Bit::Vector;
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

    $self->{_redis} = ReachMedia::DBRedis->new()->connect('localhost', '6379');

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

    my $prefix = sprintf("app:%s:c", $params->{appid});
    my ($cid, $mlength, $tstamp) = split(':', $self->{_redis}->get($prefix));
    $prefix .= ":$cid";

    my $conf = {};

    my $response = {};

    $conf->{mask} = Bit::Vector->new($mlength);
    $conf->{mask}->Fill();
    foreach my $attr (keys %{$params->{attr}})
    {
        my $all = $self->{_redis}->hget($prefix.':bits', "$attr:ALL");
        $conf->{$attr}->{ALL} = defined($all)?$all:'0';
        my $mask = Bit::Vector->new_Hex($mlength, $conf->{$attr}->{ALL});
        foreach my $value (@{$params->{attr}->{$attr}}) {
            my $bits = $self->{_redis}->hget($prefix.':bits', "$attr:$value");
            $conf->{$attr}->{$value} = defined($bits)?$bits:'0';
            $mask->Or($mask, Bit::Vector->new_Hex($mlength, $conf->{$attr}->{$value}));
        }
        $conf->{$attr}->{mask} = $mask->to_Bin();
        $conf->{mask}->And($conf->{mask}, $mask);
    }
    my @index = $conf->{mask}->Index_List_Read();
    my $objects = {};
    foreach my $i (@index) {
        my $tid = $self->{_redis}->lindex($prefix.':index', $i);
        my @params = split(',', $self->{_redis}->hget($prefix.':tids', $tid));
        foreach my $p (@params) {
            my ($k, $v) = split(':', $p);
            $conf->{tids}->{$tid}->{$k} = $v;
        }
        $objects->{$conf->{tids}->{$tid}->{p}}->{$conf->{tids}->{$tid}->{u}} = int($conf->{tids}->{$tid}->{w});
    }
    $conf->{mask} = $conf->{mask}->to_Bin();

    my @priorities = sort{int($b) <=> int($a)}(keys %{$objects});
    my $p = shift(@priorities);
    my $c = 0;
    while(%{$objects} && $c<$params->{amount}) {
        my $u = $self->randomize($objects->{$p});
        if($u) {
            delete($objects->{$p}->{$u});
            if(!%{$objects->{$p}}) {
                delete($objects->{$p});
                $p = shift(@priorities);
            }
            $response->{$c++} = $u;
        }
    }
    #print Dumper($conf, $objects) if($self->{debug});

    return $response;
}

sub randomize {
    my $self = shift;
    my $set = shift;
    my $norm = 0;
    $norm += $_ foreach (values %{$set});
    my $rand = int(rand($norm));
    my $pos = 0;
    foreach my $u (sort {$set->{$b} <=> $set->{$a}} (keys %{$set})) {
        $pos += $set->{$u};
        if($rand < $pos) {
            return $u;
        }
    }
    return undef;
}

1;
