#!/usr/bin/perl

use strict;

# Custom libraries
use lib '../lib';
use ReachMedia::TargetingConfig;

my $module = ReachMedia::TargetingConfig->new;
print $module->load();