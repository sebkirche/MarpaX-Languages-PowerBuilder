package MarpaX::Languages::PowerBuilder::PBR;
use base qw(MarpaX::Languages::PowerBuilder::base);

#a PBR parser by Nicolas Georges

sub resources{
	my ($ppa, @items) = @_;
	$DB::single = 1;	
 	return \@items;
}

sub lib_entry{
	my ($ppa, $lib, $entry) = @_;
	$DB::single = 1;	
 	return { lib => $lib, entry => $entry };
}

sub file{
	my ($ppa, $file) = @_;
	$DB::single = 1;	
	return { file => $file };	
}

1;

