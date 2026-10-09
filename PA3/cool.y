/*
 *  cool.y
 *              Parser definition for the COOL language.
 *
 */
%{
#include "cool-io.h"
#include "cool-tree.h"
#include "stringtab.h"
#include "utilities.h"

extern char *curr_filename;

void yyerror(const char *s);  /*  defined below; called for each parse error */
extern int yylex();           /*  the entry point to the lexer  */

#define YYLTYPE int
#define cool_yylloc curr_lineno

extern int node_lineno;

#define YYLLOC_DEFAULT(Current, Rhs, N)            \
  do {                                             \
    if (N) (Current) = YYRHSLOC(Rhs, 1);           \
    else   (Current) = YYRHSLOC(Rhs, 0);           \
    node_lineno = (Current);                       \
  } while (0)

#define SELF_SYM   idtable.add_string((char *) "self")
#define OBJECT_SYM idtable.add_string((char *) "Object")

/************************************************************************/
/*                DONT CHANGE ANYTHING IN THIS SECTION                  */

Program ast_root;	      /* the result of the parse  */
Classes parse_results;        /* for use in semantic analysis */
int omerrs = 0;               /* number of errors in lexing and parsing */
%}

/* A union of all the types that can be the result of parsing actions. */
%union {
  Boolean boolean;
  Symbol symbol;
  Program program;
  Class_ class_;
  Classes classes;
  Feature feature;
  Features features;
  Formal formal;
  Formals formals;
  Case case_;
  Cases cases;
  Expression expression;
  Expressions expressions;
  char *error_msg;
}

/*
   Declare the terminals; a few have types for associated lexemes.
   The token ERROR is never used in the parser; thus, it is a parse
   error when the lexer returns it.

   The integer following token declaration is the numeric constant used
   to represent that token internally.  Typically, Bison generates these
   on its own, but we give explicit numbers to prevent version parity
   problems (bison 1.25 and earlier start at 258, later versions -- at
   257)
*/
%token CLASS 258 ELSE 259 FI 260 IF 261 IN 262
%token INHERITS 263 LET 264 LOOP 265 POOL 266 THEN 267 WHILE 268
%token CASE 269 ESAC 270 OF 271 DARROW 272 NEW 273 ISVOID 274
%token <symbol>  STR_CONST 275 INT_CONST 276
%token <boolean> BOOL_CONST 277
%token <symbol>  TYPEID 278 OBJECTID 279
%token ASSIGN 280 NOT 281 LE 282 ERROR 283

/*  DON'T CHANGE ANYTHING ABOVE THIS LINE, OR YOUR PARSER WONT WORK       */
/**************************************************************************/

%locations

/* Declare types for the grammar's non-terminals. */
%type <program> program
%type <classes> class_list
%type <class_> class
%type <features> feature_list
%type <feature> feature
%type <formals> formal_list formals
%type <formal> formal
%type <cases> case_list
%type <case_> case_branch
%type <expression> expr opt_init let_body
%type <expressions> expr_block_list arg_list args

/* Precedence declarations go here. */
%right LET_PREC
%right ASSIGN
%right NOT
%nonassoc LE '<' '='
%left '+' '-'
%left '*' '/'
%right ISVOID
%right '~'
%left '@'
%left '.'

%%
/*
   Save the root of the abstract syntax tree in a global variable.
*/
program	: class_list	{ ast_root = program($1); }
        ;

class_list
	: class			/* single class */
		{ $$ = single_Classes($1);
                  parse_results = $$; }
	| class_list class	/* several classes */
		{ $$ = append_Classes($1,single_Classes($2));
                  parse_results = $$; }
	| error ';'
		{ $$ = nil_Classes();
                  parse_results = $$; }
	| class_list error ';'
		{ $$ = $1;
                  parse_results = $$; }
	;

/* If no parent is specified, the class inherits from the Object class. */
class	: CLASS TYPEID '{' feature_list '}' ';'
		{ $$ = class_($2,OBJECT_SYM,$4,
			      stringtable.add_string(curr_filename)); }
	| CLASS TYPEID INHERITS TYPEID '{' feature_list '}' ';'
		{ $$ = class_($2,$4,$6,stringtable.add_string(curr_filename)); }
	;

/* Feature list may be empty, but no empty features in list. */
feature_list
	: /* empty */
		{ $$ = nil_Features(); }
	| feature_list feature ';'
		{ $$ = append_Features($1,single_Features($2)); }
	| feature_list error ';'
		{ $$ = $1; }
	;

