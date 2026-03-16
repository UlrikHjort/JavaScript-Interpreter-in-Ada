-- ***************************************************************************
--               JavaScript interpreter - parser
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

with Lexer;

package body Parser is
   use type Lexer.Token_Type;
   use type AST.AST_Node_Ptr;
   use type AST.Node_Type;

   Current_Token : Lexer.Token;
   Error_Occurred : Boolean := False;
   Error_Msg : String (1 .. 256);
   Error_Msg_Length : Natural := 0;

   function Parse_Expression return AST.AST_Node_Ptr;
   function Parse_Ternary return AST.AST_Node_Ptr;
   function Parse_Logical_Or return AST.AST_Node_Ptr;
   function Parse_Logical_And return AST.AST_Node_Ptr;
   function Parse_Equality return AST.AST_Node_Ptr;
   function Parse_Comparison return AST.AST_Node_Ptr;
   function Parse_Additive return AST.AST_Node_Ptr;
   function Parse_Multiplicative return AST.AST_Node_Ptr;
   function Parse_Unary return AST.AST_Node_Ptr;
   function Parse_Postfix return AST.AST_Node_Ptr;
   function Parse_Primary return AST.AST_Node_Ptr;
   function Parse_Block return AST.AST_Node_Ptr;

   -- Initialize parser with source code and reset state
   procedure Init (Source : String) is
   begin
      Lexer.Init (Source);
      Current_Token := Lexer.Next_Token;
      Error_Occurred := False;
      Error_Msg_Length := 0;
   end Init;

   -- Check if any parsing errors have occurred
   function Has_Error return Boolean is
   begin
      return Error_Occurred;
   end Has_Error;

   -- Retrieve the accumulated error message
   function Get_Error_Message return String is
   begin
      return Error_Msg (1 .. Error_Msg_Length);
   end Get_Error_Message;

   -- Record a parsing error with the given message
   procedure Report_Error (Message : String) is
   begin
      Error_Occurred := True;
      Error_Msg_Length := Message'Length;
      Error_Msg (1 .. Error_Msg_Length) := Message;
   end Report_Error;

   procedure Advance is
   begin
      Current_Token := Lexer.Next_Token;
   end Advance;

   function Match (Kind : Lexer.Token_Type) return Boolean is
   begin
      return Current_Token.Kind = Kind;
   end Match;

   function Consume (Kind : Lexer.Token_Type; Message : String) return Boolean is
   begin
      if Current_Token.Kind = Kind then
         Advance;
         return True;
      else
         Report_Error (Message);
         return False;
      end if;
   end Consume;

   -- Parse unary expressions (-, !, typeof, ++, --, new)
   function Parse_Unary return AST.AST_Node_Ptr is
      Node : AST.AST_Node_Ptr;
      Op : String (1 .. 10);
      Op_Len : Natural;
   begin
      -- Handle 'new' expressions
      if Match (Lexer.Token_New) then
         Advance;
         
         if not Match (Lexer.Token_Identifier) then
            Report_Error ("Expected class name after 'new'");
            return null;
         end if;
         
         Node := new AST.AST_Node (AST.Node_New_Expression);
         Node.New_Class_Name_Length := Current_Token.Length;
         Node.New_Class_Name (1 .. Node.New_Class_Name_Length) := 
            Current_Token.Lexeme (1 .. Current_Token.Length);
         Advance;
         
         if not Consume (Lexer.Token_Left_Paren, "Expected '(' after class name") then
            return null;
         end if;
         
         -- Parse constructor arguments
         if not Match (Lexer.Token_Right_Paren) then
            declare
               Args : array (1 .. 100) of AST.AST_Node_Ptr;
               Arg_Cnt : Natural := 0;
            begin
               loop
                  Arg_Cnt := Arg_Cnt + 1;
                  Args (Arg_Cnt) := Parse_Expression;
                  exit when not Match (Lexer.Token_Comma);
                  Advance;
               end loop;
               
               Node.Constructor_Arg_Count := Arg_Cnt;
               Node.Constructor_Args := new AST.Node_Array (1 .. Arg_Cnt);
               for I in 1 .. Arg_Cnt loop
                  Node.Constructor_Args (I) := Args (I);
               end loop;
            end;
         else
            Node.Constructor_Arg_Count := 0;
            Node.Constructor_Args := null;
         end if;
         
         if not Consume (Lexer.Token_Right_Paren, "Expected ')' after constructor arguments") then
            return null;
         end if;
         
         return Node;
      -- Prefix increment/decrement: ++x, --x
      elsif Match (Lexer.Token_Plus_Plus) or Match (Lexer.Token_Minus_Minus) then
         Op_Len := Current_Token.Length;
         Op (1 .. Op_Len) := Current_Token.Lexeme (1 .. Current_Token.Length);
         Advance;
         
         Node := new AST.AST_Node (AST.Node_Prefix_Update);
         Node.Update_Op_Length := Op_Len;
         Node.Update_Operator (1 .. Op_Len) := Op (1 .. Op_Len);
         Node.Update_Operand := Parse_Unary;  -- Can nest: ++--x
         return Node;
      elsif Match (Lexer.Token_Minus) or Match (Lexer.Token_Bang) or Match (Lexer.Token_Typeof) then
         Op_Len := Current_Token.Length;
         Op (1 .. Op_Len) := Current_Token.Lexeme (1 .. Current_Token.Length);
         Advance;
         
         Node := new AST.AST_Node (AST.Node_Unary_Op);
         Node.Unary_Op_Length := Op_Len;
         Node.Unary_Operator (1 .. Op_Len) := Op (1 .. Op_Len);
         Node.Operand := Parse_Unary;
         return Node;
      else
         return Parse_Postfix;
      end if;
   end Parse_Unary;

   -- Parse postfix operators ([], ., (), ++, --)
   function Parse_Postfix return AST.AST_Node_Ptr is
      Node : AST.AST_Node_Ptr;
      Index_Node : AST.AST_Node_Ptr;
   begin
      Node := Parse_Primary;
      
      -- Handle postfix operators like [], ., and ()
      loop
         if Match (Lexer.Token_Left_Bracket) then
            -- Array indexing: arr[index]
            Advance;
            Index_Node := new AST.AST_Node (AST.Node_Array_Index);
            Index_Node.Array_Expr := Node;
            Index_Node.Index_Expr := Parse_Expression;
            if not Consume (Lexer.Token_Right_Bracket, "Expected ']' after array index") then
               return null;
            end if;
            Node := Index_Node;
         elsif Match (Lexer.Token_Dot) then
            -- Member access: arr.length or arr.push
            Advance;
            if not Match (Lexer.Token_Identifier) then
               Report_Error ("Expected property name after '.'");
               return null;
            end if;
            
            Index_Node := new AST.AST_Node (AST.Node_Member_Access);
            Index_Node.Object_Expr := Node;
            Index_Node.Member_Length := Current_Token.Length;
            Index_Node.Member_Name (1 .. Current_Token.Length) := Current_Token.Lexeme (1 .. Current_Token.Length);
            Advance;
            Node := Index_Node;
         elsif Match (Lexer.Token_Left_Paren) then
            -- Function/method call: func() or obj.method()
            Advance;
            declare
               Call_Node : constant AST.AST_Node_Ptr := new AST.AST_Node (AST.Node_Method_Call);
            begin
               -- Store the callee expression (identifier or member access)
               Call_Node.Callee := Node;
               
               -- Parse arguments
               if not Match (Lexer.Token_Right_Paren) then
                  declare
                     Args : array (1 .. 100) of AST.AST_Node_Ptr;
                     Arg_Cnt : Natural := 0;
                  begin
                     loop
                        Arg_Cnt := Arg_Cnt + 1;
                        Args (Arg_Cnt) := Parse_Expression;
                        exit when not Match (Lexer.Token_Comma);
                        Advance;
                     end loop;
                     
                     Call_Node.Method_Arg_Count := Arg_Cnt;
                     Call_Node.Method_Arguments := new AST.Node_Array (1 .. Arg_Cnt);
                     for I in 1 .. Arg_Cnt loop
                        Call_Node.Method_Arguments (I) := Args (I);
                     end loop;
                  end;
               else
                  Call_Node.Method_Arg_Count := 0;
                  Call_Node.Method_Arguments := null;
               end if;
               
               if not Consume (Lexer.Token_Right_Paren, "Expected ')' after arguments") then
                  return null;
               end if;
               
               Node := Call_Node;
            end;
         elsif Match (Lexer.Token_Plus_Plus) or Match (Lexer.Token_Minus_Minus) then
            -- Postfix increment/decrement: x++, x--
            declare
               Update_Node : constant AST.AST_Node_Ptr := new AST.AST_Node (AST.Node_Postfix_Update);
               Op_Len : constant Natural := Current_Token.Length;
            begin
               Update_Node.Update_Op_Length := Op_Len;
               Update_Node.Update_Operator (1 .. Op_Len) := Current_Token.Lexeme (1 .. Op_Len);
               Update_Node.Update_Operand := Node;
               Advance;
               Node := Update_Node;
            end;
         else
            exit;
         end if;
      end loop;
      
      return Node;
   end Parse_Postfix;

   -- Parse primary expressions (literals, identifiers, function calls, arrow functions)
   function Parse_Primary return AST.AST_Node_Ptr is
      Node : AST.AST_Node_Ptr;
   begin
      if Match (Lexer.Token_Number) then
         Node := new AST.AST_Node (AST.Node_Number_Literal);
         Node.Number_Value := Float'Value (Current_Token.Lexeme (1 .. Current_Token.Length));
         Advance;
         return Node;
      elsif Match (Lexer.Token_String) then
         Node := new AST.AST_Node (AST.Node_String_Literal);
         Node.String_Length := Current_Token.Length;
         Node.String_Value (1 .. Node.String_Length) := Current_Token.Lexeme (1 .. Current_Token.Length);
         Advance;
         return Node;
      elsif Match (Lexer.Token_True) or Match (Lexer.Token_False) then
         Node := new AST.AST_Node (AST.Node_Boolean_Literal);
         Node.Boolean_Value := Match (Lexer.Token_True);
         Advance;
         return Node;
      elsif Match (Lexer.Token_Null) then
         Node := new AST.AST_Node (AST.Node_Null_Literal);
         Advance;
         return Node;
      elsif Match (Lexer.Token_Undefined) then
         Node := new AST.AST_Node (AST.Node_Identifier);
         Node.Id_Length := 9;
         Node.Id_Name (1 .. 9) := "undefined";
         Advance;
         return Node;
      elsif Match (Lexer.Token_This) then
         Node := new AST.AST_Node (AST.Node_This_Expression);
         Advance;
         return Node;
      elsif Match (Lexer.Token_Super) then
         Advance;
         -- super() is a call to parent constructor
         if not Consume (Lexer.Token_Left_Paren, "Expected '(' after 'super'") then
            return null;
         end if;
         
         Node := new AST.AST_Node (AST.Node_Super_Call);
         
         -- Parse arguments
         if not Match (Lexer.Token_Right_Paren) then
            declare
               Args : array (1 .. 100) of AST.AST_Node_Ptr;
               Arg_Cnt : Natural := 0;
            begin
               loop
                  Arg_Cnt := Arg_Cnt + 1;
                  Args (Arg_Cnt) := Parse_Expression;
                  exit when not Match (Lexer.Token_Comma);
                  Advance;
               end loop;
               
               Node.Super_Arg_Count := Arg_Cnt;
               Node.Super_Arguments := new AST.Node_Array (1 .. Arg_Cnt);
               for I in 1 .. Arg_Cnt loop
                  Node.Super_Arguments (I) := Args (I);
               end loop;
            end;
         else
            Node.Super_Arg_Count := 0;
            Node.Super_Arguments := null;
         end if;
         
         if not Consume (Lexer.Token_Right_Paren, "Expected ')' after super arguments") then
            return null;
         end if;
         
         return Node;
      elsif Match (Lexer.Token_Identifier) then
         declare
            Name_Len : constant Natural := Current_Token.Length;
            Name : constant String := Current_Token.Lexeme (1 .. Name_Len);
         begin
            Advance;
            
            -- Check if this is a function call
            if Match (Lexer.Token_Left_Paren) then
               Advance;
               Node := new AST.AST_Node (AST.Node_Function_Call);
               Node.Call_Name_Length := Name_Len;
               Node.Call_Name (1 .. Name_Len) := Name;
               
               -- Parse arguments
               if not Match (Lexer.Token_Right_Paren) then
                  declare
                     Args : array (1 .. 100) of AST.AST_Node_Ptr;
                     Arg_Cnt : Natural := 0;
                  begin
                     loop
                        Arg_Cnt := Arg_Cnt + 1;
                        Args (Arg_Cnt) := Parse_Expression;
                        exit when not Match (Lexer.Token_Comma);
                        Advance;
                     end loop;
                     
                     Node.Arg_Count := Arg_Cnt;
                     Node.Arguments := new AST.Node_Array (1 .. Arg_Cnt);
                     for I in 1 .. Arg_Cnt loop
                        Node.Arguments (I) := Args (I);
                     end loop;
                  end;
               else
                  Node.Arg_Count := 0;
                  Node.Arguments := null;
               end if;
               
               if not Consume (Lexer.Token_Right_Paren, "Expected ')' after arguments") then
                  return null;
               end if;
               
               return Node;
            else
               -- Regular identifier
               Node := new AST.AST_Node (AST.Node_Identifier);
               Node.Id_Length := Name_Len;
               Node.Id_Name (1 .. Name_Len) := Name;
               return Node;
            end if;
         end;
      elsif Match (Lexer.Token_Left_Paren) then
         Advance;
         
         -- Empty parens () - could be () => or error
         if Match (Lexer.Token_Right_Paren) then
            Advance;
            if Match (Lexer.Token_Arrow) then
               -- () => expr
               Advance;
               declare
                  Arrow_Node : AST.AST_Node_Ptr;
               begin
                  Arrow_Node := new AST.AST_Node (AST.Node_Arrow_Function);
                  Arrow_Node.Arrow_Param_Count := 0;
                  Arrow_Node.Arrow_Params := null;
                  
                  if Match (Lexer.Token_Left_Brace) then
                     Arrow_Node.Is_Expression_Body := False;
                     Arrow_Node.Arrow_Body := Parse_Block;
                  else
                     Arrow_Node.Is_Expression_Body := True;
                     Arrow_Node.Arrow_Body := Parse_Expression;
                  end if;
                  
                  return Arrow_Node;
               end;
            else
               -- Empty () parens without arrow - error or special case
               Report_Error ("Empty parentheses without expression");
               return null;
            end if;
         end if;
         
         -- Parse first element (could be expression or parameter)
         Node := Parse_Expression;
         
         -- Check what comes next
         if Match (Lexer.Token_Comma) then
            -- Multiple elements: could be (a, b) => or error
            -- For now, assume arrow function with multiple params
            declare
               Params : array (1 .. 100) of AST.AST_Node_Ptr;
               Param_Cnt : Natural := 1;
            begin
               -- First parameter must be an identifier for arrow function
               if Node.Kind /= AST.Node_Identifier then
                  Report_Error ("Arrow function parameters must be identifiers");
                  return null;
               end if;
               Params (1) := Node;
               
               -- Parse remaining parameters
               while Match (Lexer.Token_Comma) loop
                  Advance;
                  if not Match (Lexer.Token_Identifier) then
                     Report_Error ("Expected parameter name");
                     return null;
                  end if;
                  Param_Cnt := Param_Cnt + 1;
                  Params (Param_Cnt) := new AST.AST_Node (AST.Node_Identifier);
                  Params (Param_Cnt).Id_Length := Current_Token.Length;
                  Params (Param_Cnt).Id_Name (1 .. Current_Token.Length) := 
                     Current_Token.Lexeme (1 .. Current_Token.Length);
                  Advance;
               end loop;
               
               if not Consume (Lexer.Token_Right_Paren, "Expected ')'") then
                  return null;
               end if;
               
               if not Consume (Lexer.Token_Arrow, "Expected '=>' for arrow function") then
                  return null;
               end if;
               
               -- Build arrow function
               declare
                  Arrow_Node : AST.AST_Node_Ptr;
               begin
                  Arrow_Node := new AST.AST_Node (AST.Node_Arrow_Function);
                  Arrow_Node.Arrow_Param_Count := Param_Cnt;
                  Arrow_Node.Arrow_Params := new AST.Node_Array (1 .. Param_Cnt);
                  for I in 1 .. Param_Cnt loop
                     Arrow_Node.Arrow_Params (I) := Params (I);
                  end loop;
                  
                  if Match (Lexer.Token_Left_Brace) then
                     Arrow_Node.Is_Expression_Body := False;
                     Arrow_Node.Arrow_Body := Parse_Block;
                  else
                     Arrow_Node.Is_Expression_Body := True;
                     Arrow_Node.Arrow_Body := Parse_Expression;
                  end if;
                  
                  return Arrow_Node;
               end;
            end;
         elsif Match (Lexer.Token_Right_Paren) then
            Advance;
            -- Check for arrow
            if Match (Lexer.Token_Arrow) then
               -- (x) => expr - single parameter arrow function
               Advance;
               if Node.Kind /= AST.Node_Identifier then
                  Report_Error ("Arrow function parameter must be identifier");
                  return null;
               end if;
               
               declare
                  Arrow_Node : AST.AST_Node_Ptr;
               begin
                  Arrow_Node := new AST.AST_Node (AST.Node_Arrow_Function);
                  Arrow_Node.Arrow_Param_Count := 1;
                  Arrow_Node.Arrow_Params := new AST.Node_Array (1 .. 1);
                  Arrow_Node.Arrow_Params (1) := Node;
                  
                  if Match (Lexer.Token_Left_Brace) then
                     Arrow_Node.Is_Expression_Body := False;
                     Arrow_Node.Arrow_Body := Parse_Block;
                  else
                     Arrow_Node.Is_Expression_Body := True;
                     Arrow_Node.Arrow_Body := Parse_Expression;
                  end if;
                  
                  return Arrow_Node;
               end;
            else
               -- Just a parenthesized expression
               return Node;
            end if;
         else
            Report_Error ("Expected ')' after expression");
            return null;
         end if;
      elsif Match (Lexer.Token_Left_Bracket) then
         -- Array literal [1, 2, 3]
         Advance;
         declare
            Temp_Elements : array (1 .. 100) of AST.AST_Node_Ptr;
            Count : Natural := 0;
            Array_Node : AST.AST_Node_Ptr;
         begin
            -- Empty array []
            if Match (Lexer.Token_Right_Bracket) then
               Advance;
               Array_Node := new AST.AST_Node (AST.Node_Array_Literal);
               Array_Node.Elements := new AST.Node_Array (1 .. 1);
               Array_Node.Element_Count := 0;
               return Array_Node;
            end if;
            
            -- Parse array elements
            loop
               Count := Count + 1;
               Temp_Elements (Count) := Parse_Expression;
               
               exit when not Match (Lexer.Token_Comma);
               Advance;  -- consume comma
            end loop;
            
            if not Consume (Lexer.Token_Right_Bracket, "Expected ']' after array elements") then
               return null;
            end if;
            
            Array_Node := new AST.AST_Node (AST.Node_Array_Literal);
            Array_Node.Element_Count := Count;
            Array_Node.Elements := new AST.Node_Array (1 .. Count);
            for I in 1 .. Count loop
               Array_Node.Elements (I) := Temp_Elements (I);
            end loop;
            
            return Array_Node;
         end;
      elsif Match (Lexer.Token_Left_Brace) then
         -- Object literal {key: value, ...}
         Advance;
         declare
            Temp_Props : array (1 .. 100) of AST.AST_Node_Ptr;
            Count : Natural := 0;
            Obj_Node : AST.AST_Node_Ptr;
            Key_Name : String (1 .. 256);
            Key_Len : Natural;
         begin
            -- Empty object {}
            if Match (Lexer.Token_Right_Brace) then
               Advance;
               Obj_Node := new AST.AST_Node (AST.Node_Object_Literal);
               Obj_Node.Properties := new AST.Node_Array (1 .. 1);
               Obj_Node.Property_Count := 0;
               return Obj_Node;
            end if;
            
            -- Parse properties
            loop
               Count := Count + 1;
               
               -- Parse key (identifier or string)
               if Match (Lexer.Token_Identifier) then
                  Key_Len := Current_Token.Length;
                  Key_Name (1 .. Key_Len) := Current_Token.Lexeme (1 .. Key_Len);
                  Advance;
               elsif Match (Lexer.Token_String) then
                  Key_Len := Current_Token.Length;
                  Key_Name (1 .. Key_Len) := Current_Token.Lexeme (1 .. Key_Len);
                  Advance;
               else
                  Report_Error ("Expected property name");
                  return null;
               end if;
               
               if not Consume (Lexer.Token_Colon, "Expected ':' after property name") then
                  return null;
               end if;
               
               -- Create property node
               declare
                  Prop_Node : constant AST.AST_Node_Ptr := new AST.AST_Node (AST.Node_Property);
               begin
                  Prop_Node.Prop_Key_Length := Key_Len;
                  Prop_Node.Prop_Key (1 .. Key_Len) := Key_Name (1 .. Key_Len);
                  Prop_Node.Prop_Value := Parse_Expression;
                  Temp_Props (Count) := Prop_Node;
               end;
               
               exit when not Match (Lexer.Token_Comma);
               Advance;  -- consume comma
               -- Allow trailing comma before closing brace
               exit when Match (Lexer.Token_Right_Brace);
            end loop;
            
            if not Consume (Lexer.Token_Right_Brace, "Expected '}' after object properties") then
               return null;
            end if;
            
            Obj_Node := new AST.AST_Node (AST.Node_Object_Literal);
            Obj_Node.Property_Count := Count;
            Obj_Node.Properties := new AST.Node_Array (1 .. Count);
            for I in 1 .. Count loop
               Obj_Node.Properties (I) := Temp_Props (I);
            end loop;
            
            return Obj_Node;
         end;
      else
         Report_Error ("Unexpected token in expression");
         return null;
      end if;
   end Parse_Primary;

   -- Parse expression (top-level entry point for expressions)
   function Parse_Expression return AST.AST_Node_Ptr is
   begin
      return Parse_Ternary;
   end Parse_Expression;

   -- Parse ternary conditional expressions (? :)
   function Parse_Ternary return AST.AST_Node_Ptr is
      Condition : AST.AST_Node_Ptr;
      True_Expr : AST.AST_Node_Ptr;
      False_Expr : AST.AST_Node_Ptr;
      Result : AST.AST_Node_Ptr;
   begin
      Condition := Parse_Logical_Or;
      
      if Current_Token.Kind = Lexer.Token_Question then
         Advance;  -- consume '?'
         True_Expr := Parse_Logical_Or;
         
         if Current_Token.Kind /= Lexer.Token_Colon then
            Report_Error ("Expected ':' in ternary operator");
            return Condition;
         end if;
         Advance;  -- consume ':'
         
         False_Expr := Parse_Ternary;  -- Right-associative
         
         Result := new AST.AST_Node'(
            Kind => AST.Node_Ternary_Op,
            Ternary_Condition => Condition,
            Ternary_True_Expr => True_Expr,
            Ternary_False_Expr => False_Expr
         );
         return Result;
      end if;
      
      return Condition;
   end Parse_Ternary;

   -- Parse logical OR expressions (||)
   function Parse_Logical_Or return AST.AST_Node_Ptr is
      Left : AST.AST_Node_Ptr;
      Node : AST.AST_Node_Ptr;
      Op : String (1 .. 3);
      Op_Len : Natural;
   begin
      Left := Parse_Logical_And;
      
      while Match (Lexer.Token_Or_Or) loop
         Op_Len := Current_Token.Length;
         Op (1 .. Op_Len) := Current_Token.Lexeme (1 .. Current_Token.Length);
         Advance;
         
         Node := new AST.AST_Node (AST.Node_Binary_Op);
         Node.Left := Left;
         Node.Op_Length := Op_Len;
         Node.Operator (1 .. Op_Len) := Op (1 .. Op_Len);
         Node.Right := Parse_Logical_And;
         Left := Node;
      end loop;
      
      return Left;
   end Parse_Logical_Or;

   -- Parse logical AND expressions (&&)
   function Parse_Logical_And return AST.AST_Node_Ptr is
      Left : AST.AST_Node_Ptr;
      Node : AST.AST_Node_Ptr;
      Op : String (1 .. 3);
      Op_Len : Natural;
   begin
      Left := Parse_Equality;
      
      while Match (Lexer.Token_And_And) loop
         Op_Len := Current_Token.Length;
         Op (1 .. Op_Len) := Current_Token.Lexeme (1 .. Current_Token.Length);
         Advance;
         
         Node := new AST.AST_Node (AST.Node_Binary_Op);
         Node.Left := Left;
         Node.Op_Length := Op_Len;
         Node.Operator (1 .. Op_Len) := Op (1 .. Op_Len);
         Node.Right := Parse_Equality;
         Left := Node;
      end loop;
      
      return Left;
   end Parse_Logical_And;

   -- Parse equality expressions (==, !=, ===, !==)
   function Parse_Equality return AST.AST_Node_Ptr is
      Left : AST.AST_Node_Ptr;
      Node : AST.AST_Node_Ptr;
      Op : String (1 .. 3);
      Op_Len : Natural;
   begin
      Left := Parse_Comparison;
      
      while Match (Lexer.Token_Equal_Equal) or Match (Lexer.Token_Bang_Equal) or 
            Match (Lexer.Token_Equal_Equal_Equal) or Match (Lexer.Token_Bang_Equal_Equal) loop
         Op_Len := Current_Token.Length;
         Op (1 .. Op_Len) := Current_Token.Lexeme (1 .. Current_Token.Length);
         Advance;
         
         Node := new AST.AST_Node (AST.Node_Binary_Op);
         Node.Left := Left;
         Node.Op_Length := Op_Len;
         Node.Operator (1 .. Op_Len) := Op (1 .. Op_Len);
         Node.Right := Parse_Comparison;
         Left := Node;
      end loop;
      
      return Left;
   end Parse_Equality;

   -- Parse comparison expressions (<, <=, >, >=)
   function Parse_Comparison return AST.AST_Node_Ptr is
      Left : AST.AST_Node_Ptr;
      Node : AST.AST_Node_Ptr;
      Op : String (1 .. 3);
      Op_Len : Natural;
   begin
      Left := Parse_Additive;
      
      while Match (Lexer.Token_Less) or Match (Lexer.Token_Less_Equal) or
            Match (Lexer.Token_Greater) or Match (Lexer.Token_Greater_Equal) loop
         Op_Len := Current_Token.Length;
         Op (1 .. Op_Len) := Current_Token.Lexeme (1 .. Current_Token.Length);
         Advance;
         
         Node := new AST.AST_Node (AST.Node_Binary_Op);
         Node.Left := Left;
         Node.Op_Length := Op_Len;
         Node.Operator (1 .. Op_Len) := Op (1 .. Op_Len);
         Node.Right := Parse_Additive;
         Left := Node;
      end loop;
      
      return Left;
   end Parse_Comparison;

   -- Parse additive expressions (+, -)
   function Parse_Additive return AST.AST_Node_Ptr is
      Left : AST.AST_Node_Ptr;
      Node : AST.AST_Node_Ptr;
      Op : String (1 .. 3);
      Op_Len : Natural;
   begin
      Left := Parse_Multiplicative;
      
      while Match (Lexer.Token_Plus) or Match (Lexer.Token_Minus) loop
         Op_Len := Current_Token.Length;
         Op (1 .. Op_Len) := Current_Token.Lexeme (1 .. Current_Token.Length);
         Advance;
         
         Node := new AST.AST_Node (AST.Node_Binary_Op);
         Node.Left := Left;
         Node.Op_Length := Op_Len;
         Node.Operator (1 .. Op_Len) := Op (1 .. Op_Len);
         Node.Right := Parse_Multiplicative;
         Left := Node;
      end loop;
      
      return Left;
   end Parse_Additive;

   -- Parse multiplicative expressions (*, /, %)
   function Parse_Multiplicative return AST.AST_Node_Ptr is
      Left : AST.AST_Node_Ptr;
      Node : AST.AST_Node_Ptr;
      Op : String (1 .. 3);
      Op_Len : Natural;
   begin
      Left := Parse_Unary;
      
      while Match (Lexer.Token_Star) or Match (Lexer.Token_Slash) or Match (Lexer.Token_Percent) loop
         Op_Len := Current_Token.Length;
         Op (1 .. Op_Len) := Current_Token.Lexeme (1 .. Current_Token.Length);
         Advance;
         
         Node := new AST.AST_Node (AST.Node_Binary_Op);
         Node.Left := Left;
         Node.Op_Length := Op_Len;
         Node.Operator (1 .. Op_Len) := Op (1 .. Op_Len);
         Node.Right := Parse_Unary;
         Left := Node;
      end loop;
      
      return Left;
   end Parse_Multiplicative;

   -- Parse statements (if, while, for, return, var/let/const declarations, expressions)
   function Parse_Statement return AST.AST_Node_Ptr is
      Node : AST.AST_Node_Ptr;
      Decl_Kind : AST.Declaration_Kind;
      Name : String (1 .. 256);
      Name_Len : Natural;
   begin
      if Match (Lexer.Token_Function) then
         Advance;
         
         -- Get function name
         if not Match (Lexer.Token_Identifier) then
            Report_Error ("Expected function name");
            return null;
         end if;
         
         Node := new AST.AST_Node (AST.Node_Function_Declaration);
         Node.Func_Name_Length := Current_Token.Length;
         Node.Func_Name (1 .. Node.Func_Name_Length) := Current_Token.Lexeme (1 .. Current_Token.Length);
         Advance;
         
         if not Consume (Lexer.Token_Left_Paren, "Expected '(' after function name") then
            return null;
         end if;
         
         -- Parse parameters
         if not Match (Lexer.Token_Right_Paren) then
            declare
               Params : array (1 .. 100) of AST.AST_Node_Ptr;
               Param_Cnt : Natural := 0;
            begin
               loop
                  if not Match (Lexer.Token_Identifier) then
                     Report_Error ("Expected parameter name");
                     return null;
                  end if;
                  
                  Param_Cnt := Param_Cnt + 1;
                  Params (Param_Cnt) := new AST.AST_Node (AST.Node_Identifier);
                  Params (Param_Cnt).Id_Length := Current_Token.Length;
                  Params (Param_Cnt).Id_Name (1 .. Current_Token.Length) := 
                     Current_Token.Lexeme (1 .. Current_Token.Length);
                  Advance;
                  
                  exit when not Match (Lexer.Token_Comma);
                  Advance;
               end loop;
               
               Node.Param_Count := Param_Cnt;
               Node.Params := new AST.Node_Array (1 .. Param_Cnt);
               for I in 1 .. Param_Cnt loop
                  Node.Params (I) := Params (I);
               end loop;
            end;
         else
            Node.Param_Count := 0;
            Node.Params := null;
         end if;
         
         if not Consume (Lexer.Token_Right_Paren, "Expected ')' after parameters") then
            return null;
         end if;
         
         -- Parse function body (block)
         Node.Func_Body := Parse_Block;
         return Node;
         
      elsif Match (Lexer.Token_Class) then
         Advance;
         
         -- Get class name
         if not Match (Lexer.Token_Identifier) then
            Report_Error ("Expected class name");
            return null;
         end if;
         
         Node := new AST.AST_Node (AST.Node_Class_Declaration);
         Node.Class_Name_Length := Current_Token.Length;
         Node.Class_Name (1 .. Node.Class_Name_Length) := Current_Token.Lexeme (1 .. Current_Token.Length);
         Advance;
         
         -- Check for extends
         if Match (Lexer.Token_Extends) then
            Advance;
            if not Match (Lexer.Token_Identifier) then
               Report_Error ("Expected parent class name after 'extends'");
               return null;
            end if;
            Node.Parent_Class_Name_Length := Current_Token.Length;
            Node.Parent_Class_Name (1 .. Node.Parent_Class_Name_Length) := 
               Current_Token.Lexeme (1 .. Current_Token.Length);
            Advance;
         else
            Node.Parent_Class_Name_Length := 0;  -- No parent class
         end if;
         
         if not Consume (Lexer.Token_Left_Brace, "Expected '{' after class name") then
            return null;
         end if;
         
         -- Parse class methods
         declare
            Methods : array (1 .. 100) of AST.AST_Node_Ptr;
            Method_Cnt : Natural := 0;
         begin
            while not Match (Lexer.Token_Right_Brace) and not Match (Lexer.Token_EOF) loop
               -- Parse method: name(params) { body }
               if not Match (Lexer.Token_Identifier) then
                  Report_Error ("Expected method name");
                  return null;
               end if;
               
               declare
                  Method_Node : AST.AST_Node_Ptr;
               begin
                  Method_Node := new AST.AST_Node (AST.Node_Function_Declaration);
                  Method_Node.Func_Name_Length := Current_Token.Length;
                  Method_Node.Func_Name (1 .. Method_Node.Func_Name_Length) := 
                     Current_Token.Lexeme (1 .. Current_Token.Length);
                  Advance;
                  
                  if not Consume (Lexer.Token_Left_Paren, "Expected '(' after method name") then
                     return null;
                  end if;
                  
                  -- Parse parameters
                  if not Match (Lexer.Token_Right_Paren) then
                     declare
                        Params : array (1 .. 100) of AST.AST_Node_Ptr;
                        Param_Cnt : Natural := 0;
                     begin
                        loop
                           if not Match (Lexer.Token_Identifier) then
                              Report_Error ("Expected parameter name");
                              return null;
                           end if;
                           
                           Param_Cnt := Param_Cnt + 1;
                           Params (Param_Cnt) := new AST.AST_Node (AST.Node_Identifier);
                           Params (Param_Cnt).Id_Length := Current_Token.Length;
                           Params (Param_Cnt).Id_Name (1 .. Current_Token.Length) := 
                              Current_Token.Lexeme (1 .. Current_Token.Length);
                           Advance;
                           
                           exit when not Match (Lexer.Token_Comma);
                           Advance;
                        end loop;
                        
                        Method_Node.Param_Count := Param_Cnt;
                        Method_Node.Params := new AST.Node_Array (1 .. Param_Cnt);
                        for I in 1 .. Param_Cnt loop
                           Method_Node.Params (I) := Params (I);
                        end loop;
                     end;
                  else
                     Method_Node.Param_Count := 0;
                     Method_Node.Params := null;
                  end if;
                  
                  if not Consume (Lexer.Token_Right_Paren, "Expected ')' after parameters") then
                     return null;
                  end if;
                  
                  -- Parse method body
                  Method_Node.Func_Body := Parse_Block;
                  
                  Method_Cnt := Method_Cnt + 1;
                  Methods (Method_Cnt) := Method_Node;
               end;
            end loop;
            
            Node.Method_Count := Method_Cnt;
            if Method_Cnt > 0 then
               Node.Class_Methods := new AST.Node_Array (1 .. Method_Cnt);
               for I in 1 .. Method_Cnt loop
                  Node.Class_Methods (I) := Methods (I);
               end loop;
            else
               Node.Class_Methods := null;
            end if;
         end;
         
         if not Consume (Lexer.Token_Right_Brace, "Expected '}' after class body") then
            return null;
         end if;
         
         return Node;
         
      elsif Match (Lexer.Token_Return) then
         Advance;
         
         Node := new AST.AST_Node (AST.Node_Return_Statement);
         
         -- Return value is optional
         if not Match (Lexer.Token_Semicolon) and not Match (Lexer.Token_Right_Brace) then
            Node.Return_Value := Parse_Expression;
         else
            Node.Return_Value := null;
         end if;
         
         return Node;
         
      elsif Match (Lexer.Token_Break) then
         Advance;
         Node := new AST.AST_Node (AST.Node_Break_Statement);
         return Node;
         
      elsif Match (Lexer.Token_Continue) then
         Advance;
         Node := new AST.AST_Node (AST.Node_Continue_Statement);
         return Node;
         
      elsif Match (Lexer.Token_If) then
         Advance;
         
         if not Consume (Lexer.Token_Left_Paren, "Expected '(' after 'if'") then
            return null;
         end if;
         
         Node := new AST.AST_Node (AST.Node_If_Statement);
         Node.Condition := Parse_Expression;
         
         if not Consume (Lexer.Token_Right_Paren, "Expected ')' after condition") then
            return null;
         end if;
         
         -- Parse then branch (can be a block or a single statement)
         if Match (Lexer.Token_Left_Brace) then
            Node.Then_Branch := Parse_Block;
         else
            Node.Then_Branch := Parse_Statement;
         end if;
         
         if Match (Lexer.Token_Else) then
            Advance;
            if Match (Lexer.Token_If) then
               Node.Else_Branch := Parse_Statement;
            elsif Match (Lexer.Token_Left_Brace) then
               Node.Else_Branch := Parse_Block;
            else
               Node.Else_Branch := Parse_Statement;
            end if;
         else
            Node.Else_Branch := null;
         end if;
         
         return Node;
         
      elsif Match (Lexer.Token_While) then
         Advance;
         
         if not Consume (Lexer.Token_Left_Paren, "Expected '(' after 'while'") then
            return null;
         end if;
         
         Node := new AST.AST_Node (AST.Node_While_Statement);
         Node.While_Condition := Parse_Expression;
         
         if not Consume (Lexer.Token_Right_Paren, "Expected ')' after condition") then
            return null;
         end if;
         
         -- Parse while body (can be a block or a single statement)
         if Match (Lexer.Token_Left_Brace) then
            Node.While_Body := Parse_Block;
         else
            Node.While_Body := Parse_Statement;
         end if;
         return Node;
         
      elsif Match (Lexer.Token_Do) then
         Advance;
         
         Node := new AST.AST_Node (AST.Node_Do_While_Statement);
         
         -- Parse do-while body (can be a block or a single statement)
         if Match (Lexer.Token_Left_Brace) then
            Node.Do_While_Body := Parse_Block;
         else
            Node.Do_While_Body := Parse_Statement;
         end if;
         
         if not Consume (Lexer.Token_While, "Expected 'while' after do block") then
            return null;
         end if;
         
         if not Consume (Lexer.Token_Left_Paren, "Expected '(' after 'while'") then
            return null;
         end if;
         
         Node.Do_While_Condition := Parse_Expression;
         
         if not Consume (Lexer.Token_Right_Paren, "Expected ')' after condition") then
            return null;
         end if;
         
         if not Consume (Lexer.Token_Semicolon, "Expected ';' after do-while") then
            return null;
         end if;
         
         return Node;
         
      elsif Match (Lexer.Token_For) then
         Advance;
         
         if not Consume (Lexer.Token_Left_Paren, "Expected '(' after 'for'") then
            return null;
         end if;
         
         Node := new AST.AST_Node (AST.Node_For_Statement);
         
         Node.For_Init := Parse_Statement;
         
         if not Consume (Lexer.Token_Semicolon, "Expected ';' after for initializer") then
            return null;
         end if;
         
         Node.For_Condition := Parse_Expression;
         
         if not Consume (Lexer.Token_Semicolon, "Expected ';' after for condition") then
            return null;
         end if;
         
         -- Parse update expression (can be i++, ++i, i=i+1, etc.)
         if not Match (Lexer.Token_Right_Paren) then
            -- Parse as expression statement
            declare
               Update_Expr : constant AST.AST_Node_Ptr := Parse_Expression;
               Update_Stmt : constant AST.AST_Node_Ptr := new AST.AST_Node (AST.Node_Expression_Statement);
            begin
               Update_Stmt.Expr := Update_Expr;
               Node.For_Update := Update_Stmt;
            end;
         end if;
         
         if not Consume (Lexer.Token_Right_Paren, "Expected ')' after for clauses") then
            return null;
         end if;
         
         -- Parse for body (can be a block or a single statement)
         if Match (Lexer.Token_Left_Brace) then
            Node.For_Body := Parse_Block;
         else
            Node.For_Body := Parse_Statement;
         end if;
         return Node;
         
      elsif Match (Lexer.Token_Switch) then
         Advance;
         
         if not Consume (Lexer.Token_Left_Paren, "Expected '(' after 'switch'") then
            return null;
         end if;
         
         Node := new AST.AST_Node (AST.Node_Switch_Statement);
         Node.Switch_Expr := Parse_Expression;
         
         if not Consume (Lexer.Token_Right_Paren, "Expected ')' after switch expression") then
            return null;
         end if;
         
         if not Consume (Lexer.Token_Left_Brace, "Expected '{' after switch") then
            return null;
         end if;
         
         -- Parse cases
         declare
            Cases : array (1 .. 50) of AST.AST_Node_Ptr;
            Case_Count : Natural := 0;
         begin
            while not Match (Lexer.Token_Right_Brace) and Current_Token.Kind /= Lexer.Token_EOF loop
               if Match (Lexer.Token_Case) or Match (Lexer.Token_Default) then
                  declare
                     Is_Default : constant Boolean := Match (Lexer.Token_Default);
                     Case_Node : AST.AST_Node_Ptr := new AST.AST_Node (AST.Node_Case_Clause);
                     Statements : array (1 .. 100) of AST.AST_Node_Ptr;
                     Stmt_Count : Natural := 0;
                  begin
                     Advance;  -- consume 'case' or 'default'
                     
                     if Is_Default then
                        Case_Node.Case_Value := null;
                     else
                        Case_Node.Case_Value := Parse_Expression;
                     end if;
                     
                     if not Consume (Lexer.Token_Colon, "Expected ':' after case value") then
                        return null;
                     end if;
                     
                     -- Parse statements until next case/default/close brace
                     while not Match (Lexer.Token_Case) and not Match (Lexer.Token_Default) 
                           and not Match (Lexer.Token_Right_Brace) 
                           and Current_Token.Kind /= Lexer.Token_EOF 
                           and Stmt_Count < 100 loop
                        -- Skip optional semicolons
                        if Match (Lexer.Token_Semicolon) then
                           Advance;
                        else
                           declare
                              Stmt : constant AST.AST_Node_Ptr := Parse_Statement;
                           begin
                              if Stmt /= null then
                                 Stmt_Count := Stmt_Count + 1;
                                 Statements (Stmt_Count) := Stmt;
                              else
                                 -- If we can't parse, exit to prevent infinite loop
                                 exit;
                              end if;
                           end;
                        end if;
                     end loop;
                     
                     Case_Node.Case_Statement_Count := Stmt_Count;
                     if Stmt_Count > 0 then
                        Case_Node.Case_Statements := new AST.Node_Array (1 .. Stmt_Count);
                        for I in 1 .. Stmt_Count loop
                           Case_Node.Case_Statements (I) := Statements (I);
                        end loop;
                     else
                        Case_Node.Case_Statements := null;
                     end if;
                     
                     Case_Count := Case_Count + 1;
                     Cases (Case_Count) := Case_Node;
                  end;
               else
                  Report_Error ("Expected 'case' or 'default' in switch body");
                  exit;
               end if;
            end loop;
            
            if not Consume (Lexer.Token_Right_Brace, "Expected '}' after switch body") then
               return null;
            end if;
            
            Node.Case_Count := Case_Count;
            if Case_Count > 0 then
               Node.Cases := new AST.Node_Array (1 .. Case_Count);
               for I in 1 .. Case_Count loop
                  Node.Cases (I) := Cases (I);
               end loop;
            else
               Node.Cases := null;
            end if;
         end;
         
         return Node;
         
      elsif Match (Lexer.Token_Try) then
         Advance;
         
         Node := new AST.AST_Node (AST.Node_Try_Statement);
         Node.Try_Body := Parse_Block;
         Node.Catch_Param_Length := 0;
         Node.Catch_Body := null;
         Node.Finally_Body := null;
         
         -- Parse catch block (optional)
         if Match (Lexer.Token_Catch) then
            Advance;
            
            if not Consume (Lexer.Token_Left_Paren, "Expected '(' after 'catch'") then
               return null;
            end if;
            
            if not Match (Lexer.Token_Identifier) then
               Report_Error ("Expected parameter name in catch clause");
               return null;
            end if;
            
            Node.Catch_Param_Length := Current_Token.Length;
            Node.Catch_Param (1 .. Node.Catch_Param_Length) := 
               Current_Token.Lexeme (1 .. Current_Token.Length);
            Advance;
            
            if not Consume (Lexer.Token_Right_Paren, "Expected ')' after catch parameter") then
               return null;
            end if;
            
            Node.Catch_Body := Parse_Block;
         end if;
         
         -- Parse finally block (optional)
         if Match (Lexer.Token_Finally) then
            Advance;
            Node.Finally_Body := Parse_Block;
         end if;
         
         -- Must have either catch or finally (or both)
         if Node.Catch_Body = null and Node.Finally_Body = null then
            Report_Error ("try statement must have catch or finally block");
            return null;
         end if;
         
         return Node;
         
      elsif Match (Lexer.Token_Throw) then
         Advance;
         
         Node := new AST.AST_Node (AST.Node_Throw_Statement);
         Node.Throw_Expression := Parse_Expression;
         
         return Node;
         
      elsif Match (Lexer.Token_Let) or Match (Lexer.Token_Const) or Match (Lexer.Token_Var) then
         if Match (Lexer.Token_Let) then
            Decl_Kind := AST.Decl_Let;
         elsif Match (Lexer.Token_Const) then
            Decl_Kind := AST.Decl_Const;
         else
            Decl_Kind := AST.Decl_Var;
         end if;
         Advance;
         
         if not Match (Lexer.Token_Identifier) then
            Report_Error ("Expected identifier after variable declaration");
            return null;
         end if;
         
         Name_Len := Current_Token.Length;
         Name (1 .. Name_Len) := Current_Token.Lexeme (1 .. Name_Len);
         Advance;
         
         if not Match (Lexer.Token_Equal) then
            Report_Error ("Expected '=' after variable name");
            return null;
         end if;
         Advance;
         
         Node := new AST.AST_Node (AST.Node_Variable_Declaration);
         Node.Decl_Type := Decl_Kind;
         Node.Var_Name_Length := Name_Len;
         Node.Var_Name (1 .. Name_Len) := Name (1 .. Name_Len);
         Node.Initializer := Parse_Expression;
         
         return Node;
         
      elsif Match (Lexer.Token_Identifier) then
         Name_Len := Current_Token.Length;
         Name (1 .. Name_Len) := Current_Token.Lexeme (1 .. Name_Len);
         Advance;
         
         -- Check for array/member access before checking for assignment
         if Match (Lexer.Token_Left_Bracket) or Match (Lexer.Token_Dot) then
            -- Parse as full expression, then check for assignment
            declare
               Id_Node : constant AST.AST_Node_Ptr := new AST.AST_Node (AST.Node_Identifier);
               Expr_Node : AST.AST_Node_Ptr;
            begin
               Id_Node.Id_Length := Name_Len;
               Id_Node.Id_Name (1 .. Name_Len) := Name (1 .. Name_Len);
               
               -- Parse postfix operators ([] and .)
               Expr_Node := Id_Node;
               loop
                  if Match (Lexer.Token_Left_Bracket) then
                     -- Array indexing
                     Advance;
                     declare
                        Index_Node : constant AST.AST_Node_Ptr := new AST.AST_Node (AST.Node_Array_Index);
                     begin
                        Index_Node.Array_Expr := Expr_Node;
                        Index_Node.Index_Expr := Parse_Expression;
                        if not Consume (Lexer.Token_Right_Bracket, "Expected ']'") then
                           return null;
                        end if;
                        Expr_Node := Index_Node;
                     end;
                  elsif Match (Lexer.Token_Dot) then
                     -- Member access
                     Advance;
                     if not Match (Lexer.Token_Identifier) then
                        Report_Error ("Expected property name after '.'");
                        return null;
                     end if;
                     declare
                        Member_Node : constant AST.AST_Node_Ptr := new AST.AST_Node (AST.Node_Member_Access);
                     begin
                        Member_Node.Object_Expr := Expr_Node;
                        Member_Node.Member_Length := Current_Token.Length;
                        Member_Node.Member_Name (1 .. Current_Token.Length) := 
                           Current_Token.Lexeme (1 .. Current_Token.Length);
                        Advance;
                        Expr_Node := Member_Node;
                     end;
                  elsif Match (Lexer.Token_Left_Paren) then
                     -- Method call: obj.method()
                     Advance;
                     declare
                        Call_Node : constant AST.AST_Node_Ptr := new AST.AST_Node (AST.Node_Method_Call);
                     begin
                        Call_Node.Callee := Expr_Node;
                        
                        -- Parse arguments
                        if not Match (Lexer.Token_Right_Paren) then
                           declare
                              Args : array (1 .. 100) of AST.AST_Node_Ptr;
                              Arg_Cnt : Natural := 0;
                           begin
                              loop
                                 Arg_Cnt := Arg_Cnt + 1;
                                 Args (Arg_Cnt) := Parse_Expression;
                                 exit when not Match (Lexer.Token_Comma);
                                 Advance;
                              end loop;
                              
                              Call_Node.Method_Arg_Count := Arg_Cnt;
                              Call_Node.Method_Arguments := new AST.Node_Array (1 .. Arg_Cnt);
                              for I in 1 .. Arg_Cnt loop
                                 Call_Node.Method_Arguments (I) := Args (I);
                              end loop;
                           end;
                        else
                           Call_Node.Method_Arg_Count := 0;
                           Call_Node.Method_Arguments := null;
                        end if;
                        
                        if not Consume (Lexer.Token_Right_Paren, "Expected ')' after arguments") then
                           return null;
                        end if;
                        
                        Expr_Node := Call_Node;
                     end;
                  else
                     exit;
                  end if;
               end loop;
               
               -- Check for postfix increment/decrement
               if Match (Lexer.Token_Plus_Plus) or Match (Lexer.Token_Minus_Minus) then
                  declare
                     Update_Node : constant AST.AST_Node_Ptr := new AST.AST_Node (AST.Node_Postfix_Update);
                     Op_Len : constant Natural := Current_Token.Length;
                  begin
                     Update_Node.Update_Op_Length := Op_Len;
                     Update_Node.Update_Operator (1 .. Op_Len) := Current_Token.Lexeme (1 .. Op_Len);
                     Update_Node.Update_Operand := Expr_Node;
                     Advance;
                     Node := new AST.AST_Node (AST.Node_Expression_Statement);
                     Node.Expr := Update_Node;
                     return Node;
                  end;
               end if;
               
               -- Now check if this is an assignment
               if Match (Lexer.Token_Equal) then
                  Advance;
                  -- Member/array access assignment: obj.prop = value or arr[i] = value
                  declare
                     Assign_Node : constant AST.AST_Node_Ptr := new AST.AST_Node (AST.Node_Assignment);
                  begin
                     Assign_Node.Assign_Target := Expr_Node;  -- The member access or array index
                     Assign_Node.Assign_Name_Length := 0;  -- Not a simple name assignment
                     Assign_Node.Assign_Value := Parse_Expression;
                     return Assign_Node;
                  end;
               else
                  -- Just an expression statement
                  Node := new AST.AST_Node (AST.Node_Expression_Statement);
                  Node.Expr := Expr_Node;
                  return Node;
               end if;
            end;
         elsif Match (Lexer.Token_Equal) then
            Advance;
            Node := new AST.AST_Node (AST.Node_Assignment);
            Node.Assign_Name_Length := Name_Len;
            Node.Assign_Name (1 .. Name_Len) := Name (1 .. Name_Len);
            Node.Assign_Target := null;  -- Simple variable assignment, not member access
            Node.Assign_Value := Parse_Expression;
            return Node;
         else
            -- Not an assignment, treat as expression statement
            -- Need to "un-advance" the identifier by reconstructing it
            -- Actually, we need to call Parse_Expression from the current position
            -- Since we've already consumed the identifier, we need to use Parse_Expression
            -- which will see what comes next (e.g., '(' for function call)
            -- But we already advanced past the identifier!
            -- Let's create a minimal identifier node and see if there's more
            Node := new AST.AST_Node (AST.Node_Expression_Statement);
            
            -- Check if this is a function call
            if Match (Lexer.Token_Left_Paren) then
               -- Parse it as a function call
               Advance;
               declare
                  Call_Node : constant AST.AST_Node_Ptr := new AST.AST_Node (AST.Node_Function_Call);
               begin
                  Call_Node.Call_Name_Length := Name_Len;
                  Call_Node.Call_Name (1 .. Name_Len) := Name (1 .. Name_Len);
                  
                  -- Parse arguments
                  if not Match (Lexer.Token_Right_Paren) then
                     declare
                        Args : array (1 .. 100) of AST.AST_Node_Ptr;
                        Arg_Cnt : Natural := 0;
                     begin
                        loop
                           Arg_Cnt := Arg_Cnt + 1;
                           Args (Arg_Cnt) := Parse_Expression;
                           exit when not Match (Lexer.Token_Comma);
                           Advance;
                        end loop;
                        
                        Call_Node.Arg_Count := Arg_Cnt;
                        Call_Node.Arguments := new AST.Node_Array (1 .. Arg_Cnt);
                        for I in 1 .. Arg_Cnt loop
                           Call_Node.Arguments (I) := Args (I);
                        end loop;
                     end;
                  else
                     Call_Node.Arg_Count := 0;
                     Call_Node.Arguments := null;
                  end if;
                  
                  if not Consume (Lexer.Token_Right_Paren, "Expected ')' after arguments") then
                     return null;
                  end if;
                  
                  Node.Expr := Call_Node;
                  return Node;
               end;
            else
               -- Just an identifier, check for postfix ++/--
               declare
                  Id_Node : constant AST.AST_Node_Ptr := new AST.AST_Node (AST.Node_Identifier);
               begin
                  Id_Node.Id_Length := Name_Len;
                  Id_Node.Id_Name (1 .. Name_Len) := Name (1 .. Name_Len);
                  
                  -- Check for postfix increment/decrement
                  if Match (Lexer.Token_Plus_Plus) or Match (Lexer.Token_Minus_Minus) then
                     declare
                        Update_Node : constant AST.AST_Node_Ptr := new AST.AST_Node (AST.Node_Postfix_Update);
                        Op_Len : constant Natural := Current_Token.Length;
                     begin
                        Update_Node.Update_Op_Length := Op_Len;
                        Update_Node.Update_Operator (1 .. Op_Len) := Current_Token.Lexeme (1 .. Op_Len);
                        Update_Node.Update_Operand := Id_Node;
                        Advance;
                        Node.Expr := Update_Node;
                        return Node;
                     end;
                  elsif Match (Lexer.Token_Plus) or Match (Lexer.Token_Minus) or
                     Match (Lexer.Token_Star) or Match (Lexer.Token_Slash) or
                     Match (Lexer.Token_Less) or Match (Lexer.Token_Greater) or
                     Match (Lexer.Token_Equal_Equal) or Match (Lexer.Token_And_And) or
                     Match (Lexer.Token_Or_Or) then
                     
                     declare
                        Op : String (1 .. 3);
                        Op_Len : constant Natural := Current_Token.Length;
                        Bin_Node : constant AST.AST_Node_Ptr := new AST.AST_Node (AST.Node_Binary_Op);
                     begin
                        Op (1 .. Op_Len) := Current_Token.Lexeme (1 .. Op_Len);
                        Advance;
                        
                        Bin_Node.Left := Id_Node;
                        Bin_Node.Op_Length := Op_Len;
                        Bin_Node.Operator (1 .. Op_Len) := Op (1 .. Op_Len);
                        Bin_Node.Right := Parse_Comparison;
                        
                        Node.Expr := Bin_Node;
                        return Node;
                     end;
                  else
                     Node.Expr := Id_Node;
                     return Node;
                  end if;
               end;
            end if;
         end if;
      else
         -- General expression or assignment
         declare
            Expr_Node : constant AST.AST_Node_Ptr := Parse_Expression;
         begin
            -- Check if this is an assignment
            if Match (Lexer.Token_Equal) then
               Advance;
               Node := new AST.AST_Node (AST.Node_Assignment);
               Node.Assign_Target := Expr_Node;
               Node.Assign_Name_Length := 0;
               Node.Assign_Value := Parse_Expression;
               return Node;
            else
               -- Just an expression statement
               Node := new AST.AST_Node (AST.Node_Expression_Statement);
               Node.Expr := Expr_Node;
               return Node;
            end if;
         end;
      end if;
   end Parse_Statement;

   -- Parse block statements enclosed in braces { }
   function Parse_Block return AST.AST_Node_Ptr is
      Temp_Statements : array (1 .. 5000) of AST.AST_Node_Ptr;
      Count : Natural := 0;
      Node : AST.AST_Node_Ptr;
      Block_Node : AST.AST_Node_Ptr;
   begin
      if not Consume (Lexer.Token_Left_Brace, "Expected '{'") then
         return null;
      end if;
      
      while not Match (Lexer.Token_Right_Brace) and not Match (Lexer.Token_EOF) loop
         -- Skip optional semicolons
         if Match (Lexer.Token_Semicolon) then
            Advance;
         else
            Node := Parse_Statement;
            if Node /= null then
               Count := Count + 1;
               if Count > Temp_Statements'Last then
                  raise Constraint_Error with "Too many statements in block (max 5000)";
               end if;
               Temp_Statements (Count) := Node;
            end if;
            
            -- Consume optional semicolon after statement
            if Match (Lexer.Token_Semicolon) then
               Advance;
            end if;
         end if;
      end loop;
      
      if not Consume (Lexer.Token_Right_Brace, "Expected '}'") then
         return null;
      end if;
      
      Block_Node := new AST.AST_Node (AST.Node_Block_Statement);
      Block_Node.Block_Count := Count;
      if Count > 0 then
         Block_Node.Block_Statements := new AST.Node_Array (1 .. Count);
         for I in 1 .. Count loop
            Block_Node.Block_Statements (I) := Temp_Statements (I);
         end loop;
      end if;
      
      return Block_Node;
   end Parse_Block;

   -- Parse the entire program as a sequence of statements
   function Parse_Program return AST.AST_Node_Ptr is
      Temp_Statements : array (1 .. 5000) of AST.AST_Node_Ptr;
      Count : Natural := 0;
      Node : AST.AST_Node_Ptr;
      Block_Node : AST.AST_Node_Ptr;
   begin
      while not Match (Lexer.Token_EOF) loop
         -- Skip optional semicolons
         if Match (Lexer.Token_Semicolon) then
            Advance;
         else
            Node := Parse_Statement;
            if Node /= null then
               Count := Count + 1;
               if Count > Temp_Statements'Last then
                  Report_Error ("Program too complex (max 5000 top-level statements)");
                  return null;
               end if;
               Temp_Statements (Count) := Node;
            end if;
            
            -- Consume optional semicolon after statement
            if Match (Lexer.Token_Semicolon) then
               Advance;
            end if;
         end if;
         exit when Match (Lexer.Token_EOF);
      end loop;
      
      if Count = 0 then
         return null;
      elsif Count = 1 then
         return Temp_Statements (1);
      else
         Block_Node := new AST.AST_Node (AST.Node_Block_Statement);
         Block_Node.Block_Count := Count;
         Block_Node.Block_Statements := new AST.Node_Array (1 .. Count);
         for I in 1 .. Count loop
            Block_Node.Block_Statements (I) := Temp_Statements (I);
         end loop;
         return Block_Node;
      end if;
   end Parse_Program;

   -- Main entry point for parsing (calls Parse_Program)
   function Parse return AST.AST_Node_Ptr is
   begin
      return Parse_Program;
   end Parse;

end Parser;
