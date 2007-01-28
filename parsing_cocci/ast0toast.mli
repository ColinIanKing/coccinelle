val ast0toast : Ast0_cocci.rule -> Ast_cocci.rule

val ident : Ast0_cocci.ident -> Ast_cocci.ident
val expression : Ast0_cocci.expression -> Ast_cocci.expression
val expression_dots :
    Ast0_cocci.expression Ast0_cocci.dots ->
      Ast_cocci.expression Ast_cocci.dots
val initialiser : Ast0_cocci.initialiser -> Ast_cocci.initialiser
val initialiser_dots :
    Ast0_cocci.initialiser Ast0_cocci.dots ->
      Ast_cocci.initialiser Ast_cocci.dots
val statement : Ast0_cocci.statement -> Ast_cocci.statement
val statement_dots :
    Ast0_cocci.statement Ast0_cocci.dots -> Ast_cocci.statement Ast_cocci.dots
val case_line : Ast0_cocci.case_line -> Ast_cocci.case_line
val typeC : Ast0_cocci.typeC -> Ast_cocci.fullType
val declaration : Ast0_cocci.declaration -> Ast_cocci.declaration
val parameterTypeDef :
    Ast0_cocci.parameterTypeDef -> Ast_cocci.parameterTypeDef
val parameter_list : Ast0_cocci.parameter_list -> Ast_cocci.parameter_list
val top_level : Ast0_cocci.top_level -> Ast_cocci.top_level
val mcode : 'a Ast0_cocci.mcode -> 'a Ast_cocci.mcode
