{
  open Parser
  exception Eof
}

let blank = [' ' '\r' '\t' '\n']
let digit = ['0'-'9']

rule token = parse
  | "begin" { BEGIN }
  | "end" { END }
  | "let" { LET }
  | "fun" { FUN }
  | "in" { IN }
  | "if" { IF }
  | "then" { THEN }
  | "else" { ELSE }
  | "try" { TRY }
  | "with" { WITH }
  | "raise" { RAISE }
  | 'E' { E }
  | ":=" { SETREF }
  | "rec" { REC }
  | "not" { NOT }
  | "->" { ARROW }
  | "&&" { AND }
  | "||" { OR }

  | "<>" { NEQ }
  | "<=" { LEQ }
  | ">=" { GEQ }

  | '(' { LPAREN }
  | ')' { RPAREN }
  | '+' { PLUS }
  | '-' { MINUS }
  | '*' { MULT }
  | '!' { BANG }

  | '=' { EQ }
  | '<' { LT }
  | '>' { GT }

  | ';' { SEMI }
  | ";;" { DELIM }

  | digit+ as s { INT(int_of_string s) }
  | ['_' 'a'-'z']['_' 'A'-'Z' 'a'-'z' '0'-'9' '\'']* as i { IDENT(i) }
  | blank { token lexbuf }

  | eof  { raise Eof }
