package MarpaX::Languages::PowerBuilder::base;
use strict;
use warnings;
use File::BOM qw(open_bom);
use File::Basename qw(dirname basename);
use Marpa::R2;
use Data::Dumper;

$|++;

sub slurp{
	my $input = shift;
	local $/;
	open my $IN, '<:via(File::BOM)', $input;
	my $data = <$IN>;
	close $IN;
	$data;
}

sub new{
	my $class = shift;
	
	my $self = bless {}, $class;
	
	my $grammar = do{
		my $path = dirname(__FILE__);
		my $file = lc ref $self;
		$file =~ s/.*:://g;
		my $dsl = slurp( "$path/$file.marpa");
		Marpa::R2::Scanless::G->new( { source => \$dsl } );
    };
	*grammar = sub { $grammar };

	return $self;
}

sub parse{
	my $self = shift;
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
            semantics_package => ref($self)
        } );
    my $parsed = bless { recce => $recce, input => \$input, opts => $opts }, ref($self);
    eval{ $recce->read( \$input ) };
    $parsed->{error} = $@;
    return $parsed;
}

1;