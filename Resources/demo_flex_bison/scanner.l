%{
#include"grammar.tab.h"
%}
%%
[0-9]+ {return INTLITERAL;}
\+	{return PLUS;}
. {}
\n {return NEWLINE;}


%%

int yywrap() {
	return 1;
}
