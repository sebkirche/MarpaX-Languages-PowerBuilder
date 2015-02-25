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

=pod	TODO, add helper to retrieve infos:

	$parsed->{exe}[0]	exe_name
	$parsed->{exe}[1]	application_pbr
	$parsed->{exe}[2]	prompt_for_overwrite
	$parsed->{exe}[3]	rebuild (0:incremental, 1:full) (enabled when Enable DEBUG symbol=1)
	$parsed->{exe}[4]	windows_classic_style
	
code generation options:

	$parsed->{cmp}[0]	0:Pcode, 1:Machine code
	$parsed->{cmp}[1]	Error context information
	$parsed->{cmp}[2]	Trace_information
	$parsed->{cmp}[3]	
	$parsed->{cmp}[4]	Optimisation: 0:speed, 1:space, 2:none
	$parsed->{cmp}[5]	
	$parsed->{cmp}[6]	Enable DEBUG symbol
	$parsed->{cmp}[7]	
	
Manifest Information

	$parsed->{man}[0]	0:No manifest, 1:EmbeddedManifest, 2:External manifest
	$parsed->{man}[1]	AsInvoker, requireAdministrator, highestAvailable
	$parsed->{man}[2]	Allow access to protected system UI
	
=cut