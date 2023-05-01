/* 
    References and Acknowledgements:

1. for yylineno functionality: 
    https://web.iitd.ac.in/~sumeet/flex__bison.pdf
    https://stackoverflow.com/questions/16443056/yylineno-has-always-the-same-value-in-yacc-file?noredirect=1&lq=1
2. further, https://github.com/Yeaseen/c-compiler
3. more insights from https://github.com/dhairyaagrawal/microCompiler 

*/


%{
    #include <stdio.h>
    #include <iostream>
    #include <vector>
    #include <string>
    #include <iterator>
    #include <map>
    #include <stack>
    #include <sstream>

    #include "helper.h"

    int yylex();
    void yyerror(char const* msg);
	std::vector <TAC> IR;
	std::stack <std::string> scope;

    extern void addSymbolTable();
    extern void makeIR(AST_Node * ast);
    extern void removeAST(AST_Node * ast);
    extern void pushBlock();
    extern std::string CondExprIR(AST_Node *node, std::string *t);

	struct wrapper{
    	std::string value[2];
	};
    wrapper wrap1, p;
    std::pair <std::map <std::string, wrapper>::iterator, bool> r;
    std::map <std::string, wrapper> table;
    std::map <std::string, std::map<std::string, wrapper>> sTable;
    int block_ctr = 0;
    int lab_ctr = 1;
    std::stringstream ss;
    std::stack <std::string> loopStack;
    std::vector <std::string> idVec, vars, strConst;
    int registerCounter = 1;
    std::stack <std::string> labels;
    int whileID = 0;
    std::stack <int> whileStack;

%}

%union{
    char* string;
    char* dataType;
    class AST_Node* ptr;
}

%token PROGRAM
%token _BEGIN
%token STRING
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

%token <string> IDENTIFIER
%token <string> INTLITERAL
%token <string> FLOATLITERAL
%token <string> STRINGLITERAL
%token <string> INT
%token <string> FLOAT

%token OP_ADD
%token OP_SUB
%token OP_MUL
%token OP_DIV
%token LPAREN
%token RPAREN
%token OP_SEM
%token OP_COM
%token OP_LE
%token OP_GE
%token OP_LT
%token OP_GT
%token OP_AS
%token OP_NE
%token OP_EQ

%type <string> id                           /* identifier name => str*/
%type <string> str                          /* stringliterals => str */
%type <string> compop
%type <dataType> var_type                   /* var_type => dataType */
%type <ptr> primary postfix_expr call_expr expr_list expr_list_tail addop mulop assign_expr factor factor_prefix expr_prefix expr

%%

/* Program */
program:            PROGRAM id _BEGIN {
                        scope.push("GLOBAL");
                    }
                    pgm_body END {
                        scope.pop();
                    }
                    ;
id:                 IDENTIFIER {
                        $$ = $1;
                    }
                    ;
pgm_body:           decl func_declarations
                    ;
decl:               string_decl decl
                    | var_decl decl
                    | {
                        addSymbolTable();
                    }
                    ;

/* Global String Declaration */
string_decl:        STRING id OP_AS str OP_SEM {
                        wrap1.value[0] = "STRING";
                        wrap1.value[1] = $4;
                        r = table.insert(std::pair<std::string, wrapper> ($2, wrap1));
                        if(!r.second){
                            yyerror($2);
                        }
                        ss.str("");
                        ss << "str " << $2 << " " << $4;
                        strConst.push_back(ss.str());
                    }
                    ;
str:                STRINGLITERAL {
                        $$ = $1;
                    }
                    ;

/* Variable Declaration */
var_decl:           var_type id_list OP_SEM {
                        for(typename std::vector <std::string>::reverse_iterator itr = idVec.rbegin(); itr != idVec.rend(); ++itr){
                            wrap1.value[0] = $1;
                            wrap1.value[1] = "";
                            r = table.insert(std::pair<std::string, wrapper> (*itr, wrap1));
                            if(!r.second){
                                std::string temp = *itr;
                                yyerror(temp.c_str());
                            }
                            vars.push_back(*itr);
                        }
                        idVec.clear();
                    } 
                    ;
var_type:           FLOAT { $$ = $1; }
                    | INT { $$ = $1; }
                    ;
any_type:           var_type
                    | VOID
                    ;
id_list:            id id_tail { idVec.push_back($1); }
                    ;
id_tail:            OP_COM id id_tail { idVec.push_back($2); }
                    | {}
                    ;

