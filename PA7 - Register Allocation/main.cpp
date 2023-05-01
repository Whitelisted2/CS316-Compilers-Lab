/* 
    References and Acknowledgements:

1. for yylineno functionality: 
    https://web.iitd.ac.in/~sumeet/flex__bison.pdf
    https://stackoverflow.com/questions/16443056/yylineno-has-always-the-same-value-in-yacc-file?noredirect=1&lq=1
2. further, https://github.com/Yeaseen/c-compiler
3. more insights from https://github.com/dhairyaagrawal/microCompiler 

*/

#include <iostream>
#include <stdio.h>
#include <vector>
#include <string>
#include "headers/ast.hpp"
#include "headers/assemblyCode.hpp"
#include "microParser.h"

extern FILE *yyin;
extern AssemblyCode *assembly_code;
extern CodeObject *TAC;
std::string ASTNode::id_type;
int yylex();
int yyparse();
void yyerror(char const* str){
    exit(1);
    // printf("Not accepted\n");
};

int main(int argc, char* argv[]) {
    int retval;
    if (argc < 2) {
        printf("usage: ./compiler <filename> \n");
    } else {
        if (!(yyin = fopen(argv[1], "r"))) {
            printf("Error while opening the file.\n"); 
        }
        else {
            yyin = fopen(argv[1], "r");
			retval = yyparse();
            fclose(yyin);

            //TAC->print();
            std::cout << "push" << std::endl;
            std::cout << "push r0" << std::endl;
            std::cout << "push r1" << std::endl;
            std::cout << "push r2" << std::endl;
            std::cout << "push r3" << std::endl;
            std::cout << "jsr main" << std::endl;
            std::cout << "sys halt" << std::endl;
            assembly_code->generateCode(TAC, TAC->symbolTableStack->tables);
            assembly_code->print();
            std::cout << "end" << std::endl;
        }
    }
    return 0;
}