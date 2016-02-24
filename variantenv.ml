open Types

type definition_kind   = Data of int | Hidden of int | Synonym of int * type_struct
type defined_type_list = (type_name * definition_kind) list
type constructor_list  = (constructor_name * type_name * type_struct) list
type t = defined_type_list * constructor_list


let empty = ([], [])


let rec add (varntenv : t) (constrnm : constructor_name) (tystr : type_struct) (varntnm : type_name) =
  let (defedtylst, varntenvmain) = varntenv in
    (defedtylst, add_main varntenvmain constrnm tystr varntnm)

and add_main (varntenvmain : constructor_list) (constrnm : constructor_name) (tystr : type_struct) (varntnm : type_name) =
  match varntenvmain with
  | []                -> [(constrnm, varntnm, tystr)]
  | (c, v, t) :: tail ->
      if c = constrnm then
        (constrnm, varntnm, tystr) :: tail
      else
        (c, v, t) :: (add_main tail constrnm tystr varntnm)


let rec find_definition_kind (defedtylst : defined_type_list) (tynm : type_name) =
  match defedtylst with
  | []                            -> raise Not_found
  | (tn, ts) :: tl when tn = tynm -> ts
  | _ :: tl                       -> find_definition_kind tl tynm


let rec is_defined_type_argument (tyargcons : untyped_type_argument_cons) (tyargnm : var_name) =
  match tyargcons with
  | UTEndOfTypeArgument                 -> false
  | UTTypeArgumentCons(_, nm, tailcons) ->
      if nm = tyargnm then true else is_defined_type_argument tailcons tyargnm


let rec check_type_defined (varntenv : t) (tyargcons : untyped_type_argument_cons) (tystr : type_struct) =
  let (defedtylst, varntenvmain) = varntenv in
  let f = check_type_defined varntenv tyargcons in
    match tystr with
    | FuncType(rng, tydom, tycod)          -> FuncType(rng, f tydom, f tycod)
    | ListType(rng, tycont)                -> ListType(rng, f tycont)
    | RefType(rng, tycont)                 -> RefType(rng, f tycont)
    | ProductType(rng, tylist)             -> ProductType(rng, List.map f tylist)
    | VariantType(rng, tyarglist, tynm)    ->
        begin
          try
            match find_definition_kind defedtylst tynm with
            | Synonym(argnum, tystr)          ->
                let len = List.length tyarglist in
                  if argnum = len then
                    TypeSynonym(rng, tyarglist, tynm, tystr)
                  else
                    Display.report_error_with_range rng [
                      "type synonym '" ^ tynm ^ "' is expected to have " ^ (string_of_int argnum) ^ " type argument(s)," ;
                      "but it has " ^ (string_of_int len) ^ " type argument(s) here"
                    ]
            | (Data(argnum) | Hidden(argnum)) ->
                let len = List.length tyarglist in
                  if argnum = len then
                    VariantType(rng, tyarglist, tynm)
                  else
                    Display.report_error_with_range rng [
                      "variant type '" ^ tynm ^ "' is expected to have " ^ (string_of_int argnum) ^ " type argument(s)," ;
                      "but it has " ^ (string_of_int len) ^ " type argument(s) here"
                    ]
          with
          | Not_found -> Display.report_error_with_range rng ["undefined type '" ^ tynm ^ "'"]
        end

    | TypeArgument(rng, tyargnm)           ->
          if is_defined_type_argument tyargcons tyargnm then
            TypeArgument(rng, tyargnm)
          else
            Display.report_error_with_range rng ["undefined type argument '" ^ tyargnm ^ "'"]

    | other                                -> other


let rec make_type_argument_quantified (var_id : int) (tyargcons : untyped_type_argument_cons) (tystr : type_struct) =
  match tyargcons with
  | UTEndOfTypeArgument                        -> tystr
  | UTTypeArgumentCons(rng, tyargnm, tailcons) ->
      let tystr_new = ForallType(-var_id, make_type_argument_numbered var_id tyargnm tystr) in
        make_type_argument_quantified (var_id + 1) tailcons tystr_new

and make_type_argument_numbered (var_id : int) (tyargnm : var_name) (tystr : type_struct) =
  let f = make_type_argument_numbered var_id tyargnm in
  match tystr with
  | TypeArgument(rng, nm)
                    when nm = tyargnm -> TypeVariable(rng, -var_id)
  | FuncType(rng, tydom, tycod)       -> FuncType(rng, f tydom, f tycod)
  | ListType(rng, tycont)             -> ListType(rng, f tycont)
  | RefType(rng, tycont)              -> RefType(rng, f tycont)
  | ProductType(rng, tylist)          -> ProductType(rng, List.map f tylist)
  | ForallType(tvid, tycont)          -> ForallType(tvid, f tycont)
      (* maybe contains bugs, when tvid = -var_id *)
  | VariantType(rng, tylist, varntnm) -> VariantType(rng, List.map f tylist, varntnm)
  | other                             -> other


let append_module_name mdlnm varntnm =
  match mdlnm with
  | "" -> varntnm
  | _  -> mdlnm ^ "." ^ varntnm


let rec type_argument_length tyargcons =
  match tyargcons with
  | UTEndOfTypeArgument                -> 0
  | UTTypeArgumentCons(_, _, tailcons) -> 1 + (type_argument_length tailcons)


