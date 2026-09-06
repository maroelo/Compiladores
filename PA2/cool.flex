/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
 
%{
	#include <cool-parse.h>
	#include <stringtab.h>
	#include <utilities.h>

	/* The compiler assumes these identifiers. */
	#define yylval cool_yylval
	#define yylex  cool_yylex

	/* Max size of string constants */
	#define MAX_STR_CONST 1025
	#define YY_NO_UNPUT   /* keep g++ happy */

	extern FILE *fin; /* we read from this file */

	/* define YY_INPUT so we read from the FILE fin:
	* This change makes it possible to use this scanner in
	* the Cool compiler.
	*/
	#undef YY_INPUT
	#define YY_INPUT(buf,result,max_size) \
		if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
			YY_FATAL_ERROR( "read() in flex scanner failed");

	char string_buf[MAX_STR_CONST]; /* to assemble string constants */
	char *string_buf_ptr;

	extern int curr_lineno;
	extern int verbose_flag;

	extern YYSTYPE cool_yylval;

	/*
	*  Add Your own definitions here
	*/
%}

/*
 * Define names for regular expressions here.
 */

KEY_CLASS			(?i)class
KEY_INHERITS		(?i)inherits
KEY_LET				(?i)let
KEY_IN				(?i)in
KEY_IF				(?i)if
KEY_THEN			(?i)then
KEY_ELSE			(?i)else
KEY_FI				(?i)fi 						
KEY_WHILE			(?i)while
KEY_SELF			(?i)self 				
KEY_TRUE			t(?i)rue
KEY_FALSE			f(?i)alse
KEY_NOT				(?i)not
KEY_CASE			(?i)case
KEY_ESAC			(?i)esac
KEY_ISVOID			(?i)isvoid
KEY_LOOP			(?i)loop
KEY_POOL			(?i)pool
KEY_NEW				(?i)new


OBJECT_IDENTIFIERS 		[a-z][a-zA-Z0-9]*
TYPE_IDENTIFIERS 		[A-Z][a-zA-Z0-9]*

NUM_LITERAL 		[0-9]+

STRING_LITERAL 		"[a-zA-Z0-9\n\t]*"
	
OP_EQUALS			=
OP_PLUS				\+
OP_MINUS			-
OP_TIMES			\*
OP_DIVIDE			/
OP_LESSER			<
OP_LESSEREQ			<=
OP_ASSIGN			<-
OP_DISPATCH			@
OP_XOR				~


DELIM_DOT			\.
DELIM_COLON			:
DELIM_SEMICOLON		;
DELIM_COMMA			,
DELIM_LBRACE		\{
DELIM_RBRACE		\}
DELIM_LPAREN		\(
DELIM_RPAREN		\)

WS_NEWLINE			\n
WS_TAB				\t
COMMENT				\(\*[\w\s]*\*\)

%%
/*
 * Keywords are case-insensitive except for the values true and false,
 * which must begin with a lower-case letter.
 */

/*
 *  String constants (C syntax)
 *  Escape sequence \c is accepted for all characters c. Except for 
 *  \n \t \b \f, the result is c.
 */

/*
 *  Single-character operators and symbols.
 */

{OP_PLUS}	  			{ cool_yylval.symbol = stringtable.add_string(yytext); return (int)'+'; }
{OP_EQUALS}   			{ cool_yylval.symbol = stringtable.add_string(yytext); return (int)'='; }
{OP_MINUS}   			{ cool_yylval.symbol = stringtable.add_string(yytext); return (int)'-'; }
{OP_TIMES}   			{ cool_yylval.symbol = stringtable.add_string(yytext); return (int)'*'; }
{OP_DIVIDE}   			{ cool_yylval.symbol = stringtable.add_string(yytext); return (int)'/'; }
{OP_DISPATCH}   		{ cool_yylval.symbol = stringtable.add_string(yytext); return (int)'@'; }
{OP_XOR}   				{ cool_yylval.symbol = stringtable.add_string(yytext); return (int)'~'; }
{OP_LESSER}   			{ cool_yylval.symbol = stringtable.add_string(yytext); return (int)'<'; }

{DELIM_RPAREN}   		{ cool_yylval.symbol = stringtable.add_string(yytext); return (int)')'; }
{DELIM_LPAREN}   		{ cool_yylval.symbol = stringtable.add_string(yytext); return (int)'('; }
{DELIM_LBRACE}   		{ cool_yylval.symbol = stringtable.add_string(yytext); return (int)'{'; }
{DELIM_RBRACE}   		{ cool_yylval.symbol = stringtable.add_string(yytext); return (int)'}'; }
{DELIM_SEMICOLON}   	{ cool_yylval.symbol = stringtable.add_string(yytext); return (int)';'; }
{DELIM_COLON}   		{ cool_yylval.symbol = stringtable.add_string(yytext); return (int)':'; }
{DELIM_COMMA}   		{ cool_yylval.symbol = stringtable.add_string(yytext); return (int)','; }
{DELIM_DOT}   			{ cool_yylval.symbol = stringtable.add_string(yytext); return (int)'.'; }

{NUM_LITERAL} {
	cool_yylval.symbol = inttable.add_string(yytext);
	return INT_CONST;
}
%%