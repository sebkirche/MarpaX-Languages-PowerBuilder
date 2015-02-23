package MarpaX::Languages::PowerBuilder::PBR;

#a PBR parser by Nicolas Georges

use feature 'say';
use strict;
use warnings;
use File::Slurp qw(slurp);
use Marpa::R2;
use Data::Dumper;
use File::Basename qw(dirname);

$|++;

use constant grammar => do{
    my $path = dirname(__FILE__);
    my $dsl = slurp( "$path/pbr.marpa");
	Marpa::R2::Scanless::G->new( { source => \$dsl } );
    };

sub parse{
    shift if (ref $_[0] || $_[0]) eq __PACKAGE__;   #discard package/object
    my $input = shift;
    my $opts  = shift;
    #3 ways to pass inputs: glob, file-name, full-string
    if(ref $input eq 'GLOB'){
        $input = do{ local $/; <$input> };
    }
    elsif($input!~/\n/ && -f $input){
        $input = slurp $input;
    }
    
    my $recce = Marpa::R2::Scanless::R->new({ 
            grammar => grammar(), 
            semantics_package => __PACKAGE__ 
        } );
    my $parsed = bless { recce => $recce, input => \$input, opts => $opts }, __PACKAGE__;
    eval{ $recce->read( \$input ) };
    $parsed->{error} = $@;
    return $parsed;
}

sub resources{
	my ($ppa, @items) = @_;
	$DB::single = 1;	
 	return \@items;
}

sub lib_entry{
	my ($ppa, $lib, $entry) = @_;
	$DB::single = 1;	
 	return { lib => $lib, entry => $entry };
}

sub file{
	my ($ppa, $file) = @_;
	$DB::single = 1;	
	return { file => $file };	
}

1;

