#ifndef SEMANT_H_
#define SEMANT_H_

#include <assert.h>
#include <map>
#include <vector>
#include "cool-io.h"
#include "cool-tree.h"
#include "stringtab.h"
#include "symtab.h"
#include "list.h"

#define TRUE 1
#define FALSE 0

class ClassTable;
typedef ClassTable *ClassTableP;

// Tabela de classes: guarda o grafo de herança, as tabelas de métodos e
// atributos de cada classe e o ambiente de objetos (escopos) usado durante
// a verificação de tipos de uma classe.

class ClassTable {
private:
  int semant_errors;
  void install_basic_classes();
  ostream& error_stream;

  std::map<Symbol, Class_> class_map;
  std::vector<Class_> user_classes;
  std::map<Symbol, std::map<Symbol, method_class *> > method_table;
  std::map<Symbol, std::map<Symbol, attr_class *> > attr_table;

  Class_ current_class;

  void add_class(Class_ c, bool basic);
  void check_parents();
  void check_cycles();
  void check_main();
  void collect_features(Class_ c);
  void check_inherited_features(Class_ c);
  void check_method_signature(Class_ c, method_class *m);
  void check_attr_declaration(Class_ c, attr_class *a);
  void add_attributes_to_scope(Symbol cls);
  void dump_graph();

public:
  SymbolTable<Symbol, Entry> objects;

  ClassTable(Classes);
  int errors() { return semant_errors; }
  ostream& semant_error();
  ostream& semant_error(Class_ c);
  ostream& semant_error(Symbol filename, tree_node *t);
  ostream& semant_error(tree_node *t);

  void type_check_classes();

  bool is_defined(Symbol type);
  bool is_basic_class(Symbol name);
  Symbol parent_of(Symbol type);
  Class_ get_current_class() { return current_class; }
  Symbol current_class_name() { return current_class->get_name(); }

  bool conforms(Symbol child, Symbol ancestor);
  Symbol lub(Symbol a, Symbol b);
  method_class *lookup_method(Symbol cls, Symbol name);
  attr_class *lookup_attr(Symbol cls, Symbol name);
  Symbol lookup_object(Symbol name);
};

#endif
