#!/usr/bin/perl

use rmdata;

my $d = rmdata->new;
$d->init();
print $d->out();