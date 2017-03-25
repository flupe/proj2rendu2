%{
  open Expr
%}

%token <string> IDENT
%token <int> INT
%token LPAREN RPAREN BEGIN END SEMI
%token LET IN IF THEN ELSE DELIM FUN ARROW PRINT REC
%token PLUS MINUS MULT OR AND LT GT LEQ GEQ EQ NOT NEQ

%token TRY WITH RAISE E
%token SETREF BANG

%start main

%type <Expr.expr> main
%type <Expr.expr> expr
%type <string list> list_of_idents

%nonassoc ELSE
%right SEMI
%right IN
%right ARROW
%left PLUS MINUS OR
%left MULT AND

%nonassoc NOT LET IF THEN DELIM FUN INT REF BANG SETREF
%nonassoc LPAREN RPAREN LT GT LEQ GEQ EQ NEQ IDENT
%nonassoc BEGIN END

%%

main:
  | expr DELIM { $1 }

list_of_idents:
  | { [] }
  | list_of_idents IDENT { $2 :: $1 }

expr:
  | { Constant Unit }

  | LET IDENT list_of_idents EQ expr IN expr {
      Let ($2, List.fold_left (fun e x -> Fun (x, e)) $5 $3, $7)
    }

  | FUN IDENT list_of_idents ARROW expr {
      Fun ($2, List.fold_left (fun e x -> Fun (x, e)) $5 $3)
    }

  | IF expr THEN expr ELSE expr { IfThenElse ($2, $4, $6) }
  /* | IF expr THEN expr { IfThenElse ($2, $4, Constant Unit) } */

  | TRY expr WITH E IDENT ARROW expr { TryWith ($2, $5, $7) }
  | RAISE enclosed { Raise $2 }

  | BANG expr { Call (Var "!", $2) }
  | expr SETREF expr   { BinaryOp (SetRef, $1, $3) }

  | NOT expr        { UnaryOp (Not, $2) }
  | expr PLUS expr  { BinaryOp (Plus, $1, $3) }
  | expr MINUS expr { BinaryOp (Minus, $1, $3) }
  | expr MULT expr  { BinaryOp (Mult, $1, $3) }
  | expr OR expr    { BinaryOp (Or, $1, $3) }
  | expr AND expr   { BinaryOp (And, $1, $3) }
  | expr LT expr    { BinaryOp (Lt, $1, $3) }
  | expr GT expr    { BinaryOp (Gt, $1, $3) }
  | expr LEQ expr   { BinaryOp (Leq, $1, $3) }
  | expr GEQ expr   { BinaryOp (Geq, $1, $3) }
  | expr EQ expr    { BinaryOp (Eq, $1, $3) }
  | expr NEQ expr   { BinaryOp (Neq, $1, $3) }

  | func { $1 }

func:
  | func enclosed { Call ($1, $2) }
  | enclosed { $1 }

enclosed:
  | BEGIN expr END { $2 }
  | LPAREN expr RPAREN { $2 }
  | INT   { Constant (Int $1) }
  | IDENT { Var $1 }

