#!/usr/bin/perl

use strict;
use CGI;

# Custom libraries
use lib '../../lib';
use ReachMedia::TargetingConfig;

my $params = {%ENV};
my $cgi = CGI->new;
$params->{INPUT_DATA} = $cgi->param('POSTDATA');

my $module = ReachMedia::TargetingConfig->new;
print $module->query($params)->http();