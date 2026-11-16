#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <set>
#include "semant.h"
#include "utilities.h"


extern int semant_debug;
extern char *curr_filename;
extern int node_lineno;

//////////////////////////////////////////////////////////////////////
//
// Symbols
//
// For convenience, a large number of symbols are predefined here.
// These symbols include the primitive type and method names, as well
// as fixed names used by the runtime system.
//
//////////////////////////////////////////////////////////////////////
static Symbol
    arg,
    arg2,
    Bool,
    concat,
    cool_abort,
    copy,
    Int,
    in_int,
    in_string,
    IO,
    length,
    Main,
    main_meth,
    No_class,
    No_type,
    Object,
    out_int,
    out_string,
    prim_slot,
    self,
    SELF_TYPE,
    Str,
    str_field,
    substr,
    type_name,
    val;
//
// Initializing the predefined symbols.
//
static void initialize_constants(void)
{
    arg         = idtable.add_string("arg");
    arg2        = idtable.add_string("arg2");
    Bool        = idtable.add_string("Bool");
    concat      = idtable.add_string("concat");
    cool_abort  = idtable.add_string("abort");
    copy        = idtable.add_string("copy");
    Int         = idtable.add_string("Int");
    in_int      = idtable.add_string("in_int");
    in_string   = idtable.add_string("in_string");
    IO          = idtable.add_string("IO");
    length      = idtable.add_string("length");
    Main        = idtable.add_string("Main");
    main_meth   = idtable.add_string("main");
    //   _no_class is a symbol that can't be the name of any
    //   user-defined class.
    No_class    = idtable.add_string("_no_class");
    No_type     = idtable.add_string("_no_type");
    Object      = idtable.add_string("Object");
    out_int     = idtable.add_string("out_int");
    out_string  = idtable.add_string("out_string");
    prim_slot   = idtable.add_string("_prim_slot");
    self        = idtable.add_string("self");
    SELF_TYPE   = idtable.add_string("SELF_TYPE");
    Str         = idtable.add_string("String");
    str_field   = idtable.add_string("_str_field");
    substr      = idtable.add_string("substr");
    type_name   = idtable.add_string("type_name");
    val         = idtable.add_string("_val");
}

//////////////////////////////////////////////////////////////////////
//
// Construção e validação do grafo de herança
//
// O construtor executa a primeira fase da análise: registra as classes
// básicas e as do usuário, valida os pais de cada classe e procura
// ciclos. Se algo falhar aqui, program_class::semant() interrompe a
// compilação, pois as fases seguintes dependem de um grafo bem formado.
//
//////////////////////////////////////////////////////////////////////

ClassTable::ClassTable(Classes classes) : semant_errors(0) , error_stream(cerr) {

    current_class = NULL;
    install_basic_classes();

    for (int i = classes->first(); classes->more(i); i = classes->next(i))
        add_class(classes->nth(i), false);

    check_parents();
    check_cycles();

    if (semant_debug)
        dump_graph();
}

void ClassTable::add_class(Class_ c, bool basic)
{
    Symbol name = c->get_name();

    if (!basic) {
        if (name == SELF_TYPE || is_basic_class(name)) {
            semant_error(c) << "Redefinition of basic class " << name << "." << endl;
            return;
        }
        if (class_map.find(name) != class_map.end()) {
            semant_error(c) << "Class " << name << " was previously defined." << endl;
            return;
        }
        user_classes.push_back(c);
    }
    class_map[name] = c;
}

bool ClassTable::is_basic_class(Symbol name)
{
    return name == Object || name == IO || name == Int ||
           name == Bool || name == Str;
}

void ClassTable::check_parents()
{
    for (size_t i = 0; i < user_classes.size(); i++) {
        Class_ c = user_classes[i];
        Symbol parent = c->get_parent();

        if (parent == Int || parent == Bool || parent == Str || parent == SELF_TYPE) {
            semant_error(c) << "Class " << c->get_name()
                            << " cannot inherit class " << parent << "." << endl;
        } else if (class_map.find(parent) == class_map.end()) {
            semant_error(c) << "Class " << c->get_name()
                            << " inherits from an undefined class " << parent << "." << endl;
        }
    }
}

