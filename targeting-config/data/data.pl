#!/usr/bin/perl

use lib '../../lib';
use strict;
use CGI;
use ReachMedia::tgconfig;
use Data::Dumper;

my $params = {%ENV};
my $cgi = CGI->new;
$params->{INPUT_DATA} = $cgi->param('POSTDATA');

my $config = ReachMedia::tgconfig->new;
print $config->query($params)->http_response();