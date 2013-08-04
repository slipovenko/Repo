#!/usr/bin/perl

use lib '../lib';

use ReachMedia::node;
use ReachMedia::redis;

my $n = new ReachMedia::node('test-node');

$n->connect('ipc:///tmp/modbusd-test.socket');

$n->run();
