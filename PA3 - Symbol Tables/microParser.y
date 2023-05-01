/* References Used:
1. for yylineno functionality: 
    https://web.iitd.ac.in/~sumeet/flex__bison.pdf
    https://stackoverflow.com/questions/16443056/yylineno-has-always-the-same-value-in-yacc-file?noredirect=1&lq=1
2. further, https://github.com/Yeaseen/c-compiler 
*/


%{
    #include<stdio.h>
    #include<stdlib.h>
    #include<string.h>
    #define MAX_SCOPES 100
    #define MAX_VARS_PER_SCOPE 100

    int yylex();
    int yyerror(char* msg);
    extern int yylineno; // get yylineno from .l file

    int scope = 0;
    int block_ctr = 0;
    int fn_call = 0;
    char* scope_names[MAX_SCOPES];
    char* type_temp;

    // each scope needs a symbol table
    struct varDecl{
		char* name;
		char* type;
        char* value;
        int line;
	};
    struct symTable{
        struct varDecl all_vars[MAX_VARS_PER_SCOPE];
        int num_vars;
    };
    struct symTable symbolTable[MAX_SCOPES];

%}

%token PROGRAM
%token _BEGIN
%token IDENTIFIER
%token STRINGLITERAL
%token INTLITERAL
%token FLOATLITERAL
%token STRING
%token FLOAT
%token INT
%token VOID
%token FUNCTION
%token READ
%token WRITE
%token RETURN
%token ENDIF
%token IF
%token ELSE
%token CONTINUE
%token BREAK
%token ENDWHILE
%token WHILE
%token END

%union{
    char* string;
    char* dataType;
    struct varDecl* var_decl;
    int linenum;
}

%type <string> id                           /* identifier name => str*/
%type <string> str                          /* stringliterals => str */
%type <dataType> var_type                   /* var_type => dataType */

%type <var_decl> var_decl
%type <var_decl> string_decl
%type <var_decl> param_decl
%type <var_decl> id_list
%type <var_decl> id_tail


%%



/* Program */
program:            PROGRAM id _BEGIN {
                        scope_names[scope] = "GLOBAL";
                        symbolTable[scope].num_vars = 0;
                    }
                    pgm_body END {
                        // printing to output file; if this is executed, no error has been detected.
                        for(int i=0; i<=scope; i++){
                            if(i>0) printf("\n");
                            printf("Symbol table %s", scope_names[i]);
                            if(scope_names[i] == "BLOCK"){
                                block_ctr++;
                                printf(" %d", block_ctr);
                            }
                            printf("\n");
                            for(int j=0; j<symbolTable[i].num_vars; j++){
                                
                                // printf("type = %d\n", strcmp(symbolTable[i].all_vars[j].type,"INT"));
                                if(!strcmp(symbolTable[i].all_vars[j].type, "STRING")){
                                    // output for str [ex: name str type STRING value "test"]
                                    printf("name %s type %s value %s\n", symbolTable[i].all_vars[j].name, symbolTable[i].all_vars[j].type, symbolTable[i].all_vars[j].value);
                                } 
                                else if(!strcmp(symbolTable[i].all_vars[j].type, "INT") || !strcmp(symbolTable[i].all_vars[j].type, "FLOAT")){
                                    // output for non-str [ex: name a type INT]
                                    printf("name %s type %s\n", symbolTable[i].all_vars[j].name, symbolTable[i].all_vars[j].type);
                                }
                            }   
                        }
                    }
                    ;
id:                 IDENTIFIER {}
                    ;
pgm_body:           decl func_declarations
                    ;
decl:               string_decl decl
                    | var_decl decl
                    |
                    ;

