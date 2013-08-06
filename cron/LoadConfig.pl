#!/usr/bin/perl

use strict;
use FindBin qw($Bin);

# Custom libraries
use lib "$Bin/../lib";
use ReachMedia::TargetingConfig;

my $module = ReachMedia::TargetingConfig->new;
print $module->load();