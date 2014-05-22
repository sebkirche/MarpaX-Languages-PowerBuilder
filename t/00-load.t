#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'MarpaX::Languages::PowerBuilder' ) || print "Bail out!\n";
}

diag( "Testing MarpaX::Languages::PowerBuilder $MarpaX::Languages::PowerBuilder::VERSION, Perl $], $^X" );
