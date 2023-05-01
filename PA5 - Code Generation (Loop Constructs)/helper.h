#ifndef HELPER_FLAG
#define HELPER_FLAG

#include <iostream>
#include <string>

class TAC{
    public:
        std::string op, operand1, operand2, result, cType;
        
        // constructors
        TAC(std::string op_in, std::string op1_in, std::string op2_in, std::string res_in) {
            this->op = op_in;
            this->operand1 = op1_in;
            this->operand2 = op2_in;
            this->result = res_in;
            this->cType = "_";
        }
        TAC(std::string op_in, std::string op1_in, std::string op2_in, std::string res_in, std::string cType_in) {
            this->op = op_in;
            this->operand1 = op1_in;
            this->operand2 = op2_in;
            this->result = res_in;
            this->cType = cType_in;
        }

        void CodeGen_3AC() {
            if(op != ""){
				std::cout << ";"; // prefix since this code is not the tiny code
                std::cout << op;
				if(operand1 != "")
					std::cout << " " << operand1;
				if(operand2 != "")
					std::cout << " " << operand2;
				std::cout << " " << result << "\n";
			}
        }
};

class AST_Node{
    public:
        std::string val, datatype, valtype, temp;
        AST_Node* left;
        AST_Node* right;

        virtual TAC CodeGen() = 0; // no definition; intended to be overridden
};

class AST_Node_int : public AST_Node { // this can only be a leaf node
    public:
        AST_Node_int(std::string val_in) {
            // std::cout << ";---- "<< val_in <<"\n"; 
            this->val = val_in;
            this->datatype = "INT";
            this->left = NULL;
            this->right = NULL;
            this->valtype = "CONST";
        }
        TAC CodeGen() {
            // std::cout<<"val= "<<val<<" temp= "<<temp<<"\n";
            return TAC("STOREI", val, "", temp); // .....
        }
};

class AST_Node_float : public AST_Node { // this can only be a leaf node
    public:
        AST_Node_float(std::string val_in) {
            this->val = val_in;
            this->datatype = "FLOAT";
            this->left = NULL;
            this->right = NULL;
            this->valtype = "CONST";
        }
        TAC CodeGen() {
            return TAC("STOREF", val, "", temp);
        }
};

class AST_Node_var : public AST_Node{
	public:
		AST_Node_var(std::string val_in, std::string datatype_in){
			this->val = val_in;
			this->temp = val_in;
			this->datatype = datatype_in;
			this->left = NULL;
			this->right = NULL;
			this->valtype = "VAR";
		}

		TAC CodeGen(){
			return TAC("", "", "", temp, "VAR");
		}
};

class AST_Node_op : public AST_Node{
	public:
		AST_Node_op(std::string op){
			this->valtype = "OP"; // can't use `datatype' here
			this->val = op;
			this->left = NULL;
			this->right = NULL;
		}

		AST_Node_op(std::string op, AST_Node* subtree_l, AST_Node* subtree_r){
			this->valtype = "OP";
			this->val = op;
			this->left = subtree_l;
			this->right = subtree_r;
		}

		TAC CodeGen(){
			if (val == "+"){
				if(datatype == "INT")
					return TAC("ADDI", this->left->temp, this->right->temp, temp);
				else
					return TAC("ADDF", this->left->temp, this->right->temp, temp);
			} else if (val == "-"){
				if(datatype == "INT")
					return TAC("SUBI", this->left->temp, this->right->temp, temp);
				else
					return TAC("SUBF", this->left->temp, this->right->temp, temp);

			} else if (val == "*"){
				if (datatype == "INT")
					return TAC("MULTI", this->left->temp, this->right->temp, temp);
				else
					return TAC("MULTF", this->left->temp, this->right->temp, temp);

			} else if (val == "/"){
				if (datatype == "INT")
					return TAC("DIVI", this->left->temp, this->right->temp, temp);
				else
					return TAC("DIVF", this->left->temp, this->right->temp, temp);

			}
			else if (val == "="){
				if (datatype == "INT"){
                    // std::cout<<"val` = "<<this->right->temp<<" temp = "<<temp<<"\n"; // ok
					return TAC("STOREI", this->right->temp, "", temp);
                }else
					return TAC("STOREF", this->right->temp, "", temp);
			}
			else 
				return TAC("", "", "", "");
		}
};

#endif