open Types


let tyid_option  = Typeenv.Raw.fresh_type_id "option"
let tyid_itemize = Typeenv.Raw.fresh_type_id "itemize"
let tyid_color   = Typeenv.Raw.fresh_type_id "color"
let tyid_script  = Typeenv.Raw.fresh_type_id "script"
let tyid_page    = Typeenv.Raw.fresh_type_id "page"
let tyid_mathcls = Typeenv.Raw.fresh_type_id "math-class"


let add_default_types (tyenvmid : Typeenv.t) : Typeenv.t =
  let dr = Range.dummy "add_default_types" in
  let unit_type = (dr, BaseType(UnitType)) in
  let float_type = (dr, BaseType(FloatType)) in
  let length_type = (dr, BaseType(LengthType)) in
  let bid = BoundID.fresh UniversalKind () in
  let typaram = (dr, TypeVariable(ref (Bound(bid)))) in

  tyenvmid
  |> Typeenv.Raw.register_type "option" tyid_option (Typeenv.Data(1))
  |> Typeenv.Raw.add_constructor "None" ([bid], Poly(unit_type)) tyid_option
  |> Typeenv.Raw.add_constructor "Some" ([bid], Poly(typaram)) tyid_option

  |> Typeenv.Raw.register_type "itemize" tyid_itemize (Typeenv.Data(0))
  |> Typeenv.Raw.add_constructor "Item" ([], Poly(
       (dr, ProductType([(dr, BaseType(TextRowType)); (dr, ListType((dr, VariantType([], tyid_itemize)))); ]))
     )) tyid_itemize

  |> Typeenv.Raw.register_type "color" tyid_color (Typeenv.Data(0))
  |> Typeenv.Raw.add_constructor "Gray" ([], Poly(float_type)) tyid_color
  |> Typeenv.Raw.add_constructor "RGB"  ([], Poly((dr, ProductType([float_type; float_type; float_type])))) tyid_color
  |> Typeenv.Raw.add_constructor "CMYK" ([], Poly((dr, ProductType([float_type; float_type; float_type; float_type])))) tyid_color

  |> Typeenv.Raw.register_type "script" tyid_script (Typeenv.Data(0))
  |> Typeenv.Raw.add_constructor "Latin"          ([], Poly(unit_type)) tyid_script
  |> Typeenv.Raw.add_constructor "HanIdeographic" ([], Poly(unit_type)) tyid_script
  |> Typeenv.Raw.add_constructor "Kana"           ([], Poly(unit_type)) tyid_script
  |> Typeenv.Raw.add_constructor "OtherScript"    ([], Poly(unit_type)) tyid_script

  |> Typeenv.Raw.register_type "page" tyid_page (Typeenv.Data(0))
  |> Typeenv.Raw.add_constructor "A4Paper"          ([], Poly(unit_type)) tyid_page
  |> Typeenv.Raw.add_constructor "UserDefinedPaper" ([], Poly((dr, ProductType([length_type; length_type])))) tyid_page

  |> Typeenv.Raw.register_type "math-class" tyid_mathcls (Typeenv.Data(0))
  |> Typeenv.Raw.add_constructor "MathOrd"    ([], Poly(unit_type)) tyid_mathcls
  |> Typeenv.Raw.add_constructor "MathBin"    ([], Poly(unit_type)) tyid_mathcls
  |> Typeenv.Raw.add_constructor "MathRel"    ([], Poly(unit_type)) tyid_mathcls
  |> Typeenv.Raw.add_constructor "MathOp"     ([], Poly(unit_type)) tyid_mathcls
  |> Typeenv.Raw.add_constructor "MathPunct"  ([], Poly(unit_type)) tyid_mathcls
  |> Typeenv.Raw.add_constructor "MathOpen"   ([], Poly(unit_type)) tyid_mathcls
  |> Typeenv.Raw.add_constructor "MathClose"  ([], Poly(unit_type)) tyid_mathcls
  |> Typeenv.Raw.add_constructor "MathPrefix" ([], Poly(unit_type)) tyid_mathcls


