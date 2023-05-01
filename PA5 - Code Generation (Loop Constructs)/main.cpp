#include <iostream>
#include <stdio.h>
#include <vector>
#include <string>
#include <map>
#include <stack>
#include <iterator>
#include <sstream>
#include "helper.h"
#include "microParser.h"
using namespace std;

extern FILE* yyin;
extern vector <TAC> IR;
extern stack <std::string> scope;
extern struct wrapper p;
struct wrapper{
    	std::string value[2];
};
extern map <std::string, map<std::string, wrapper> > sTable;
extern stringstream ss;
extern int block_ctr;
extern int lab_ctr;
extern int registerCounter;
extern map <std::string, wrapper> table;
extern std::vector <std::string> strConst, vars;
stack <int> registers;

int yylex();
int yyparse();
void yyerror(char const* str){
    exit(1);
    // printf("Not accepted\n");
}
void generate_3AC();
void pushBlock();
void addSymbolTable();
string CondExprIR(AST_Node * node, string * t);
void makeIR(AST_Node * node); 
void removeAST(AST_Node * node);
void generateCMPI(string op1, string op2, string savedReg, int outputReg, int * currentReg);
void generateCMPR(string op1, string op2, string savedReg, int outputReg, int * currentReg);
void generateADD(string opcode, string op1, string op2, int * currentReg, int * addopTemp, int * mulopTemp, int * outputReg);
void generateMUL(string opcode, string op1, string op2, int * currentReg, int * temp, int* outputReg);
void generateMUL(string opcode, string op1, string op2, int * currentReg, int * temp, int* outputReg);
void printSymbolTable();
void printTinyCode();

int main(int argc, char* argv[]){
    if(argc>1){
        FILE *fp = fopen(argv[1], "r");
        if(fp != NULL){
            yyin = fp;
        }
    } else {
        printf("Not enough arguments passed.\n");
        return 3;
    }
    yyparse();
    generate_3AC();
    printTinyCode();
}

void generate_3AC() {
    cout << ";3AC Code" << "\n";
    for(vector <TAC>::iterator itr = IR.begin(); itr != IR.end(); itr++){
		itr->CodeGen_3AC();
	}
}
void pushBlock() {
	ss.str("");
	ss << "BLOCK " << ++block_ctr;
	scope.push(ss.str());
}

void addSymbolTable() {
	sTable[scope.top()] = table;
	table.clear();
}

string CondExprIR(AST_Node * node, string * t) {
	if(node != NULL){
		CondExprIR(node->left, t);
		CondExprIR(node->right, t);
		ss.str("");
		if(node->valtype == "OP"){
			node->datatype = node->left->datatype;
			ss << "$T" << registerCounter++;
			node->temp = ss.str();
		}
		if(node->valtype == "CONST")
		{
			ss << "$T" << registerCounter++;
			node->temp = ss.str();
		}
		IR.push_back(node->CodeGen());
		*t = node->datatype;
		return node->temp;
	}
	*t = "NONE";
	return "";
}

void makeIR(AST_Node * node) {
	if (node != NULL){
		makeIR(node->left); // postorder
		makeIR(node->right);
		ss.str("");
		if (node->valtype == "OP"){
			node->datatype = node->left->datatype;
			if (node->val != "="){
				ss << "$T" << registerCounter++;
				node->temp = ss.str();
			}
			else
				node->temp = node->left->temp;
		}
		if(node->valtype == "CONST"){
			ss << "$T" << registerCounter++;
			node->temp = ss.str();
		}
		IR.push_back(node->CodeGen());
	}
}

void removeAST(AST_Node * node) {
	if (node != NULL){
		removeAST(node->left);
		removeAST(node->right);
		delete node;
	}
}

void generateCMPI(string op1, string op2, string savedReg, int outputReg, int * currentReg) {
    if (op1[0] != '$' && op2[0] != '$') {
        cout << "move " << op2 << " r" << *currentReg << endl;
        outputReg = *currentReg;
        *currentReg = *currentReg + 1;
        cout << "cmpi " << op1 << " r" << outputReg << endl;
    } 
    else if (op1[0] != '$') {
        cout << "cmpi " << op1 << " r" << outputReg << endl;
    } 
    else if (op2[0] != '$') {
        cout << "cmpi r" << outputReg << " " << op2 << endl;
    } 
    else {
        cout << "cmpi r" << savedReg << " r" << outputReg;
    }
}

