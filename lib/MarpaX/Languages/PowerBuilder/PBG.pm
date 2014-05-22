package MarpaX::Languages::PowerBuilder::PBG;

#a PBG parser by Sébastien Kirche

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
    my $dsl = slurp( "$path/pbg.marpa");
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

sub syntax {
	my ($ppa, $fmt, $libs, $objs) = @_;
    my %attrs = ( format => $fmt, libraries => $libs, objects => $objs);
 	return \%attrs;
}

sub format {
	my ($ppa, $vers, $date) = @_;
    my %attrs = ( version => $vers,
    				date => $date);
	return \%attrs;
}

sub libraries {
	my ($ppa, @objs) = @_;
	my @libs = map{ $_->[0] } @{$objs[0]}; # LibraryList -> ObjectLocationList -> ObjectLocation+
    return \@libs;
} 

sub objects {
	my ($ppa, @objs) = @_;
	my %objects;
	map{$objects{$_->[0]} = $_->[1]} @{$objs[0]}; # ObjectList -> ObjectLocationList -> ObjectLocation+
	return \%objects;
}

sub string {
	my ($ppa, $str) = @_;
	$str =~ s/^"|"$//g;
	return $str;
}

1;

