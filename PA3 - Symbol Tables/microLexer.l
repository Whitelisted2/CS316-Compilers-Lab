%{
    #include "microParser.h"
%}
%option yylineno

DIGIT [0-9]
INTLITERAL {DIGIT}+
FLOATLITERAL {DIGIT}*"."{DIGIT}+
LETTER [a-zA-Z]
ID {LETTER}({LETTER}|{DIGIT})*
COMMENT [/][/]
OPERATOR [+]|[-]|[*]|[/]|[(]|[)]|[;]|[,]|[=]|[<]|[>]|[:]|[!]
DQUOTE ["]
WHITESPACE [ \t\r]
NEWLINE [\n]
/* KEYWORD PROGRAM|BEGIN|END|FUNCTION|READ|WRITE|IF|ELSE|ENDIF|WHILE|ENDWHILE|BREAK|CONTINUE|RETURN|INT|VOID|STRING|FLOAT */

%%

{COMMENT}.*"\n" {}

{NEWLINE} {}

{WHITESPACE}+ {}

{INTLITERAL} {
    return INTLITERAL;
}

{FLOATLITERAL} {
    return FLOATLITERAL;
}

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
INT { yylval.dataType = "INT";
    return INT; }
VOID { return VOID; }
STRING { yylval.dataType = "STRING";
    return STRING; }
FLOAT { yylval.dataType = "FLOAT";
    return FLOAT; }
END { return END; }

{ID} {
    yylval.string = strdup(yytext);
    return IDENTIFIER;
}

{OPERATOR} {
    return *yytext;
}

{DQUOTE}[^"]*{DQUOTE} {
    yylval.string = strdup(yytext);
    return STRINGLITERAL;
}

%%

int yywrap(){
    return 1;
}