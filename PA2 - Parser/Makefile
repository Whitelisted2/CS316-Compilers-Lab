compiler: main.c microParser.y microLexer.l
	bison -d -o microParser.c microParser.y
	flex microLexer.l
	gcc lex.yy.c microParser.c main.c -o a.out
clean:
	rm -rf lex.yy.c microParser.c microParser.h
dev:
	@echo "B Siddharth Prabhu"
	@echo "200010003@iitdh.ac.in"