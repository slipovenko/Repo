package ReachMedia::ModuleRuntime;
use strict;

use ZMQ;
use ZMQ::Constants qw(:all);
use Data::MessagePack;
use Data::Dumper;
use Switch;
use Mason;

sub new {
	my ($proto, %params) = @_;                 	# извлекаем имя класса или указатель на объект
	my $class = ref($proto) || $proto; 			# если указатель, то взять из него имя класса
	my $self  = {};
	$self->{name}    = $params{name} || die;
	$self->{debug} = $params{debug} || 0;
	$self->{desc} = $params{desc} || '';
	$self->{function_table} = {};
	$self->{template_table} = {};
	if ($params{register_api_function} && ref $params{register_api_function} eq 'HASH') {
		while (my($fn,$fptr) = each %{$params{register_api_function}}) {
			$self->{function_table}->{$fn} = $fptr;
		}
	}
	if ($params{register_template} && ref $params{register_template} eq 'HASH') {
		while (my($fn,$fptr) = each %{$params{register_template}}) {
			$self->{template_table}->{$fn} = $fptr;
		}
	}
	bless($self, $class);              
	return $self;
}

sub run {
	my $self = shift;
	
	# подключаемся к фабрике
	my $cxt = new ZMQ::Context or die( "Error creating ZMQ Context!" );
	my $sock = $cxt->socket( ZMQ_DEALER ) or die( "Error creating ZMQ Socket!" );
	die( "Error connecting to server!" ) if $sock->connect( "ipc:///tmp/modbusd-test.socket" ) != 0;
	$self->{sock} = $sock;
	
	# send introduce
	$self->send('introduce');
	print "Send introduce\n";
	# listen socket, in loop
	while (1) {
		my $mp = new Data::MessagePack;
		my $msg = $sock->recvmsg();
		my $cmd = $mp->unpack( $msg->data() );
		$msg->close();
		
		my $command = exists $cmd->{command} ? $cmd->{command} : undef;
		die ( "No commands in message!\n" ) unless($command) ;
		$self->{cmd} = $cmd;
		
		switch ($command) {
			case "ping" {
				print "PING <===> PONG\n";
			}
			case "stop" {
				print "Stop received - stopping\n";
				last;
			}
			case "call" {
				my  $func = $cmd->{body}->{function};
				print "Call of $func received\n";
				if (exists $self->{function_table}->{$func}) { 
					print "call API received... ";
					print Dumper $cmd if $self->{debug};
					my $body = $self->{function_table}->{$func}->($cmd->{body}->{parameters});
					my $response = $self->response('result', $cmd);
					$response->{body}->{result} = $body;
					$self->{sock}->sendmsg($mp->pack($response)); 
				} elsif (exists $self->{template_table}->{$func}) {
					print "call TEMPLATE $func html\n";
					
           			my @body;
					push(@body,200);
					push(@body,['Content-type','text/html; charset=utf-8']);
					my $html = $self->{template_table}->{$func}->($cmd->{body}->{parameters});
					push(@body,[$html]);
					my $response = $self->response('result', $cmd);
					$response->{body}->{result} = \@body;
					$self->{sock}->sendmsg($mp->pack($response));
				} else {
					print "ERROR\n";
				}
				print "Done\n";
			}
			else {  
				print "Unknown command received - ignore\n";
			}	
			
		}
		delete($self->{cmd});
	}
}

sub response {
	my ($self, $msg, $cmd) = @_;
	return { "command"=>$msg, "actionid"=>$cmd->{actionid} };
}

sub send {
	my ($self, $cmd, %opt) = @_;
	die ("Command not defined!") unless ($cmd);
	
	my $body = {};
	my $function_list;
	switch ($cmd) {
        case 'introduce'  { 
			$body->{debug} = $self->{debug};
#			$body->{provides} = $function_list,
		}
        case 'call' { 
			$body->{module} = $opt{module};
			$body->{function} = $opt{function};
			$body->{parameters} = $opt{parameters};
		} 
		else { 
			die "Unknown command $cmd!";
		}
    }
	my $mp = new Data::MessagePack;
	my $msg = new ZMQ::Message( $mp->pack( {
		"command" => $cmd,
		"body" => {
			%$body, 
			pid=>$$, 
			name=>$self->{name}, 
			desc=>$self->{desc}
		},
		"actionid" => get_actionid()				
		} ) 
	);

	$self->{sock}->sendmsg( $msg );
	$msg = $self->{sock}->recvmsg();
	my $resp = $mp->unpack( $msg->data() );
	$msg->close();
	if ($resp->{body}->{result}) {
		return $resp->{body}->{result};
	} else {
		print "Caught exception ".(Dumper $resp->{body})."\n\n";
		return;
	}

}

sub get_actionid {
	my $self = shift;
	return time().$$;
}

1;