// Sobe pela cadeia de pais de cada classe. Como existem apenas N classes,
// uma cadeia que ainda não terminou depois de N passos necessariamente
// entrou em um ciclo. Pais inexistentes já foram reportados e encerram
// a caminhada sem gerar um segundo erro.
void ClassTable::check_cycles()
{
    size_t limit = class_map.size();

    for (size_t i = 0; i < user_classes.size(); i++) {
        Class_ c = user_classes[i];
        Symbol cur = c->get_name();
        size_t steps = 0;

        while (cur != No_class && steps <= limit) {
            std::map<Symbol, Class_>::iterator it = class_map.find(cur);
            if (it == class_map.end())
                break;
            cur = it->second->get_parent();
            steps++;
        }

        if (steps > limit) {
            semant_error(c) << "Class " << c->get_name() << ", or an ancestor of "
                            << c->get_name() << ", is involved in an inheritance cycle."
                            << endl;
        }
    }
}

void ClassTable::dump_graph()
{
    cerr << "Grafo de herança:" << endl;
    for (std::map<Symbol, Class_>::iterator it = class_map.begin();
         it != class_map.end(); ++it) {
        cerr << "  " << it->first << " -> " << it->second->get_parent() << endl;
    }
}

void ClassTable::install_basic_classes() {

    // The tree package uses these globals to annotate the classes built below.
    node_lineno  = 0;
    Symbol filename = stringtable.add_string("<basic class>");

    // The following demonstrates how to create dummy parse trees to
    // refer to basic Cool classes.  There's no need for method
    // bodies -- these are already built into the runtime system.

    //
    // The Object class has no parent class. Its methods are
    //        abort() : Object    aborts the program
    //        type_name() : Str   returns a string representation of class name
    //        copy() : SELF_TYPE  returns a copy of the object
    //
    // There is no need for method bodies in the basic classes---these
    // are already built in to the runtime system.

    Class_ Object_class =
	class_(Object,
	       No_class,
	       append_Features(
			       append_Features(
					       single_Features(method(cool_abort, nil_Formals(), Object, no_expr())),
					       single_Features(method(type_name, nil_Formals(), Str, no_expr()))),
			       single_Features(method(copy, nil_Formals(), SELF_TYPE, no_expr()))),
	       filename);

    //
    // The IO class inherits from Object. Its methods are
    //        out_string(Str) : SELF_TYPE       writes a string to the output
    //        out_int(Int) : SELF_TYPE            "    an int    "  "     "
    //        in_string() : Str                 reads a string from the input
    //        in_int() : Int                      "   an int     "  "     "
    //
    Class_ IO_class =
	class_(IO,
	       Object,
	       append_Features(
			       append_Features(
					       append_Features(
							       single_Features(method(out_string, single_Formals(formal(arg, Str)),
										      SELF_TYPE, no_expr())),
							       single_Features(method(out_int, single_Formals(formal(arg, Int)),
										      SELF_TYPE, no_expr()))),
					       single_Features(method(in_string, nil_Formals(), Str, no_expr()))),
			       single_Features(method(in_int, nil_Formals(), Int, no_expr()))),
	       filename);

    //
    // The Int class has no methods and only a single attribute, the
    // "val" for the integer.
    //
    Class_ Int_class =
	class_(Int,
	       Object,
	       single_Features(attr(val, prim_slot, no_expr())),
	       filename);

    //
    // Bool also has only the "val" slot.
    //
    Class_ Bool_class =
	class_(Bool, Object, single_Features(attr(val, prim_slot, no_expr())),filename);

    //
    // The class Str has a number of slots and operations:
    //       val                                  the length of the string
    //       str_field                            the string itself
    //       length() : Int                       returns length of the string
    //       concat(arg: Str) : Str               performs string concatenation
    //       substr(arg: Int, arg2: Int): Str     substring selection
    //
    Class_ Str_class =
	class_(Str,
	       Object,
	       append_Features(
			       append_Features(
					       append_Features(
							       append_Features(
									       single_Features(attr(val, Int, no_expr())),
									       single_Features(attr(str_field, prim_slot, no_expr()))),
							       single_Features(method(length, nil_Formals(), Int, no_expr()))),
					       single_Features(method(concat,
								      single_Formals(formal(arg, Str)),
								      Str,
								      no_expr()))),
			       single_Features(method(substr,
						      append_Formals(single_Formals(formal(arg, Int)),
								     single_Formals(formal(arg2, Int))),
						      Str,
						      no_expr()))),
	       filename);

    add_class(Object_class, true);
    add_class(IO_class, true);
    add_class(Int_class, true);
    add_class(Bool_class, true);
    add_class(Str_class, true);
}

