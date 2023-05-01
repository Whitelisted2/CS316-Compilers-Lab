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
    #include "headers/ast.hpp"
    #include "headers/assemblyCode.hpp"
    #include "microParser.h"
    int yylex();
    void yyerror(char const *s);
%}
%option yylineno

DIGIT [0-9]
INTLITERAL {DIGIT}+
FLOATLITERAL {DIGIT}*"."{DIGIT}+
IDENTIFIER [a-zA-Z][a-zA-Z0-9]*
COMMENT [/][/]
DQUOTE ["]
WHITESPACE [ \t\r]
NEWLINE [\n]
/* KEYWORD PROGRAM|BEGIN|END|FUNCTION|READ|WRITE|IF|ELSE|ENDIF|WHILE|ENDWHILE|BREAK|CONTINUE|RETURN|INT|VOID|STRING|FLOAT */


%%

{COMMENT}.*\n  {}

{INTLITERAL}+ {
    yylval.intval = atoi(yytext);
    return INTLITERAL;
}

{FLOATLITERAL} {
    yylval.floatval = atof(yytext);
    return FLOATLITERAL;
}

"+" {return OP_ADD; }
"-" {return OP_SUB; }
"*" {return OP_MUL; }
"/" {return OP_DIV; }
"(" {return LPAREN; }
")" {return RPAREN; }
";" {return OP_SEM; }
"," {return OP_COM; }
"<=" {return OP_LE; }
">=" {return OP_GE; }
"<" {return OP_LT; }
">" {return OP_GT; }
":=" {return OP_AS; }
"!=" {return OP_NE; }
"=" {return OP_EQ; }

PROGRAM { return PROGRAM; }
BEGIN { return _BEGIN; }
FUNCTION { return FUNCTION; }
READ { return READ; }
WRITE { return WRITE; }
ENDIF { return ENDIF; }
IF { return IF; }
ELSE { return ELSE; }
ENDWHILE { return ENDWHILE; }
WHILE { return WHILE; }
BREAK { return BREAK; }
CONTINUE { return CONTINUE; }
RETURN { return RETURN; }
INT { return INT; }
VOID { return VOID; }
STRING { return STRING; }
FLOAT { return FLOAT; }
END { return END; }

{IDENTIFIER} { 
    yylval.stringval = new std::string (yytext);
    return IDENTIFIER;
}

{DQUOTE}[^"]*{DQUOTE} {
    yylval.stringval = new std::string (yytext);
    return STRINGLITERAL;
}

{NEWLINE} {}

{WHITESPACE}+ {}

%%

int yywrap(){
  	return 1;
}