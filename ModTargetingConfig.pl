#!/usr/bin/perl -w

use strict;
use FindBin qw($Bin);

# Custom libraries
use lib "$Bin/lib";
use ReachMedia::TargetingConfig;

my $module = ReachMedia::TargetingConfig->new(debug=>1);
$module->run();


