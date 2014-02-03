package ReachMedia::Adv;

use strict;
use ZMQ;
use ZMQ::Constants qw(:all);
use Data::MessagePack;
use URI;
use URI::QueryParam;
use HTTP::Status qw(:constants status_message);
use JSON::XS;
use Data::Dumper;
use Switch;
use DBI;
use ReachMedia::ModuleRuntime;

our @ISA = ("ReachMedia::ModuleRuntime");
our @INTERFACE = qw(list);

@PARENT::ISA = @ISA;

sub new
{
	my $class = shift;
	my (%params) = @_;
	my $self = $class->PARENT::new(name=>'adv', desc=>'Advertising Module', debug=> $params{debug} || 0);

    my $host = "127.0.0.1";
    my $port = "5432";
    my $dbname = "targeting";
    my $username = "rm";
    my $password = "rm";

    $self->{_db} = DBI->connect("dbi:Pg:dbname=$dbname;host=$host;port=$port","$username","$password",
        {PrintError => 0});
    if (! defined $self->{_db})
    {
        $self->{_status} = HTTP_INTERNAL_SERVER_ERROR;
        $self->{_header} = [['Content-Type', 'text/plain; charset=utf-8']];
        $self->{_body} = [sprintf("DB Connection error. Error #%s: %s", $DBI::err, $DBI::errstr)];
        push(@{$self->{_header}},['Content-Length', length($self->{_body}->[0])]);
    }
    $self->{_json} = JSON::XS->new->latin1;

	bless($self, $class);

	# Define interface functions
	foreach my $i (@INTERFACE) {
        $self->{function_table}->{$i} = sub { $self->$i(@_);};
	}

    return $self;
}

# List command
sub list
{
    my $self = shift;
    my $params = shift;
    $self->query($params);
    return $self->http_adapter();
}

# prepare response for call from http-adapter
sub http_adapter
{
    my $self = shift;
    my @response = ($self->{_status}, []);
    foreach my $h (@{$self->{_header}}) {
        push($response[1], $h->[0], $h->[1]);
    }
    push(@response, $self->{_body});
    return \@response;
}

# Process CGI-query
sub query
{
	my $self = shift;
    if(! defined $self->{_db}) { return $self; }

    $self->{_parameters} = shift;
    my $query = {};
    my $url = URI->new('http://'.$self->{_parameters}->{SERVER_NAME}.$self->{_parameters}->{REQUEST_URI});
    foreach my $p ($url->query_param()) {
        $query->{$p} = $url->query_param($p) if (defined $url->query_param($p));
    }

    $self->{_status} = HTTP_OK;
    $self->{_header} = [];
    $self->{_body} = [];

    if(defined($query->{appid})) {
        my $params = { appid => $query->{appid}};
        $params->{amount} = (defined($query->{amount}) && $query->{amount} =~ /\d+/) ? $query->{amount} : 1;
        $params->{atrr} = {};
        $params->{atrr}->{age} = $query->{age} if (defined($query->{age}) && $query->{age} =~ /\d{1,3}/);
        $params->{atrr}->{gen} = $query->{gen} if (defined($query->{gen}) && $query->{gen} =~ /[0-2]/);
        $params->{atrr}->{geo} = $query->{geo} if (defined($query->{geo}) && $query->{geo} =~ /\d{1,9}/);
        my $result = $self->send('call', module=>'targeting', function=>'targeting', parameters=>$params);
        my $objects = [];
        my $sql = "SELECT flink,mtype FROM obj.ado a ".
                  "INNER JOIN dict.type t ON a.tid=t.id ".
                   "WHERE uuid = ? AND a.deleted != true";
        foreach my $n (keys %{$result}) {
            my $obj = {n=>$n};
            my $sth = $dbh->prepare($sql);
            $sth->execute();
            if(my $ado = $sth->fetchrow_hashref()) {

            }
            my $rv = $sth->finish();
            push(@{$objects}, $obj);
            [
            { n:0, src:'…', target:'…', type:'image' },
            { n:1, src:'…', target:'…', type:'video' },
        }
        push(@{$self->{_body}}, $self->{_json}->encode($objects));
    }
    else {
        $self->{_status} = HTTP_BAD_REQUEST;
        push(@{$self->{_body}}, '[]');
	}

	use bytes;
	push(@{$self->{_header}}, ['Content-Length', length($self->{_body}->[0])]);
	return $self;
}