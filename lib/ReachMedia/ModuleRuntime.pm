package ReachMedia::ModuleRuntime;
use strict;

use ZMQ;
use ZMQ::Constants qw( :all );
use Data::MessagePack;
use Data::Dumper;
use Switch;
use Time::HiRes qw( time );

sub new {
	my ($proto, %params) = @_;                 	# извлекаем имя класса или указатель на объект
	my $class = ref($proto) || $proto; 			# если указатель, то взять из него имя класса
	my $self  = {};
	$self->{name}    = $params{name} || die "Ну хоть имя-то надо было задать!";
	$self->{debug} = $params{debug} || 0;
	$self->{desc} = $params{desc} || '';
	$self->{function_table} = {};
	$self->{template_table} = {};
	$self->{function_versions} = {};
	$self->{socket} = $params{socket};
	die "Не передан путь и  имя сокета" unless ($self->{socket});
	$self->{socket} = 'ipc://' . $self->{socket} unless $self->{socket} =~ /^ipc:/;
	die "Не заданы функции-обработчики" unless( ref($params{config}) eq 'ARRAY' && @{$params{config}} );
	foreach my $fproto ( @{$params{config}} ) {
		die "Неверное определение функции обработчика"
			unless(
				exists( $fproto->{name} ) &&
				exists( $fproto->{type} ) &&
				exists( $fproto->{ptr} ) &&
				exists( $fproto->{version} )
			);
		switch( $fproto->{type} ) {
			case 'api' {
				$self->{function_table}->{$fproto->{name}} = $fproto->{ptr};
			}
			case 'html' {
				$self->{template_table}->{$fproto->{name}} = $fproto->{ptr};
			}
			else {
				die "Неверный тип функции";
			}
		}
		$self->{function_versions}->{$fproto->{name}} = int $fproto->{version};
	}

	bless($self, $class);
	return $self;
}

sub run {
	my $self = shift;
	
	# подключаемся к фабрике
	my $cxt = new ZMQ::Context or die( "Error creating ZMQ Context!" );
	my $sock = $cxt->socket( ZMQ_DEALER ) or die( "Error creating ZMQ Socket!" );
	die( "Error connecting to server!" ) if $sock->connect( $self->{socket} ) != 0;
	print 'Connected to ' . $self->{socket}."\n";
	$self->{sock} = $sock;
	
	# send introduce
	$self->send( 'introduce' );
	print "Sent introduce\n";
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
				if( exists $self->{function_table}->{$func} ) {
					print "call API received";
					my $response;
					my $result = eval { $self->{function_table}->{$func}->( $cmd->{body}->{parameters} ) };
					if( defined( $result ) ) {
						$response = $self->response( 'result', $cmd );
						$response->{body}->{result} = $result;
					} else {
						$response = $self->response( 'exception', $cmd );
						$response->{body}->{exception} = 202;
						$response->{body}->{string} = $@;
					}
					$self->{sock}->sendmsg( $mp->pack( $response ) );
				} elsif( exists $self->{template_table}->{$func} ) {
					print "call TEMPLATE $func html\n";
					my $response;
           			my @result;
					my $html = eval { $self->{template_table}->{$func}->( $cmd->{body}->{parameters} ) };
					if( defined( $html ) ) {
						push(@result,200);
						push(@result,['Content-type','text/html; charset=utf-8']);
						push(@result,[$html]);
						$response = $self->response( 'result', $cmd );
						$response->{body}->{result} = \@result;
					} else {
						$response = $self->response( 'exception', $cmd );
						$response->{body}->{exception} = 202;
						$response->{body}->{string} = $@;
					}
					$self->{sock}->sendmsg($mp->pack($response));
				} else {
					print "ERROR\n";
				}
				print "Finish\n";
			}
			else {
				print "Unknown command received - ignore\n";
			}	
			
		}
		delete($self->{cmd});

	}
}

sub response {
	my ( $self, $msg, $cmd ) = @_;
	return { "command" => $msg, "actionid" => $cmd->{actionid} };
}

sub send {
	my ($self, $cmd, %opt) = @_;
	die "Команда не определена!" unless $cmd;
	
	my $body = {};
	switch( $cmd ) {
        case 'introduce'  { 
			$body->{pid} = $$;
			$body->{name} = $self->{name};
			$body->{desc} = $self->{desc};
			$body->{debug} = $self->{debug};
			$body->{provides} = $self->{function_versions};
		}
        case 'call' { 
			$body->{module} = $opt{module};
			$body->{function} = $opt{function};
			$body->{parameters} = $opt{parameters};
			$body->{version} = $opt{version};
		} 
		else { 
			die "Неизвестная команда $cmd!";
		}
    }
	my $mp = new Data::MessagePack;
	my $msg = new ZMQ::Message( $mp->pack( {
		"command" => $cmd,
		"body" => $body,
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
		die "Возникло исключение в процессе обработки команды $cmd: " . (Dumper $resp->{body}) . "\n\n";
	}

}

sub get_actionid {
	my $self = shift;
	my $t = time();
	return "$t.$$";
}

sub call {
	my $self = shift;
	my ( $module, $function, $version, $parameters ) = @_;
	return $self->send( 'call', ( module => $module, function => $function, parameters => $parameters, version => $version ) );
}

1;
