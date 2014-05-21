
use strict;
use warnings;
use feature 'say';
use MarpaX::Languages::PowerBuilder::PBSelect;

my $data = <<'ENDOFSELECT';
PBSELECT(
VERSION(400)
    TABLE(NAME="esri_alias" )  
    TABLE(NAME="check_rules_results" ) 
    COLUMN(NAME="esri_alias.ea_table") 
    COLUMN(NAME="esri_alias.ea_dbname") 
    COLUMN(NAME="esri_alias.ea_text") 
    COLUMN(NAME="esri_alias.ea_alias") 
    COLUMN(NAME="check_rules_results.key_2") 
    COLUMN(NAME="check_rules_results.key_1") 
    COMPUTE(NAME="max(rule_id)") 
    COMPUTE(NAME="min(rule_id)")    
    JOIN (LEFT="esri_alias.ea_table"    OP ="="RIGHT="check_rules_results.table_name" )    
    JOIN (LEFT="esri_alias.ea_dbname"    OP ="="RIGHT="check_rules_results.column_name" )
    WHERE(    EXP1 ="~"check_rules_results~".~"spid~""   OP ="=" EXP2 ="@@spid"    LOGIC ="And" ) 
    WHERE(    EXP1 ="~"esri_alias~".~"ea_table~""   OP ="like"    EXP2 ="'B%'"    LOGIC ="or" ) 
    WHERE(    EXP1 ="~"esri_alias~".~"ea_table~""   OP ="= all" 
        NEST = PBSELECT( 
            VERSION(400) 
            TABLE(NAME="sys.systable" ) 
            COLUMN(NAME="sys.systable.table_name")
            WHERE(    EXP1 ="~"sys~".~"systable~".~"table_name~""   OP ="like"    EXP2 ="'___'" ) 
            )
        )  
    GROUP(NAME="esri_alias.ea_table") 
    GROUP(NAME="esri_alias.ea_dbname") 
    GROUP(NAME="esri_alias.ea_text") 
    GROUP(NAME="esri_alias.ea_alias") 
    GROUP(NAME="check_rules_results.key_2") 
    GROUP(NAME="check_rules_results.key_1")   
    HAVING (   EXP1 ="~"esri_alias~".~"ea_text~""   OP ="like"    EXP2 ="'a%'"    LOGIC ="" )
) 
ORDER(NAME="esri_alias.ea_table" ASC=no)  
ORDER(NAME="esri_alias.ea_dbname" ASC=no)  
ORDER(NAME="check_rules_results.key_1" ASC=yes )  
ORDER(NAME="check_rules_results.key_2" ASC=yes ) 

ENDOFSELECT

my $parsed = MarpaX::Languages::PowerBuilder::PBSelect::parse($data);
my $ast = ${$parsed->{recce}->value};

use Data::Dumper::GUI;
#Dumper $parsed;
#Dumper $ast;
say MarpaX::Languages::PowerBuilder::PBSelect::to_sql($ast);