let add_to_environment env varnm rfast =
  Hashtbl.add env varnm rfast


let lam evid ast = LambdaAbstract(evid, ast)
let lamenv env evid ast = FuncWithEnvironment(evid, ast, env)
let ( !- ) evid = ContentOf(evid)

let rec lambda1 astf env =
  let evid1 = EvalVarID.fresh "(dummy:lambda1-1)" in
    lamenv env evid1 (astf (!- evid1))

let rec lambda2 astf env =
  let evid1 = EvalVarID.fresh "(dummy:lambda2-1)" in
  let evid2 = EvalVarID.fresh "(dummy:lambda2-2)" in
    lamenv env evid1 (lam evid2 (astf (!- evid1) (!- evid2)))

let rec lambda3 astf env =
  let evid1 = EvalVarID.fresh "(dummy:lambda3-1)" in
  let evid2 = EvalVarID.fresh "(dummy:lambda3-2)" in
  let evid3 = EvalVarID.fresh "(dummy:lambda3-3)" in
    lamenv env evid1 (lam evid2 (lam evid3 (astf (!- evid1) (!- evid2) (!- evid3))))

let rec lambda4 astf env =
  let evid1 = EvalVarID.fresh "(dummy:lambda4-1)" in
  let evid2 = EvalVarID.fresh "(dummy:lambda4-2)" in
  let evid3 = EvalVarID.fresh "(dummy:lambda4-3)" in
  let evid4 = EvalVarID.fresh "(dummy:lambda4-4)" in
    lamenv env evid1 (lam evid2 (lam evid3 (lam evid4 (astf (!- evid1) (!- evid2) (!- evid3) (!- evid4)))))


(* -- begin: constants just for experimental use -- *)

let pdfpt = HorzBox.Length.of_pdf_point


let default_font_scheme =
  List.fold_left (fun mapacc (script, font_info) -> mapacc |> HorzBox.FontSchemeMap.add script font_info)
    HorzBox.FontSchemeMap.empty
    [
      (CharBasis.HanIdeographic    , ("ipaexm", 0.92, 0.));
      (CharBasis.HiraganaOrKatakana, ("ipaexm", 0.92, 0.));
      (CharBasis.Latin             , ("Arno"  , 1., 0.));
      (CharBasis.OtherScript       , HorzBox.default_font_with_ratio);
    ]


let default_math_left_paren hgt dpt hgtaxis fontsize color =
  let lenappend = HorzBox.(fontsize *% 0.1) in
  let minhalflen = HorzBox.(fontsize *% 0.5) in
  let halflen = HorzBox.(Length.max minhalflen ((Length.max (hgt -% hgtaxis) (hgtaxis -% dpt)) +% lenappend)) in
  let widparen = HorzBox.(halflen *% 0.375) in
  let wid = HorzBox.(widparen +% fontsize *% 0.1) in
  let graphics (xpos, ypos) =
    HorzBox.(Graphics.pdfops_of_stroke (pdfpt 0.5) color [
      GeneralPath((xpos +% wid, ypos +% hgtaxis +% halflen), [
        LineTo((xpos +% wid -% widparen, ypos +% hgtaxis));
        LineTo((xpos +% wid, ypos +% hgtaxis -% halflen));
      ], None);
    ])
  in
  let kerninfo y =
    let widkern = widparen in
    let r = 0. in
    let gap = HorzBox.(Length.abs (y -% hgtaxis)) in
    let topdfpt = HorzBox.Length.to_pdf_point in  (* for debug *)
    let () = Printf.printf "Primitives> y = %f, hgtaxis = %f\n" (topdfpt y) (topdfpt hgtaxis) in  (* for debug *)
    HorzBox.(
      if halflen *% r <% gap then
        widkern *% ((gap -% halflen *% r) /% (halflen *% (1. -. r)))
      else
        Length.zero
    )
  in
  let hgtparen = HorzBox.(hgtaxis +% halflen) in
  let dptparen = HorzBox.(hgtaxis -% halflen) in
  (HorzBox.([HorzPure(PHGFixedGraphics(wid, hgtparen, dptparen, graphics))]), kerninfo)


