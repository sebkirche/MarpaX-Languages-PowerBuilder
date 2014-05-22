package MarpaX::Languages::PowerBuilder::SRQ;
#a SRQ parser and compiler to SQL

use feature 'say';
use strict;
use warnings;
use File::Slurp qw(slurp);
use Marpa::R2;
use File::Basename qw(dirname);

$|++;

use constant grammar => do{
    my $path = dirname(__FILE__);
    my $dsl = slurp( "$path/srq.marpa");
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

sub sql{
    my $self = shift;
    my $val = $self->{recce}->value();
    return _compile( $$val );
}

sub _compile{
    my $ast = shift;
    my $select = exists $ast->{select} ? $ast->{select} : $ast;
    my $sql = "SELECT\n\t";
    $sql .= join ",\n\t", @{$select->{columns}//[]}, @{$select->{computes}//[]};
    $sql .= "\n\tFROM ";
    $sql .= join ",\n\t", @{$select->{tables}//[]};
    #joins are threated like where clause
    if(@{$select->{wheres}//[]} + @{$select->{joins}//[]}){
        $sql .= "\n\tWHERE ";
        my $where = "(";
        foreach( @{$select->{wheres}} ){
            $where .= "\t";
            $where .= "($_->{exp1} " . uc($_->{op})." ";
            if(ref $_->{exp2}){
                $where .= "(" . _compile($_->{exp2}) . ")";
            }
            else{
                $where .= "$_->{exp2}";
            }
            $where .= ")";
            $where .= uc " $_->{logic}\n" if exists $_->{logic};
        }
        $where .=")\n";
        
        my @joins = map{ "\t(" . join(" ", $_->{left}, uc($_->{op}), $_->{right}).")" } @{$select->{joins}};
        $sql .= join " AND\n", @joins, $where;
    }
    #groups
    if(@{$select->{groups}//[]}){
      $sql .= "\tGROUP BY ";
      $sql .= join ",\n\t", @{$select->{groups}};
    }
    #havings
    if(@{$select->{havings}//[]}){
        $sql .= "\n\tHAVING ";
        foreach( @{$select->{havings}} ){
            $sql .= "\t";
            $sql .= "($_->{exp1} " . uc($_->{op})." ";
            $sql .= "$_->{exp2})";
            $sql .= uc " $_->{logic}\n" if exists $_->{logic};
        }
    }
    #orders
    if(exists $ast->{orders}){
        $sql .= "\tORDER BY ";
        $sql .= join ",\n\t" , map { $_->{name} . " " . uc $_->{dir} } @{$ast->{orders}};
    }
    return $sql;
}

sub version{
    my (undef, $name, @children) = @_;
    return { lc $name => $children[1] };
}

sub table{
    my (undef, $name, @children) = @_;
    return $children[3];
}

sub tables{
    my (undef, @children) = @_;
    return { 'tables' => \@children };
}

sub column{
    my (undef, $name, @children) = @_;
    return $children[3];
}

sub columns{
    my (undef, @children) = @_;
    return { 'columns' => \@children };
}

sub compute{
    my (undef, $name, @children) = @_;
    return $children[3];
}

sub computes{
    my (undef, @children) = @_;
    return { 'computes' => \@children };
}

sub join{
    my (undef, $name, @children) = @_;
    return { left => $children[3], op => $children[6], right => $children[9] };
}

sub joins{
    my (undef, @children) = @_;
    return { 'joins' => \@children };
}

sub where_logic{
    my (undef, $name, @children) = @_;
    return { exp1 => $children[3], op => $children[6], exp2 => $children[7], logic => $children[10] };
}

sub where{
    my (undef, $name, @children) = @_;
    return { exp1 => $children[3], op => $children[6], exp2 => $children[7] };
}

sub where_exp2{
    my (undef, $name, @children) = @_;
    return $children[1];
}

sub where_nest{
    my (undef, $name, @children) = @_;
    return $children[1];
}

sub wheres{
    my (undef, @children) = @_;
    return { 'wheres' => \@children };
}

sub group{
    my (undef, $name, @children) = @_;
    return $children[3];
}

sub groups{
    my (undef, @children) = @_;
    return { 'groups' => \@children };
}

sub having_logic{
    my (undef, $name, @children) = @_;
    return { exp1 => $children[3], op => $children[6], exp2 => $children[7], logic => $children[10] };
}

sub havings{
    my (undef, @children) = @_;
    return { 'havings' => \@children };
}

sub order{
    my (undef, $name, @children) = @_;
    return { name => $children[3], dir => (lc($children[6]//'no') eq 'yes')?'asc':'desc' };
}

sub orders{
    my (undef, @children) = @_;
    return \@children;
}

sub pbselect{
    my (undef, @children) = @_;
    my %mixed;
    %mixed = (%mixed, %$_) for @children;
    return \%mixed;
}

sub query{
    my (undef, @children) = @_;
    return { select => $children[0], orders => $children[1] };
}

sub string{
    my (undef, $string) = @_;
    #remove bounding quotes and escape chars.
    $string =~ s/^"|"$//g;
    $string =~ s/~(.)/$1/g;
    return $string;
}

sub quoted_db_identifier{
    my (undef, $dbidentifier) = @_;
    return $dbidentifier;
}

1;