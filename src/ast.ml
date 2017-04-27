type identifier =
  string

type constant =
  | Int  of int
  | Bool of bool
  | Unit 

type pattern =
  | PAll (* underscore, matches everything *)
  | PConst of constant
  | PField of identifier
  | PTuple  of pattern list

type t
  = Var  of identifier
  | Const of constant
  | Tuple of t list

  | Let of pattern * t
  | LetRec of identifier * t
  | LetIn of pattern * t * t
  | LetRecIn of identifier * t * t

  | IfThenElse of t * t * t
  | Fun of pattern * t
  | Call of t * t
  | TryWith of t * pattern * t
  | Raise of t
  | Seq of t * t
  | ArraySet of t * t * t
  | ArrayRead of t * t
