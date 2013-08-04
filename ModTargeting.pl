#!/usr/bin/perl -w

use strict;
use FindBin qw($Bin);

# Custom libraries
use lib "$Bin/lib";
use ReachMedia::Targeting;

my $module = ReachMedia::Targeting->new(debug=>1);
$module->run();


