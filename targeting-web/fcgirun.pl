#!/usr/bin/perl -w

use strict;
use Plack::Handler::FCGI;
use TargetingWeb;
use Data::Dumper;

my $server = Plack::Handler::FCGI->new(
    nproc  => 1,
    listen => [ '/tmp/fastcgi.sock' ],
    detach => 0,
);

$server->run(\&the_app);

sub the_app {
	my $env = shift;

    print Dumper($env);
    return TargetingWeb::run($env);
}