let default_math_right_paren hgt dpt hgtaxis fontsize color =
  let lenappend = HorzBox.(fontsize *% 0.1) in
  let minhalflen = HorzBox.(fontsize *% 0.5) in
  let halflen = HorzBox.(Length.max minhalflen ((Length.max (hgt -% hgtaxis) (hgtaxis -% dpt)) +% lenappend)) in
  let widparen = HorzBox.(halflen *% 0.375) in
  let wid = HorzBox.(widparen +% fontsize *% 0.1) in
  let graphics (xpos, ypos) =
    HorzBox.(Graphics.pdfops_of_stroke (pdfpt 0.5) color [
      GeneralPath((xpos, ypos +% hgtaxis +% halflen), [
        LineTo((xpos +% widparen, ypos +% hgtaxis));
        LineTo((xpos, ypos +% hgtaxis -% halflen));
      ], None);
    ])
  in
  let kerninfo y =
    let widkern = widparen in
    let r = 0. in
    let gap = HorzBox.(Length.abs (y -% hgtaxis)) in
    let topdfpt = HorzBox.Length.to_pdf_point in  (* for debug *)
    let () = Printf.printf "Primitives> y = %f, hgtaxis = %f\n" (topdfpt y) (topdfpt hgtaxis) in  (* for debug *)
    HorzBox.(
      if halflen *% r <% gap then
        widkern *% ((gap -% halflen *% r) /% (halflen *% (1. -. r)))
      else
        Length.zero
    )
  in
  let hgtparen = HorzBox.(hgtaxis +% halflen) in
  let dptparen = HorzBox.(hgtaxis -% halflen) in
  (HorzBox.([HorzPure(PHGFixedGraphics(wid, hgtparen, dptparen, graphics))]), kerninfo)


let default_radical hgt_bar t_bar dpt fontsize color =
  HorzBox.(begin
  let wM = fontsize *% 0.02 in
  let w1 = fontsize *% 0.1 in
  let w2 = fontsize *% 0.15 in
  let w3 = fontsize *% 0.4 in
  let wA = fontsize *% 0.18 in
  let h1 = fontsize *% 0.3 in
  let h2 = fontsize *% 0.375 in

  let dpt = dpt +% fontsize *% 0.1 in

  let lR = hgt_bar +% dpt in

  let wid = wM +% w1 +% w2 +% w3 in
  let a1 = (h2 -% h1) /% w1 in
  let a2 = h2 /% w2 in
  let a3 = lR /% w3 in
  let t1 = t_bar *% (sqrt (1. +. a1 *. a1)) in
  let t3 = t_bar *% ((sqrt (1. +. a3 *. a3) -. 1.) /. a3) in
  let hA = h1 +% t1 +% wA *% a1 in
  let wB = (lR +% t_bar -% hA -% (w1 +% w2 +% w3 -% t3 -% wA) *% a3) *% (-. 1. /. (a2 +. a3)) in
  let hB = hA -% wB *% a2 in

  let graphics (xpos, ypos) =
    Graphics.pdfops_of_fill color [
      GeneralPath((xpos +% wid, ypos +% hgt_bar), [
        LineTo(xpos +% wM +% w1 +% w2, ypos -% dpt);
        LineTo(xpos +% wM +% w1      , ypos -% dpt +% h2);
        LineTo(xpos +% wM            , ypos -% dpt +% h1);
        LineTo(xpos +% wM            , ypos -% dpt +% h1 +% t1);
        LineTo(xpos +% wM +% wA      , ypos -% dpt +% hA);
        LineTo(xpos +% wM +% wA +% wB, ypos -% dpt +% hB);
        LineTo(xpos +% wid -% t3     , ypos +% hgt_bar +% t_bar);
        LineTo(xpos +% wid           , ypos +% hgt_bar +% t_bar);
      ], Some(LineTo(())))
    ]
  in
  [HorzPure(PHGFixedGraphics(wid, hgt_bar +% t_bar, dpt, graphics))]
  end)


let envinit : environment = Hashtbl.create 128