/* Global String Declaration */
string_decl:        STRING id ':''=' str ';' {
                        // (error handling): check if var name used already in same scope.
                        for(int i=0; i<symbolTable[scope].num_vars; i++){
                            if(!strcmp(symbolTable[scope].all_vars[i].name, $2)){
                                // error msg [ex. DECLARATION ERROR n (previous declaration was at line 6)]
                                printf("DECLARATION ERROR %s (previous declaration was at line %d)", symbolTable[scope].all_vars[i].name, symbolTable[scope].all_vars[i].line);
                                return 1;
                            }
                        }

                        // if OK, then continue
                        $<var_decl>$ = (struct varDecl*)malloc(sizeof(struct varDecl));
                        $<var_decl>$->name = $2;
                        $<var_decl>$->type = "STRING";
                        $<var_decl>$->value = $5;
                        $<var_decl>$->line = yylineno;
                        // printf("line: %d\n", $<var_decl>$->line);
                        symbolTable[scope].all_vars[symbolTable[scope].num_vars] = *($<var_decl>$);
                        symbolTable[scope].num_vars++;
                    }
                    ;
str:                STRINGLITERAL {}
                    ;

/* Variable Declaration */
var_decl:           var_type {
                        type_temp = $1;
                    } 
                    id_list ';' {}
                    ;
var_type:           FLOAT {}
                    | INT {}
                    ;
any_type:           var_type
                    | VOID
                    ;
id_list:            id {
                        if(!fn_call){
                            // (error handling): check if var name used already in same scope.
                            for(int i=0; i<symbolTable[scope].num_vars; i++){
                                if(!strcmp(symbolTable[scope].all_vars[i].name, $1)){
                                    // error msg [ex. DECLARATION ERROR n (previous declaration was at line 6)]
                                    printf("DECLARATION ERROR %s (previous declaration was at line %d)", symbolTable[scope].all_vars[i].name, symbolTable[scope].all_vars[i].line);

                                    return 1;
                                }
                            }

                            // if OK, then continue
                            $<var_decl>$ = (struct varDecl*)malloc(sizeof(struct varDecl));
                            $<var_decl>$->name = $1;
                            $<var_decl>$->type = type_temp;
                            $<var_decl>$->line = yylineno;
                            symbolTable[scope].all_vars[symbolTable[scope].num_vars] = *($<var_decl>$);
                            symbolTable[scope].num_vars++;
                        }
                        fn_call = 0;
                        
                    } 
                    id_tail {}
                    ;
id_tail:            ',' id {
                        if(!fn_call){
                            // (error handling): check if var name used already in same scope.
                            for(int i=0; i<symbolTable[scope].num_vars; i++){
                                if(!strcmp(symbolTable[scope].all_vars[i].name, $2)){
                                    // error msg [ex. DECLARATION ERROR n (previous declaration was at line 6)]
                                    printf("DECLARATION ERROR %s (previous declaration was at line %d)", symbolTable[scope].all_vars[i].name, symbolTable[scope].all_vars[i].line);

                                    return 1;
                                }
                            }
                            // if OK, then continue
                            $<var_decl>$ = (struct varDecl*)malloc(sizeof(struct varDecl));
                            $<var_decl>$->name = $2;
                            $<var_decl>$->type = type_temp;
                            $<var_decl>$->line = yylineno;
                            symbolTable[scope].all_vars[symbolTable[scope].num_vars] = *($<var_decl>$);
                            symbolTable[scope].num_vars++;
                        }
                        fn_call = 0;
                    } 
                    id_tail {}
                    | { 
                        type_temp = "UNSET"; // when id list is done, UNSET the type_temp
                    }
                    ;

/* Function Parameter List */
param_decl_list:    param_decl param_decl_tail
                    |
                    ;
param_decl:         var_type id {
                        if(!fn_call){
                            // error handling
                            for(int i=0; i<symbolTable[scope].num_vars; i++){
                                if(!strcmp(symbolTable[scope].all_vars[i].name, $2)){
                                    // error msg [ex. DECLARATION ERROR n (previous declaration was at line 6)]
                                    printf("DECLARATION ERROR %s (previous declaration was at line %d)", symbolTable[scope].all_vars[i].name, symbolTable[scope].all_vars[i].line);
                                    return 1;
                                }
                            }
                        
                            $<var_decl>$ = (struct varDecl*)malloc(sizeof(struct varDecl));
                            $<var_decl>$->name = $2;
                            $<var_decl>$->type = $1;
                            $<var_decl>$->line = yylineno;
                            symbolTable[scope].all_vars[symbolTable[scope].num_vars] = *($<var_decl>$);
                            symbolTable[scope].num_vars++;
                        }
                        fn_call = 0;
                    }
                    ;
