open Types

exception TypeCheckError of string

type type_variable_id = int
type type_struct =
  | UnitType
  | IntType
  | StringType
  | BoolType
  | FuncType of type_struct * type_struct
  | TypeVariable of type_variable_id

type type_environment = (var_name, type_struct) Hashtbl.t
type type_equation = ((type_struct * type_struct) Stacklist.t) ref

let print_process msg = (* print_string (msg ^ "\n") ; *) ()

let rec string_of_type_struct tystr =
  match tystr with
  | UnitType -> "unit"
  | IntType -> "int"
  | StringType -> "string"
  | BoolType -> "bool"
  | FuncType(tyf, tyl) -> "(" ^ (string_of_type_struct tyf) ^ " -> " ^ (string_of_type_struct tyl) ^ ")"
  | TypeVariable(tvid) -> "'" ^ (string_of_int tvid)

let find_real_type theta tvid =
  ( print_process ("  *seeking '" ^ (string_of_int tvid) ^ "\n") ;
    Hashtbl.find theta tvid )

let tvidmax : type_variable_id ref = ref 0
let new_type_variable () = 
  let res = TypeVariable(!tvidmax) in
  ( print_process ("  *make '" ^ (string_of_int !tvidmax) ^ "\n") ;
    tvidmax := !tvidmax + 1 ;
    res
  )
let rec equivalent tya tyb =
  match (tya, tyb) with
  | (UnitType, UnitType)     -> true
  | (IntType, IntType)       -> true
  | (StringType, StringType) -> true
  | (BoolType, BoolType)     -> true
  | (FuncType(tyadom, tyacod), FuncType(tybdom, tybcod))
      -> (equivalent tyadom tybdom) && (equivalent tyacod tybcod)
  | (TypeVariable(tvida), TypeVariable(tvidb)) -> (tvida == tvidb)
  | _ -> false

(* type_environment -> Types.abstract_tree -> type_struct *)
let rec typecheck tyeq tyenv abstr =
  match abstr with
  | NumericEmpty -> IntType
  | StringEmpty -> StringType
  | NumericConstant(_) -> IntType
  | StringConstant(_) -> StringType

  | ContentOf(nv) ->
      ( try
          let ty = Hashtbl.find tyenv nv in
          ( 
              print_process ("  " ^ nv ^ ": <" ^ string_of_type_struct ty ^ ">") ;
            
            ty )
        with
        | Not_found -> raise (TypeCheckError("undefined variable '" ^ nv ^ "'"))
      )

  | ConcatOperation(astf, astl) ->
      let tyf = typecheck tyeq tyenv astf in
      let tyl = typecheck tyeq tyenv astl in
      ( ( if equivalent StringType tyf then () else Stacklist.push tyeq (StringType, tyf) ) ;
        ( if equivalent StringType tyl then () else Stacklist.push tyeq (StringType, tyl) ) ;
        StringType
      )

  | Concat(astf, astl) ->
      let tyf = typecheck tyeq tyenv astf in
      let tyl = typecheck tyeq tyenv astl in
      ( ( if equivalent StringType tyf then () else Stacklist.push tyeq (StringType, tyf) ) ;
        ( if equivalent StringType tyl then () else Stacklist.push tyeq (StringType, tyl) ) ;
        StringType
      )

  | NumericApply(astf, astl) ->
      let tyf = typecheck tyeq tyenv astf in
      let tyl = typecheck tyeq tyenv astl in
      ( match tyf with
        | FuncType(tydom, tycod) ->
            ( ( if equivalent tydom tyl then () else Stacklist.push tyeq (tydom, tyl) ) ;
              tycod
            )
        | _ -> let ntycod = new_type_variable () in
            ( Stacklist.push tyeq (tyf, FuncType(tyl, ntycod)) ;
              ntycod
            )
      )