let get_initial_context pagesch =
  HorzBox.({
    font_scheme      = default_font_scheme;
    font_size        = pdfpt 12.;
    math_font        = "lmodern";
    dominant_script  = CharBasis.OtherScript;
    space_natural    = 0.33;
    space_shrink     = 0.08;
    space_stretch    = 0.16; (* 0.32; *)
    adjacent_stretch = 0.025;
    paragraph_width  = pagesch.HorzBox.area_width;
    paragraph_top    = pdfpt 18.;
    paragraph_bottom = pdfpt 18.;
    leading          = pdfpt 18.;
    text_color       = HorzBox.DeviceGray(0.);
    manual_rising    = pdfpt 0.;
    page_scheme      = pagesch;
    badness_space    = 100;
  })
(*
let margin = pdfpt 2.


let frame_deco_VS =
  (fun (xpos, ypos) wid hgt dpt ->
    let xposb = xpos in
    let hgtb = hgt in
    let dptb = dpt in
    let widb = wid in
      Graphics.pdfops_of_graphics default_graphics_context HorzBox.DrawStroke [
        HorzBox.Rectangle((xposb, ypos +% dptb), (widb, hgtb -% dptb));
      ]
  )

let frame_deco_VH =
  (fun (xpos, ypos) wid hgt dpt ->
    let xposb = xpos in
    let hgtb = hgt in
    let dptb = dpt in
    let widb = wid in
      Graphics.pdfops_of_graphics default_graphics_context HorzBox.DrawStroke [
        HorzBox.GeneralPath((xposb, ypos +% dptb), [
          HorzBox.LineTo(xposb, ypos +% hgtb);
          HorzBox.LineTo(xposb +% widb, ypos +% hgtb);
          HorzBox.LineTo(xposb +% widb, ypos +% dptb);
        ], None);
      ]
  )

let frame_deco_VT =
  (fun (xpos, ypos) wid hgt dpt ->
    let xposb = xpos in
    let hgtb = hgt in
    let dptb = dpt in
    let widb = wid in
      Graphics.pdfops_of_graphics default_graphics_context HorzBox.DrawStroke [
        HorzBox.GeneralPath((xposb, ypos +% hgtb), [
          HorzBox.LineTo(xposb, ypos +% dptb);
          HorzBox.LineTo(xposb +% widb, ypos +% dptb);
          HorzBox.LineTo(xposb +% widb, ypos +% hgtb);
        ], None);
      ]
  )

let frame_deco_VM =
  (fun (xpos, ypos) wid hgt dpt ->
    let xposb = xpos in
    let hgtb = hgt in
    let dptb = dpt in
    let widb = wid in
    List.append (
      Graphics.pdfops_of_graphics default_graphics_context HorzBox.DrawStroke [
        HorzBox.GeneralPath((xposb, ypos +% hgtb), [
          HorzBox.LineTo(xposb, ypos +% dptb);
        ], None);
      ]
    ) (
      Graphics.pdfops_of_graphics default_graphics_context HorzBox.DrawStroke [
        HorzBox.GeneralPath((xposb +% widb, ypos +% hgtb), [
          HorzBox.LineTo(xposb +% widb, ypos +% dptb);
        ], None);
      ]
    )
  )
*)
(* -- end: constants just for experimental use -- *)


let ( ~! ) = Range.dummy

