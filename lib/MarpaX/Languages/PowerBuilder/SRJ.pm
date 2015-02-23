package MarpaX::Languages::PowerBuilder::SRJ;
use base qw(MarpaX::Languages::PowerBuilder::base);
#a SRJ parser by Nicolas Georges

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

sub string {
	my ($ppa, $str) = @_;
	return $str;
}

sub integer {
	my ($ppa, $int) = @_;
	return $int;
}

1;

