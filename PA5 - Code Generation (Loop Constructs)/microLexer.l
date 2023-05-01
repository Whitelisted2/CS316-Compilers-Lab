%{
    #include "microParser.h"
    #include <iostream>
%}
%option yylineno

DIGIT [0-9]
INTLITERAL {DIGIT}+
FLOATLITERAL {DIGIT}*"."{DIGIT}+
LETTER [a-zA-Z]
ID {LETTER}({LETTER}|{DIGIT})*
COMMENT [/][/]
DQUOTE ["]
WHITESPACE [ \t\r]
NEWLINE [\n]
/* KEYWORD PROGRAM|BEGIN|END|FUNCTION|READ|WRITE|IF|ELSE|ENDIF|WHILE|ENDWHILE|BREAK|CONTINUE|RETURN|INT|VOID|STRING|FLOAT */

%%

{COMMENT}.*"\n" {}

{NEWLINE} {}

{WHITESPACE}+ {}

{INTLITERAL} {
    yylval.string = strdup(yytext);
    return INTLITERAL;
}

{FLOATLITERAL} {
    yylval.string = strdup(yytext);
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
INT { yylval.dataType = strdup(yytext);
    return INT; }
VOID { return VOID; }
STRING { yylval.dataType = strdup(yytext);
    return STRING; }
FLOAT { yylval.dataType = strdup(yytext);
    return FLOAT; }
END { return END; }

{ID} {
    yylval.string = strdup(yytext);
    return IDENTIFIER;
}

{DQUOTE}[^"]*{DQUOTE} {
    yylval.string = strdup(yytext);
    return STRINGLITERAL;
}

%%

int yywrap(){
    return 1;
}