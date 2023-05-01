#include <stdio.h>
#include "microParser.h"

extern FILE* yyin;
int yylex();
int yyparse();

int yyerror(const char *str){
    // printf("Not accepted\n");
    return 1;
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
        // printf("Accepted\n");
    }
}