//////////////////////////////////////////////////////////////////////
//
// Consultas sobre o grafo de herança
//
//////////////////////////////////////////////////////////////////////

bool ClassTable::is_defined(Symbol type)
{
    return class_map.find(type) != class_map.end();
}

Symbol ClassTable::parent_of(Symbol type)
{
    std::map<Symbol, Class_>::iterator it = class_map.find(type);
    if (it == class_map.end())
        return No_class;
    return it->second->get_parent();
}

// Relação de conformidade (A <= B) do manual, com as regras de SELF_TYPE:
//   SELF_TYPE_C <= SELF_TYPE_C
//   SELF_TYPE_C <= T  se  C <= T
//   T <= SELF_TYPE_C  nunca vale para T diferente de SELF_TYPE
// Tipos não definidos já geraram erro em outro ponto; considerá-los
// conformes evita uma cascata de mensagens sobre o mesmo problema.
bool ClassTable::conforms(Symbol child, Symbol ancestor)
{
    if (child == No_type || child == ancestor)
        return true;
    if (ancestor == SELF_TYPE)
        return false;
    if (child == SELF_TYPE)
        child = current_class_name();
    if (!is_defined(child) || !is_defined(ancestor))
        return true;

    while (child != No_class) {
        if (child == ancestor)
            return true;
        child = parent_of(child);
    }
    return false;
}

// Menor ancestral comum (join) de dois tipos, usado em if e case.
// lub(SELF_TYPE_C, SELF_TYPE_C) = SELF_TYPE_C; nos demais casos
// SELF_TYPE é trocado pela classe corrente C.
Symbol ClassTable::lub(Symbol a, Symbol b)
{
    if (a == b)
        return a;
    if (a == No_type)
        return b;
    if (b == No_type)
        return a;
    if (a == SELF_TYPE)
        a = current_class_name();
    if (b == SELF_TYPE)
        b = current_class_name();
    if (!is_defined(a) || !is_defined(b))
        return Object;

    std::set<Symbol> ancestors;
    for (Symbol t = a; t != No_class; t = parent_of(t))
        ancestors.insert(t);
    for (Symbol t = b; t != No_class; t = parent_of(t))
        if (ancestors.count(t))
            return t;
    return Object;
}

method_class *ClassTable::lookup_method(Symbol cls, Symbol name)
{
    if (cls == SELF_TYPE)
        cls = current_class_name();

    while (cls != No_class && is_defined(cls)) {
        std::map<Symbol, method_class *> &methods = method_table[cls];
        std::map<Symbol, method_class *>::iterator it = methods.find(name);
        if (it != methods.end())
            return it->second;
        cls = parent_of(cls);
    }
    return NULL;
}

attr_class *ClassTable::lookup_attr(Symbol cls, Symbol name)
{
    while (cls != No_class && is_defined(cls)) {
        std::map<Symbol, attr_class *> &attrs = attr_table[cls];
        std::map<Symbol, attr_class *>::iterator it = attrs.find(name);
        if (it != attrs.end())
            return it->second;
        cls = parent_of(cls);
    }
    return NULL;
}

Symbol ClassTable::lookup_object(Symbol name)
{
    return objects.lookup(name);
}

//////////////////////////////////////////////////////////////////////
//
// Coleta de features e verificação de assinaturas
//
// Como métodos e atributos podem ser usados antes de serem declarados,
// todas as features de todas as classes são registradas antes de
// qualquer corpo ser verificado.
//
//////////////////////////////////////////////////////////////////////

void ClassTable::collect_features(Class_ c)
{
    Symbol cname = c->get_name();
    Features features = c->get_features();
    std::map<Symbol, method_class *> &methods = method_table[cname];
    std::map<Symbol, attr_class *> &attrs = attr_table[cname];

    for (int i = features->first(); features->more(i); i = features->next(i)) {
        Feature f = features->nth(i);
        Symbol fname = f->get_name();

        if (f->is_method()) {
            if (methods.find(fname) != methods.end())
                semant_error(c->get_filename(), f) << "Method " << fname
                                                   << " is multiply defined." << endl;
            else
                methods[fname] = (method_class *) f;
        } else {
            if (fname == self)
                continue;
            if (attrs.find(fname) != attrs.end())
                semant_error(c->get_filename(), f) << "Attribute " << fname
                                                   << " is multiply defined in class." << endl;
            else
                attrs[fname] = (attr_class *) f;
        }
    }
}