void generateCMPR(string op1, string op2, string savedReg, int outputReg, int * currentReg) {
    if (op1[0] != '$' && op2[0] != '$') {
        cout << "move " << op2 << " r" << *currentReg << endl;
        outputReg = *currentReg;
        *currentReg = *currentReg + 1;
        cout << "cmpr " << op1 << " r" << outputReg << endl;
    } 
    else if (op1[0] != '$')  {
        cout << "cmpr " << op1 << " r" << outputReg << endl;
    } 
    else if (op2[0] != '$')  {
        cout << "cmpr r" << outputReg << " " << op2 << endl;
    } 
    else  {
        cout << "cmpr r" << savedReg << " r" << outputReg;
    }
}

void generateADD(string opcode, string op1, string op2, int * currentReg, int * addopTemp, int * mulopTemp, int * outputReg) {
    if (op1[0] != '$') {
        cout << "move " << op1 << " r" << *currentReg << endl;
        *addopTemp = *currentReg - 1;
        *currentReg = *currentReg + 1;

        if (op2[0] != '$')  {
            cout << opcode << " " << op2 << " r" << *currentReg - 1 << endl;
            registers.push(*currentReg - 1);
        } 
        else  {
            cout << opcode << " r" << *addopTemp << " r" << *currentReg - 1 << endl;
            if (!registers.empty()) {
                registers.pop();
            }
            registers.push(*currentReg - 1);
        }
        *outputReg = *currentReg - 1;
        *addopTemp = *currentReg - 1;
    } 
    else  {
        if (op2[0] != '$')  {
            cout << opcode << " " << op2 << " r" << *currentReg - 1 << endl;
            *outputReg = *currentReg - 1;
        } 
        else  {
            while (!registers.empty()) {
                *addopTemp = registers.top();
                registers.pop();
            }
            cout << opcode << " r" << *currentReg - 1 << " r" << *addopTemp << endl;
            *outputReg = *addopTemp;
            registers.push(*addopTemp);
        }
    }
    *mulopTemp = *addopTemp;
}

void generateMUL(string opcode, string op1, string op2, int * currentReg, int * temp, int * outputReg) {
    if (op1[0] != '$')  {
        cout << "move " << op1 << " r" << *currentReg << endl;
        *temp = *currentReg - 1;
        *currentReg = *currentReg + 1;

        if (op2[0] != '$')  {
            cout << opcode << " " << op2 << " r" << *currentReg - 1 << endl;
            registers.push(*currentReg - 1);
        } 
        else  {
            cout << opcode << " r" << *temp << " r" << *currentReg - 1 << endl;
            if (!registers.empty()) {
                registers.pop();
            }
            registers.push(*currentReg - 1);
        }
        *outputReg = *currentReg - 1;
        *temp = *currentReg - 1;
    } 
    else {
        if (op2[0] != '$') {
            cout << opcode << " " << op2 << " r" << *currentReg - 1 << endl;
            *outputReg = *currentReg - 1;
        } 
        else {
            while (!registers.empty()) {
                *temp = registers.top();
                registers.pop();
            }
            cout << opcode << " r" << *currentReg - 1 << " r" << *temp << endl;
            *outputReg = *temp;
            registers.push(*temp);
        }
    }
}

void printSymbolTable() {
	for(map <string, map<string, wrapper> >::iterator itr = sTable.begin(); itr != sTable.end(); ++itr){
		cout << "Symbol table " << itr->first << "\n";
		map <string, wrapper> &internal_map = itr->second;
		for(map <string, wrapper>::iterator itr2 = internal_map.begin(); itr2 != internal_map.end(); ++itr2){
			p = itr2->second;
			if(p.value[0] == "STRING")
				cout << "name " << itr2->first << " type " << p.value[0] << " value " << p.value[1] << "\n";
			else
				cout << "name " << itr2->first << " type " << p.value[0] << "\n";
		}
		cout << "\n";
	}
}

