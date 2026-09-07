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

	static int comment_depth = 0;					// Counter for nested comments

	static int null_char_in_string = 0;			
	static int curr_buf_len = 0;	
%}

 /*
 * Define names for regular expressions here.
 */


KEY_CLASS			[Cc][Ll][Aa][Ss][Ss]   
KEY_INHERITS		[Ii][Nn][Hh][Ee][Rr][Ii][Tt][Ss]
KEY_LET				[Ll][Ee][Tt]
KEY_IN				[Ii][Nn]
KEY_IF				[Ii][Ff]
KEY_THEN			[Tt][Hh][Ee][Nn]
KEY_ELSE			[Ee][Ll][Ss][Ee]
KEY_FI				[Ff][Ii]
KEY_WHILE			[Ww][Hh][Ii][Ll][Ee]
KEY_SELF			[Ss][Ee][Ll][Ff]
KEY_TRUE			t[Rr][Uu][Ee]
KEY_FALSE			f[Aa][Ll][Ss][Ee]
KEY_NOT				[Nn][Oo][Tt]
KEY_CASE			[Cc][Aa][Ss][Ee]
KEY_ESAC			[Ee][Ss][Aa][Cc]
KEY_ISVOID			[Ii][Ss][Vv][Oo][Ii][Dd]
KEY_LOOP			[Ll][Oo][Oo][Pp]
KEY_POOL			[Pp][Oo][Oo][Ll]
KEY_NEW				[Nn][Ee][Ww]
KEY_OF				[Oo][Ff]

OBJECT_IDENTIFIERS 		[a-z][a-zA-Z0-9_]*
TYPE_IDENTIFIERS 		[A-Z][a-zA-Z0-9_]*

NUM_LITERAL 		[0-9]+
	
OP_EQUALS			=
OP_PLUS				\+
OP_MINUS			-
OP_TIMES			\*
OP_DIVIDE			\/
OP_LESSER			<
OP_LESSEREQ			<=
OP_ASSIGN			<-
OP_DISPATCH			@
OP_NEG				~
OP_DARROW			=>


DELIM_DOT			\. 
DELIM_COLON			:
DELIM_SEMICOLON		;
DELIM_COMMA			,
DELIM_LBRACE		\{
DELIM_RBRACE		\}
DELIM_LPAREN		\(
DELIM_RPAREN		\)

WHITESPACES 		[ \t\f\r\v]+

%x comment str

%%

 /*
  * Whitespaces
  */
{WHITESPACES} 		{}
\n					{ curr_lineno++; }


 /*
  * Comments and Nested Comments
  */
--.*				{}
\*\)                { 
						cool_yylval.error_msg = "Unmatched *)."; 
						return (ERROR); 
					}
\(\*				{ 
						comment_depth = 1; 
						BEGIN(comment); 
					}

<comment>{
    \n          	{ curr_lineno++; }
	\(\*        	{ comment_depth++; }
    \*\)        	{ 
                  		comment_depth--;
                  		if (comment_depth == 0) { BEGIN(INITIAL); }
                	}
    <<EOF>>     	{
                  		BEGIN(INITIAL);
                  		cool_yylval.error_msg = "EOF in comment";
                  		return (ERROR);
                	}
    .           	{}
}


 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{KEY_CLASS}			{ return (CLASS); }
{KEY_INHERITS}		{ return (INHERITS); }
{KEY_LET}			{ return (LET); }
{KEY_IN}			{ return (IN); }
{KEY_IF}			{ return (IF); }
{KEY_THEN}			{ return (THEN); }
{KEY_ELSE}			{ return (ELSE); }
{KEY_FI}			{ return (FI); }
{KEY_WHILE}			{ return (WHILE); }
{KEY_NOT}			{ return (NOT); }
{KEY_CASE}			{ return (CASE); }
{KEY_ESAC}			{ return (ESAC); }
{KEY_ISVOID}		{ return (ISVOID); }
{KEY_LOOP}			{ return (LOOP); }
{KEY_POOL}			{ return (POOL); }
{KEY_NEW}			{ return (NEW); }
{KEY_OF}			{ return (OF); }

{KEY_TRUE}			{ cool_yylval.boolean = 1; return (BOOL_CONST); }
{KEY_FALSE}			{ cool_yylval.boolean = 0; return (BOOL_CONST); }
 
 /*
  *  The multiple-character operators.
  */
{OP_DARROW}			{ return(DARROW); }
{OP_LESSEREQ}		{ return(LE); }
{OP_ASSIGN}			{ return(ASSIGN); }


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  */

\" 					{ 
						string_buf_ptr = string_buf;
						curr_buf_len = 0;

						null_char_in_string = 0;
						
						BEGIN(str); 
					}

