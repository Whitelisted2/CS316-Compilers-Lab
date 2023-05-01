DIGIT [0-9]
INTLITERAL {DIGIT}+
FLOATLITERAL {DIGIT}*"."{DIGIT}+
LETTER [a-zA-Z]
ID {LETTER}({LETTER}|{DIGIT})*
COMMENT [/][/]
/* OPERATOR [:][=]|[+]|[-]|[*]|[/]|[=]|[!][=]|[<]|[>]|[(]|[)]|[;]|[,]|[<][=]|[>][=] */
DQUOTE ["]
WHITESPACE [ \n\t]
/* KEYWORD PROGRAM|BEGIN|END|FUNCTION|READ|WRITE|IF|ELSE|ENDIF|WHILE|ENDWHILE|BREAK|CONTINUE|RETURN|INT|VOID|STRING|FLOAT */

%%

{COMMENT}.*"\n" {}

{WHITESPACE}+ {}

{INTLITERAL} {
    printf("Token Type: INTLITERAL\nValue: %d\n", atoi(yytext));
}

{FLOATLITERAL} {
    printf("Token Type: FLOATLITERAL\nValue: %s\n", yytext);
}

PROGRAM { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }
BEGIN { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }
END { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }
FUNCTION { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }
READ { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }
WRITE { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }
IF { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }
ELSE { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }
ENDIF { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }
WHILE { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }
ENDWHILE { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }
BREAK { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }
CONTINUE { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }
RETURN { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }
INT { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }
VOID { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }
STRING { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }
FLOAT { printf("Token Type: KEYWORD\nValue: %s\n", yytext); }

{ID} {
    printf("Token Type: IDENTIFIER\nValue: %s\n", yytext);
}

":=" { printf("Token Type: OPERATOR\nValue: %s\n", yytext); }
"+" { printf("Token Type: OPERATOR\nValue: %s\n", yytext); }
"-" { printf("Token Type: OPERATOR\nValue: %s\n", yytext); }
"*" { printf("Token Type: OPERATOR\nValue: %s\n", yytext); }
"/" { printf("Token Type: OPERATOR\nValue: %s\n", yytext); }
"=" { printf("Token Type: OPERATOR\nValue: %s\n", yytext); }
"!=" { printf("Token Type: OPERATOR\nValue: %s\n", yytext); }
">" { printf("Token Type: OPERATOR\nValue: %s\n", yytext); }
"<" { printf("Token Type: OPERATOR\nValue: %s\n", yytext); }
"(" { printf("Token Type: OPERATOR\nValue: %s\n", yytext); }
")" { printf("Token Type: OPERATOR\nValue: %s\n", yytext); }
";" { printf("Token Type: OPERATOR\nValue: %s\n", yytext); }
"," { printf("Token Type: OPERATOR\nValue: %s\n", yytext); }
"<=" { printf("Token Type: OPERATOR\nValue: %s\n", yytext); }
">=" { printf("Token Type: OPERATOR\nValue: %s\n", yytext); }

{DQUOTE}.*{DQUOTE} {
    printf("Token Type: STRINGLITERAL\nValue: %s\n", yytext);
}

%%

int main(int argc, char *argv[]){
    if(argc>1){
        FILE* fp = fopen(argv[1], "r");
        if(fp != NULL){
            yyin = fp;
        }
    }
    yylex();
    return 0;
}

int yywrap(){
    return 1;
}