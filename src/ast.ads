-- ***************************************************************************
--               JavaScript interpreter - ast
--
--           Copyright (C) 2026 By Ulrik Hørlyk Hjort
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
-- LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- ***************************************************************************

package AST is

   type Node_Type is (
      Node_Program,
      Node_Number_Literal,
      Node_String_Literal,
      Node_Boolean_Literal,
      Node_Null_Literal,
      Node_Identifier,
      Node_Binary_Op,
      Node_Unary_Op,
      Node_Ternary_Op,
      Node_Prefix_Update,
      Node_Postfix_Update,
      Node_Assignment,
      Node_Variable_Declaration,
      Node_Print_Statement,
      Node_Expression_Statement,
      Node_Statement_List,
      Node_If_Statement,
      Node_While_Statement,
      Node_Do_While_Statement,
      Node_Switch_Statement,
      Node_Case_Clause,
      Node_For_Statement,
      Node_Block_Statement,
      Node_Function_Declaration,
      Node_Arrow_Function,
      Node_Function_Call,
      Node_Method_Call,
      Node_Return_Statement,
      Node_Break_Statement,
      Node_Continue_Statement,
      Node_Array_Literal,
      Node_Array_Index,
      Node_Member_Access,
      Node_Object_Literal,
      Node_Property,
      Node_Class_Declaration,
      Node_New_Expression,
      Node_This_Expression,
      Node_Super_Call,
      Node_Try_Statement,
      Node_Throw_Statement
   );

   type Declaration_Kind is (Decl_Let, Decl_Const, Decl_Var);

   type AST_Node;
   type AST_Node_Ptr is access AST_Node;
   
   type Node_Array is array (Positive range <>) of AST_Node_Ptr;
   type Node_Array_Ptr is access Node_Array;

   type AST_Node (Kind : Node_Type := Node_Program) is record
      case Kind is
         when Node_Number_Literal =>
            Number_Value : Float;
         when Node_String_Literal =>
            String_Value : String (1 .. 256);
            String_Length : Natural;
         when Node_Boolean_Literal =>
            Boolean_Value : Boolean;
         when Node_Identifier =>
            Id_Name : String (1 .. 256);
            Id_Length : Natural;
         when Node_Binary_Op =>
            Left : AST_Node_Ptr;
            Operator : String (1 .. 3);
            Op_Length : Natural;
            Right : AST_Node_Ptr;
         when Node_Unary_Op =>
            Unary_Operator : String (1 .. 10);
            Unary_Op_Length : Natural;
            Operand : AST_Node_Ptr;
         when Node_Ternary_Op =>
            Ternary_Condition : AST_Node_Ptr;
            Ternary_True_Expr : AST_Node_Ptr;
            Ternary_False_Expr : AST_Node_Ptr;
         when Node_Prefix_Update | Node_Postfix_Update =>
            Update_Operator : String (1 .. 2);  -- ++ or --
            Update_Op_Length : Natural;
            Update_Operand : AST_Node_Ptr;  -- Variable or array index
         when Node_Assignment =>
            Assign_Name : String (1 .. 256);
            Assign_Name_Length : Natural;
            Assign_Target : AST_Node_Ptr;  -- For member access assignment like this.name = value
            Assign_Value : AST_Node_Ptr;
         when Node_Variable_Declaration =>
            Decl_Type : Declaration_Kind;
            Var_Name : String (1 .. 256);
            Var_Name_Length : Natural;
            Initializer : AST_Node_Ptr;
         when Node_Print_Statement =>
            Print_Expr : AST_Node_Ptr;
         when Node_Expression_Statement =>
            Expr : AST_Node_Ptr;
         when Node_Statement_List =>
            Statements : Node_Array_Ptr;
            Statement_Count : Natural;
         when Node_If_Statement =>
            Condition : AST_Node_Ptr;
            Then_Branch : AST_Node_Ptr;
            Else_Branch : AST_Node_Ptr;
         when Node_While_Statement =>
            While_Condition : AST_Node_Ptr;
            While_Body : AST_Node_Ptr;
         when Node_Do_While_Statement =>
            Do_While_Body : AST_Node_Ptr;
            Do_While_Condition : AST_Node_Ptr;
         when Node_Switch_Statement =>
            Switch_Expr : AST_Node_Ptr;
            Cases : Node_Array_Ptr;
            Case_Count : Natural;
         when Node_Case_Clause =>
            Case_Value : AST_Node_Ptr;  -- null for default
            Case_Statements : Node_Array_Ptr;
            Case_Statement_Count : Natural;
         when Node_For_Statement =>
            For_Init : AST_Node_Ptr;
            For_Condition : AST_Node_Ptr;
            For_Update : AST_Node_Ptr;
            For_Body : AST_Node_Ptr;
         when Node_Block_Statement =>
            Block_Statements : Node_Array_Ptr;
            Block_Count : Natural;
         when Node_Function_Declaration =>
            Func_Name : String (1 .. 256);
            Func_Name_Length : Natural;
            Params : Node_Array_Ptr;
            Param_Count : Natural;
            Func_Body : AST_Node_Ptr;
         when Node_Arrow_Function =>
            Arrow_Params : Node_Array_Ptr;
            Arrow_Param_Count : Natural;
            Arrow_Body : AST_Node_Ptr;
            Is_Expression_Body : Boolean;  -- True for (x) => x*2, False for (x) => { return x*2; }
         when Node_Function_Call =>
            Call_Name : String (1 .. 256);
            Call_Name_Length : Natural;
            Arguments : Node_Array_Ptr;
            Arg_Count : Natural;
         when Node_Method_Call =>
            Callee : AST_Node_Ptr;
            Method_Arguments : Node_Array_Ptr;
            Method_Arg_Count : Natural;
         when Node_Return_Statement =>
            Return_Value : AST_Node_Ptr;
         when Node_Array_Literal =>
            Elements : Node_Array_Ptr;
            Element_Count : Natural;
         when Node_Array_Index =>
            Array_Expr : AST_Node_Ptr;
            Index_Expr : AST_Node_Ptr;
         when Node_Member_Access =>
            Object_Expr : AST_Node_Ptr;
            Member_Name : String (1 .. 256);
            Member_Length : Natural;
         when Node_Object_Literal =>
            Properties : Node_Array_Ptr;  -- Array of Property nodes
            Property_Count : Natural;
         when Node_Property =>
            Prop_Key : String (1 .. 256);
            Prop_Key_Length : Natural;
            Prop_Value : AST_Node_Ptr;
         when Node_Class_Declaration =>
            Class_Name : String (1 .. 256);
            Class_Name_Length : Natural;
            Class_Methods : Node_Array_Ptr;  -- Array of Method declarations
            Method_Count : Natural;
            Parent_Class_Name : String (1 .. 256);
            Parent_Class_Name_Length : Natural;  -- 0 if no parent
         when Node_New_Expression =>
            New_Class_Name : String (1 .. 256);
            New_Class_Name_Length : Natural;
            Constructor_Args : Node_Array_Ptr;
            Constructor_Arg_Count : Natural;
         when Node_This_Expression =>
            null;  -- 'this' has no additional data
         when Node_Super_Call =>
            Super_Arguments : Node_Array_Ptr;
            Super_Arg_Count : Natural;
         when Node_Try_Statement =>
            Try_Body : AST_Node_Ptr;
            Catch_Param : String(1..100);
            Catch_Param_Length : Natural;
            Catch_Body : AST_Node_Ptr;
            Finally_Body : AST_Node_Ptr;
         when Node_Throw_Statement =>
            Throw_Expression : AST_Node_Ptr;
         when others =>
            null;
      end case;
   end record;

end AST;
