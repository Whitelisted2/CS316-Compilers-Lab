/* 
    References and Acknowledgements:

1. for yylineno functionality: 
    https://web.iitd.ac.in/~sumeet/flex__bison.pdf
    https://stackoverflow.com/questions/16443056/yylineno-has-always-the-same-value-in-yacc-file?noredirect=1&lq=1
2. further, https://github.com/Yeaseen/c-compiler
3. more insights from https://github.com/dhairyaagrawal/microCompiler 

*/


%{
	#include <iostream>
	#include <string>
	#include <vector>
    #include <stack>
    #include "headers/ast.hpp"
    #include "headers/assemblyCode.hpp"

	int yylex();
	void yyerror(char const *s);
	SymbolTableStack *tableStack = new SymbolTableStack();
    CodeObject *TAC = new CodeObject(tableStack);
    AssemblyCode *assembly_code = new AssemblyCode();
    std::stack<int> cont;
%}

%union {
    int intval;
    float floatval;
    std::string* stringval;
    std::vector<std::string*> *stringlist;
    ASTNode *astnode;
    std::vector<ASTNode*> *astlist;
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

%token <stringval> IDENTIFIER
%token <intval> INTLITERAL
%token <floatval> FLOATLITERAL
%token <stringval> STRINGLITERAL
%token INT
%token FLOAT

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

%type <stringval> str
%type <stringval> id
%type <astnode> compop
%type <intval> var_type
%type <stringlist> id_list id_tail
%type <astnode> mulop addop primary postfix_expr factor_prefix factor expr_prefix expr return_stmt call_expr
%type <astlist> expr_list expr_list_tail

%%

/* Program */
program:			PROGRAM id _BEGIN {
                        tableStack->addNewTable("GLOBAL");
                    } pgm_body END { 
                        tableStack->removeTable(); 
                    }
					;
id:					IDENTIFIER
					;
pgm_body:			decl func_declarations
					;
decl:				string_decl decl
                    | var_decl decl
                    |
					;

/* Global String Declaration */
string_decl:		STRING id OP_AS str OP_SEM {
                        tableStack->insertSymbol(*($2), "STRING", *($4));
                    }
					;
str:				STRINGLITERAL
					;

/* Variable Declaration */
var_decl:			var_type id_list OP_SEM {
						std::string str_type = "";
						std::vector<std::string*> list = *$2;
						for (int i = list.size(); i != 0; --i) {
							if ($1 == FLOAT) {
								tableStack->insertSymbol(*(list[i-1]), "FLOAT");
							}
							else if ($1 == INT) {
								tableStack->insertSymbol(*(list[i-1]), "INT");
							}
						}
					}
                    ;
var_type:			FLOAT { $$ = FLOAT; }
                    | INT { $$ = INT; }
					;
any_type:			var_type
                    | VOID
					;
id_list:			id id_tail {
						$$ = $2;
						$$->push_back($1);
					}
                    ;
id_tail:			OP_COM id id_tail {
						$$ = $3;
						$$->push_back($2);
					} 
                    | {
						std::vector<std::string*>* temp = new std::vector<std::string*>;
						$$ = temp;
					}
                    ;

/* Function Parameter List */
param_decl_list:	param_decl param_decl_tail 
                    |
					;
param_decl:			var_type id {
						if ($1 == FLOAT)
							tableStack->insertSymbol(*$2, "FLOAT", true);
						else if ($1 == INT)
							tableStack->insertSymbol(*$2, "INT", true);
					}
                    ;
param_decl_tail:	OP_COM param_decl param_decl_tail
                    |
					;

/* Function Declarations */
func_declarations:	func_decl func_declarations
                    |
					;
func_decl:			FUNCTION any_type id { 
                        tableStack->addNewTable(*($3)); 
                        TAC->TAC.push_back(new CodeLine(TAC->symbolTableStack->table_stack.top()->scope, "LABEL", *($3)));
                        TAC->TAC.push_back(new CodeLine(TAC->symbolTableStack->table_stack.top()->scope, "LINK", ""));
                    } LPAREN param_decl_list RPAREN _BEGIN func_body END {
                        tableStack->removeTable();
                    }
					;
func_body:			decl stmt_list 
					;

/* Statement List */
stmt_list:			stmt stmt_list
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
assign_stmt:		assign_expr OP_SEM
					;
assign_expr:		id OP_AS expr {
                        ASTNode * node = new ASTNode_Assign(tableStack->findEntry(*$1));
                        node->right = $3;
                        node->generateCode(TAC);
                    }
                    ;
read_stmt:			READ LPAREN id_list RPAREN OP_SEM {
                        std::vector<std::string*> list = *($3);
                        for (int i = list.size(); i != 0; --i) {
                            std::string name = *(list[i-1]);
                            std::string type = tableStack->findType(name);
                            TAC->addRead(name, type);
                        }
                    }
                    ;
write_stmt:			WRITE LPAREN id_list RPAREN OP_SEM {
                        std::vector<std::string*> list = *($3);
                        for (int i = list.size(); i != 0; --i) {
                            std::string name = *(list[i-1]);
                            std::string type = tableStack->findType(name);
                            TAC->addWrite(name, type);
                        }
                    }
                    ;
return_stmt:		RETURN expr OP_SEM {
                        std::string a = ($2)->generateCode(TAC);
                        TAC->TAC.push_back(new CodeLine(TAC->symbolTableStack->table_stack.top()->scope, "RET", a));
                    }
                    ;

/* Expressions */
expr:				expr_prefix factor {
                        if ($1 == nullptr)
                            $$ = $2;
                        else {
                            $1->right = $2;
                            $$ = $1;
                        }
                    }
                    ;
expr_prefix:		expr_prefix factor addop {
                        if ($1 == nullptr)
                            $3->left = $2;
                        else {
                            $1->right = $2;
                            $3->left = $1;
                        }
                        $$ = $3;
                    }
                    | { 
                        $$ = nullptr;
                    }
                    ;
factor:				factor_prefix postfix_expr {
                        if ($1 == nullptr)
                            $$ = $2;
                        else
                        {
                            $1->right = $2;
                            $$ = $1;
                        }
                    }
                    ;
factor_prefix:		factor_prefix postfix_expr mulop {
                        if ($1 == nullptr)
                            $3->left = $2;
                        else
                        {
                            $1->right = $2;
                            $3->left = $1;
                        }
                        $$ = $3;
                    }
                    | {
                        $$ = nullptr;
                    }
                    ;
postfix_expr:		primary { $$ = $1; }
                    | call_expr { $$ = $1; }
                    ;
call_expr:			id LPAREN expr_list RPAREN {
                        $$ = new ASTNode_CallExpr(*($1), $3);
                    }
                    ;
expr_list:			expr expr_list_tail {
                        $$ = $2;
                        $$->push_back($1);
                    }
                    | {
                        std::vector<ASTNode *> *node = new std::vector<ASTNode*>;
                        $$ = node;
                    }
                    ;
expr_list_tail:		OP_COM expr expr_list_tail {
                        $$ = $3;
                        $$->push_back($2);
                    }
                    | {
                        std::vector<ASTNode *> *node = new std::vector<ASTNode*>;
                        $$ = node;
                    }
                    ;
primary:			LPAREN expr RPAREN {$$ = $2;} 
                    | id {
                        $$ = new ASTNode_ID(tableStack->findEntry(*$1));
                    }
                    | INTLITERAL {
                        $$ = new ASTNode_INT($1);
                    }
                    | FLOATLITERAL {
                        $$ = new ASTNode_FLOAT($1);
                    }
                    ;
addop:				OP_ADD { $$ = new ASTNode_Expr('+'); } | OP_SUB { $$ = new ASTNode_Expr('-'); }
                    ;
mulop:				OP_MUL { $$ = new ASTNode_Expr('*'); } | OP_DIV { $$ = new ASTNode_Expr('/'); }
                    ;

/* Complex Statements and Condition */
if_stmt:		    IF {
                        tableStack->addNewTable(); 
                    } LPAREN cond RPAREN decl stmt_list {
                        TAC->lb += 1;
                        TAC->lbList.push_front(TAC->lb);
                        TAC->TAC.push_back(new CodeLine(TAC->symbolTableStack->table_stack.top()->scope, "JUMP", "LABEL"+std::to_string(TAC->lb)));
                        int x = TAC->lbList.back();
                        TAC->lbList.pop_back();
                        TAC->TAC.push_back(new CodeLine(TAC->symbolTableStack->table_stack.top()->scope, "LABEL", "LABEL"+std::to_string(x)));
                        tableStack->removeTable(); 
                    } else_part ENDIF {
                        int x = TAC->lbList.front();
                        TAC->lbList.pop_front();
                        TAC->TAC.push_back(new CodeLine(TAC->symbolTableStack->table_stack.top()->scope, "LABEL", "LABEL"+std::to_string(x)));
                    }
                    ;
else_part:			ELSE {
                        tableStack->addNewTable();
                    } decl stmt_list {
                        tableStack->removeTable();
                    }
                    |
					;
cond:				expr compop expr {
                        $2->left = $1;
                        $2->right = $3;
                        $2->generateCode(TAC);   
                    }
                    ;
compop:				OP_LT { $$ = new ASTNode_Cond("<"); }
                    | OP_GT { $$ = new ASTNode_Cond(">"); }
                    | OP_EQ { $$ = new ASTNode_Cond("="); }
                    | OP_NE { $$ = new ASTNode_Cond("!="); }
                    | OP_LE { $$ = new ASTNode_Cond("<="); }
                    | OP_GE { $$ = new ASTNode_Cond(">="); }
					;

while_stmt:         WHILE {
                        tableStack->addNewTable();
                        TAC->lb += 1;
                        TAC->lbList.push_front(TAC->lb);
                        cont.push(TAC->lb);
                        TAC->TAC.push_back(new CodeLine(TAC->symbolTableStack->table_stack.top()->scope, "LABEL", "LABEL"+std::to_string(TAC->lb)));
                    } LPAREN cond RPAREN decl aug_stmt_list ENDWHILE {
                        int x = TAC->lbList.front();
                        TAC->lbList.pop_front();
                        TAC->TAC.push_back(new CodeLine(TAC->symbolTableStack->table_stack.top()->scope, "JUMP", "LABEL"+std::to_string(x)));

                        x = TAC->lbList.back();
                        TAC->lbList.pop_back();
                        TAC->TAC.push_back(new CodeLine(TAC->symbolTableStack->table_stack.top()->scope, "LABEL", "LABEL"+std::to_string(x)));
                        cont.pop();
                        tableStack->removeTable();
                    };

aug_stmt_list:      aug_stmt aug_stmt_list 
                    |
                    ;
aug_stmt:           base_stmt 
                    | aug_if_stmt
                    | while_stmt
                    | CONTINUE {
                        TAC->TAC.push_back(new CodeLine(TAC->symbolTableStack->table_stack.top()->scope, "JUMP", "LABEL"+std::to_string(cont.top())));
                    } OP_SEM
                    | BREAK {
                        TAC->TAC.push_back(new CodeLine(TAC->symbolTableStack->table_stack.top()->scope, "JUMP", "LABEL"+std::to_string(cont.top()+1)));
                    } OP_SEM
                    ;

aug_if_stmt:        IF {
                        tableStack->addNewTable();
                    } LPAREN cond RPAREN decl aug_stmt_list {
                        TAC->lb += 1;
                        TAC->lbList.push_front(TAC->lb);
                        TAC->TAC.push_back(new CodeLine(TAC->symbolTableStack->table_stack.top()->scope, "JUMP", "LABEL"+std::to_string(TAC->lb)));

                        int x = TAC->lbList.back();
                        TAC->lbList.pop_back();
                        TAC->TAC.push_back(new CodeLine(TAC->symbolTableStack->table_stack.top()->scope, "LABEL", "LABEL"+std::to_string(x)));
                        tableStack->removeTable(); 
                    }  aug_else_part ENDIF {
                        int x = TAC->lbList.front();
                        TAC->lbList.pop_front();
                        TAC->TAC.push_back(new CodeLine(TAC->symbolTableStack->table_stack.top()->scope, "LABEL", "LABEL"+std::to_string(x)));
                    }
                    ;
aug_else_part:      ELSE {
                        tableStack->addNewTable();
                    } decl aug_stmt_list {
                        tableStack->removeTable();
                    } 
                    |
                    ;

%%