(*
  | StringApply(csnm, _, _, argcons) ->
      typecheck tyeq tyenv (convert_into_numeric_apply csnm argcons)
*)
  | BreakAndIndent -> StringType
  | DeeperIndent(astf) ->
      let tyf = typecheck tyeq tyenv astf in
      ( ( if equivalent StringType tyf then () else Stacklist.push tyeq (StringType, tyf) ) ;
        StringType
      )

  | Times(astf, astl) ->
      let tyf = typecheck tyeq tyenv astf in
      let tyl = typecheck tyeq tyenv astl in
      ( ( if equivalent IntType tyf then () else Stacklist.push tyeq (IntType, tyf) ) ;
        ( if equivalent IntType tyl then () else Stacklist.push tyeq (IntType, tyl) ) ;
        IntType
      )

  | Divides(astf, astl) ->
      let tyf = typecheck tyeq tyenv astf in
      let tyl = typecheck tyeq tyenv astl in
      ( ( if equivalent IntType tyf then () else Stacklist.push tyeq (IntType, tyf) ) ;
        ( if equivalent IntType tyl then () else Stacklist.push tyeq (IntType, tyl) ) ;
        IntType
      )

  | Mod(astf, astl) ->
      let tyf = typecheck tyeq tyenv astf in
      let tyl = typecheck tyeq tyenv astl in
      ( ( if equivalent IntType tyf then () else Stacklist.push tyeq (IntType, tyf) ) ;
        ( if equivalent IntType tyl then () else Stacklist.push tyeq (IntType, tyl) ) ;
        IntType
      )

  | Plus(astf, astl) ->
      let tyf = typecheck tyeq tyenv astf in
      let tyl = typecheck tyeq tyenv astl in
      ( ( if equivalent IntType tyf then () else Stacklist.push tyeq (IntType, tyf) ) ;
        ( if equivalent IntType tyl then () else Stacklist.push tyeq (IntType, tyl) ) ;
        IntType
      )

  | Minus(astf, astl) ->
      let tyf = typecheck tyeq tyenv astf in
      let tyl = typecheck tyeq tyenv astl in
      ( ( if equivalent IntType tyf then () else Stacklist.push tyeq (IntType, tyf) ) ;
        ( if equivalent IntType tyl then () else Stacklist.push tyeq (IntType, tyl) ) ;
        IntType
      )

  | GreaterThan(astf, astl) ->
      let tyf = typecheck tyeq tyenv astf in
      let tyl = typecheck tyeq tyenv astl in
      ( ( if equivalent IntType tyf then () else Stacklist.push tyeq (IntType, tyf) ) ;
        ( if equivalent IntType tyl then () else Stacklist.push tyeq (IntType, tyl) ) ;
        BoolType
      )

  | LessThan(astf, astl) ->
      let tyf = typecheck tyeq tyenv astf in
      let tyl = typecheck tyeq tyenv astl in
      ( ( if equivalent IntType tyf then () else Stacklist.push tyeq (IntType, tyf) ) ;
        ( if equivalent IntType tyl then () else Stacklist.push tyeq (IntType, tyl) ) ;
        BoolType
      )

  | EqualTo(astf, astl) ->
      let tyf = typecheck tyeq tyenv astf in
      let tyl = typecheck tyeq tyenv astl in
      (
        ( match (tyf, tyl) with
          | (FuncType(_, _), _) -> raise (TypeCheckError("cannot compare functions using '=='"))
          | (_, FuncType(_, _)) -> raise (TypeCheckError("cannot compare functions using '=='"))
          | (UnitType, _) -> raise (TypeCheckError("cannot compare units using '=='"))
          | (_, UnitType) -> raise (TypeCheckError("cannot compare units using '=='"))
          | _ -> ()
        ) ;
        ( if equivalent tyf tyl then () else Stacklist.push tyeq (tyf, tyl) ) ;
        BoolType
      )

  | LogicalAnd(astf, astl) ->
      let tyf = typecheck tyeq tyenv astf in
      let tyl = typecheck tyeq tyenv astl in
      ( ( if equivalent BoolType tyf then () else Stacklist.push tyeq (BoolType, tyf) ) ;
        ( if equivalent BoolType tyl then () else Stacklist.push tyeq (BoolType, tyl) ) ;
        BoolType
      )

  | LogicalOr(astf, astl) ->
      let tyf = typecheck tyeq tyenv astf in
      let tyl = typecheck tyeq tyenv astl in
      ( ( if equivalent BoolType tyf then () else Stacklist.push tyeq (BoolType, tyf) ) ;
        ( if equivalent BoolType tyl then () else Stacklist.push tyeq (BoolType, tyl) ) ;
        BoolType
      )

  | LogicalNot(astf) ->
      let tyf = typecheck tyeq tyenv astf in
      ( ( if equivalent BoolType tyf then () else Stacklist.push tyeq (BoolType, tyf) ) ;
        BoolType
      )

  | LetIn(nv, astf, astl) ->
    ( print_process "#LetIn" ;
      let tyenv_new = Hashtbl.copy tyenv in
      let ntv = new_type_variable () in
      ( Hashtbl.add tyenv_new nv ntv ;
        let tyf = typecheck tyeq tyenv_new astf in
        ( Stacklist.push tyeq (ntv, tyf) ;
          let tyl = typecheck tyeq tyenv_new astl in
          ( Hashtbl.clear tyenv_new ;
            tyl
          )
        )
      )
    )

  | IfThenElse(astb, astf, astl) ->
      let tyb = typecheck tyeq tyenv astb in
      let tyf = typecheck tyeq tyenv astf in
      let tyl = typecheck tyeq tyenv astl in
      ( ( if equivalent BoolType tyb then () else Stacklist.push tyeq (BoolType, tyb) ) ;
        ( if equivalent tyf tyl then () else Stacklist.push tyeq (tyf, tyl) ) ;
        tyf
      )

  | LambdaAbstract(varnm, astdef) ->
    ( print_process "#LambdaAbstract" ;
      let tyvar = new_type_variable () in
      let tyenv_new = Hashtbl.copy tyenv in
      ( Hashtbl.add tyenv_new varnm tyvar ;
        let tydef = typecheck tyeq tyenv_new astdef in
          FuncType(tyvar, tydef)
      )
      (* assign_lambda_abstract_type tyeq tyenv argvarcons astdef *)
    )

  | _ -> raise (TypeCheckError("remains to be implemented"))

