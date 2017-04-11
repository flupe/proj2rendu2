open Ast
open Print
open Structures

exception InterpretationError

let eval (env : constant Env.t) (k : 'a callback) (kE : 'a callback) e : unit =
  let rec step env k kE = function
    | Int c -> k env <| CInt c
    | Bool b -> k env <| CBool b
    | Unit -> k env <| CUnit

    | BinaryOp (op, l, r) ->
        let k' _ lc = 
        let k' _ rc =
          k env <|
          match lc, rc with
          | CInt lv, CInt rv -> begin
              match op with
              | Plus -> CInt (lv + rv)
              | Minus -> CInt (lv - rv)
              | Mult -> CInt (lv * rv)
              | Div -> CInt (lv / rv)
              | Mod -> CInt (lv mod rv)
              | Lt -> CBool (lv < rv)
              | Gt -> CBool (lv > rv)
              | Leq -> CBool (lv <= rv)
              | Geq -> CBool (lv >= rv)
              | Eq -> CBool (lv = rv)
              | Neq -> CBool (lv <> rv)
              | _ -> raise InterpretationError
            end

          | CBool lv, CBool rv -> begin
              match op with
              | Or -> CBool (lv || rv)
              | And -> CBool (lv && rv)
              | Eq -> CBool (lv = rv)
              | Neq -> CBool (lv <> rv)
              | _ -> raise InterpretationError
            end

          | CRef r, _ ->
              if op = SetRef then
                (* references cannot change type *)
                if equal_types rc !r then begin
                  r := rc;
                  CUnit
                end else raise InterpretationError
              else raise InterpretationError

          | _ -> raise InterpretationError
        in step env k' kE r
        in step env k' kE l

    | UnaryOp (op, e) ->
        let k' _ c =
          k env <|
          match c with
          | CBool b ->
              if op = Not then CBool (not b)
              else raise InterpretationError
          | CInt i ->
              if op = UMinus then CInt (-i)
              else raise InterpretationError
          | _ -> raise InterpretationError
        in step env k' kE e

    | Var id ->
        k env <|
        if Env.mem id env then
          Env.find id env
        else raise InterpretationError

    | IfThenElse (cond, truthy, falsy) ->
        let k' _ c = 
          match c with
          | CBool b ->
              if b then step env k kE truthy
              else step env k kE falsy
          | _ -> raise InterpretationError
        in step env k' kE cond

    | LetIn (id, e, fn) ->
        let k' _ c =
          let env' = Env.add id c env
          in step env' k kE fn
        in step env k' kE e

    | LetRecIn (id, e, fn) -> begin
        match e with
        | Fun (id', e') ->
            let f = CRec(id, id', e', env) in
            let env' = Env.add id f env in
            step env' k kE fn

        (* ain't recursive, or at least not in the way we allow *)
        | _ ->
            let k' _ c =
              let env' = Env.add id c env
              in step env' k kE fn
            in step env k' kE e
      end

    | Let (id, e) ->
        let k' _ c =
          let env' = Env.add id c env
          in k env' CUnit
        in step env k' kE e

    | LetRec (id, e) -> begin
        match e with
        | Fun (id', e') ->
            let f = CRec(id, id', e', env) in
            let env' = Env.add id f env in
            k env' CUnit

        (* ain't recursive, or at least not in the way we allow *)
        | _ ->
            let k' _ c =
              let env' = Env.add id c env
              in k env' CUnit
            in step env k' kE e
      end

    | Fun (id, e) ->
        k env <| CClosure (id, e, env)

    | Call (e, x) ->
        let k' _ fc =
          match fc with
          | CClosure (id, fn, env') ->
              let k' _ v = 
                let env' =
                  Env.add id v env'
                in step env' k kE fn
              in step env k' kE x

          | CRec (name, id, e, env') ->
              let k' _ v = 
                let env' =
                  env'
                  |> Env.add name fc
                  |> Env.add id v
                in step env' k kE e
              in step env k' kE x

          | _ -> raise InterpretationError
        in step env k' kE e

    | Ref e ->
        let k' _ v =
          k env <| CRef (ref v)
        in step env k' kE e

    | Deref e ->
        let k' _ v =
          match v with
          | CRef r -> k env !r
          | _ -> raise InterpretationError
        in step env k' kE e

    | Print e ->
        let k' _ v = 
          match v with
          | CInt i ->
              print_int i;
              print_newline ();
              k env v
          | _ -> raise InterpretationError
        in step env k' kE e

    | ArrayMake e ->
        let k' _ v = 
          match v with
          | CInt i when i >= 0 ->
              k env <| CArray (Array.make i 0)
          | _ -> raise InterpretationError
        in step env k' kE e

    | ArraySet (arr, key, v) ->
        let k' _ arr = 
          match arr with
          | CArray a ->
              let k' _ p =
                match p with
                | CInt p when p >= 0 ->
                  if p >= Array.length a then
                    raise InterpretationError
                  else
                  let k' _ v =
                    match v with
                    | CInt v ->
                        a.(p) <- v;
                        k env CUnit
                    | _ -> raise InterpretationError
                  in step env k' kE v
                | _ -> raise InterpretationError
              in step env k' kE key
          | _ -> raise InterpretationError
        in step env k' kE arr

    | ArrayRead (arr, key) ->
        let k' _ arr =
          match arr with
          | CArray a ->
              let k' _ p =
                match p with
                | CInt p when p >= 0 ->
                  if p >= Array.length a then
                    raise InterpretationError
                  else
                    k env <| CInt a.(p)
                | _ -> raise InterpretationError
              in step env k' kE key
          | _ -> raise InterpretationError
        in step env k' kE arr

    | Raise e ->
        step env kE kE e

    | TryWith (l, p, r) ->
        let kE' _ x = 
          (* pseudo pattern matching *)
          (* only allowed on ints or catch-all identifiers *)
          match p, x with
            | Int p, CInt v ->
                if p = v then
                  step env k kE r
                else
                  kE env x
            | Var id, _ ->
                let env' = Env.add id x env in
                step env' k kE r

            | _ -> raise InterpretationError
        in step env k kE' l

    | Seq (l, r) ->
        let k' _ lc =
          if lc = CUnit then
            step env k kE r
          else raise InterpretationError
        in step env k' kE l

  in let () = step env k kE e 
  in ()
