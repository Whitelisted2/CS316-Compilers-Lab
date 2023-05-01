%{
    #include"microParser.h"
    // extern YYSTYPE yylval;
%}

DIGIT [0-9]
INTLITERAL {DIGIT}+
FLOATLITERAL {DIGIT}*"."{DIGIT}+
LETTER [a-zA-Z]
ID {LETTER}({LETTER}|{DIGIT})*
COMMENT [/][/]
OPERATOR [+]|[-]|[*]|[/]|[(]|[)]|[;]|[,]|[=]|[<]|[>]|[:]|[!]
DQUOTE ["]
WHITESPACE [ \n\t\r]
/* KEYWORD PROGRAM|BEGIN|END|FUNCTION|READ|WRITE|IF|ELSE|ENDIF|WHILE|ENDWHILE|BREAK|CONTINUE|RETURN|INT|VOID|STRING|FLOAT */

%%

{COMMENT}.*"\n" {}

{WHITESPACE}+ {}

{INTLITERAL} {
    // yylval = atoi(yytext);
    return INTLITERAL;
}

{FLOATLITERAL} {
    // yylval = strtof(yytext);
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
INT { return INT; }
VOID { return VOID; }
STRING { return STRING; }
FLOAT { return FLOAT; }
END { return END; }

{ID} {
    // yylval = yytext;
    return IDENTIFIER;
}

{OPERATOR} {
    return *yytext;
}

{DQUOTE}[^"]*{DQUOTE} {
    return STRINGLITERAL;
}

%%

int yywrap(){
    return 1;
}