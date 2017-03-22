%{
  open Expr
%}

%token <string> IDENT
%token <int> INT
%token TRUE FALSE
%token LPAREN RPAREN
%token LET IN IF THEN ELSE DELIM FUN ARROW PRINT EOL
%token PLUS MINUS MULT OR AND LT GT LEQ GEQ EQ NOT NEQ

%start main
%type <Expr.expr> main

%left EQ NEQ LEQ GEQ LT GT
%left PLUS MINUS OR
%left MULT AND

%nonassoc NOT

%%

main:
  | expr DELIM { $1 }
  | expr EOL { $1 }

expr:
  | LPAREN expr RPAREN { $2 }

  | TRUE  { Constant (Bool true) }
  | FALSE { Constant (Bool false) }
  | INT   { Constant (Int $1) }

  | expr PLUS expr  { BinaryOp (Plus, $1, $3) }
  | expr MINUS expr { BinaryOp (Minus, $1, $3) }
  | expr MULT expr  { BinaryOp (Mult, $1, $3) }
  | expr OR expr    { BinaryOp (Or, $1, $3) }
  | expr AND expr   { BinaryOp (And, $1, $3) }
  | expr LT expr    { BinaryOp (Lt, $1, $3) }
  | expr GT expr    { BinaryOp (Gt, $1, $3) }
  | expr LEQ expr   { BinaryOp (Leq, $1, $3) }
  | expr GEQ expr   { BinaryOp (Geq, $1, $3) }

  | NOT expr   { UnaryOp (Not, $2) }

  | IDENT { Var $1 }

  | FUN IDENT ARROW expr { Fun ($2, $4) }

  | IF expr THEN expr           { IfThenElse ($2, $4, Constant Unit) }
  | IF expr THEN expr ELSE expr { IfThenElse ($2, $4, $6) }

  | LET IDENT EQ expr IN expr       { Let ($2, $4, $6) }
  | LET IDENT IDENT EQ expr IN expr { Let ($2, Fun ($3, $5), $7) }

  | expr expr { Call ($1, $2) }
  | PRINT expr { Print ($2) }
