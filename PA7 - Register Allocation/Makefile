compiler: main.cpp microParser.y microLexer.l
	bison -d -o microParser.c microParser.y
	flex microLexer.l
	@chmod +x runme
	g++ lex.yy.c headers/*.hpp main.cpp microParser.c -o a.out
clean:
	rm -rf lex.yy.c microParser.c microParser.h a.out tiny
dev:
	@echo "B Siddharth Prabhu"
	@echo "200010003@iitdh.ac.in"