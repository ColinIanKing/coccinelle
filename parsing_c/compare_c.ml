open Common open Commonop

open Ast_c


type compare_result = 
  | Correct 
  | Pb of string
  | PbOnlyInNotParsedCorrectly


(*****************************************************************************)
(* Normalise before comparing *)
(*****************************************************************************)

(* List taken from CVS manual, 'Keyword substitution' chapter. Note
 * that I do not put "Log" because it is used only in comment, and it
 * is not enough to substituate until the end of the line. *)
let cvs_keyword_list = [
  "Id";"Date"; "Revision"; (* the common one *)
  "Name";"Author";"CVSHeader";"Header";"Locker";"RCSfile";"Source";"State";
]

(* Can also have just dollarIDdollar but it is only when you have not
 * yet committed the file. After the commit it would be a dollarIddollar:.
 * If reput Id:, do not join the regexp!! otherwise CVS will modify it :)
 *)
let cvs_keyword_regexp = Str.regexp 
  ("\\$\\([A-Za-z_]+\\):[^\\$]*\\$")

let normal_form_program xs = 
  let bigf = { Visitor_c.default_visitor_c_s with 

    Visitor_c.kini_s = (fun (k,bigf) ini -> 
      match ini with
      | InitList xs, [i1;i2;iicommaopt] -> 
          k (InitList xs, [i1;i2])
      | _ -> k ini
    );
    Visitor_c.kexpr_s = (fun (k,bigf) e -> 
      match e with
      (* todo: should also do something for multistrings *)
      | (Constant (String (s,kind)), typ), [ii] 
          when Common.string_match_substring cvs_keyword_regexp s -> 

          let newstr = 
            Str.global_substitute cvs_keyword_regexp (fun _s -> 
              let substr = Str.matched_string s in
              assert (substr ==~ cvs_keyword_regexp); (* use its side-effect *)
              let tag = matched1 substr in

              if not (List.mem tag cvs_keyword_list)
              then failwith ("unknown CVS keyword: " ^ tag);
              
              "CVS_MAGIC_STRING" 
            ) s 
          in
          (Constant (String (newstr,kind)), typ), [rewrap_str newstr ii]
      | _ -> k e    

    );
  }
  in
  xs +> List.map (fun p -> Visitor_c.vk_program_s  bigf p)
    
(*****************************************************************************)
(* Entry point *)
(*****************************************************************************)

(* Note that I do a kind of astdiff to know if there is a difference, but
 * then I use diff to print the differences. So sometimes you have to dig
 * a little to find really where the real difference (one not involving 
 * just spacing difference) was.
 * Note also that the astdiff is not very accurate. As I skip comments,
 * macro definitions, those are not in the Ast and if there is a diff
 * between 2 files regarding macro def, then I will not be able to report it :(
 * update: I now put the toplevel #define at least in the Ast.
 *
 * todo?: do astdiff, tokendiff, linediff ? 
 * I have the info for tokendiff, because c1 and c2 are programElement2.
 * (update: could also get them via visitor_c now).
 * Maybe easier to print the relevant difference if do tokendiff.
 *)
let compare (c1,filename1) (c2, filename2)  =

    let c1' = c1 +> Lib_parsing_c.al_program +> normal_form_program in
    let c2' = c2 +> Lib_parsing_c.al_program +> normal_form_program in
    
    let xs =
      process_output_to_list 
        ("diff -u -b -B " ^  filename1 ^ " "  ^ filename2) 
    in
    (* get rid of the --- and +++ lines *)
    let xs = 
      if null xs then xs 
      else 
        Common.drop 2 xs
    in
        
    let error = ref 0 in
    let pb_notparsed = ref 0 in
    
    let res = 
     if List.length c1' <> List.length c2' 
     then Pb "not same number of entities (func, decl, ...)"
     else 
       begin
         zip c1' c2' +> List.iter (function
           | Declaration a, Declaration b -> if not (a =*= b) then incr error
           | Definition a, Definition b ->   if not (a =*= b) then incr error
           | EmptyDef a, EmptyDef b ->       if not (a =*= b) then incr error
           | SpecialDeclMacro (a1,b1,c1), SpecialDeclMacro (a2,b2,c2) -> 
               if not ((a1,b1,c1) =*= (a2,b2,c2)) then incr error
           | CPPInclude a, CPPInclude b -> if not (a =*= b) then incr error
           | CPPDefine a, CPPDefine b ->   if not (a =*= b) then incr error
           | NotParsedCorrectly a, NotParsedCorrectly b -> 
               if not (a =*= b) then incr pb_notparsed
           | NotParsedCorrectly a, _ -> 
               incr pb_notparsed
           | _, NotParsedCorrectly b -> 
               incr pb_notparsed
           | FinalDef a, FinalDef b -> if not (a =*= b) then incr error
           | _, _ -> incr error
                        );
         (match () with
         | _ when !pb_notparsed > 0 && !error = 0 -> PbOnlyInNotParsedCorrectly
         | _ when !error > 0 -> Pb ""
         | _ -> Correct
         )
       end
    in
    res, xs
