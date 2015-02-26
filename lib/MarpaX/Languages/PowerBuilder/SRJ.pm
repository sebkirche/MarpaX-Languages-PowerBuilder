package MarpaX::Languages::PowerBuilder::SRJ;
use base qw(MarpaX::Languages::PowerBuilder::base);
#a SRJ parser by Nicolas Georges

#helper methods
sub value{
	my $self = shift;
	unless(exists $self->{__value__}){
		$self->{__value__} = ${ $self->{recce}->value // \{} };
	}
	return $self->{__value__};
}

sub exe_name{ $_[0]->value->{exe}[0] }

#Grammar action methods
sub project {
	my ($ppa, $items) = @_;
	
    my %attrs;	# = ( pbd => \@pbd, obj => \@obj, exe => \$exe);
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

sub compiler{
	my ($ppa, $ary) = @_;
	
	return [ cmp => @$ary ];
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

