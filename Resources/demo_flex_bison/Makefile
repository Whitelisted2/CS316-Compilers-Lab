compiler:
	bison -d grammar.y
	flex scanner.l
	gcc lex.yy.c grammar.tab.c -o $@
clean:
	rm lex.yy.c grammar.tab.c grammar.tab.h compiler