void ClassTable::check_attr_declaration(Class_ c, attr_class *a)
{
    Symbol name = a->get_name();
    Symbol type = a->get_type_decl();

    if (name == self) {
        semant_error(c->get_filename(), a)
            << "'self' cannot be the name of an attribute." << endl;
        return;
    }
    if (type != SELF_TYPE && !is_defined(type)) {
        semant_error(c->get_filename(), a) << "Class " << type << " of attribute "
                                           << name << " is undefined." << endl;
    }
    if (lookup_attr(c->get_parent(), name) != NULL) {
        semant_error(c->get_filename(), a) << "Attribute " << name
                                           << " is an attribute of an inherited class." << endl;
    }
}

// Valida parâmetros formais e tipo de retorno e, quando o método redefine
// outro herdado, exige a mesma quantidade de parâmetros, os mesmos tipos e
// o mesmo tipo de retorno (regra de redefinição do manual, seção 6).
void ClassTable::check_method_signature(Class_ c, method_class *m)
{
    Symbol filename = c->get_filename();
    Formals formals = m->get_formals();
    std::set<Symbol> seen;

    for (int i = formals->first(); formals->more(i); i = formals->next(i)) {
        Formal f = formals->nth(i);
        Symbol fname = f->get_name();
        Symbol ftype = f->get_type_decl();

        if (fname == self)
            semant_error(filename, f) << "'self' cannot be the name of a formal parameter." << endl;
        else if (seen.count(fname))
            semant_error(filename, f) << "Formal parameter " << fname
                                      << " is multiply defined." << endl;
        seen.insert(fname);

        if (ftype == SELF_TYPE)
            semant_error(filename, f) << "Formal parameter " << fname
                                      << " cannot have type SELF_TYPE." << endl;
        else if (!is_defined(ftype))
            semant_error(filename, f) << "Class " << ftype << " of formal parameter "
                                      << fname << " is undefined." << endl;
    }

    Symbol ret = m->get_return_type();
    if (ret != SELF_TYPE && !is_defined(ret))
        semant_error(filename, m) << "Undefined return type " << ret << " in method "
                                  << m->get_name() << "." << endl;

    method_class *original = lookup_method(c->get_parent(), m->get_name());
    if (original == NULL)
        return;

    Formals orig_formals = original->get_formals();
    if (orig_formals->len() != formals->len()) {
        semant_error(filename, m) << "Incompatible number of formal parameters in redefined method "
                                  << m->get_name() << "." << endl;
    } else {
        for (int i = formals->first(); formals->more(i); i = formals->next(i)) {
            Symbol t_new = formals->nth(i)->get_type_decl();
            Symbol t_old = orig_formals->nth(i)->get_type_decl();
            if (t_new != t_old) {
                semant_error(filename, m) << "In redefined method " << m->get_name()
                                          << ", parameter type " << t_new
                                          << " is different from original type " << t_old
                                          << endl;
            }
        }
    }

    if (ret != original->get_return_type()) {
        semant_error(filename, m) << "In redefined method " << m->get_name()
                                  << ", return type " << ret
                                  << " is different from original return type "
                                  << original->get_return_type() << "." << endl;
    }
}

void ClassTable::check_inherited_features(Class_ c)
{
    Features features = c->get_features();
    for (int i = features->first(); features->more(i); i = features->next(i)) {
        Feature f = features->nth(i);
        if (f->is_method())
            check_method_signature(c, (method_class *) f);
        else
            check_attr_declaration(c, (attr_class *) f);
    }
}