param_decl_tail:    ',' param_decl param_decl_tail
                    |
                    ;

/* Function Declarations */
func_declarations:  func_decl func_declarations
                    |
                    ;
func_decl:          FUNCTION any_type id { // func params => part of func scope
                        scope++;
                        scope_names[scope] = $3;
                        symbolTable[scope].num_vars = 0;
                    } 
                    '(' param_decl_list ')' _BEGIN func_body END
                    ;
func_body:          decl stmt_list
                    ;

/* Statement List */
stmt_list:          stmt stmt_list
                    |
                    ;
stmt:               base_stmt
                    | if_stmt
                    | while_stmt
                    ;
base_stmt:          assign_stmt
                    | read_stmt
                    | write_stmt
                    | return_stmt
                    ;

/* Basic Statements */
assign_stmt:        assign_expr ';'
                    ;
assign_expr:        id ':''=' expr
                    ;
read_stmt:          READ {
                        fn_call = 1;
                    } 
                    '(' id_list ')' ';'
                    ;
write_stmt:         WRITE {
                        fn_call = 1;
                    } 
                    '(' id_list ')' ';'
                    ;
return_stmt:        RETURN expr ';'
                    ;

/* Expressions */
expr:               expr_prefix factor
                    ;
expr_prefix:        expr_prefix factor addop
                    |
                    ;
factor:             factor_prefix postfix_expr
                    ;
factor_prefix:      factor_prefix postfix_expr mulop
                    |
                    ;
postfix_expr:       primary
                    | call_expr
                    ;
call_expr:          id '(' expr_list ')'
                    ;
expr_list:          expr expr_list_tail
                    |
                    ;
expr_list_tail:     ',' expr expr_list_tail
                    |
                    ;
primary:            '(' expr ')'
                    | id
                    | INTLITERAL
                    | FLOATLITERAL
                    ;
addop:              '+' | '-'
                    ;
mulop:              '*' | '/'
                    ;

/* Complex Statements and Condition */
if_stmt:            IF {
                        scope++;
                        scope_names[scope] = "BLOCK";
                        symbolTable[scope].num_vars = 0;
                    }  
                    '(' cond ')' decl stmt_list else_part ENDIF
                    ;
else_part:          ELSE {
                        scope++;
                        scope_names[scope] = "BLOCK";
                        symbolTable[scope].num_vars = 0;
                    } 
                    decl stmt_list
                    |
                    ;
cond:               expr compop expr
                    ;
compop:             '>''='
                    | '<''='
                    | '!''='
                    | '<'
                    | '>'
                    | '='
                    ;
while_stmt:         WHILE {
                        scope++;
                        scope_names[scope] = "BLOCK";
                        symbolTable[scope].num_vars = 0;
                    } 
                    '(' cond ')' decl aug_stmt_list ENDWHILE
                    ;
aug_stmt_list:      aug_stmt aug_stmt_list
                    |
                    ;
aug_stmt:           base_stmt
                    | aug_if_stmt
                    | while_stmt
                    | CONTINUE ';'
                    | BREAK ';'
                    ;
aug_if_stmt:        IF {
                        scope++;
                        scope_names[scope] = "BLOCK";
                        symbolTable[scope].num_vars = 0;
                    } 
                    '(' cond ')' decl aug_stmt_list aug_else_part ENDIF
                    ;
aug_else_part:      ELSE {
                        scope++;
                        scope_names[scope] = "BLOCK";
                        symbolTable[scope].num_vars = 0;
                    }
                    decl aug_stmt_list
                    |
                    ;

%%
