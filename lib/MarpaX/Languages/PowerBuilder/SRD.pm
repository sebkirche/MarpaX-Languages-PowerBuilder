package MarpaX::Languages::PowerBuilder::SRD;

#a datawindow parser by Nicolas Georges

use feature 'say';
use strict;
use warnings;
use File::Slurp qw(slurp);
use Marpa::R2;
use Encode qw(decode);        #used in string -> HA decodes
use Data::Dumper;
use File::Basename qw(dirname);
use constant DEBUG => 1;

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
    
    #3 ways to pass input: glob, file-name, full-string
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
    my ($ppa, $header, $release, $containers, $binsection) = @_;
    my %attr = ( release => $release );
    $attr{binary}=$binsection if defined $binsection;
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

my $control_types = do{ 
        my $types = join '|', qw(column text bitmap button 
                    compute ellipse graph groupbox 
                    inkpic line ole rectangle 
                    report roundrectangle tableblob);
        qr/^($types)$/io;
    };
                    
sub containers{ 
    my (undef, @containers ) =@_;
    my @controls = map { (%$_)[1]->{type} = (%$_)[0]; values %$_ } grep { (%$_)[0] =~ $control_types } @containers;
    @containers = grep { (%$_)[0] !~ $control_types } @containers;
#    die Dumper( \@containers );
    if(@controls){
#    	die Dumper(\@controls);

		#add index to columns controls
        my $id = 1;
        $_->{'#'} = $id++ for grep {$_->{type} eq 'column'} @controls;
        
        #inject a name to pre-7 texts that have no name (PB call them obj_xxx at runtime)
        $id = 1;
        $_->{'name'} = 't_'.$id++ for grep {$_->{type} eq 'text' && !$_->{name}} @controls;
        my %ctls;
        $ctls{$_->{name}}=$_ for @controls;
        push @containers, { controls => \%ctls };
    }
    return \@containers;
}

sub attributes{
    shift;
    my %attr;
    my @cols = map{ $_->{columns} } grep { exists $_->{columns} } @_;
	
	#inject a column id into the column list
	my $id = 1;
	for (@cols){
		(values %$_)[0]{'#'} = $id++;	#FIXME: ???! is it the perlish way to do ?
	}
	
    $attr{columns} = listkeyval( undef, @cols ) if @cols;
    %attr = (%attr, %$_) for grep { !exists $_->{columns} } @_;
    return \%attr;
}

sub colattribute{    
    my ($ppa, $name, undef, $value) = @_;
    return { columns => { $value->{name} => $value } };
}

sub attribute{
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
    if($ppa->{encoding}//'' eq 'HA$' ){
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