(*
(* type_equation -> type_environment -> type_struct -> argument_cons -> type_struct *)
and deal_with_string_apply tyeq tyenv tycs argcons =
    print_string "deal_with_string_apply" ;
    match (tycs, argcons) with
    | (tya, EndOfArgument) -> 
        ( ( if equivalent tya StringType then () else Stacklist.push tyeq (tya, StringType) ) ;
          StringType
        )
    | (FuncType(tydom, tycod), ArgumentCons(astofarg, actail)) ->
        let tyarg = typecheck tyeq tyenv astofarg in
        ( ( if equivalent tydom tyarg then () else Stacklist.push tyeq (tydom, tyarg) ) ;
          deal_with_string_apply tyeq tyenv tycod actail
        )
    | (TypeVariable(tvid), ArgumentCons(astofarg, actail)) ->
        let tydom = typecheck tyeq tyenv astofarg in
        let ntycod = new_type_variable () in
        let tyafter = deal_with_string_apply tyeq tyenv ntycod argcons in
        ( Stacklist.push tyeq (TypeVariable(tvid), FuncType(tydom, ntycod)) ;
          tyafter
        )

    | (_, _) -> raise (TypeCheckError("error 4"))

(* type_equation -> argument_variable_cons -> abstract_tree -> type_struct *)
and assign_lambda_abstract_type tyeq tyenv argvarcons astf =
  match argvarcons with
  | EndOfArgumentVariable -> typecheck tyeq tyenv astf
  | ArgumentVariableCons(av, avcsub) ->
      let ntv = new_type_variable () in
      let tyenv_new = Hashtbl.copy tyenv in
      ( Hashtbl.add tyenv_new av ntv ;
        let res = FuncType(ntv, assign_lambda_abstract_type tyeq tyenv_new avcsub astf) in
        ( Hashtbl.clear tyenv_new ; res )
      )
*)