/* Function Parameter List */
param_decl_list:    param_decl param_decl_tail
                    |
                    ;
param_decl:         var_type id {
                        wrap1.value[0] = $1;
                        wrap1.value[1] = "";
                        r = table.insert(std::pair<std::string, wrapper>($2, wrap1));
                        if(!r.second){
                            yyerror($2);
                        }
                    }
                    ;
param_decl_tail:    OP_COM param_decl param_decl_tail
                    |
                    ;

/* Function Declarations */
func_declarations:  func_decl func_declarations
                    |
                    ;
func_decl:          FUNCTION any_type id { 
                        scope.push($3);
                        std::string func_name = $3;
                        if(func_name == "main"){
                            IR.push_back(TAC("LABEL", "", "", "main"));
                        }
                    } 
                    LPAREN param_decl_list RPAREN _BEGIN func_body END {
                        scope.pop();
                    }
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
assign_stmt:        assign_expr OP_SEM {
                        makeIR($1);
                        removeAST($1);
                    }
                    ;
assign_expr:        id OP_AS expr {
                        std::map <std::string, wrapper> mapp = sTable["GLOBAL"];
                        std::string key = $1;
                        AST_Node_var* node = new AST_Node_var(key, mapp[key].value[0]);
                        $$ = new AST_Node_op("=", node, $3);
                    }
                    ;
read_stmt:          READ LPAREN id_list RPAREN OP_SEM {
                        for(typename std::vector <std::string>::reverse_iterator itr = idVec.rbegin(); itr != idVec.rend(); ++itr){
                            std::map <std::string, wrapper> mapp = sTable["GLOBAL"];
                            if (mapp[*itr].value[0] == "INT")
                                IR.push_back(TAC("READI", "", "", *itr));
                            else
                                IR.push_back(TAC("READF", "", "", *itr));
                        }
                        idVec.clear();
                    }
                    ;
write_stmt:         WRITE LPAREN id_list RPAREN OP_SEM {
                        for(typename std::vector <std::string>::reverse_iterator itr = idVec.rbegin(); itr != idVec.rend(); ++itr){
                            std::map <std::string, wrapper> mapp = sTable["GLOBAL"];
                            if (mapp[*itr].value[0] == "INT")
                                IR.push_back(TAC("WRITEI", "", "", *itr));
                            else if (mapp[*itr].value[0] == "FLOAT")
                                IR.push_back(TAC("WRITEF", "", "", *itr));
                            else
                                IR.push_back(TAC("WRITES", "", "", *itr));

                        }
                        idVec.clear();
                    }
                    ;
return_stmt:        RETURN expr OP_SEM
                    ;

/* Expressions */
expr:               expr_prefix factor {
                        if($1 != NULL){
                            $1->right = $2;
                            $$ = $1;
                        }
                        else{
                            $$ = $2;
                        }
                    }
                    ;
expr_prefix:        expr_prefix factor addop {
                        if($1 != NULL){
                            $3->left = $1;
                            $1->right = $2;
                        }
                        else{
                            $3->left = $2;
                        }
                        $$ = $3;
                    }
                    | {
                        $$ = NULL;
                    }
                    ;
factor:             factor_prefix postfix_expr {
                        if($1 != NULL){
                            $1->right = $2;
                            $$ = $1;
                        }
                        else{
                            $$ = $2;
                        }
                    }
                    ;
factor_prefix:      factor_prefix postfix_expr mulop {
                        {
                            if($1 != NULL){
                                $3->left = $1;
                                $2->right = $2;
                            }
                            else{
                                $3->left = $2;
                            }
                            $$ = $3;
                        }
                    }
                    | {
                        $$ = NULL;
                    }
                    ;
postfix_expr:       primary { $$ = $1; }
                    | call_expr {$$ = $1; }
                    ;
call_expr:          id LPAREN expr_list RPAREN { $$ = $3; }
                    ;
expr_list:          expr expr_list_tail { $$ = $1; }
                    | { $$ = NULL; }
                    ;
expr_list_tail:     OP_COM expr expr_list_tail { $$ = $2; }
                    | { $$ = NULL; }
                    ;
primary:            LPAREN expr RPAREN { $$ = $2; }
                    | id { 
                        std::map <std::string, wrapper> mapp = sTable["GLOBAL"];
                        std::string key = $1;
                        $$ = new AST_Node_var(key, mapp[key].value[0]);
                    }
                    | INTLITERAL { $$ = new AST_Node_int($1); }
                    | FLOATLITERAL { $$ = new AST_Node_float($1); }
                    ;