void printTinyCode() {
	cout << "; Tiny Code" << "\n";
	for (vector<string>::iterator itr = vars.begin(); itr != vars.end(); ++itr) { // var decls before prog items
	    cout << "var " << *itr << "\n";
	}
	for (vector<string>::iterator itr = strConst.begin(); itr != strConst.end(); ++itr) { // string decl
	    cout << *itr << "\n";
	}

	int curr_reg = 0;
	int op_reg = 0;
	int addopTemp = 0;
	int mulopTemp = 0;

	string code, op1, op2, result, savedReg;
	for (vector<TAC>::iterator itr = IR.begin(); itr != IR.end(); ++itr) {
	    code = itr->op;
	    op1 = itr->operand1;
	    op2 = itr->operand2;
	    result = itr->result;

	    if (code == "WRITEI") {
	        cout << "sys writei " << result << endl;
	    } 
	    else if (code == "WRITEF") {
	        cout << "sys writer " << result << endl;
	    } 
	    else if (code == "WRITES") {
	        cout << "sys writes " << result << endl;
	    } 
	    else if (code == "READI") {
	        cout << "sys readi " << result << endl;
	    } 
	    else if (code == "READF") {
	        cout << "sys readr " << result << endl;
	    } 
	    else if (code == "JUMP") {
	        cout << "jmp " << result << endl;
	    } 
	    else if (code == "GT") {
	        if (itr->cType == "INT") {
	            generateCMPI(op1, op2, savedReg, op_reg, &curr_reg);
	        } else {
	            generateCMPR(op1, op2, savedReg, op_reg, &curr_reg);
	        }
	        cout << "jgt " << result << endl;
	        while (!registers.empty()) 
	            registers.pop();
	    } 
	    else if (code == "GE") {
	        if (itr->cType == "INT") {
	            generateCMPI(op1, op2, savedReg, op_reg, &curr_reg);
	        } else {
	            generateCMPR(op1, op2, savedReg, op_reg, &curr_reg);
	        }
	        cout << "jge " << result << endl;
	        while (!registers.empty()) 
	            registers.pop();
	    } 
	    else if (code == "LT") {
	        if (itr->cType == "INT") {
	            generateCMPI(op1, op2, savedReg, op_reg, &curr_reg);
	        } else {
	            generateCMPR(op1, op2, savedReg, op_reg, &curr_reg);
	        }
	        cout << "jlt " << result << endl;
	        while (!registers.empty()) 
	            registers.pop();
	    } 
	    else if (code == "LE") {
	        if (itr->cType == "INT") {
	            generateCMPI(op1, op2, savedReg, op_reg, &curr_reg);
	        } else {
	            generateCMPR(op1, op2, savedReg, op_reg, &curr_reg);
	        }
	        cout << "jle " << result << endl;
	        while (!registers.empty()) 
	            registers.pop();
	    } 
	    else if (code == "NE") {
	        if (itr->cType == "INT") {
	            generateCMPI(op1, op2, savedReg, op_reg, &curr_reg);
	        } else {
	            generateCMPR(op1, op2, savedReg, op_reg, &curr_reg);
	        }
	        cout << "jne " << result << endl;
	        while (!registers.empty()) 
	            registers.pop();
	    } 
	    else if (code == "EQ") {
	        if (itr->cType == "INT") {
	            generateCMPI(op1, op2, savedReg, op_reg, &curr_reg);
	        } else {
	            generateCMPR(op1, op2, savedReg, op_reg, &curr_reg);
	        }
	        cout << "jeq " << result << endl;
	        while (!registers.empty()) 
	            registers.pop();
	    } 
	    else if (code == "LABEL") {
	        cout << "label " << result << endl;
	    } 
	    else if (code == "STOREI" || code == "STOREF") {
	        if (result[0] != '$'){
	            if (op1[0] != '$'){
	                cout << "move " << op1 << " r" << curr_reg << endl;
	                cout << "move r" << curr_reg << " " << result << endl;
	                curr_reg = curr_reg + 1;
	            } 
	            else {
	                cout << "move r" << op_reg << " " << result << endl;
	                while (!registers.empty()) registers.pop();
	            }
	        } 
	        else {
	            cout << "move " << op1 << " r" << curr_reg << endl;
	            op_reg = curr_reg;
	            registers.push(curr_reg);
	            curr_reg++;
	        }
	    }
	    else if (code == "ADDI") {
	        generateADD("addi", op1, op2, &curr_reg, &addopTemp, &mulopTemp, &op_reg);
	    } 
	    else if (code == "ADDF") {
	        generateADD("addr", op1, op2, &curr_reg, &addopTemp, &mulopTemp, &op_reg);
	    }
	    else if (code == "SUBI") {
	        generateADD("subi", op1, op2, &curr_reg, &addopTemp, &mulopTemp, &op_reg);
	    } 
	    else if (code == "SUBF") {
	        generateADD("subr", op1, op2, &curr_reg, &addopTemp, &mulopTemp, &op_reg);
	    }
	    else if (code == "MULTI") {
	        generateMUL("muli", op1, op2, &curr_reg, &mulopTemp, &op_reg);
	    } 
	    else if (code == "MULTF") {
	        generateMUL("mulr", op1, op2, &curr_reg, &mulopTemp, &op_reg);
	    }
	    else if (code == "DIVI") {
	        generateMUL("divi", op1, op2, &curr_reg, &mulopTemp, &op_reg);
	    } 
	    else if (code == "DIVF") {
	        generateMUL("divr", op1, op2, &curr_reg, &mulopTemp, &op_reg);
	    }
	}
	cout << "sys halt";
}