void ClassTable::check_main()
{
    if (!is_defined(Main)) {
        semant_error() << "Class Main is not defined." << endl;
        return;
    }

    // Assim como no coolc de referência, main precisa ser declarado na
    // própria classe Main; um main apenas herdado não é aceito.
    Class_ main_class = class_map[Main];
    std::map<Symbol, method_class *> &methods = method_table[Main];
    method_class *m = (methods.find(main_meth) != methods.end()) ? methods[main_meth] : NULL;
    if (m == NULL) {
        semant_error(main_class) << "No 'main' method in class Main." << endl;
    } else if (m->get_formals()->len() != 0) {
        semant_error(main_class->get_filename(), m)
            << "'main' method in class Main should have no arguments." << endl;
    }
}

// Coloca no escopo corrente os atributos da classe e de todos os seus
// ancestrais. Os ancestrais entram primeiro; assim, se houver um atributo
// redefinido (já reportado como erro), vale a declaração mais próxima.
void ClassTable::add_attributes_to_scope(Symbol cls)
{
    if (cls == No_class || !is_defined(cls))
        return;
    add_attributes_to_scope(parent_of(cls));

    std::map<Symbol, attr_class *> &attrs = attr_table[cls];
    for (std::map<Symbol, attr_class *>::iterator it = attrs.begin(); it != attrs.end(); ++it)
        objects.addid(it->first, it->second->get_type_decl());
}

//////////////////////////////////////////////////////////////////////
//
// Segunda fase: features e expressões
//
//   1. registra métodos e atributos de todas as classes;
//   2. verifica a existência de Main.main;
//   3. verifica declarações e redefinições de cada feature;
//   4. verifica os tipos de cada corpo de método e inicialização de
//      atributo, anotando cada expressão com o tipo inferido.
//
//////////////////////////////////////////////////////////////////////

void ClassTable::type_check_classes()
{
    for (std::map<Symbol, Class_>::iterator it = class_map.begin(); it != class_map.end(); ++it)
        collect_features(it->second);

    check_main();

    for (size_t i = 0; i < user_classes.size(); i++)
        check_inherited_features(user_classes[i]);

    for (size_t i = 0; i < user_classes.size(); i++) {
        current_class = user_classes[i];
        if (semant_debug)
            cerr << "Verificando a classe " << current_class->get_name() << endl;

        objects.enterscope();
        add_attributes_to_scope(current_class->get_name());
        objects.addid(self, SELF_TYPE);

        Features features = current_class->get_features();
        for (int j = features->first(); features->more(j); j = features->next(j))
            features->nth(j)->type_check(this);

        objects.exitscope();
    }
}

////////////////////////////////////////////////////////////////////
//
// semant_error is an overloaded function for reporting errors
// during semantic analysis.  There are four versions:
//
//    ostream& ClassTable::semant_error()
//
//    ostream& ClassTable::semant_error(Class_ c)
//       print line number and filename for `c'
//
//    ostream& ClassTable::semant_error(Symbol filename, tree_node *t)
//       print a line number and filename
//
//    ostream& ClassTable::semant_error(tree_node *t)
//       usa o arquivo da classe que está sendo verificada
//
///////////////////////////////////////////////////////////////////

ostream& ClassTable::semant_error(Class_ c)
{
    return semant_error(c->get_filename(),c);
}

ostream& ClassTable::semant_error(Symbol filename, tree_node *t)
{
    error_stream << filename << ":" << t->get_line_number() << ": ";
    return semant_error();
}

ostream& ClassTable::semant_error(tree_node *t)
{
    return semant_error(current_class->get_filename(), t);
}

ostream& ClassTable::semant_error()
{
    semant_errors++;
    return error_stream;
}

//////////////////////////////////////////////////////////////////////
//
// Verificação de features
//
//////////////////////////////////////////////////////////////////////

// O corpo do método é verificado em um escopo novo com os parâmetros
// formais, que escondem atributos de mesmo nome. Parâmetros inválidos
// (self ou repetidos) já foram reportados e não entram no escopo.
void method_class::type_check(ClassTable *ct)
{
    ct->objects.enterscope();

    for (int i = formals->first(); formals->more(i); i = formals->next(i)) {
        Formal f = formals->nth(i);
        Symbol fname = f->get_name();
        if (fname == self || ct->objects.probe(fname) != NULL)
            continue;
        Symbol ftype = f->get_type_decl();
        if (ftype == SELF_TYPE)
            ftype = Object;
        ct->objects.addid(fname, ftype);
    }

    Symbol body_type = expr->type_check(ct);

    if ((return_type == SELF_TYPE || ct->is_defined(return_type)) &&
        !ct->conforms(body_type, return_type)) {
        ct->semant_error(this) << "Inferred return type " << body_type << " of method "
                               << name << " does not conform to declared return type "
                               << return_type << "." << endl;
    }

    ct->objects.exitscope();
}

