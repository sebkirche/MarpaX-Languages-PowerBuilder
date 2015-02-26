#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 't/lib';
use TestFunctions;
plan tests => 5;

use_ok( 'MarpaX::Languages::PowerBuilder::SRJ' )       || print "Bail out!\n";

my $parser = MarpaX::Languages::PowerBuilder::SRJ->new;
is( ref($parser), 'MarpaX::Languages::PowerBuilder::SRJ', 'testing new');
	
my $DATA = <<'DATA';
HA$PBExportHeader$p_plexus_geni.srj
$PBExportComments$Generated Application Executable Project
EXE:plexus9.exe,plexus.pbr,0,1,1
CMP:0,0,0,2,0,0,0
COM:Conceptware
DES:Plexus - Bank regulatory reporting
CPY:Copyright 1994-2014 Conceptware
PRD:Plexus
PVS:9.6.1 interne 10
PVN:9,6,1,0
FVS:9060100
FVN:9,6,1,0
MAN:1,asInvoker,0
PBD:plexus.pbl,plexus.pbr,1
PBD:conceptware.pbl,plexus.pbr,1
OBJ:C:\Developpement\Powerbuilder\Plexus\trunk\Sources\p8_iml.pbl,uo_class_iml_host,u
OBJ:C:\Developpement\Powerbuilder\Plexus\trunk\Sources\conceptware.pbl,makefullpath,f
OBJ:C:\Developpement\Powerbuilder\Plexus\trunk\Sources\plexus.pbl,optimizedatabase,f
DATA
my $parsed = $parser->parse( $DATA );
is( $parsed->{error}, '', 'testing parse(FH) without error');

my $got = $parsed->value;
my $expected = {
	  cmp => [
		'0',
		'0',
		'0',
		'2',
		'0',
		'0',
		'0'
	  ],
	  com => [
		'Conceptware'
	  ],
	  cpy => [
		'Copyright 1994-2014 Conceptware'
	  ],
	  des => [
		'Plexus - Bank regulatory reporting'
	  ],
	  exe => [
		'plexus9.exe',
		'plexus.pbr',
		'0',
		'1',
		'1'
	  ],
	  fvn => [
		'9',
		'6',
		'1',
		'0'
	  ],
	  fvs => [
		'9060100'
	  ],
	  man => [
		'1',
		'asInvoker',
		'0'
	  ],
	  obj => [
		[
		  'C:\\Developpement\\Powerbuilder\\Plexus\\trunk\\Sources\\p8_iml.pbl',
		  'uo_class_iml_host',
		  'u'
		],
		[
		  'C:\\Developpement\\Powerbuilder\\Plexus\\trunk\\Sources\\conceptware.pbl',
		  'makefullpath',
		  'f'
		],
		[
		  'C:\\Developpement\\Powerbuilder\\Plexus\\trunk\\Sources\\plexus.pbl',
		  'optimizedatabase',
		  'f'
		]
	  ],
	  pbd => [
		[
		  'plexus.pbl',
		  'plexus.pbr',
		  '1'
		],
		[
		  'conceptware.pbl',
		  'plexus.pbr',
		  '1'
		]
	  ],
	  prd => [
		'Plexus'
	  ],
	  pvn => [
		'9',
		'6',
		'1',
		'0'
	  ],
	  pvs => [
		'9.6.1 interne 10'
	  ]
	};

_is_deep_diff( $got, $expected, 'testing parse(FH) value');

#additional tests
$DB::single=1;
is( $parsed->exe_name, 'plexus9.exe', 'retrieve info: exe name');