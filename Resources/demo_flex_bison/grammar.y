%{
#include<stdio.h>
#include<stdlib.h>
int yylex();
int yyerror(char* msg);
%}
%token INTLITERAL PLUS NEWLINE
%%
L: E NEWLINE {printf("Matched a valid E\n");}
 | NEWLINE {exit(0);}
 ;
E: E PLUS E {printf("Matched E PLUS E\n");}
 | INTLITERAL {printf("Matched INTLITERAL\n");}
 ;


%%
int yyerror(char* msg){
	printf("Syntax error\n");
}

int main() {
 int state = yyparse();
}
