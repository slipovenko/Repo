#!/usr/bin/perl -w
#generate test user context
#context is a string encoded in base64

use Data::Dumper;
use lib '../lib';
use ReachMedia::EncodeUtils;

my %context = ('age' => [''], 'gen' => ['1'], 'geo' => ['10010001']);

my $econtext = encodeUserContext(\%context);
print $econtext;

$ucontext = decodeUserContext($econtext);
print Dumper($ucontext);