(* type_variable_id -> type_struct -> bool *)
let rec emerge_in tyid tystr =
  match tystr with
  | TypeVariable(tyidsub) -> tyid == tyidsub
  | FuncType(tydom, tycod) -> (emerge_in tyid tydom) || (emerge_in tyid tycod)
  | _ -> false

(* ((type_variable_id, type_struct) Hashtbl.t) -> type_struct -> type_struct *)
let rec subst_type_by_theta theta tystr =
  match tystr with
  | TypeVariable(tvid) -> ( try find_real_type theta tvid with Not_found -> TypeVariable(tvid) )
  | FuncType(tydom, tycod) -> FuncType(subst_type_by_theta theta tydom, subst_type_by_theta theta tycod)
  | tys -> tys

let rec subst_list theta tyeqlst =
  match tyeqlst with
  | [] -> []
  | (tya, tyb) :: tail -> ((subst_type_by_theta theta tya), (subst_type_by_theta theta tyb)) :: (subst_list theta tail)

let rec string_of_tyeqlst tyeqlst =
  match tyeqlst with
  | [] -> ""
  | (tya, tyb) :: tail ->
      "<" ^ (string_of_type_struct tya) ^ "> = <" ^ (string_of_type_struct tyb) ^ ">\n"
        ^ (string_of_tyeqlst tail)

(* (type_struct * type_struct) -> ((type_variable_id, type_struct) Hashtbl.t) -> unit *)
let rec solve tyeqlst theta =
  (* uncommentout below if you would like to see recognized type equations *)

  print_string (string_of_tyeqlst tyeqlst) ;

  match tyeqlst with
  | [] -> ()
  | (tya, tyb) :: tail ->
      if equivalent tya tyb then
        solve tail theta
      else
      ( match (tya, tyb) with
        | (FuncType(tyadom, tyacod), FuncType(tybdom, tybcod)) ->
            solve ((tyadom, tybdom) :: (tyacod, tybcod) :: tail) theta

        | (TypeVariable(tvid), tystr) ->
            ( if emerge_in tvid tystr then
                raise (TypeCheckError("error 1"))
              else
              ( print_string ("  $subst '" ^ (string_of_int tvid) ^ " := " ^ (string_of_type_struct tystr) ^ "\n") ;
                Hashtbl.add theta tvid tystr ;
                solve (subst_list theta tail) theta )
            )
        | (_, TypeVariable(tvidb)) ->
            solve ((tyb, tya) :: tail) theta
              (*  this pattern matching must be after (TypeVariable(tvid), tystr)
                  in order to avoid endless loop
                  (TypeVariable(_), TypeVariable(_)) causes *)

        | (_, _) -> raise (TypeCheckError("error 2"))
      )


(* type_equation -> ((type_variable_id, type_struct) Hashtbl.t) -> unit *)
let unify_type_variables tyeq theta =
  let tyeqlst = Stacklist.to_list !tyeq in solve tyeqlst theta

(* ((type_variable_id, type_struct) Hashtbl.t) -> type_struct -> type_struct *)
let rec unify theta ty =
  match ty with
  | FuncType(tydom, tycod) -> FuncType(unify theta tydom, unify theta tycod)
  | TypeVariable(tvid) -> ( try find_real_type theta tvid with Not_found -> TypeVariable(tvid) )
  | tystr -> tystr

(* Types.abstract_tree -> string *)
let main ast =
  let tyeq : type_equation = ref Stacklist.empty in
  let tyenv : type_environment = Hashtbl.create 128 in
  let theta : (type_variable_id, type_struct) Hashtbl.t = Hashtbl.create 128 in
  ( tvidmax := 0 ;
    let type_before_unified = typecheck tyeq tyenv ast in
    ( unify_type_variables tyeq theta ;
      string_of_type_struct (subst_type_by_theta theta type_before_unified)
    )
  )