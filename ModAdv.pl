#!/usr/bin/perl -w

use strict;
use FindBin qw($Bin);

# Custom libraries
use lib "$Bin/lib";
use ReachMedia::Adv;

my $module = ReachMedia::Adv->new(debug=>1);
$module->run();