<str>{
	\"				{
						BEGIN(INITIAL);
						*string_buf_ptr = '\0';

						if (null_char_in_string) {
							cool_yylval.error_msg = "String contains null character";
							return (ERROR);
						} else if (curr_buf_len >= MAX_STR_CONST) {
							cool_yylval.error_msg = "String constant too long";
							return (ERROR);
						} else {
							cool_yylval.symbol = stringtable.add_string(string_buf);
							return (STR_CONST);
						}
					}
	\n          	{
                  		BEGIN(INITIAL);
                  		curr_lineno++;
                  		cool_yylval.error_msg = "Unterminated string constant";
                  		return (ERROR);
                	}
	\0				{
						null_char_in_string = 1;
					}
	\\0				{
						if (curr_buf_len < MAX_STR_CONST) {
							*string_buf_ptr++ = '0';
							curr_buf_len++;
						}
					}
	\\n   			{ 
						if (curr_buf_len < MAX_STR_CONST) { 
							*string_buf_ptr++ = '\n';
							curr_buf_len++; 
						} 
					}
	\\t   			{ 
						if (curr_buf_len < MAX_STR_CONST)	{ 
							*string_buf_ptr++ = '\t'; 
							curr_buf_len++;
						}
					}
	\\b   			{ 
						if (curr_buf_len < MAX_STR_CONST) { 
							*string_buf_ptr++ = '\b'; 
							curr_buf_len++; 
						} 
					}
	\\f   			{ 
						if (curr_buf_len < MAX_STR_CONST) { 
							*string_buf_ptr++ = '\f';
							curr_buf_len++; 
						} 
					}
	\\.   			{ 
						if (curr_buf_len < MAX_STR_CONST) { 
							*string_buf_ptr++ = yytext[0]; 
							curr_buf_len++; 
						} 
					}
	.				{
						if (curr_buf_len < MAX_STR_CONST) {
							*string_buf_ptr = yytext[0];
							string_buf_ptr++;
							curr_buf_len++;
						}
					}
}


 /*
  *  Single-character operators and symbols.
  */
{OP_PLUS}	  		{ return (int)'+'; }
{OP_EQUALS}   		{ return (int)'='; }
{OP_MINUS}   		{ return (int)'-'; }
{OP_TIMES}   		{ return (int)'*'; }
{OP_DIVIDE}   		{ return (int)'/'; }
{OP_DISPATCH}   	{ return (int)'@'; }
{OP_NEG}   			{ return (int)'~'; }
{OP_LESSER}   		{ return (int)'<'; }

{DELIM_RPAREN}   	{ return (int)')'; }
{DELIM_LPAREN}   	{ return (int)'('; }
{DELIM_LBRACE}   	{ return (int)'{'; }
{DELIM_RBRACE}   	{ return (int)'}'; }
{DELIM_SEMICOLON}   { return (int)';'; }
{DELIM_COLON}   	{ return (int)':'; }
{DELIM_COMMA}   	{ return (int)','; }
{DELIM_DOT}   		{ return (int)'.'; }

 /*
  * Integer constants.
  */
{NUM_LITERAL} 		{
						cool_yylval.symbol = inttable.add_string(yytext);
						return INT_CONST;
					}

 /*
  * Identifiers.
  */
{OBJECT_IDENTIFIERS} {
						cool_yylval.symbol = idtable.add_string(yytext);
						return (OBJECTID);
					 }

{TYPE_IDENTIFIERS}	{
						cool_yylval.symbol = idtable.add_string(yytext);
						return (TYPEID);
					}

 /*
  * Invalid characters
  * If a character doesn't match with any rule above, than it's not a valid character in this language
  * . -> matches every single character
  */
. 					{
						cool_yylval.error_msg = yytext;
						return (ERROR);
					}
%%