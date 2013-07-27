#!/usr/bin/perl -w
use lib '../../lib';
use strict;
use ModuleRuntime;
use ReachMedia::tgconfig;

my $mr = new ModuleRuntime(name=>'targeting-config', desc=>'Targeting Configurator', debug=>1, register_api_function=>{ edit=>\&edit });
$mr->run();

sub edit {
    my $params = shift;
    my $config = ReachMedia::tgconfig->new;
    return $config->query($params)->response();
}



