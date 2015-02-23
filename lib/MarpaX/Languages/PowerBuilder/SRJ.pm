package MarpaX::Languages::PowerBuilder::SRJ;

#a SRJ parser by Nicolas Georges

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
    my $dsl = slurp( "$path/srj.marpa");
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

sub project {
	my ($ppa, $items) = @_;
	
    my %attrs;	# = ( pbd => \@pbd, obj => \@obj, exe => \$exe);
	$DB::single=1;
	ITEM:
	for(@$items){
		my $item = $_->[0];
		my ($name, @children) = @$item;
		if($name =~ /^(PBD|OBJ)$/i){
			push @{$attrs{$name}}, \@children;
		}
		else{
			$attrs{$name} = \@children;
		}
	}
	
 	return \%attrs;
}

sub string {
	my ($ppa, $str) = @_;
	return $str;
}

sub integer {
	my ($ppa, $int) = @_;
	return $int;
}

1;

