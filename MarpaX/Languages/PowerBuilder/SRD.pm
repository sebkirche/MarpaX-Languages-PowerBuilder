package MarpaX::Languages::PowerBuilder::SRD;
#a SRQ parser and compiler to SQL

use feature 'say';
use strict;
use warnings;
use File::Slurp qw(slurp);
use Marpa::R2;
use Encode qw(decode);        #used in string -> HA decodes
use Data::Dumper;
use File::Basename qw(dirname);

$|++;

use constant grammar => do{
    my $path = dirname(__FILE__);
    my $dsl = slurp( "$path/srd.marpa");
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

sub syntax{
    my ($ppa, $header, $release, $containers, @remains) = @_;
    my %attr = ( release => $release );
    %attr = (%attr, %$_) for @$containers, $header->[1];
    return \%attr;
}

sub list{ shift, \@_ }
sub keyval{ +{@_[1,2]} }
sub listkeyval{
    shift;
    my %attr;
    %attr = (%attr, %$_) for @_;
    return \%attr;
    }

sub header{ { encoding => $_[0]->{encoding} = $_[1], file => $_[2] } }

sub comment{ { comment => $_[1] } }

sub release{ $_[2] }

sub containers{ 
    my (undef, @containers ) =@_;
    my @columns = map { values %$_ } grep { exists $_->{column} } @containers;
    @containers = grep { !exists $_->{column} } @containers;
    if(@columns){
        my $id = 1;
        $_->{id} = $id++ for @columns;
        my %cols;
        $cols{$_->{name}}=$_ for @columns;
        push @containers, { columns => \%cols };
    }
    return \@containers;
}

sub attributs{
    shift;
    my %attr;
    my @cols = map{ $_->{columns} } grep { exists $_->{columns} } @_;
    $attr{columns} = listkeyval( undef, @cols ) if @cols;
    %attr = (%attr, %$_) for grep { !exists $_->{columns} } @_;
    return \%attr;
}

sub colattribut{    
    my ($ppa, $name, undef, $value) = @_;
    return { columns => { $value->{name} => $value } };
}

sub attribut{
    my ($ppa, $name, undef, $value) = @_;
    return {$name => $value};
}

sub data{
    my ($ppa, $name, undef, $values, undef) = @_;
    return {data => $values};
    #~ return $ppa->{data}=$values;
}

sub datatype{ shift; join '', @_ }

sub hadecode{
    my $codes = shift;
    decode('utf16le', pack 'H*', $codes);
}

sub string{ 
    my ($ppa, $str) = @_;    
    if($ppa->{encoding}//'' eq 'HA' ){
        #cr$$HEX1$$e900$$ENDHEX$$ance 
        $str =~ s/\$\$HEX\d+\$\$([a-fA-F0-9]+)\$\$ENDHEX\$\$/hadecode($1)/ge;
    }
    if(1){#unquote string
        $str =~ s/^"|"$//g;
        $str =~ s/~(.)/$1/g;
    }
    return $str;
}

1;