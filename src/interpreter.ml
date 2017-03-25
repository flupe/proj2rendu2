open Expr

module Env = Map.Make(struct
  type t = identifier
  let compare = Pervasives.compare
end)

exception InterpretationError

(* eval : expr -> constant *)
let eval e =
  let env = Env.empty in

  let rec step env = function
    | Constant c -> c

    | BinaryOp (op, l, r) -> begin
        let lc = step env l in
        let rc = step env r in

        match lc, rc with
        | Int lv, Int rv -> begin
            match op with
            | Plus -> Int (lv + rv)
            | Minus -> Int (lv - rv)
            | Mult -> Int (lv * rv)
            | Lt -> Bool (lv < rv)
            | Gt -> Bool (lv > rv)
            | Leq -> Bool (lv <= rv)
            | Geq -> Bool (lv >= rv)
            | _ -> raise InterpretationError
          end

        | Bool lv, Bool rv -> begin
            match op with
            | Or -> Bool (lv || rv)
            | And -> Bool (lv && rv)
            | _ -> raise InterpretationError
          end

        (* todo: handle refs *)

        | _ -> raise InterpretationError
      end

    | UnaryOp (op, e) -> begin
        let c = step env e in
        match c with
        | Bool b ->
            if op = Not then Bool (not b)
            else raise InterpretationError
        | _ -> raise InterpretationError
      end

    | Var id ->
        if Env.mem id env then
          Env.find id env
        else raise InterpretationError

    | Let (id, e, fn) ->
        let c = step env e in
        let env' = Env.add id c env in
        step env' fn

    | Call (e, x) -> begin
        let fc = step env e in
        match fc with
        | Fun (id, fn) ->
            let v = step env x in
            let env' = Env.add id v env in
            step env' e

        | _ -> raise InterpretationError
      end

    | _ -> Unit
  in

  step env e
