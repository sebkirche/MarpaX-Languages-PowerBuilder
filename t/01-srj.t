#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 't/lib';
use TestFunctions;
use utf8;

plan tests => 35;

my $package = 'MarpaX::Languages::PowerBuilder::SRJ';
use_ok( $package )       || print "Bail out!\n";

my $parser = $package->new;
is( ref($parser), $package, 'testing new');
	
my $DATA = <<'DATA';
HA$PBExportHeader$p_plexus_geni.srj
$PBExportComments$Generated Application Executable Project
EXE:plexus9.exe,plexus.pbr,0,1,1
CMP:0,0,0,2,0,0,0
COM:Conceptware S-$$HEX1$$e000$$ENDHEX$$-r-l
DES:Plexus - Bank regulatory reporting
CPY:Copyright 1994-2014 Conceptware
PRD:Plexus
PVS:9.6.10 interne 10
PVN:9,6,10,0
FVS:9061000
FVN:9,6,10,0
MAN:1,asInvoker,0
PBD:plexus.pbl,plexus.pbr,1
PBD:conceptware.pbl,plexus.pbr,1
OBJ:C:\Developpement\Powerbuilder\Plexus\trunk\Sources\p8_iml.pbl,uo_class_iml_host,u
OBJ:C:\Developpement\Powerbuilder\Plexus\trunk\Sources\conceptware.pbl,makefullpath,f
OBJ:C:\Developpement\Powerbuilder\Plexus\trunk\Sources\plexus.pbl,optimizedatabase,f
DATA
my $parsed = $parser->parse( $DATA );
is( ref($parser), $package, 'testing parsed package');
is( $parsed->{error}, '', 'testing parse(FH) without error');

my $got = $parsed->value;
my $expected = {
	  exe => [ 'plexus9.exe', 'plexus.pbr', '0', '1', '1' ],
	  cmp => [ '0', '0', '0', '2', '0', '0', '0' ],
	  com => [ 'Conceptware S-à-r-l' ],
	  des => [ 'Plexus - Bank regulatory reporting' ],
	  cpy => [ 'Copyright 1994-2014 Conceptware' ],
	  prd => [ 'Plexus' ],
	  pvs => [ '9.6.10 interne 10' ],
	  pvn => [ '9', '6', '10', '0' ],
	  fvs => [ '9061000' ],
	  fvn => [ '9', '6', '10', '0' ],
	  man => [ '1', 'asInvoker', '0' ],
	  pbd => [
		[ 'plexus.pbl', 'plexus.pbr', '1' ],
		[ 'conceptware.pbl', 'plexus.pbr', '1' ],
	  ],
	  obj => [ 
		[ 'C:\\Developpement\\Powerbuilder\\Plexus\\trunk\\Sources\\p8_iml.pbl', 'uo_class_iml_host', 'u' ],
		[ 'C:\\Developpement\\Powerbuilder\\Plexus\\trunk\\Sources\\conceptware.pbl', 'makefullpath', 'f' ],
		[ 'C:\\Developpement\\Powerbuilder\\Plexus\\trunk\\Sources\\plexus.pbl', 'optimizedatabase', 'f' ],
	  ],
	};

_is_deep_diff( $got, $expected, 'testing parse(FH) value');

#additional tests
my @tests = ( 
		[ 'executable_name'             , 'plexus9.exe' ],
		[ 'application_pbr'             , 'plexus.pbr'  ],
		[ 'prompt_for_overwrite'        , 0             ],
		[ 'rebuild_type'                , 'full'        ],
		[ 'rebuild_type_int'            , 1             ],
		[ 'windows_classic_style'       , 0             ],
		[ 'new_visual_style_controls'   , 1             ],

		[ 'build_type'			        , ''            ],
		[ 'build_type_int'		        , 0             ],
		[ 'with_error_context'          , 0             ],
		[ 'with_trace_information'      , 0             ],
		[ 'optimisation'                , 'speed'       ],
		[ 'optimisation_int'            , 0             ],
		[ 'enable_debug_symbol'         , 0             ],

		[ 'manifest_type'               , 'embedded'    ],
		[ 'manifest_type_int'           , 1             ],
		[ 'execution_level'             , 'asInvoker'   ],
		[ 'access_protected_sys_ui'     , 'false'       ],
		[ 'access_protected_sys_ui_int' , 0             ], 
		
		[ 'product_name'                , 'Plexus'      ],
		[ 'company_name'                , 'Conceptware S-à-r-l' ],
		[ 'description'                 , 'Plexus - Bank regulatory reporting' ],
		[ 'copyright'                   , 'Copyright 1994-2014 Conceptware'    ],
		[ 'product_version_string'      , '9.6.10 interne 10'                   ],
		[ 'product_version_number'      , '9.6.10.0'     ],
		[ 'product_version_numbers'     , '9,6,10,0'     ],
		[ 'file_version_string'         , '9061000'     ],
		[ 'file_version_number'         , '9.6.10.0'     ],
		[ 'file_version_numbers'        , '9,6,10,0'     ],
		
		[ 'manifestinfo_string'         , '1;asInvoker;false' ],
		
		#todo: test 'pbd' and 'obj' methods
	);

for my $test( @tests ){
	
	my $method = $test->[0];
	$expected  = $test->[1];

	$got       = join ',', $parsed->$method();
	
	$method    =~ tr/_-/  /;
	
	is( $got, $expected, "retrieve info '$method'" );
}
