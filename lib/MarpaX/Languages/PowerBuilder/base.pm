package MarpaX::Languages::PowerBuilder::base;
use strict;
use warnings;
use File::BOM qw(open_bom);
use File::Basename qw(dirname basename);
use Marpa::R2;
use Data::Dumper;

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
		
	unless($self->can('grammar')){
		my $pkg  = ref $self;
		my $grammar = do{
			my $path = dirname(__FILE__);
			my $file = lc $pkg;
			$file =~ s/.*:://g;
			my $dsl = slurp( "$path/$file.marpa");
			Marpa::R2::Scanless::G->new( { source => \$dsl } );
		};
		#inject grammar method
		{
			no strict 'refs';
			*{$pkg.'::grammar'} = sub { $grammar };
		}
	}

	return $self;
}

sub parse{
	my $self = shift;
	die "forget to call new() ?" unless ref($self) && $self->can('grammar');
    my $input = shift;
    my $opts  = shift;
    #3 ways to pass inputs: glob, file-name, full-string
    if(ref $input eq 'GLOB'){
		$input = File::BOM::decode_from_bom( do{ local $/=undef; <$input> } );
    }
    elsif($input!~/\n/ && -f $input){
        $input = slurp $input;
    }
    
    my $recce = Marpa::R2::Scanless::R->new({ 
            grammar => $self->grammar(), 
            semantics_package => ref($self)
        } );
    my $parsed = bless { recce => $recce, input => \$input, opts => $opts }, __PACKAGE__;
    eval{ $recce->read( \$input ) };
    $parsed->{error} = $@;
    return $parsed;
}

1;