package MarpaX::Languages::PowerBuilder::PBT;
#a PBT parser

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
    my $dsl = slurp( "$path/pbt.marpa");
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
	#~ Format ProjectList AppName AppLib LibList Type
	my $ppa = shift;
	my ($fmt, $projects, $app, $applib, $libs, $type) = @_;

	my %attrs = ( format => $fmt, projects => $projects, appname => $app, applib => $applib, liblist => $libs, type => $type);
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

sub libList {
	my ($ppa, $liblist) = @_;
	my @libs = split ';', $liblist;
	return \@libs;
}

sub deploy {
	my ($ppa, $depproj) = @_;
	my @proj;
	foreach my $dp (@$depproj){
		my ($chk, $name, $lib) = split '&', $dp;
		push @proj, {name => $name, lib => $lib, checked => $chk};
	}
	return \@proj;
}

sub string {
	my ($ppa, $str) = @_;
	$str =~ s/\\\\/\\/g;
	$str =~ s/^"|"$//g;
	return $str;
}

1;

