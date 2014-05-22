package MarpaX::Languages::PowerBuilder::PBW;

#a PBW parser by Sébastien Kirche

use feature 'say';
use strict;
use warnings;
use File::Slurp qw(slurp);
use Marpa::R2;
use Data::Dumper;
use File::Basename qw(dirname);

$|++;

use constant grammar => do{
$DB::single=1;
    my $path = dirname(__FILE__);
    my $dsl = slurp( "$path/pbw.marpa");
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
	my $ppa = shift;
	my ($fmt, $uncheck, $targets, $deftrg, $defrmt);
	($fmt, $uncheck, $targets, $deftrg, $defrmt) = @_ if (scalar @_ == 5);
	($fmt, $targets, $deftrg, $defrmt, $uncheck) = (@_, []) if (scalar @_ == 4); #no uncheck

	my %attrs = ( format => $fmt, unchecked => $uncheck, targets => $targets, defaulttarget => $deftrg, defaultremotetarget => $defrmt);
 	return \%attrs;
}

sub format {
	my ($ppa, $vers, $date) = @_;
    my %attrs = ( version => $vers,
    				date => $date);
	return \%attrs;
}

sub indexedItems {
	my ($ppa, @list) = @_;
	my @items = map {$_->[1]} @list;
	#~ map{$items{$_->[0]} = $_->[1]} @list;
	return \@items;
}

sub string {
	my ($ppa, $str) = @_;
	$str =~ s/^"|"$//g;
	return $str;
}

1;

