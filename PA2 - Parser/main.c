#include <stdio.h>
#include "microParser.h"

extern FILE* yyin;
int yylex();
int yyparse();

void yyerror(char *str){
    printf("Not accepted\n");
}

int main(int argc, char* argv[]){
    if(argc>1){
        FILE *fp = fopen(argv[1], "r");
        if(fp != NULL){
            yyin = fp;
        }
    } else {
        printf("Not enough arguments passed.\n");
    }
    if (yyparse() == 0){
        printf("Accepted\n");
    }
}