feature
	: OBJECTID '(' formals ')' ':' TYPEID '{' expr '}'
		{ $$ = method($1,$3,$6,$8); }
	| OBJECTID ':' TYPEID opt_init
		{ $$ = attr($1,$3,$4); }
	;

opt_init
	: /* empty */
		{ $$ = no_expr(); }
	| ASSIGN expr
		{ $$ = $2; }
	;

formals
	: /* empty */
		{ $$ = nil_Formals(); }
	| formal_list
		{ $$ = $1; }
	;

formal_list
	: formal
		{ $$ = single_Formals($1); }
	| formal_list ',' formal
		{ $$ = append_Formals($1,single_Formals($3)); }
	;

formal	: OBJECTID ':' TYPEID
		{ $$ = formal($1,$3); }
	;

args
	: /* empty */
		{ $$ = nil_Expressions(); }
	| arg_list
		{ $$ = $1; }
	;

arg_list
	: expr
		{ $$ = single_Expressions($1); }
	| arg_list ',' expr
		{ $$ = append_Expressions($1,single_Expressions($3)); }
	;

expr_block_list
	: expr ';'
		{ $$ = single_Expressions($1); }
	| expr_block_list expr ';'
		{ $$ = append_Expressions($1,single_Expressions($2)); }
	| error ';'
		{ $$ = nil_Expressions(); }
	| expr_block_list error ';'
		{ $$ = $1; }
	;

case_list
	: case_branch
		{ $$ = single_Cases($1); }
	| case_list case_branch
		{ $$ = append_Cases($1,single_Cases($2)); }
	;

case_branch
	: OBJECTID ':' TYPEID DARROW expr ';'
		{ $$ = branch($1,$3,$5); }
	;

let_body
	: OBJECTID ':' TYPEID opt_init IN expr %prec LET_PREC
		{ $$ = let($1,$3,$4,$6); }
	| OBJECTID ':' TYPEID opt_init ',' let_body
		{ $$ = let($1,$3,$4,$6); }
	| error ',' let_body
		{ $$ = $3; }
	| error IN expr %prec LET_PREC
		{ $$ = $3; }
	;

expr
	: OBJECTID ASSIGN expr
		{ $$ = assign($1,$3); }
	| expr '@' TYPEID '.' OBJECTID '(' args ')'
		{ $$ = static_dispatch($1,$3,$5,$7); }
	| expr '.' OBJECTID '(' args ')'
		{ $$ = dispatch($1,$3,$5); }
	| OBJECTID '(' args ')'
		{ $$ = dispatch(object(SELF_SYM),$1,$3); }
	| IF expr THEN expr ELSE expr FI
		{ $$ = cond($2,$4,$6); }
	| WHILE expr LOOP expr POOL
		{ $$ = loop($2,$4); }
	| '{' expr_block_list '}'
		{ $$ = block($2); }
	| LET let_body
		{ $$ = $2; }
	| CASE expr OF case_list ESAC
		{ $$ = typcase($2,$4); }
	| NEW TYPEID
		{ $$ = new_($2); }
	| ISVOID expr
		{ $$ = isvoid($2); }
	| expr '+' expr
		{ $$ = plus($1,$3); }
	| expr '-' expr
		{ $$ = sub($1,$3); }
	| expr '*' expr
		{ $$ = mul($1,$3); }
	| expr '/' expr
		{ $$ = divide($1,$3); }
	| '~' expr
		{ $$ = neg($2); }
	| expr '<' expr
		{ $$ = lt($1,$3); }
	| expr LE expr
		{ $$ = leq($1,$3); }
	| expr '=' expr
		{ $$ = eq($1,$3); }
	| NOT expr
		{ $$ = comp($2); }
	| '(' expr ')'
		{ $$ = $2; }
	| OBJECTID
		{ $$ = object($1); }
	| INT_CONST
		{ $$ = int_const($1); }
	| STR_CONST
		{ $$ = string_const($1); }
	| BOOL_CONST
		{ $$ = bool_const($1); }
	;

/* end of grammar */
%%

/* This function is called automatically when Bison detects a parse error. */
void yyerror(const char *s)
{
  extern int curr_lineno;

  cerr << "\"" << curr_filename << "\", line " << curr_lineno << ": " \
    << s << " at or near ";
  print_cool_token(yychar);
  cerr << endl;
  omerrs++;

  if(omerrs>50) {fprintf(stdout, "More than 50 errors\n"); exit(1);}
}