void attr_class::type_check(ClassTable *ct)
{
    Symbol init_type = init->type_check(ct);

    if (name == self)
        return;

    if (!ct->conforms(init_type, type_decl)) {
        ct->semant_error(this) << "Inferred type " << init_type
                               << " of initialization of attribute " << name
                               << " does not conform to declared type " << type_decl
                               << "." << endl;
    }
}

//////////////////////////////////////////////////////////////////////
//
// Verificação de expressões
//
// Cada método type_check calcula o tipo da expressão de acordo com as
// regras do manual (seção 12), grava o resultado no campo `type' do nó
// e o devolve. Quando não é possível inferir um tipo, o erro é
// reportado e a expressão recebe Object para que a análise continue.
//
//////////////////////////////////////////////////////////////////////

Symbol assign_class::type_check(ClassTable *ct)
{
    Symbol expr_type = expr->type_check(ct);

    if (name == self) {
        ct->semant_error(this) << "Cannot assign to 'self'." << endl;
        type = expr_type;
        return type;
    }

    Symbol declared = ct->lookup_object(name);
    if (declared == NULL) {
        ct->semant_error(this) << "Assignment to undeclared variable " << name << "." << endl;
    } else if (!ct->conforms(expr_type, declared)) {
        ct->semant_error(this) << "Type " << expr_type
                               << " of assigned expression does not conform to declared type "
                               << declared << " of identifier " << name << "." << endl;
    }

    type = expr_type;
    return type;
}

// Verifica os argumentos de uma chamada contra os parâmetros formais do
// método encontrado. Compartilhada por dispatch e static_dispatch.
static void check_actuals(ClassTable *ct, tree_node *call, method_class *m,
                          Expressions actual, std::vector<Symbol> &actual_types)
{
    Formals formals = m->get_formals();

    if (formals->len() != actual->len()) {
        ct->semant_error(call) << "Method " << m->get_name()
                               << " called with wrong number of arguments." << endl;
        return;
    }

    for (int i = formals->first(); formals->more(i); i = formals->next(i)) {
        Formal f = formals->nth(i);
        if (!ct->conforms(actual_types[i], f->get_type_decl())) {
            ct->semant_error(call) << "In call of method " << m->get_name() << ", type "
                                   << actual_types[i] << " of parameter " << f->get_name()
                                   << " does not conform to declared type "
                                   << f->get_type_decl() << "." << endl;
        }
    }
}

static void type_check_actuals(ClassTable *ct, Expressions actual,
                               std::vector<Symbol> &actual_types)
{
    for (int i = actual->first(); actual->more(i); i = actual->next(i))
        actual_types.push_back(actual->nth(i)->type_check(ct));
}

Symbol static_dispatch_class::type_check(ClassTable *ct)
{
    Symbol expr_type = expr->type_check(ct);
    std::vector<Symbol> actual_types;
    type_check_actuals(ct, actual, actual_types);

    type = Object;

    if (type_name == SELF_TYPE) {
        ct->semant_error(this) << "Static dispatch to SELF_TYPE." << endl;
        return type;
    }
    if (!ct->is_defined(type_name)) {
        ct->semant_error(this) << "Static dispatch to undefined class " << type_name << "." << endl;
        return type;
    }
    if (!ct->conforms(expr_type, type_name)) {
        ct->semant_error(this) << "Expression type " << expr_type
                               << " does not conform to declared static dispatch type "
                               << type_name << "." << endl;
    }

    method_class *m = ct->lookup_method(type_name, name);
    if (m == NULL) {
        ct->semant_error(this) << "Static dispatch to undefined method " << name << "." << endl;
        return type;
    }

    check_actuals(ct, this, m, actual, actual_types);

    Symbol ret = m->get_return_type();
    type = (ret == SELF_TYPE) ? expr_type : ret;
    return type;
}