let make_environments () =
  let tyenvinit = add_default_types Typeenv.empty in

  let i             = (~! "int"     , BaseType(IntType)    ) in
  let fl            = (~! "float"   , BaseType(FloatType)  ) in
  let b             = (~! "bool"    , BaseType(BoolType)   ) in
  let ln            = (~! "length"  , BaseType(LengthType) ) in
  let s             = (~! "string"  , BaseType(StringType) ) in
  let (~@) n        = (~! "tv"      , TypeVariable(n)      ) in
  let (-%) n ptysub = ptysub in
  let (~%) ty       = Poly(ty) in
  let l ty          = (~! "list"    , ListType(ty)       ) in
  let r ty          = (~! "ref"     , RefType(ty)        ) in
  let prod tylst    = (~! "product" , ProductType(tylst)   ) in
  let opt ty        = (~! "option"  , VariantType([ty], tyid_option)) in
  let (@->) dom cod = (~! "func"    , FuncType(dom, cod)   ) in

  let tr            = (~! "inline-text" , BaseType(TextRowType)) in
  let tc            = (~! "block-text"  , BaseType(TextColType)) in
  let br            = (~! "inline-boxes", BaseType(BoxRowType) ) in
  let bc            = (~! "block-boxes" , BaseType(BoxColType) ) in
  let ft            = (~! "font"        , BaseType(FontType)   ) in
  let ctx           = (~! "context"     , BaseType(ContextType)) in
  let path          = (~! "path"        , BaseType(PathType)   ) in
  let prp           = (~! "pre-path"    , BaseType(PrePathType)) in
  let scr           = (~! "script"      , VariantType([], tyid_script)) in
  let doc           = (~! "document"    , BaseType(DocumentType)) in
  let math          = (~! "math"        , BaseType(MathType)   ) in
  let gr            = (~! "graphics", BaseType(GraphicsType)) in
  let clr           = (~! "color"   , VariantType([], tyid_color)) in
  let pg            = (~! "page"    , VariantType([], tyid_page)) in
  let mathcls       = (~! "mathcls" , VariantType([], tyid_mathcls)) in
  let pads          = prod [ln; ln; ln; ln] in
  let pt            = prod [ln; ln] in
  let dash          = prod [ln; ln; ln] in
  let deco          = pt @-> ln @-> ln @-> ln @-> (l gr) in
  let decoset       = prod [deco; deco; deco; deco] in
  let igr           = pt @-> (l gr) in

  let tv1 = (let bid1 = BoundID.fresh UniversalKind () in ref (Bound(bid1))) in
  let tv2 = (let bid2 = BoundID.fresh UniversalKind () in ref (Bound(bid2))) in

  let table : (var_name * poly_type * (environment -> abstract_tree)) list =
    let ptyderef  = tv1 -% (~% ((r (~@ tv1)) @-> (~@ tv1))) in
    let ptycons   = tv2 -% (~% ((~@ tv2) @-> (l (~@ tv2)) @-> (l (~@ tv2)))) in
    let ptyappinv = tv1 -% (tv2 -% (~% ((~@ tv1) @-> ((~@ tv1) @-> (~@ tv2)) @-> (~@ tv2)))) in
      [
        ( "+"  , ~% (i @-> i @-> i)   , lambda2 (fun v1 v2 -> Plus(v1, v2))                    );
        ( "-"  , ~% (i @-> i @-> i)   , lambda2 (fun v1 v2 -> Minus(v1, v2))                   );
        ( "mod", ~% (i @-> i @-> i)   , lambda2 (fun v1 v2 -> Mod(v1, v2))                     );
        ( "*"  , ~% (i @-> i @-> i)   , lambda2 (fun v1 v2 -> Times(v1, v2))                   );
        ( "/"  , ~% (i @-> i @-> i)   , lambda2 (fun v1 v2 -> Divides(v1, v2))                 );
        ( "^"  , ~% (s @-> s @-> s)   , lambda2 (fun v1 v2 -> Concat(v1, v2))                  );
        ( "==" , ~% (i @-> i @-> b)   , lambda2 (fun v1 v2 -> EqualTo(v1, v2))                 );
        ( "<>" , ~% (i @-> i @-> b)   , lambda2 (fun v1 v2 -> LogicalNot(EqualTo(v1, v2)))     );
        ( ">"  , ~% (i @-> i @-> b)   , lambda2 (fun v1 v2 -> GreaterThan(v1, v2))             );
        ( "<"  , ~% (i @-> i @-> b)   , lambda2 (fun v1 v2 -> LessThan(v1, v2))                );
        ( ">=" , ~% (i @-> i @-> b)   , lambda2 (fun v1 v2 -> LogicalNot(LessThan(v1, v2)))    );
        ( "<=" , ~% (i @-> i @-> b)   , lambda2 (fun v1 v2 -> LogicalNot(GreaterThan(v1, v2))) );
        ( "&&" , ~% (b @-> b @-> b)   , lambda2 (fun v1 v2 -> LogicalAnd(v1, v2))              );
        ( "||" , ~% (b @-> b @-> b)   , lambda2 (fun v1 v2 -> LogicalOr(v1, v2))               );
        ( "not", ~% (b @-> b)         , lambda1 (fun v1 -> LogicalNot(v1))                     );
        ( "!"  , ptyderef             , lambda1 (fun v1 -> Reference(v1))                      );
        ( "::" , ptycons              , lambda2 (fun v1 v2 -> ListCons(v1, v2))                );
        ( "+." , ~% (fl @-> fl @-> fl), lambda2 (fun v1 v2 -> FloatPlus(v1, v2))               );
        ( "-." , ~% (fl @-> fl @-> fl), lambda2 (fun v1 v2 -> FloatMinus(v1, v2))              );
        ( "+'" , ~% (ln @-> ln @-> ln), lambda2 (fun v1 v2 -> LengthPlus(v1, v2))              );
        ( "-'" , ~% (ln @-> ln @-> ln), lambda2 (fun v1 v2 -> LengthMinus(v1, v2))             );
        ( "*'" , ~% (ln @-> fl @-> ln), lambda2 (fun v1 v2 -> LengthTimes(v1, v2))             );
        ( "++" , ~% (br @-> br @-> br), lambda2 (fun vbr1 vbr2 -> HorzConcat(vbr1, vbr2))      );
        ( "+++", ~% (bc @-> bc @-> bc), lambda2 (fun vbc1 vbc2 -> VertConcat(vbc1, vbc2))      );
        ( "|>" , ptyappinv            , lambda2 (fun vx vf -> Apply(vf, vx)));

        ( "string-same"  , ~% (s @-> s @-> b)           , lambda2 (fun v1 v2 -> PrimitiveSame(v1, v2)) );
        ( "string-sub"   , ~% (s @-> i @-> i @-> s)     , lambda3 (fun vstr vpos vwid -> PrimitiveStringSub(vstr, vpos, vwid)) );
        ( "string-length", ~% (s @-> i)                 , lambda1 (fun vstr -> PrimitiveStringLength(vstr)) );
        ( "arabic"       , ~% (i @-> s)                 , lambda1 (fun vnum -> PrimitiveArabic(vnum)) );
        ( "float"        , ~% (i @-> fl)                , lambda1 (fun vi -> PrimitiveFloat(vi)) );

        ("form-paragraph"        , ~% (ctx @-> br @-> bc)                 , lambda2 (fun vctx vbr -> BackendLineBreaking(vctx, vbr)) );
        ("form-document"         , ~% (ctx @-> bc @-> doc)                , lambda2 (fun vctx vbc -> BackendPageBreaking(vctx, vbc)));
        ("inline-skip"           , ~% (ln @-> br)                         , lambda1 (fun vwid -> BackendFixedEmpty(vwid))   );
        ("inline-glue"           , ~% (ln @-> ln @-> ln @-> br)           , lambda3 (fun vn vp vm -> BackendOuterEmpty(vn, vp, vm)) );
        ("inline-fil"            , ~% br                                  , (fun _ -> Horz([HorzBox.HorzPure(HorzBox.PHSOuterFil)])));
        ("inline-frame-solid"    , ~% (pads @-> deco @-> br @-> br)       , lambda3 (fun vpads vdeco vbr -> BackendOuterFrame(vpads, vdeco, vbr)));
        ("inline-frame-breakable", ~% (pads @-> decoset @-> br @-> br)    , lambda3 (fun vpads vdecoset vbr -> BackendOuterFrameBreakable(vpads, vdecoset, vbr)));
        ("font"                  , ~% (s @-> fl @-> fl @-> ft)            , lambda3 (fun vabbrv vszrat vrsrat -> BackendFont(vabbrv, vszrat, vrsrat)));
        ("block-nil"             , ~% bc                                  , (fun _ -> Vert([])));
        ("block-frame-breakable" , ~% (ctx @-> pads @-> decoset @-> (ctx @-> bc) @-> bc), lambda4 (fun vctx vpads vdecoset vbc -> BackendVertFrame(vctx, vpads, vdecoset, vbc)));
        ("embedded-block-top"    , ~% (ctx @-> ln @-> (ctx @-> bc) @-> br), lambda3 (fun vctx vlen vk -> BackendEmbeddedVert(vctx, vlen, vk)));

        ("read-inline", ~% (ctx @-> tr @-> br), lambda2 (fun vctx vtr -> HorzLex(vctx, vtr)));
        ("read-block" , ~% (ctx @-> tc @-> bc), lambda2 (fun vctx vtc -> VertLex(vctx, vtc)));

        ("get-initial-context", ~% (pg @-> pt @-> ln @-> ln @-> ctx)   , lambda4 (fun vpage vpt vwid vhgt -> PrimitiveGetInitialContext(vpage, vpt, vwid, vhgt)));
        ("set-space-ratio"    , ~% (fl @-> ctx @-> ctx)                , lambda2 (fun vratio vctx -> PrimitiveSetSpaceRatio(vratio, vctx)));
        ("set-font-size"      , ~% (ln @-> ctx @-> ctx)                , lambda2 (fun vsize vctx -> PrimitiveSetFontSize(vsize, vctx)));
        ("get-font-size"      , ~% (ctx @-> ln)                        , lambda1 (fun vctx -> PrimitiveGetFontSize(vctx)));
        ("set-font"           , ~% (scr @-> ft @-> ctx @-> ctx)        , lambda3 (fun vscript vfont vctx -> PrimitiveSetFont(vscript, vfont, vctx)));
        ("get-font"           , ~% (scr @-> ctx @-> ft)                , lambda2 (fun vscript vctx -> PrimitiveGetFont(vscript, vctx)));
        ("set-math-font"      , ~% (s @-> ctx @-> ctx)                 , lambda2 (fun vs vctx -> PrimitiveSetMathFont(vs, vctx)));
        ("set-dominant-script", ~% (scr @-> ctx @-> ctx)               , lambda2 (fun vscript vctx -> PrimitiveSetDominantScript(vscript, vctx)));
        ("set-text-color"     , ~% (clr @-> ctx @-> ctx)               , lambda2 (fun vcolor vctx -> PrimitiveSetTextColor(vcolor, vctx)));
        ("set-leading"        , ~% (ln @-> ctx @-> ctx)                , lambda2 (fun vlen vctx -> PrimitiveSetLeading(vlen, vctx)));
        ("set-manual-rising"  , ~% (ln @-> ctx @-> ctx)                , lambda2 (fun vlen vctx -> PrimitiveSetManualRising(vlen, vctx)));
        ("get-text-width"     , ~% (ctx @-> ln)                        , lambda1 (fun vctx -> PrimitiveGetTextWidth(vctx)));
        ("embed"              , ~% (s @-> tr)                          , lambda1 (fun vstr -> PrimitiveEmbed(vstr)));
        ("inline-graphics"    , ~% (ln @-> ln @-> ln @-> igr @-> br)   , lambda4 (fun vwid vhgt vdpt vg -> BackendInlineGraphics(vwid, vhgt, vdpt, vg)));
        ("get-natural-width"  , ~% (br @-> ln)                         , lambda1 (fun vbr -> PrimitiveGetNaturalWidth(vbr)));

        ("stroke"                  , ~% (ln @-> clr @-> path @-> gr)                , lambda3 (fun vwid vclr vpath -> PrimitiveDrawStroke(vwid, vclr, vpath)));
        ("dashed-stroke"           , ~% (ln @-> dash @-> clr @-> path @-> gr)       , lambda4 (fun vwid vdash vclr vpath -> PrimitiveDrawDashedStroke(vwid, vdash, vclr, vpath)));
        ("fill"                    , ~% (clr @-> path @-> gr)                       , lambda2 (fun vclr vpath -> PrimitiveDrawFill(vclr, vpath)));
        ("draw-text"               , ~% (pt @-> br @-> gr)                          , lambda2 (fun vpt vbr -> PrimitiveDrawText(vpt, vbr)));
        ("start-path"              , ~% (pt @-> prp)                                , lambda1 (fun vpt -> PrePathBeginning(vpt)));
        ("line-to"                 , ~% (pt @-> prp @-> prp)                        , lambda2 (fun vpt vprp -> PrePathLineTo(vpt, vprp)));
        ("bezier-to"               , ~% (pt @-> pt @-> pt @-> prp @-> prp)          , lambda4 (fun vptS vptT vpt1 vprp -> PrePathCubicBezierTo(vptS, vptT, vpt1, vprp)));
        ("terminate-path"          , ~% (prp @-> path)                              , lambda1 (fun vprp -> PrePathTerminate(vprp)));
        ("close-with-line"         , ~% (prp @-> path)                              , lambda1 (fun vprp -> PrePathCloseWithLine(vprp)));
        ("close-with-bezier"       , ~% (pt @-> pt @-> prp @-> path)                , lambda3 (fun vptS vptT vprp -> PrePathCloseWithCubicBezier(vptS, vptT, vprp)));
        ("unite-path"              , ~% (path @-> path @-> path)                    , lambda2 (fun vpath1 vpath2 -> PathUnite(vpath1, vpath2)));
        ("math-glyph"              , ~% (mathcls @-> s @-> math)                    , lambda2 (fun vmc vs -> BackendMathGlyph(vmc, vs)));
        ("math-group"              , ~% (mathcls @-> mathcls @-> math @-> math)     , lambda3 (fun vmc1 vmc2 vm -> BackendMathGroup(vmc1, vmc2, vm)));
        ("math-sup"                , ~% (math @-> math @-> math)                    , lambda2 (fun vm1 vm2 -> BackendMathSuperscript(vm1, vm2)));
        ("math-sub"                , ~% (math @-> math @-> math)                    , lambda2 (fun vm1 vm2 -> BackendMathSubscript(vm1, vm2)));
        ("math-frac"               , ~% (math @-> math @-> math)                    , lambda2 (fun vm1 vm2 -> BackendMathFraction(vm1, vm2)));
        ("math-radical"            , ~% (opt math @-> math @-> math)                , lambda2 (fun vm1 vm2 -> BackendMathRadical(vm1, vm2)));
        ("math-paren"              , ~% (math @-> math)                             , lambda1 (fun vm -> BackendMathParen(vm)));
        ("math-upper"              , ~% (math @-> math @-> math)                    , lambda2 (fun vm1 vm2 -> BackendMathUpperLimit(vm1, vm2)));
        ("math-lower"              , ~% (math @-> math @-> math)                    , lambda2 (fun vm1 vm2 -> BackendMathLowerLimit(vm1, vm2)));
        ("math-concat"             , ~% (math @-> math @-> math)                    , lambda2 (fun vm1 vm2 -> BackendMathConcat(vm1, vm2)));
        ("text-in-math"            , ~% (mathcls @-> (ctx @-> br) @-> math)         , lambda2 (fun vmc vbrf -> BackendMathText(vmc, vbrf)));
        ("embed-math"              , ~% (ctx @-> math @-> br)                       , lambda2 (fun vctx vm -> BackendEmbeddedMath(vctx, vm)));
        ("string-unexplode"        , ~% ((l i) @-> s)                               , lambda1 (fun vil -> PrimitiveStringUnexplode(vil)));
      ]
  in
  let temporary_ast = StringEmpty in
  let (tyenvfinal, locacc) =
    table |> List.fold_left (fun (tyenv, acc) (varnm, pty, deff) ->
      let evid = EvalVarID.fresh varnm in
      let loc = ref temporary_ast in
      let tyenvnew = Typeenv.add tyenv varnm (pty, evid) in
      begin
        add_to_environment envinit evid loc;
        (tyenvnew, (loc, deff) :: acc)
      end
    ) (tyenvinit, [])
  in
  let () =
    locacc |> List.iter (fun (loc, deff) -> begin loc := deff envinit; end)
  in
    (tyenvfinal, envinit)
