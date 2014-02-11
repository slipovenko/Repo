#!/usr/bin/perl -w

use strict;
use FindBin qw($Bin);

# Custom libraries
use lib "$Bin/lib";
use ReachMedia::TargetingConfig;
use ModuleRuntime;

my $targetingConfig;

my $functions = [
	{
		name => 'edit',
		type => 'api',
		ptr => \&editEntry,
		version => 1,
	},
	{
		name => 'insert',
		type => 'api',
		ptr => \&insertEntry,
		version => 1,
	},
	{
		name => 'update',
		type => 'api',
		ptr => \&updateEntry,
		version => 1,
	},
	{
		name => 'delete',
		type => 'api',
		ptr => \&deleteEntry,
		version => 1,
	},
	{
		name => 'select',
		type => 'api',
		ptr => \&selectEntry,
		version => 1,
	},
	{
		name => 'status',
		type => 'api',
		ptr => \&statusEntry,
		version => 1,
	}
];

our $module = new ModuleRuntime(
	name => 'ModTargetingConfig', 
	desc => 'Модуль конфигурации таргетинга', 
	debug => 1,
	config => $functions,
	socket => $ARGV[0] || '/tmp/modbusd-test.socket',
);

$targetingConfig = ReachMedia::TargetingConfig->new(debug=>1) or die "Can't instantiate TargetingConfig";
$module->run();

sub editEntry {
    return $targetingConfig->edit(@_);
} ## --- end sub editEntry

sub insertEntry {
    return $targetingConfig->insert(@_);
} ## --- end sub insertEntry

sub updateEntry {
    return $targetingConfig->udate(@_);
} ## --- end sub updateEntry

sub deleteEntry {
    return $targetingConfig->delete(@_);
} ## --- end sub deleteEntry

sub selectEntry {
    return $targetingConfig->select(@_);
} ## --- end sub selectEntry

sub statusEntry {
    return $targetingConfig->status(@_);
} ## --- end sub statusEntry
