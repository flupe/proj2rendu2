open Ast
open Print
open Shared

type value = Shared.value

let match_pattern = Interpreter.match_pattern

let rec eval_expr env expr =
  let rec aux env = function
    | Empty -> CList []
    | Const c -> CConst c

    | Var id ->
        if Env.mem id env then Env.find id env
        else raise InterpretationError

    | IfThenElse (cond, truthy, falsy) -> begin
        match aux env cond with
        | CConst (Bool b) ->
            aux env (if b then truthy else falsy)
        | _ -> raise InterpretationError
      end

    | Let (p, e, fn) ->
        let env' = match_pattern env p (aux env e) in aux env' fn

    (* no pattern matching for the 1rst token of recursive definitions *)
    | LetRec (id, e, fn) -> begin
        let f = CRec(id, e, env) in
        aux (Env.add id f env) fn
      end

    | Fun (pattern, e) -> CClosure (pattern, e, env)

    | Call (e, x) -> begin
        let fc = aux env e in  
        match fc with
        | CClosure (pattern, fn, env') ->
            let env' = match_pattern env pattern (aux env x) in aux env' fn

        | CRec (name, e, env') ->
            let env' = Env.add name fc env' in
            aux env' (Call (e, x))

        | CMetaClosure f -> f (aux env x)

        | _ -> raise InterpretationError
      end

    | ArraySet (arr, key, v) -> begin
        match aux env arr with
        | CArray a -> begin
            match aux env key with
            | CConst (Int p) when p >= 0 ->
                (* out of bounds *)
                if p >= Array.length a then raise InterpretationError
                else begin
                  match aux env v with
                  | CConst (Int v) -> a.(p) <- v; CConst Unit
                  | _ -> raise InterpretationError
                end
            | _ -> raise InterpretationError
          end
        | _ -> raise InterpretationError
      end

    | ArrayRead (arr, key) -> begin
        match aux env arr with
        | CArray a -> begin
            match aux env key with
            | CConst (Int p) when p >= 0 ->
                (* out of bounds *)
                if p >= Array.length a then raise InterpretationError
                else CConst (Int a.(p))
            | _ -> raise InterpretationError
          end
        | _ -> raise InterpretationError
      end

    | Seq (l, r) ->
        let lc = aux env l in
        if lc = CConst Unit then aux env r
        else raise InterpretationError

    | Tuple vl -> CTuple (List.map (aux env) vl)

    | TryWith _
    | Raise _ -> failwith "Exceptions not supported"
  in aux env expr

let make_interp exceptions references = (module struct
  let env = ref Shared.base
  let eval k kE e = k <| eval_expr !env e
  let bind id v = env := Env.add id v !env
end : Shared.Interp)
