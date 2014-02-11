#!/usr/bin/perl -w

use strict;
use FindBin qw($Bin);

# Custom libraries
use lib "$Bin/lib";
use ModuleRuntime;
use ReachMedia::Targeting;

my $functions = [
	{
		name => 'targeting',
		type => 'api',
		ptr => \&targetingEntry,
		version => 1,
	}
];

our $module = new ModuleRuntime(
	name => 'ModTargeting', 
	desc => 'Модуль таргетинга', 
	debug => 1,
	config => $functions,
	socket => $ARGV[0] || '/tmp/modbusd-test.socket',
);

$module->run();

sub targetingEntry {
	my $targetingClass = new ReachMedia::Targeting() or die "Can't instantiate targetingClass";
	return $targetingClass->targeting(@_);
}