Symbol dispatch_class::type_check(ClassTable *ct)
{
    Symbol expr_type = expr->type_check(ct);
    std::vector<Symbol> actual_types;
    type_check_actuals(ct, actual, actual_types);

    type = Object;

    Symbol cls = (expr_type == SELF_TYPE) ? ct->current_class_name() : expr_type;
    if (!ct->is_defined(cls)) {
        ct->semant_error(this) << "Dispatch on undefined class " << cls << "." << endl;
        return type;
    }

    method_class *m = ct->lookup_method(cls, name);
    if (m == NULL) {
        ct->semant_error(this) << "Dispatch to undefined method " << name << "." << endl;
        return type;
    }

    check_actuals(ct, this, m, actual, actual_types);

    Symbol ret = m->get_return_type();
    type = (ret == SELF_TYPE) ? expr_type : ret;
    return type;
}

Symbol cond_class::type_check(ClassTable *ct)
{
    if (pred->type_check(ct) != Bool)
        ct->semant_error(this) << "Predicate of 'if' does not have type Bool." << endl;

    Symbol then_type = then_exp->type_check(ct);
    Symbol else_type = else_exp->type_check(ct);
    type = ct->lub(then_type, else_type);
    return type;
}

Symbol loop_class::type_check(ClassTable *ct)
{
    if (pred->type_check(ct) != Bool)
        ct->semant_error(this) << "Loop condition does not have type Bool." << endl;

    body->type_check(ct);
    type = Object;
    return type;
}

// Cada ramo é verificado em seu próprio escopo. O tipo do case é o lub
// dos tipos dos corpos dos ramos, e dois ramos não podem declarar o
// mesmo tipo.
Symbol typcase_class::type_check(ClassTable *ct)
{
    expr->type_check(ct);

    std::set<Symbol> branch_types;
    Symbol result = NULL;

    for (int i = cases->first(); cases->more(i); i = cases->next(i)) {
        Case c = cases->nth(i);
        Symbol decl = c->get_type_decl();

        if (branch_types.count(decl))
            ct->semant_error(c) << "Duplicate branch " << decl << " in case statement." << endl;
        branch_types.insert(decl);

        Symbol branch_type = c->type_check(ct);
        result = (result == NULL) ? branch_type : ct->lub(result, branch_type);
    }

    type = (result == NULL) ? Object : result;
    return type;
}

Symbol branch_class::type_check(ClassTable *ct)
{
    Symbol bound_type = type_decl;

    if (type_decl == SELF_TYPE) {
        ct->semant_error(this) << "Identifier " << name
                               << " declared with type SELF_TYPE in case branch." << endl;
        bound_type = Object;
    } else if (!ct->is_defined(type_decl)) {
        ct->semant_error(this) << "Class " << type_decl << " of case branch is undefined." << endl;
    }

    ct->objects.enterscope();
    if (name == self)
        ct->semant_error(this) << "'self' bound in 'case'." << endl;
    else
        ct->objects.addid(name, bound_type);

    Symbol body_type = expr->type_check(ct);
    ct->objects.exitscope();
    return body_type;
}

Symbol block_class::type_check(ClassTable *ct)
{
    Symbol last = Object;
    for (int i = body->first(); body->more(i); i = body->next(i))
        last = body->nth(i)->type_check(ct);
    type = last;
    return type;
}

// A inicialização é verificada antes de abrir o escopo do let, pois o
// identificador declarado não é visível na própria inicialização.
Symbol let_class::type_check(ClassTable *ct)
{
    if (type_decl != SELF_TYPE && !ct->is_defined(type_decl)) {
        ct->semant_error(this) << "Class " << type_decl << " of let-bound identifier "
                               << identifier << " is undefined." << endl;
    }

    Symbol init_type = init->type_check(ct);
    if (!ct->conforms(init_type, type_decl)) {
        ct->semant_error(this) << "Inferred type " << init_type << " of initialization of "
                               << identifier << " does not conform to identifier's declared type "
                               << type_decl << "." << endl;
    }

    ct->objects.enterscope();
    if (identifier == self)
        ct->semant_error(this) << "'self' cannot be bound in a 'let' expression." << endl;
    else
        ct->objects.addid(identifier, type_decl);

    type = body->type_check(ct);
    ct->objects.exitscope();
    return type;
}