addop:              OP_ADD { $$ = new AST_Node_op("+"); } | OP_SUB { $$ = new AST_Node_op("-"); }
                    ;
mulop:              OP_MUL { $$ = new AST_Node_op("*"); } | OP_DIV { $$ = new AST_Node_op("/"); }
                    ;

/* Complex Statements and Condition */
if_stmt:            IF {
                        pushBlock();
                    }  
                    LPAREN cond RPAREN decl stmt_list {
                        ss.str("");
                        ss << "label" << lab_ctr++;
                        IR.push_back(TAC("JUMP", "", "", ss.str()));
                        IR.push_back(TAC("LABEL", "", "", labels.top()));
                        labels.pop();
                        labels.push(ss.str());
                    } else_part {
                        IR.push_back(TAC("LABEL", "", "", labels.top()));
                        labels.pop();
                    } ENDIF {
                        scope.pop();
                    }
                    ;
else_part:          ELSE {
                        pushBlock();
                    } 
                    decl stmt_list {
                        scope.pop();
                    }
                    |
                    ;
cond:               expr compop expr {
                        std::string t;
                        std::string op1 = CondExprIR($1, &t);
                        IR.push_back(TAC("", "", "", "", "SAVE"));
                        std::string op2 = CondExprIR($3, &t);
                        ss.str("");
                        ss << "label" << lab_ctr++;  
                        IR.push_back(TAC($2, op1, op2, ss.str(), t)); 
                        labels.push(ss.str()); 
                        removeAST($1); 
                        removeAST($3);
                    }
                    ;
compop:             OP_LE { $$ = (char *) "GT"; }
                    | OP_GE { $$ = (char *) "LT"; }
                    | OP_NE { $$ = (char *) "EQ"; }
                    | OP_LT { $$ = (char *) "GE"; }
                    | OP_GT { $$ = (char *) "LE"; }
                    | OP_EQ { $$ = (char *) "NE"; }
                    ;
while_stmt:         WHILE {
                        whileID++;
                        whileStack.push(whileID); // curr whileID = top
                        pushBlock();
                        ss.str("");
                        ss << "label" << lab_ctr++;
                        loopStack.push(ss.str());
                        labels.push(ss.str());
                        IR.push_back(TAC("LABEL", "", "", ss.str()));
                    } 
                    LPAREN cond RPAREN decl aug_stmt_list {
                        std::string temp = labels.top();
                        labels.pop();
                        IR.push_back(TAC("JUMP", "", "", labels.top()));
                        labels.push(temp);
                        IR.push_back(TAC("LABEL", "", "", labels.top()));
                    
                    }
                    ENDWHILE {
                        whileStack.pop();
                        ss.str("");
                        ss << "labelw" << whileID;
                        IR.push_back(TAC("LABEL", "", "", ss.str()));
                        loopStack.pop();
                        scope.pop();

                    }
                    ;
aug_stmt_list:      aug_stmt aug_stmt_list
                    |
                    ;
aug_stmt:           base_stmt
                    | aug_if_stmt
                    | while_stmt
                    | CONTINUE OP_SEM {
                        IR.push_back(TAC("LABEL", "", "", loopStack.top()));
                    }
                    | BREAK OP_SEM {
                        IR.push_back(TAC("JUMP", "", "", "labelw"+std::to_string(whileStack.top())));
                    }
                    ;
aug_if_stmt:        IF {
                        pushBlock();
                    } 
                    LPAREN cond RPAREN decl aug_stmt_list {
                        ss.str("");
                        ss << "label" << lab_ctr++;
                        IR.push_back(TAC("JUMP", "", "", ss.str()));
                        IR.push_back(TAC("LABEL", "", "", labels.top()));
                        
                        labels.pop();
                        labels.push(ss.str());
                    } aug_else_part {
                        
                        labels.pop();
                    } ENDIF {
                        
                        scope.pop();
                    }
                    ;
aug_else_part:      ELSE {
                        pushBlock();
                        
                    } 
                    decl aug_stmt_list {
                        IR.push_back(TAC("LABEL", "", "", labels.top()));
                        scope.pop();
                    }
                    | {IR.push_back(TAC("LABEL", "", "", labels.top()));}
                    ;

%%
