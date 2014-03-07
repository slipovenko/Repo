#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: transferData.pl
#
#        USAGE: ./transferData.pl  
#
#  DESCRIPTION: transfer data from tables in on db to tables another db
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 03/05/2014 05:20:54 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;
use DBI;
use Data::Dumper;

my $db1_driver = 'dbi:mysql';
my $db1_dbname = 'medicforum';
my $db1_host = 'localhost';
my $db1_user = 'root';
my $db1_pass = 'vbifnrf';

my $db2_driver = 'dbi:Pg';
my $db2_dbname = 'targeting';
my $db2_dbscheme = 'medicforum';
my $db2_host = 'localhost';
my $db2_user = 'rm';
my $db2_pass = 'rm';

my @db1_tables = ('post', 'keywords', 'post_category', 'post_keywords', 'category');
my @db2_tables = ('medicforum.post', 'medicforum.keywords', 'medicforum.post_category', 'medicforum.post_keywords', 'medicforum.category');

my $select = 'SELECT * FROM <table>';
my $insert = 'INSERT INTO <table> (<field_names>) VALUES (<question_marks>)';

my %db1_params = (PrintError => 1, AutoCommit => 0);
if ($db1_driver eq 'dbi:mysql'){
    $db1_params{'mysql_enable_utf8'} = 1;
}elsif ($db1_driver eq 'dbi:Pg'){
    $db1_params{'pg_enable_utf8'} = 1;
}
my %db2_params = (PrintError => 1, AutoCommit => 0);
if ($db2_driver eq 'dbi:mysql'){
    $db2_params{'mysql_enable_utf8'} = 1;
}elsif ($db2_driver eq 'dbi:Pg'){
    $db2_params{'pg_enable_utf8'} = 1;
}
my $db1h = DBI->connect($db1_driver.":database=".$db1_dbname.";host=".$db1_host, $db1_user, $db1_pass, \%db1_params) or die 'Can\'t connect to db1'; 
my $db2h = DBI->connect($db2_driver.":database=".$db2_dbname.";host=".$db2_host, $db2_user, $db2_pass, \%db2_params) or die 'Can\'t connect to db2'; 

for my $i (0..(scalar(@db1_tables)-1)){
   my $db1_table = $db1_tables[$i];
   my $db2_table = $db2_tables[$i];

   my $sel = $select;
   $sel =~ s/<table>/$db1_table/e;
   my $db1sth = $db1h->prepare($sel) or die 'Can\'t prepare query '.$sel;
   my $ins = $insert;
   $ins =~ s/<table>/$db2_table/e;
   my $getInfoSth = $db1h->column_info(undef,undef,$db1_table, '%');
   my $columnInfoRows = $getInfoSth->fetchall_arrayref();
   my @fieldNames = map {$_->[3]} (sort {$a->[16] <=> $b->[16]} @{$columnInfoRows});
   my @fieldPlaceholders = map {'?'} (1..scalar(@fieldNames));

   $ins =~ s/<field_names>/(join(', ', @fieldNames))/e;
   $ins =~ s/<question_marks>/(join(', ', @fieldPlaceholders))/e;

   $db1sth->execute();
   my $db2sth = $db2h->prepare($ins) or die 'Can\'t prepare query '.$ins;
   eval{
        while (my @row = $db1sth->fetchrow_array()){
        print "row :".Dumper(@row)."\n";
        $db2sth->execute(@row);
     }
     $db2h->commit();
   };
   if ($@){
       $db2h->rollback();
       die "Transaction aborted : $@";
   }
}