static Symbol check_arith(ClassTable *ct, tree_node *node, Expression e1, Expression e2,
                          const char *op)
{
    Symbol t1 = e1->type_check(ct);
    Symbol t2 = e2->type_check(ct);
    if (t1 != Int || t2 != Int)
        ct->semant_error(node) << "non-Int arguments: " << t1 << " " << op << " " << t2 << endl;
    return Int;
}

Symbol plus_class::type_check(ClassTable *ct)
{
    type = check_arith(ct, this, e1, e2, "+");
    return type;
}

Symbol sub_class::type_check(ClassTable *ct)
{
    type = check_arith(ct, this, e1, e2, "-");
    return type;
}

Symbol mul_class::type_check(ClassTable *ct)
{
    type = check_arith(ct, this, e1, e2, "*");
    return type;
}

Symbol divide_class::type_check(ClassTable *ct)
{
    type = check_arith(ct, this, e1, e2, "/");
    return type;
}

Symbol neg_class::type_check(ClassTable *ct)
{
    Symbol t = e1->type_check(ct);
    if (t != Int)
        ct->semant_error(this) << "Argument of '~' has type " << t << " instead of Int." << endl;
    type = Int;
    return type;
}

Symbol lt_class::type_check(ClassTable *ct)
{
    check_arith(ct, this, e1, e2, "<");
    type = Bool;
    return type;
}

Symbol leq_class::type_check(ClassTable *ct)
{
    check_arith(ct, this, e1, e2, "<=");
    type = Bool;
    return type;
}

// Objetos quaisquer podem ser comparados, mas se um dos lados for Int,
// String ou Bool o outro precisa ter exatamente o mesmo tipo.
Symbol eq_class::type_check(ClassTable *ct)
{
    Symbol t1 = e1->type_check(ct);
    Symbol t2 = e2->type_check(ct);

    bool basic1 = (t1 == Int || t1 == Str || t1 == Bool);
    bool basic2 = (t2 == Int || t2 == Str || t2 == Bool);
    if ((basic1 || basic2) && t1 != t2)
        ct->semant_error(this) << "Illegal comparison with a basic type." << endl;

    type = Bool;
    return type;
}

Symbol comp_class::type_check(ClassTable *ct)
{
    Symbol t = e1->type_check(ct);
    if (t != Bool)
        ct->semant_error(this) << "Argument of 'not' has type " << t << " instead of Bool." << endl;
    type = Bool;
    return type;
}

Symbol int_const_class::type_check(ClassTable *ct)
{
    type = Int;
    return type;
}

Symbol bool_const_class::type_check(ClassTable *ct)
{
    type = Bool;
    return type;
}

Symbol string_const_class::type_check(ClassTable *ct)
{
    type = Str;
    return type;
}

Symbol new__class::type_check(ClassTable *ct)
{
    if (type_name != SELF_TYPE && !ct->is_defined(type_name)) {
        ct->semant_error(this) << "'new' used with undefined class " << type_name << "." << endl;
        type = Object;
    } else {
        type = type_name;
    }
    return type;
}

Symbol isvoid_class::type_check(ClassTable *ct)
{
    e1->type_check(ct);
    type = Bool;
    return type;
}

Symbol no_expr_class::type_check(ClassTable *ct)
{
    type = No_type;
    return type;
}

Symbol object_class::type_check(ClassTable *ct)
{
    if (name == self) {
        type = SELF_TYPE;
        return type;
    }

    Symbol t = ct->lookup_object(name);
    if (t == NULL) {
        ct->semant_error(this) << "Undeclared identifier " << name << "." << endl;
        t = Object;
    }
    type = t;
    return type;
}


/*   This is the entry point to the semantic checker.

     Your checker should do the following two things:

     1) Check that the program is semantically correct
     2) Decorate the abstract syntax tree with type information
        by setting the `type' field in each Expression node.
        (see `tree.h')

     You are free to first do 1), make sure you catch all semantic
     errors. Part 2) can be done in a second stage, when you want
     to build mycoolc.
 */
void program_class::semant()
{
    initialize_constants();

    /* ClassTable constructor may do some semantic analysis */
    ClassTable *classtable = new ClassTable(classes);

    if (classtable->errors()) {
	cerr << "Compilation halted due to static semantic errors." << endl;
	exit(1);
    }

    classtable->type_check_classes();

    if (classtable->errors()) {
	cerr << "Compilation halted due to static semantic errors." << endl;
	exit(1);
    }
}
