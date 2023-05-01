#ifndef SYMBOL_TABLE_HPP
#define SYMBOL_TABLE_HPP

#include <bits/stdc++.h>
#include "entry.hpp"
#include "symbolTable.hpp"

class CodeLine
{
public:
    std::string command, arg1 ,arg2, arg3;
    std::string scope;

    CodeLine(std::string scope, std::string command, std::string arg1)
    {
        this->scope = scope;
        this->command = command;
        this->arg1 = arg1;
        this->arg2 = "";
        this->arg3 = "";
    }

    CodeLine(std::string scope, std::string command, std::string arg1, std::string arg2)
    {
        this->scope = scope;
        this->command = command;
        this->arg1 = arg1;
        this->arg2 = arg2;
        this->arg3 = "";
    }

    CodeLine(std::string scope, std::string command, std::string arg1, std::string arg2, std::string arg3)
    {
        this->scope = scope;
        this->command = command;
        this->arg1 = arg1;
        this->arg2 = arg2;
        this->arg3 = arg3;
    }

    void print()
    {
        std::string print_val =  command + " " + arg1;
        if (arg2 != "")
            print_val += " " + arg2;
        if (arg3 != "")
            print_val += " " + arg3;
        std::cout << print_val << std::endl;
    }

};

class SymbolTable
{
public:
    std::string scope;
    
    // Map of name and Entry
    std::unordered_map<std::string, Entry *> symbols;
    std::vector<Entry *> ordered_symbols;
    int total_parameters = 0;
    int total_non_parameters = 0;

    SymbolTable(std::string scope) {
        this->scope = scope;
    }

    int linkSize() {
        return total_non_parameters;
    }

    Entry* findEntry(std::string name) {
        return symbols[name];
    }

    void addEntry(std::string name, std::string type) {
        total_non_parameters++;
        Entry* variable = new Entry(name, type);
        variable->stackname = "$-" + std::to_string(total_non_parameters);
        ordered_symbols.push_back(variable);
        symbols[name] = variable;
        std::cout << "var " << name << std::endl;
    }

    void addEntry(std::string name, std::string type, std::string value) {
        total_non_parameters++;
        Entry* variable = new Entry(name, type, value);
        variable->stackname = value;
        ordered_symbols.push_back(variable);
        symbols[name] = variable;
        if(value ==""){
            std::cout << "var " << name << std::endl;
        }
        else{
            std::cout << "str " << name << " " << value << std::endl;
        }
    }

    void addEntry(std::string name, std::string type, bool isParameter) {
        total_parameters++;
        Entry* variable = new Entry(name, type, isParameter);
        variable->stackname = "$" + std::to_string(total_parameters+1);
        ordered_symbols.push_back(variable);
        symbols[name] = variable;
        std::cout<<"var "<<name<<std::endl;
    }

    bool ifExists(std::string name) {
        if (symbols.find(name) == symbols.end())
            return false;
        else
            return true;
    }

    void printTable() {
        std::cout << "Symbol table " << scope << std::endl;

        for (auto it = ordered_symbols.begin(); it != ordered_symbols.end(); ++it) {
            std::cout << "name " << (*it)->name << " type " << (*it)->type;    
            if ((*it)->value != "")
                std::cout << " value " << (*it)->value;
            std::cout << std::endl;
        }
    }
};

class SymbolTableStack
{
    std::string error_variable = "";

public:
    std::vector<SymbolTable *> tables;
    std::stack<SymbolTable *> table_stack;
    int block_number = 1;

    
    // add new table for IF, ELSE and FOR
    void addNewTable()
    {
        SymbolTable *temp = new SymbolTable("$BLOCK " + std::to_string(block_number));
        table_stack.push(temp);
        tables.push_back(temp);
        block_number += 1;
    }

    // for GLOBAL and FUNCTION
    void addNewTable(std::string name)
    {
        SymbolTable *temp = new SymbolTable(name);
        table_stack.push(temp);
        tables.push_back(temp);
    }

    // remove symbol table from stack
    void removeTable()
    {
        table_stack.pop();
    }

    void insertSymbol(std::string name, std::string type)
    {
        SymbolTable *table = table_stack.top();

        if (table->ifExists(name) && error_variable == "")
            error_variable = name;
        else
            table->addEntry(name, type);
    }

    void insertSymbol(std::string name, std::string type, std::string value)
    {
        SymbolTable *table = table_stack.top();

        if (table->ifExists(name) && error_variable == "")
            error_variable = name;
        else
            table->addEntry(name, type, value);
    }

    void insertSymbol(std::string name, std::string type, bool isParameter)
    {
        SymbolTable *table = table_stack.top();
        
        if (table->ifExists(name) && error_variable == "")
            error_variable = name;
        else
            table->addEntry(name, type, isParameter);
    }

    Entry* findEntry(std::string name)
    {
        std::stack<SymbolTable *> temp_stack = table_stack;
        while (temp_stack.size())
        {
            if (temp_stack.top()->ifExists(name))
                return temp_stack.top()->findEntry(name);
            temp_stack.pop();
        }
        return new Entry("error", "error");
    }

    Entry* findEntry(std::string name, std::string scope) {
        for(auto table : tables) {
            if(table->scope == scope)
                return table->findEntry(name);
        }
        return new Entry("error", "error");
    }

    std::string findType(std::string name)
    {
        return findEntry(name)->type;
    }

    void printStack()
    {
        if (error_variable != "")
            std::cout << "DECLARATION ERROR " + error_variable << std::endl;
        else {
            for (int i = 0; i != tables.size(); i++) {
                tables[i]->printTable();
                if (i != tables.size() - 1)
                    std::cout << std::endl;
            }
        }
    }
};

class CodeObject
{
    int temp_value = 0;
public:
    std::vector<CodeLine*> TAC;
    SymbolTableStack* symbolTableStack;
    int lb = 0;
    std::deque<int> lbList;
    
    CodeObject(SymbolTableStack* symbolTableStack)
    {
        this->symbolTableStack = symbolTableStack;
    }

    std::string getTemp()
    {
        return "$T" + std::to_string(++temp_value);
    }

    void addRead(std::string var_name, std::string type)
    {
        if (type == "INT")
            TAC.push_back(new CodeLine(symbolTableStack->table_stack.top()->scope, "READI", var_name));
        else if (type == "FLOAT")
            TAC.push_back(new CodeLine(symbolTableStack->table_stack.top()->scope, "READF", var_name));
    }

    void addWrite(std::string var_name, std::string type)
    {
        if (type == "INT")
            TAC.push_back(new CodeLine(symbolTableStack->table_stack.top()->scope, "WRITEI", var_name));
        else if (type == "FLOAT")
            TAC.push_back(new CodeLine(symbolTableStack->table_stack.top()->scope, "WRITEF", var_name));
        else if (type == "STRING")
            TAC.push_back(new CodeLine(symbolTableStack->table_stack.top()->scope, "WRITES", var_name));
    }

    void print()
    {
        for (auto s: TAC)
            s->print();
    }

};

#endif
