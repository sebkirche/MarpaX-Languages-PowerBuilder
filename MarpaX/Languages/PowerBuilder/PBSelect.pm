package MarpaX::Languages::PowerBuilder::PBSelect;

use 5.10.1;
use strict;
use warnings;
use Marpa::R2;

use constant DEBUG=> 0;

# PBSelect Marpa grammar by Nicolas Georges
# adapted to  MarpaX::Languages::PowerBuilder by Sébastien Kirche

$|++; #autoflush stdout/stderr

sub parse{
	my $input = shift;
	my $opts = shift;
	my $dsl = <<'END_OF_DSL';
:default            ::= action => [name,values]
:start              ::= query
lexeme default = latm => 1

query               ::= pbselect orders action => query
pbselect            ::= ('PBSELECT' '(') version tables columns computes joins wheres groups havings (')') action => pbselect
version             ::= 'VERSION' '(' number ')' action => version
tables              ::= table+ action => tables
table               ::= 'TABLE' '(' 'NAME' '=' <db identifier> ')' action => table
columns             ::= column+ action => columns
column              ::= 'COLUMN' '(' 'NAME' '=' <db identifier> ')' action => column
computes            ::= compute* action => computes
compute             ::= 'COMPUTE' '(' 'NAME' '=' string ')' action => compute
joins               ::= join* action => joins
join                ::= 'JOIN' '(' 'LEFT' '=' <db identifier> 'OP' '=' string 'RIGHT' '=' <db identifier> ')' action => join
wheres              ::= where* action => wheres
where               ::= 'WHERE' '(' 'EXP1' '=' string 'OP' '=' string where_exp2 'LOGIC' '=' string ')' action => where_logic
                      | 'WHERE' '(' 'EXP1' '=' string 'OP' '=' string where_exp2 ')' action => where
where_exp2          ::= 'EXP2' '=' string action => where_exp2
                      | 'NEST' '=' pbselect action => where_nest
groups              ::= group* action => groups
group               ::= 'GROUP' '(' 'NAME' '=' string ')' action => group
havings             ::= having* action => havings
having              ::= 'HAVING' '(' 'EXP1' '=' string 'OP' '=' string where_exp2 'LOGIC' '=' string ')' action => having_logic
orders              ::= order* action => orders
order               ::= 'ORDER' '(' 'NAME' '=' <db identifier> 'ASC' '=' boolean ')' action => order
boolean               ~ 'yes':i | 'no':i
<db identifier>     ::= ('"') identifier ('"') action => quoted_db_identifier
                      | identifier
identifier            ~ [_a-zA-Z.] rest_id
rest_id               ~ [_0-9a-zA-Z.]*
number                ~ [\d]+

string              ::= <string lexeme> action => string
<string lexeme>       ~ quote <string contents> quote
# This cheats -- it recognizers a superset of legal JSON strings.
# The bad ones can sorted out later, as desired
quote                 ~ ["]
<string contents>     ~ <string char>*
<string char>         ~ [^"~] | '~' <any char>
<any char>            ~ [\d\D]

:discard              ~ crlf
crlf                  ~ [\x{D}\x{A}]+
:discard              ~ whitespace
whitespace            ~ [\s]+

END_OF_DSL
 
    my $grammar = Marpa::R2::Scanless::G->new( { source => \$dsl } );
    my $recce = Marpa::R2::Scanless::R->new({ grammar => $grammar, semantics_package => 'QueryParser' } );
#    eval{ $recce->read( \$input ) };
    
    my $parsed = bless { recce => $recce, input => \$input, opts => $opts }, __PACKAGE__;
    eval{ $recce->read( \$input ) };
    $parsed->{error} = $@;
	
    if (DEBUG){
    	use Data::Dumper::GUI;
    	Dumper ${$parsed->{recce}->value // {}};
    }

    return $parsed;
}
    
sub to_sql{
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
                $where .= "(" . to_sql($_->{exp2}) . ")";
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
      $sql .= "\n\tGROUP BY ";
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
        $sql .= "\n\tORDER BY ";
        $sql .= join ",\n\t" , map { $_->{name} . " " . uc $_->{dir} } @{$ast->{orders}};
    }
    return $sql;
}

sub QueryParser::version{
    my (undef, $name, @children) = @_;
    return { lc $name => $children[1] };
}

sub QueryParser::table{
    my (undef, $name, @children) = @_;
    return $children[3];
}

sub QueryParser::tables{
    my (undef, @children) = @_;
    return { 'tables' => \@children };
}

sub QueryParser::column{
    my (undef, $name, @children) = @_;
    return $children[3];
}

sub QueryParser::columns{
    my (undef, @children) = @_;
    return { 'columns' => \@children };
}

sub QueryParser::compute{
    my (undef, $name, @children) = @_;
    return $children[3];
}

sub QueryParser::computes{
    my (undef, @children) = @_;
    return { 'computes' => \@children };
}

sub QueryParser::join{
    my (undef, $name, @children) = @_;
    return { left => $children[3], op => $children[6], right => $children[9] };
}

sub QueryParser::joins{
    my (undef, @children) = @_;
    return { 'joins' => \@children };
}

sub QueryParser::where_logic{
    my (undef, $name, @children) = @_;
    return { exp1 => $children[3], op => $children[6], exp2 => $children[7], logic => $children[10] };
}

sub QueryParser::where{
    my (undef, $name, @children) = @_;
    return { exp1 => $children[3], op => $children[6], exp2 => $children[7] };
}

sub QueryParser::where_exp2{
    my (undef, $name, @children) = @_;
    return $children[1];
}

sub QueryParser::where_nest{
    my (undef, $name, @children) = @_;
    return $children[1];
}

sub QueryParser::wheres{
    my (undef, @children) = @_;
    return { 'wheres' => \@children };
}

sub QueryParser::group{
    my (undef, $name, @children) = @_;
    return $children[3];
}

sub QueryParser::groups{
    my (undef, @children) = @_;
    return { 'groups' => \@children };
}

sub QueryParser::having_logic{
    my (undef, $name, @children) = @_;
    return { exp1 => $children[3], op => $children[6], exp2 => $children[7], logic => $children[10] };
}

sub QueryParser::havings{
    my (undef, @children) = @_;
    return { 'havings' => \@children };
}

sub QueryParser::order{
    my (undef, $name, @children) = @_;
    return { name => $children[3], dir => (lc($children[6]//'no') eq 'yes')?'asc':'desc' };
}

sub QueryParser::orders{
    my (undef, @children) = @_;
    return \@children;
}

sub QueryParser::pbselect{
    my (undef, @children) = @_;
    my %mixed;
    %mixed = (%mixed, %$_) for @children;
    return \%mixed;
}

sub QueryParser::query{
    my (undef, @children) = @_;
    return { select => $children[0], orders => $children[1] };
}

sub QueryParser::string{
    my (undef, $string) = @_;
    #remove bounding quotes and escape chars.
    $string =~ s/^"|"$//g;
    $string =~ s/~(.)/$1/g;
    return $string;
}

sub QueryParser::quoted_db_identifier{
    my (undef, $dbidentifier) = @_;
    return $dbidentifier;
}

1;