let add_variant (varntenv :t) (tyargcons : untyped_type_argument_cons) (tynm : type_name) =
  let len = type_argument_length tyargcons in
  let (defedtypelist, varntenvmain) = varntenv in
    ((tynm, Data(len)) :: defedtypelist, varntenvmain)


let add_hidden_type (mdlnm : module_name) (varntenv : t) (tyargcons : untyped_type_argument_cons) (tynm : type_name) =
  let len = type_argument_length tyargcons in
  let (defedtypelist, varntenvmain) = varntenv in
    ((append_module_name mdlnm tynm, Hidden(len)) :: defedtypelist, varntenvmain)


let add_synonym (varntenv : t) (tyargcons : untyped_type_argument_cons) (tysynnm : type_name) (tystr : type_struct) =
  let len = type_argument_length tyargcons in
  let (defedtypelist, varntenvmain) = varntenv in
  let tystr_new    = check_type_defined varntenv tyargcons tystr in
  let tystr_forall = make_type_argument_quantified 1 tyargcons tystr_new in
    ((tysynnm, Synonym(len, tystr_forall)) :: defedtypelist, varntenvmain)


let rec apply_to_type_synonym (tyarglist : type_struct list) (tystr : type_struct) =
  match (tystr, tyarglist) with
  | (ForallType(tvid, tycont), tyarghd :: tyargtl) -> apply_to_type_synonym tyargtl (Typeenv.replace_id [(tvid, tyarghd)] tycont)
  | (_, [])                                        -> tystr
  | _                                              -> assert false


(* discarded *)
let add_type_synonym (varntenv : t) (tynm : type_name) (tystr : type_struct) =
  let (defedtypelist, varntenvmain) = varntenv in
  let tystr_new = check_type_defined varntenv UTEndOfTypeArgument tystr in
    ((tynm, Synonym(0, tystr_new)) :: defedtypelist, varntenvmain)


let rec add_variant_cons (mdlnm : module_name) (varntenv : t)
                           (tyargcons : untyped_type_argument_cons) (varntnm : type_name) (utvc : untyped_variant_cons) =
    add_variant_cons_main mdlnm (add_variant varntenv tyargcons varntnm) tyargcons varntnm utvc

and add_variant_cons_main (mdlnm : module_name) (varntenv : t)
                            (tyargcons : untyped_type_argument_cons) (varntnm : type_name) (utvc : untyped_variant_cons) =
  let (rng, utvcmain) = utvc in
    match utvcmain with
    | UTEndOfVariant                           -> varntenv
    | UTVariantCons(constrnm, tystr, tailcons) ->
        let tystr_new    = check_type_defined varntenv tyargcons tystr in
        let tystr_forall = make_type_argument_quantified 1 tyargcons tystr_new in
        let varntenv_new = add varntenv constrnm tystr_forall (append_module_name mdlnm varntnm) in
          add_variant_cons_main mdlnm varntenv_new tyargcons varntnm tailcons


let rec add_mutual_cons (varntenv : t) (mutvarntcons : untyped_mutual_variant_cons) =
  let varntenv_new = add_mutual_type "" varntenv mutvarntcons in
    match mutvarntcons with
    | UTEndOfMutualVariant                                     -> varntenv_new
    | UTMutualVariantCons(tyargcons, varntnm, utvc, tailcons)  ->
        add_mutual_cons (add_variant_cons "" varntenv_new tyargcons varntnm utvc) tailcons
    | UTMutualSynonymCons(tyargcons, tysynnm, tystr, tailcons) ->
        add_mutual_cons (add_synonym varntenv_new tyargcons tysynnm tystr) tailcons


and add_mutual_cons_hidden (mdlnm : module_name) (varntenv : t) (mutvarntcons : untyped_mutual_variant_cons) =
  let varntenv_new = add_mutual_type mdlnm varntenv mutvarntcons in
    match mutvarntcons with
    | UTEndOfMutualVariant                                 -> varntenv_new
    | UTMutualVariantCons(tyargcons, varntnm, _, tailcons) ->
        add_mutual_cons_hidden mdlnm (add_hidden_type mdlnm varntenv_new tyargcons varntnm) tailcons


and add_mutual_type (mdlnm : module_name) (varntenv : t) (mutvarntcons : untyped_mutual_variant_cons) =
  match mutvarntcons with
  | UTEndOfMutualVariant                                 -> varntenv
  | UTMutualVariantCons(tyargcons, varntnm, _, tailcons) ->
      let varntenv_new = add_variant varntenv tyargcons (append_module_name mdlnm varntnm) in
        add_mutual_type mdlnm varntenv_new tailcons
  | UTMutualSynonymCons(tyargcons, tysynnm, _, tailcons) ->
      let varntenv_new = add_variant varntenv tyargcons (append_module_name mdlnm tysynnm) in
        add_mutual_type mdlnm varntenv_new tailcons




let rec find (varntenv : t) (constrnm : constructor_name) =
  let (_, varntenvmain) = varntenv in find_main varntenvmain constrnm

and find_main varntenvmain constrnm =
    match varntenvmain with
    | []                -> raise Not_found
    | (c, v, t) :: tail -> if c = constrnm then (v, t) else find_main tail constrnm
