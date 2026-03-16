-- ***************************************************************************
--              JavaScript interpreter - evaluator
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

with Ada.Text_IO;
with Ada.Strings.Fixed;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Strings.Hash;
with Ada.Calendar;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;


package body Evaluator is
   use type AST.AST_Node_Ptr;
   use type AST.Node_Array_Ptr;
   use type AST.Node_Type;

   package Float_IO is new Ada.Text_IO.Float_IO (Float);

   -- Exception for early return from functions
   Return_Exception : exception;
   Return_Val : JS_Value;

   -- Exceptions for loop control
   Break_Exception : exception;
   Continue_Exception : exception;

   -- Exception for runtime errors
   Runtime_Error : exception;

   package Variable_Maps is new Ada.Containers.Indefinite_Hashed_Maps
     (Key_Type => String,
      Element_Type => JS_Value,
      Hash => Ada.Strings.Hash,
      Equivalent_Keys => "=");

   Variables : Variable_Maps.Map;

   -- Context for 'this' keyword
   Current_This : JS_Value_Ptr := null;

   -- Track which class constructor is currently executing (for super() calls)
   Current_Constructor_Class : AST.AST_Node_Ptr := null;

   -- Store a value in the global variable map
   procedure Set_Variable (Name : String; Val : JS_Value) is
   begin
      Variables.Include (Name, Val);
   end Set_Variable;

   -- Retrieve a variable value from the global variable map
   function Get_Variable (Name : String) return JS_Value is
   begin
      if Variables.Contains (Name) then
         return Variables.Element (Name);
      else
         return (Kind => Val_Undefined);
      end if;
   end Get_Variable;

   -- Clear all variables from the global variable map
   procedure Clear_Variables is
   begin
      Variables.Clear;
   end Clear_Variables;

   -- Initialize built-in objects and functions
   procedure Initialize_Builtins is
      Math_Obj : JS_Value (Kind => Val_Object);
      Console_Obj : JS_Value (Kind => Val_Object);
   begin
      -- Create Math object (empty object, methods handled specially)
      Math_Obj.Object_Properties := new Object_Maps.Map;
      Math_Obj.Is_Class_Instance := False;

      -- Add Math constants as properties (need pointers)
      declare
         PI_Val : constant JS_Value_Ptr := new JS_Value'(Kind => Val_Number, Number => 3.14159265359);
         E_Val : constant JS_Value_Ptr := new JS_Value'(Kind => Val_Number, Number => 2.71828182846);
      begin
         Math_Obj.Object_Properties.Include("PI", PI_Val);
         Math_Obj.Object_Properties.Include("E", E_Val);
      end;

      Set_Variable("Math", Math_Obj);

      -- Create console object (empty object, methods handled specially)
      Console_Obj.Object_Properties := new Object_Maps.Map;
      Console_Obj.Is_Class_Instance := False;
      Set_Variable("console", Console_Obj);
   end Initialize_Builtins;

   -- Convert a JavaScript value to a boolean using JavaScript truthiness rules
   function Value_To_Boolean (Val : JS_Value) return Boolean is
   begin
      case Val.Kind is
         when Val_Boolean =>
            return Val.Bool;
         when Val_Number =>
            return Val.Number /= 0.0;
         when Val_String =>
            return Val.Str_Length > 0;
         when Val_Array =>
            return Val.Array_Length > 0;
         when Val_Object =>
            return True;  -- Objects are always truthy
         when Val_Function =>
            return True;  -- Functions are always truthy
         when Val_Class =>
            return True;  -- Classes are always truthy
         when Val_Null | Val_Undefined =>
            return False;
      end case;
   end Value_To_Boolean;

   -- Execute a statement node without printing expression results
   procedure Eval_Statement (Node : AST.AST_Node_Ptr) is
   begin
      Eval_Statement (Node, False);
   end Eval_Statement;

   -- Execute a statement node with optional expression result printing
   procedure Eval_Statement (Node : AST.AST_Node_Ptr; Print_Expr : Boolean) is
      Val : JS_Value;
   begin
      if Node = null then
         return;
      end if;

      case Node.Kind is
         when AST.Node_Function_Declaration =>
            -- Store the function as a JS_Value in Variables
            declare
               Func_Val : JS_Value (Kind => Val_Function);
               Closure : Object_Map_Ptr := new Object_Maps.Map;
            begin
               -- Capture current environment (shallow copy of variable values)
               for Cursor in Variables.Iterate loop
                  Closure.Include (
                     Variable_Maps.Key (Cursor),
                     new JS_Value'(Variable_Maps.Element (Cursor))
                  );
               end loop;

               Func_Val.Func_Node := Node;
               Func_Val.Closure_Env := Closure;
               Set_Variable (Node.Func_Name (1 .. Node.Func_Name_Length), Func_Val);
            end;

         when AST.Node_Class_Declaration =>
            -- Store the class as a JS_Value in Variables
            declare
               Class_Val : JS_Value (Kind => Val_Class);
            begin
               Class_Val.Class_Node := Node;
               Set_Variable (Node.Class_Name (1 .. Node.Class_Name_Length), Class_Val);
            end;

         when AST.Node_Return_Statement =>
            -- Evaluate return value and raise exception to unwind
            if Node.Return_Value /= null then
               Return_Val := Eval (Node.Return_Value);
            else
               Return_Val := (Kind => Val_Undefined);
            end if;
            raise Return_Exception;

         when AST.Node_Break_Statement =>
            raise Break_Exception;

         when AST.Node_Continue_Statement =>
            raise Continue_Exception;

         when AST.Node_Variable_Declaration =>
            Val := Eval (Node.Initializer);
            Set_Variable (Node.Var_Name (1 .. Node.Var_Name_Length), Val);

         when AST.Node_Assignment =>
            Val := Eval (Node.Assign_Value);

            if Node.Assign_Target /= null then
               -- Member access or array index assignment
               if Node.Assign_Target.Kind = AST.Node_Member_Access then
                  -- obj.property = value or this.property = value
                  declare
                     Obj_Val : JS_Value := Eval (Node.Assign_Target.Object_Expr);
                     Member : constant String := Node.Assign_Target.Member_Name (1 .. Node.Assign_Target.Member_Length);
                  begin
                     if Obj_Val.Kind = Val_Object then
                        -- Set object property
                        if Obj_Val.Object_Properties.Contains (Member) then
                           -- Update existing property
                           Obj_Val.Object_Properties.Replace (Member, new JS_Value'(Val));
                        else
                           -- Insert new property
                           Obj_Val.Object_Properties.Insert (Member, new JS_Value'(Val));
                        end if;

                        -- Update the object in current 'this' context if it's this.property
                        if Node.Assign_Target.Object_Expr.Kind = AST.Node_This_Expression and Current_This /= null then
                           Current_This.all := Obj_Val;
                        elsif Node.Assign_Target.Object_Expr.Kind = AST.Node_Identifier then
                           -- Update variable
                           declare
                              Var_Name : constant String :=
                                 Node.Assign_Target.Object_Expr.Id_Name (1 .. Node.Assign_Target.Object_Expr.Id_Length);
                           begin
                              Set_Variable (Var_Name, Obj_Val);
                           end;
                        end if;
                     end if;
                  end;
                elsif Node.Assign_Target.Kind = AST.Node_Array_Index then
                  -- arr[index] = value
                  declare
                     Array_Val : JS_Value := Eval (Node.Assign_Target.Array_Expr);
                     Index_Val : constant JS_Value := Eval (Node.Assign_Target.Index_Expr);
                  begin
                     if Array_Val.Kind = Val_Array and Index_Val.Kind = Val_Number then
                        declare
                           Index : constant Integer := Integer (Index_Val.Number);
                        begin
                           if Index >= 0 then
                              -- Grow array if necessary
                              if Index >= Array_Val.Array_Length then
                                 declare
                                    New_Length : constant Positive := Index + 1;
                                    New_Elements : constant Value_Array_Ptr := new Value_Array (1 .. New_Length);
                                 begin
                                    -- Copy existing elements
                                    for I in 1 .. Array_Val.Array_Length loop
                                       New_Elements (I) := Array_Val.Array_Elements (I);
                                    end loop;
                                    -- Initialize new elements to undefined
                                    for I in Array_Val.Array_Length + 1 .. New_Length loop
                                       New_Elements (I) := new JS_Value'(Kind => Val_Undefined);
                                    end loop;
                                    -- Update array
                                    Array_Val.Array_Elements := New_Elements;
                                    Array_Val.Array_Length := New_Length;
                                 end;
                              end if;

                              -- Now assign the value
                              Array_Val.Array_Elements (Index + 1) := new JS_Value'(Val);

                              -- Update the variable
                              if Node.Assign_Target.Array_Expr.Kind = AST.Node_Identifier then
                                 declare
                                    Var_Name : constant String :=
                                       Node.Assign_Target.Array_Expr.Id_Name (1 .. Node.Assign_Target.Array_Expr.Id_Length);
                                 begin
                                    Set_Variable (Var_Name, Array_Val);
                                 end;
                              end if;
                           end if;
                        end;
                     end if;
                  end;
               end if;
            else
               -- Simple variable assignment
               Set_Variable (Node.Assign_Name (1 .. Node.Assign_Name_Length), Val);
            end if;

         when AST.Node_Print_Statement =>
            Val := Eval (Node.Print_Expr);
            Ada.Text_IO.Put_Line (Value_To_String (Val));

         when AST.Node_Expression_Statement =>
            Val := Eval (Node.Expr);
            -- Only print in REPL mode
            if Print_Expr then
               Ada.Text_IO.Put_Line (Value_To_String (Val));
            end if;

         when AST.Node_Block_Statement =>
            if Node.Block_Statements /= null then
               for I in 1 .. Node.Block_Count loop
                  Eval_Statement (Node.Block_Statements (I), Print_Expr);
               end loop;
            end if;

         when AST.Node_If_Statement =>
            Val := Eval (Node.Condition);
            if Value_To_Boolean (Val) then
               Eval_Statement (Node.Then_Branch, Print_Expr);
            elsif Node.Else_Branch /= null then
               Eval_Statement (Node.Else_Branch, Print_Expr);
            end if;

         when AST.Node_While_Statement =>
            begin
               loop
                  Val := Eval (Node.While_Condition);
                  exit when not Value_To_Boolean (Val);
                  begin
                     Eval_Statement (Node.While_Body, Print_Expr);
                  exception
                     when Continue_Exception =>
                        null;  -- Continue to next iteration
                  end;
               end loop;
            exception
               when Break_Exception =>
                  null;  -- Exit the loop
            end;

         when AST.Node_Switch_Statement =>
            declare
               Switch_Val : constant JS_Value := Eval (Node.Switch_Expr);
               Matched : Boolean := False;
               Fall_Through : Boolean := False;
            begin
               -- Evaluate cases
               for I in 1 .. Node.Case_Count loop
                  declare
                     Case_Node : constant AST.AST_Node_Ptr := Node.Cases (I);
                  begin
                     -- Check if this case matches (or is default, or we're falling through)
                     if not Matched then
                        if Case_Node.Case_Value = null then
                           -- Default case
                           Matched := True;
                        else
                           declare
                              Case_Val : constant JS_Value := Eval (Case_Node.Case_Value);
                           begin
                              -- Simple equality check
                              if Switch_Val.Kind = Case_Val.Kind then
                                 case Switch_Val.Kind is
                                    when Val_Number =>
                                       Matched := Switch_Val.Number = Case_Val.Number;
                                    when Val_String =>
                                       if Switch_Val.Str_Length = Case_Val.Str_Length then
                                          Matched := Switch_Val.Str (1 .. Switch_Val.Str_Length) =
                                                    Case_Val.Str (1 .. Case_Val.Str_Length);
                                       end if;
                                    when Val_Boolean =>
                                       Matched := Switch_Val.Bool = Case_Val.Bool;
                                    when others =>
                                       null;
                                 end case;
                              end if;
                           end;
                        end if;
                     end if;

                     -- Execute case statements if matched or falling through
                     if Matched or Fall_Through then
                        begin
                           if Case_Node.Case_Statements /= null then
                              for J in 1 .. Case_Node.Case_Statement_Count loop
                                 Eval_Statement (Case_Node.Case_Statements (J), Print_Expr);
                              end loop;
                           end if;
                           Fall_Through := True;  -- Continue to next case (unless break)
                        exception
                           when Break_Exception =>
                              exit;  -- Exit switch
                        end;
                     end if;
                  end;
               end loop;
            end;

         when AST.Node_Do_While_Statement =>
            begin
               loop
                  begin
                     Eval_Statement (Node.Do_While_Body, Print_Expr);
                  exception
                     when Continue_Exception =>
                        null;  -- Continue to next iteration
                  end;
                  Val := Eval (Node.Do_While_Condition);
                  exit when not Value_To_Boolean (Val);
               end loop;
            exception
               when Break_Exception =>
                  null;  -- Exit the loop
            end;

         when AST.Node_For_Statement =>
            begin
               if Node.For_Init /= null then
                  Eval_Statement (Node.For_Init, Print_Expr);
               end if;

               loop
                  if Node.For_Condition /= null then
                     Val := Eval (Node.For_Condition);
                     exit when not Value_To_Boolean (Val);
                  end if;

                  begin
                     Eval_Statement (Node.For_Body, Print_Expr);
                  exception
                     when Continue_Exception =>
                        null;  -- Continue to update
                  end;

                  if Node.For_Update /= null then
                     Eval_Statement (Node.For_Update, Print_Expr);
                  end if;
               end loop;
            exception
               when Break_Exception =>
                  null;  -- Exit the loop
            end;

         when AST.Node_Try_Statement =>
            -- Execute try block with exception handling
            declare
               Return_Caught : Boolean := False;
               Break_Caught : Boolean := False;
               Continue_Caught : Boolean := False;
            begin
               -- Execute try block
               begin
                  if Node.Try_Body /= null then
                     Eval_Statement (Node.Try_Body, Print_Expr);
                  end if;
               exception
                  when JS_Exception =>
                     -- JavaScript exception was thrown
                     if Node.Catch_Body /= null then
                        -- Execute catch block with error binding
                        declare
                           Saved_Variables : constant Variable_Maps.Map := Variables;
                           Catch_Param : constant String :=
                              Node.Catch_Param (1 .. Node.Catch_Param_Length);
                        begin
                           -- Bind the caught value to the catch parameter
                           if Thrown_Value /= null then
                              Set_Variable (Catch_Param, Thrown_Value.all);
                           else
                              Set_Variable (Catch_Param, (Kind => Val_Undefined));
                           end if;

                           -- Execute catch block
                           Eval_Statement (Node.Catch_Body, Print_Expr);

                           -- Restore variables (catch param goes out of scope)
                           Variables := Saved_Variables;
                        end;
                     end if;
                  when Return_Exception =>
                     Return_Caught := True;
                  when Break_Exception =>
                     Break_Caught := True;
                  when Continue_Exception =>
                     Continue_Caught := True;
               end;

               -- Always execute finally block (even after return/break/continue)
               if Node.Finally_Body /= null then
                  Eval_Statement (Node.Finally_Body, Print_Expr);
               end if;

               -- Re-raise control flow exceptions after finally
               if Return_Caught then
                  raise Return_Exception;
               elsif Break_Caught then
                  raise Break_Exception;
               elsif Continue_Caught then
                  raise Continue_Exception;
               end if;
            end;

         when AST.Node_Throw_Statement =>
            -- Evaluate the expression to throw
            Val := Eval (Node.Throw_Expression);

            -- Store the thrown value
            Thrown_Value := new JS_Value'(Val);

            -- Raise the JavaScript exception
            raise JS_Exception;

         when others =>
            null;
      end case;
   end Eval_Statement;

   -- Evaluate an expression node and return its JavaScript value
   function Eval (Node : AST.AST_Node_Ptr) return JS_Value is
      Result : JS_Value (Val_String);
      Left_Val, Right_Val : JS_Value;
      Op : String (1 .. 3);
   begin
      if Node = null then
         return (Kind => Val_Null);
      end if;

      case Node.Kind is
         when AST.Node_Number_Literal =>
            return (Kind => Val_Number, Number => Node.Number_Value);

         when AST.Node_String_Literal =>
            Result.Str_Length := Node.String_Length;
            Result.Str (1 .. Node.String_Length) := Node.String_Value (1 .. Node.String_Length);
            return Result;

         when AST.Node_Boolean_Literal =>
            return (Kind => Val_Boolean, Bool => Node.Boolean_Value);

         when AST.Node_Null_Literal =>
            return (Kind => Val_Null);

         when AST.Node_Identifier =>
            return Get_Variable (Node.Id_Name (1 .. Node.Id_Length));

         when AST.Node_Ternary_Op =>
            declare
               Condition_Val : constant JS_Value := Eval (Node.Ternary_Condition);
            begin
               if Value_To_Boolean (Condition_Val) then
                  return Eval (Node.Ternary_True_Expr);
               else
                  return Eval (Node.Ternary_False_Expr);
               end if;
            end;

         when AST.Node_Unary_Op =>
            declare
               Operand_Val : constant JS_Value := Eval (Node.Operand);
               Op : constant String := Node.Unary_Operator (1 .. Node.Unary_Op_Length);
               Type_Str : JS_Value (Val_String);
            begin
               if Op = "-" then
                  if Operand_Val.Kind = Val_Number then
                     return (Kind => Val_Number, Number => -Operand_Val.Number);
                  end if;
                  return (Kind => Val_Number, Number => 0.0);
               elsif Op = "!" then
                  return (Kind => Val_Boolean, Bool => not Value_To_Boolean (Operand_Val));
               elsif Op = "typeof" then
                  case Operand_Val.Kind is
                     when Val_Number =>
                        Type_Str.Str_Length := 6;
                        Type_Str.Str (1 .. 6) := "number";
                     when Val_Boolean =>
                        Type_Str.Str_Length := 7;
                        Type_Str.Str (1 .. 7) := "boolean";
                     when Val_String =>
                        Type_Str.Str_Length := 6;
                        Type_Str.Str (1 .. 6) := "string";
                     when Val_Null =>
                        Type_Str.Str_Length := 6;
                        Type_Str.Str (1 .. 6) := "object";
                     when Val_Array =>
                        Type_Str.Str_Length := 6;
                        Type_Str.Str (1 .. 6) := "object";
                     when Val_Object =>
                        Type_Str.Str_Length := 6;
                        Type_Str.Str (1 .. 6) := "object";
                     when Val_Function =>
                        Type_Str.Str_Length := 8;
                        Type_Str.Str (1 .. 8) := "function";
                     when Val_Class =>
                        Type_Str.Str_Length := 8;
                        Type_Str.Str (1 .. 8) := "function";  -- Classes are functions in JS
                     when Val_Undefined =>
                        Type_Str.Str_Length := 9;
                        Type_Str.Str (1 .. 9) := "undefined";
                  end case;
                  return Type_Str;
               end if;
               return (Kind => Val_Undefined);
            end;

         when AST.Node_Prefix_Update =>
            -- Prefix increment/decrement: ++x, --x
            declare
               Op : constant String := Node.Update_Operator (1 .. Node.Update_Op_Length);
               Operand : constant AST.AST_Node_Ptr := Node.Update_Operand;
            begin
               -- Get current value and increment/decrement it
               if Operand.Kind = AST.Node_Identifier then
                  declare
                     Var_Name : constant String := Operand.Id_Name (1 .. Operand.Id_Length);
                     Current_Val : JS_Value := Get_Variable (Var_Name);
                     New_Val : JS_Value;
                  begin
                     if Current_Val.Kind = Val_Number then
                        if Op = "++" then
                           New_Val := (Kind => Val_Number, Number => Current_Val.Number + 1.0);
                        else  -- "--"
                           New_Val := (Kind => Val_Number, Number => Current_Val.Number - 1.0);
                        end if;
                        Set_Variable (Var_Name, New_Val);
                        return New_Val;  -- Prefix returns new value
                     end if;
                  end;
               elsif Operand.Kind = AST.Node_Array_Index then
                  -- Array element: arr[i]++
                  if Operand.Array_Expr.Kind = AST.Node_Identifier then
                     declare
                        Var_Name : constant String :=
                           Operand.Array_Expr.Id_Name (1 .. Operand.Array_Expr.Id_Length);
                        Array_Val : JS_Value := Get_Variable (Var_Name);
                        Index_Val : constant JS_Value := Eval (Operand.Index_Expr);
                        Index : Integer;
                        Current_Val, New_Val : JS_Value;
                     begin
                        if Array_Val.Kind = Val_Array and Index_Val.Kind = Val_Number then
                           Index := Integer (Index_Val.Number);
                           if Index >= 0 and Index < Array_Val.Array_Length then
                              Current_Val := Array_Val.Array_Elements (Index + 1).all;
                              if Current_Val.Kind = Val_Number then
                                 if Op = "++" then
                                    New_Val := (Kind => Val_Number, Number => Current_Val.Number + 1.0);
                                 else
                                    New_Val := (Kind => Val_Number, Number => Current_Val.Number - 1.0);
                                 end if;
                                 Array_Val.Array_Elements (Index + 1).all := New_Val;
                                 Set_Variable (Var_Name, Array_Val);
                                 return New_Val;
                              end if;
                           end if;
                        end if;
                     end;
                  end if;
               end if;
               return (Kind => Val_Undefined);
            end;

         when AST.Node_Postfix_Update =>
            -- Postfix increment/decrement: x++, x--
            declare
               Op : constant String := Node.Update_Operator (1 .. Node.Update_Op_Length);
               Operand : constant AST.AST_Node_Ptr := Node.Update_Operand;
            begin
               if Operand.Kind = AST.Node_Identifier then
                  declare
                     Var_Name : constant String := Operand.Id_Name (1 .. Operand.Id_Length);
                     Current_Val : constant JS_Value := Get_Variable (Var_Name);
                     New_Val : JS_Value;
                  begin
                     if Current_Val.Kind = Val_Number then
                        if Op = "++" then
                           New_Val := (Kind => Val_Number, Number => Current_Val.Number + 1.0);
                        else  -- "--"
                           New_Val := (Kind => Val_Number, Number => Current_Val.Number - 1.0);
                        end if;
                        Set_Variable (Var_Name, New_Val);
                        return Current_Val;  -- Postfix returns old value
                     end if;
                  end;
               elsif Operand.Kind = AST.Node_Array_Index then
                  -- Array element: arr[i]++
                  if Operand.Array_Expr.Kind = AST.Node_Identifier then
                     declare
                        Var_Name : constant String :=
                           Operand.Array_Expr.Id_Name (1 .. Operand.Array_Expr.Id_Length);
                        Array_Val : JS_Value := Get_Variable (Var_Name);
                        Index_Val : constant JS_Value := Eval (Operand.Index_Expr);
                        Index : Integer;
                        Current_Val, New_Val : JS_Value;
                     begin
                        if Array_Val.Kind = Val_Array and Index_Val.Kind = Val_Number then
                           Index := Integer (Index_Val.Number);
                           if Index >= 0 and Index < Array_Val.Array_Length then
                              Current_Val := Array_Val.Array_Elements (Index + 1).all;
                              if Current_Val.Kind = Val_Number then
                                 if Op = "++" then
                                    New_Val := (Kind => Val_Number, Number => Current_Val.Number + 1.0);
                                 else
                                    New_Val := (Kind => Val_Number, Number => Current_Val.Number - 1.0);
                                 end if;
                                 Array_Val.Array_Elements (Index + 1).all := New_Val;
                                 Set_Variable (Var_Name, Array_Val);
                                 return Current_Val;  -- Postfix returns old value
                              end if;
                           end if;
                        end if;
                     end;
                  end if;
               end if;
               return (Kind => Val_Undefined);
            end;

         when AST.Node_Binary_Op =>
            Op (1 .. Node.Op_Length) := Node.Operator (1 .. Node.Op_Length);

            -- Special handling for assignment operator
            if Op (1 .. Node.Op_Length) = "=" then
               -- This is array/member/object assignment: arr[i] = value, obj.prop = value, obj["key"] = value
               -- Left side should be Array_Index or Member_Access
               if Node.Left.Kind = AST.Node_Array_Index then
                  -- Array element or object property assignment
                  -- We need to get the variable and modify it
                  Right_Val := Eval (Node.Right);

                  if Node.Left.Array_Expr.Kind = AST.Node_Identifier then
                     declare
                        Var_Name : constant String :=
                           Node.Left.Array_Expr.Id_Name (1 .. Node.Left.Array_Expr.Id_Length);
                        Val : JS_Value := Get_Variable (Var_Name);
                        Index_Val : constant JS_Value := Eval (Node.Left.Index_Expr);
                     begin
                        if Val.Kind = Val_Array and then Index_Val.Kind = Val_Number then
                           declare
                              Index : constant Integer := Integer (Index_Val.Number);
                           begin
                              if Index >= 0 and then Index < Val.Array_Length then
                                 -- Modify the array element
                                 Val.Array_Elements (Index + 1).all := Right_Val;
                                 -- Save it back to the variable
                                 Set_Variable (Var_Name, Val);
                                 return Right_Val;
                              end if;
                           end;
                        elsif Val.Kind = Val_Object and then Index_Val.Kind = Val_String then
                           -- Object property assignment: obj["key"] = value
                           declare
                              Key : constant String := Index_Val.Str (1 .. Index_Val.Str_Length);
                           begin
                              if Val.Object_Properties.Contains (Key) then
                                 Val.Object_Properties.Replace (Key, new JS_Value'(Right_Val));
                              else
                                 Val.Object_Properties.Insert (Key, new JS_Value'(Right_Val));
                              end if;
                              Set_Variable (Var_Name, Val);
                              return Right_Val;
                           end;
                        end if;
                     end;
                  end if;
               elsif Node.Left.Kind = AST.Node_Member_Access then
                  -- Object property assignment: obj.prop = value
                  Right_Val := Eval (Node.Right);

                  if Node.Left.Object_Expr.Kind = AST.Node_Identifier then
                     declare
                        Var_Name : constant String :=
                           Node.Left.Object_Expr.Id_Name (1 .. Node.Left.Object_Expr.Id_Length);
                        Obj_Val : JS_Value := Get_Variable (Var_Name);
                        Prop : constant String := Node.Left.Member_Name (1 .. Node.Left.Member_Length);
                     begin
                        if Obj_Val.Kind = Val_Object then
                           if Obj_Val.Object_Properties.Contains (Prop) then
                              Obj_Val.Object_Properties.Replace (Prop, new JS_Value'(Right_Val));
                           else
                              Obj_Val.Object_Properties.Insert (Prop, new JS_Value'(Right_Val));
                           end if;
                           Set_Variable (Var_Name, Obj_Val);
                           return Right_Val;
                        end if;
                     end;
                  end if;
               end if;
               return (Kind => Val_Undefined);
            end if;

            -- Regular binary operations
            Left_Val := Eval (Node.Left);
            Right_Val := Eval (Node.Right);

            if Op (1 .. Node.Op_Length) = "+" then
               if Left_Val.Kind = Val_Number and Right_Val.Kind = Val_Number then
                  return (Kind => Val_Number, Number => Left_Val.Number + Right_Val.Number);
               elsif Left_Val.Kind = Val_String or Right_Val.Kind = Val_String then
                  -- String concatenation
                  declare
                     Left_Str : constant String := Value_To_String (Left_Val);
                     Right_Str : constant String := Value_To_String (Right_Val);
                     Concat_Result : JS_Value (Val_String);
                  begin
                     Concat_Result.Str_Length := Left_Str'Length + Right_Str'Length;
                     Concat_Result.Str (1 .. Left_Str'Length) := Left_Str;
                     Concat_Result.Str (Left_Str'Length + 1 .. Concat_Result.Str_Length) := Right_Str;
                     return Concat_Result;
                  end;
               end if;
            elsif Op (1 .. Node.Op_Length) = "-" then
               if Left_Val.Kind = Val_Number and Right_Val.Kind = Val_Number then
                  return (Kind => Val_Number, Number => Left_Val.Number - Right_Val.Number);
               end if;
            elsif Op (1 .. Node.Op_Length) = "*" then
               if Left_Val.Kind = Val_Number and Right_Val.Kind = Val_Number then
                  return (Kind => Val_Number, Number => Left_Val.Number * Right_Val.Number);
               end if;
            elsif Op (1 .. Node.Op_Length) = "/" then
               if Left_Val.Kind = Val_Number and Right_Val.Kind = Val_Number then
                  if Right_Val.Number /= 0.0 then
                     return (Kind => Val_Number, Number => Left_Val.Number / Right_Val.Number);
                  else
                     return (Kind => Val_Number, Number => Float'First);
                  end if;
               end if;
            elsif Op (1 .. Node.Op_Length) = "%" then
               if Left_Val.Kind = Val_Number and Right_Val.Kind = Val_Number then
                  -- JavaScript modulo: a % b = a - (b * floor(a/b))
                  -- This ensures the result has the same sign as the dividend
                  declare
                     A : constant Float := Left_Val.Number;
                     B : constant Float := Right_Val.Number;
                     Result : Float;
                  begin
                     if B = 0.0 then
                        Result := Float'First;  -- Division by zero
                     else
                        -- JavaScript % operator: result has sign of dividend
                        Result := A - B * Float'Floor(A / B);
                     end if;
                     return (Kind => Val_Number, Number => Result);
                  end;
               end if;
            elsif Op (1 .. Node.Op_Length) = "<" then
               if Left_Val.Kind = Val_Number and Right_Val.Kind = Val_Number then
                  return (Kind => Val_Boolean, Bool => Left_Val.Number < Right_Val.Number);
               elsif Left_Val.Kind = Val_String and Right_Val.Kind = Val_String then
                  declare
                     Left_Str : constant String := Left_Val.Str (1 .. Left_Val.Str_Length);
                     Right_Str : constant String := Right_Val.Str (1 .. Right_Val.Str_Length);
                  begin
                     return (Kind => Val_Boolean, Bool => Left_Str < Right_Str);
                  end;
               end if;
            elsif Op (1 .. Node.Op_Length) = "<=" then
               if Left_Val.Kind = Val_Number and Right_Val.Kind = Val_Number then
                  return (Kind => Val_Boolean, Bool => Left_Val.Number <= Right_Val.Number);
               elsif Left_Val.Kind = Val_String and Right_Val.Kind = Val_String then
                  declare
                     Left_Str : constant String := Left_Val.Str (1 .. Left_Val.Str_Length);
                     Right_Str : constant String := Right_Val.Str (1 .. Right_Val.Str_Length);
                  begin
                     return (Kind => Val_Boolean, Bool => Left_Str <= Right_Str);
                  end;
               end if;
            elsif Op (1 .. Node.Op_Length) = ">" then
               if Left_Val.Kind = Val_Number and Right_Val.Kind = Val_Number then
                  return (Kind => Val_Boolean, Bool => Left_Val.Number > Right_Val.Number);
               elsif Left_Val.Kind = Val_String and Right_Val.Kind = Val_String then
                  declare
                     Left_Str : constant String := Left_Val.Str (1 .. Left_Val.Str_Length);
                     Right_Str : constant String := Right_Val.Str (1 .. Right_Val.Str_Length);
                  begin
                     return (Kind => Val_Boolean, Bool => Left_Str > Right_Str);
                  end;
               end if;
            elsif Op (1 .. Node.Op_Length) = ">=" then
               if Left_Val.Kind = Val_Number and Right_Val.Kind = Val_Number then
                  return (Kind => Val_Boolean, Bool => Left_Val.Number >= Right_Val.Number);
               elsif Left_Val.Kind = Val_String and Right_Val.Kind = Val_String then
                  declare
                     Left_Str : constant String := Left_Val.Str (1 .. Left_Val.Str_Length);
                     Right_Str : constant String := Right_Val.Str (1 .. Right_Val.Str_Length);
                  begin
                     return (Kind => Val_Boolean, Bool => Left_Str >= Right_Str);
                  end;
               end if;
            elsif Op (1 .. Node.Op_Length) = "==" then
               if Left_Val.Kind = Val_Number and Right_Val.Kind = Val_Number then
                  return (Kind => Val_Boolean, Bool => Left_Val.Number = Right_Val.Number);
               elsif Left_Val.Kind = Val_Boolean and Right_Val.Kind = Val_Boolean then
                  return (Kind => Val_Boolean, Bool => Left_Val.Bool = Right_Val.Bool);
               elsif Left_Val.Kind = Val_String and Right_Val.Kind = Val_String then
                  declare
                     Left_Str : constant String := Left_Val.Str (1 .. Left_Val.Str_Length);
                     Right_Str : constant String := Right_Val.Str (1 .. Right_Val.Str_Length);
                  begin
                     return (Kind => Val_Boolean, Bool => Left_Str = Right_Str);
                  end;
               elsif Left_Val.Kind = Val_Null and Right_Val.Kind = Val_Null then
                  return (Kind => Val_Boolean, Bool => True);
               elsif Left_Val.Kind = Val_Undefined and Right_Val.Kind = Val_Undefined then
                  return (Kind => Val_Boolean, Bool => True);
               else
                  -- Different types: == returns false
                  return (Kind => Val_Boolean, Bool => False);
               end if;
            elsif Op (1 .. Node.Op_Length) = "===" then
               -- Strict equality: check type AND value
               if Left_Val.Kind /= Right_Val.Kind then
                  return (Kind => Val_Boolean, Bool => False);
               elsif Left_Val.Kind = Val_Number then
                  return (Kind => Val_Boolean, Bool => Left_Val.Number = Right_Val.Number);
               elsif Left_Val.Kind = Val_Boolean then
                  return (Kind => Val_Boolean, Bool => Left_Val.Bool = Right_Val.Bool);
               elsif Left_Val.Kind = Val_String then
                  declare
                     Left_Str : constant String := Left_Val.Str (1 .. Left_Val.Str_Length);
                     Right_Str : constant String := Right_Val.Str (1 .. Right_Val.Str_Length);
                  begin
                     return (Kind => Val_Boolean, Bool => Left_Str = Right_Str);
                  end;
               elsif Left_Val.Kind = Val_Null or Left_Val.Kind = Val_Undefined then
                  return (Kind => Val_Boolean, Bool => True);
               else
                  -- For objects/arrays/functions, compare identity (not implemented fully)
                  return (Kind => Val_Boolean, Bool => False);
               end if;
            elsif Op (1 .. Node.Op_Length) = "!=" then
               if Left_Val.Kind = Val_Number and Right_Val.Kind = Val_Number then
                  return (Kind => Val_Boolean, Bool => Left_Val.Number /= Right_Val.Number);
               elsif Left_Val.Kind = Val_Boolean and Right_Val.Kind = Val_Boolean then
                  return (Kind => Val_Boolean, Bool => Left_Val.Bool /= Right_Val.Bool);
               elsif Left_Val.Kind = Val_String and Right_Val.Kind = Val_String then
                  declare
                     Left_Str : constant String := Left_Val.Str (1 .. Left_Val.Str_Length);
                     Right_Str : constant String := Right_Val.Str (1 .. Right_Val.Str_Length);
                  begin
                     return (Kind => Val_Boolean, Bool => Left_Str /= Right_Str);
                  end;
               elsif Left_Val.Kind = Val_Null and Right_Val.Kind = Val_Null then
                  return (Kind => Val_Boolean, Bool => False);
               elsif Left_Val.Kind = Val_Undefined and Right_Val.Kind = Val_Undefined then
                  return (Kind => Val_Boolean, Bool => False);
               else
                  -- Different types: != returns true
                  return (Kind => Val_Boolean, Bool => True);
               end if;
            elsif Op (1 .. Node.Op_Length) = "!==" then
               -- Strict inequality: check type AND value
               if Left_Val.Kind /= Right_Val.Kind then
                  return (Kind => Val_Boolean, Bool => True);
               elsif Left_Val.Kind = Val_Number then
                  return (Kind => Val_Boolean, Bool => Left_Val.Number /= Right_Val.Number);
               elsif Left_Val.Kind = Val_Boolean then
                  return (Kind => Val_Boolean, Bool => Left_Val.Bool /= Right_Val.Bool);
               elsif Left_Val.Kind = Val_String then
                  declare
                     Left_Str : constant String := Left_Val.Str (1 .. Left_Val.Str_Length);
                     Right_Str : constant String := Right_Val.Str (1 .. Right_Val.Str_Length);
                  begin
                     return (Kind => Val_Boolean, Bool => Left_Str /= Right_Str);
                  end;
               elsif Left_Val.Kind = Val_Null or Left_Val.Kind = Val_Undefined then
                  return (Kind => Val_Boolean, Bool => False);
               else
                  -- For objects/arrays/functions, compare identity
                  return (Kind => Val_Boolean, Bool => True);
               end if;
            elsif Op (1 .. Node.Op_Length) = "&&" then
               return (Kind => Val_Boolean, Bool => Value_To_Boolean (Left_Val) and Value_To_Boolean (Right_Val));
            elsif Op (1 .. Node.Op_Length) = "||" then
               return (Kind => Val_Boolean, Bool => Value_To_Boolean (Left_Val) or Value_To_Boolean (Right_Val));
            end if;

         when AST.Node_Function_Call =>
            declare
               Func_Name : constant String := Node.Call_Name (1 .. Node.Call_Name_Length);
               Func_Val : JS_Value;
               Func_Node : AST.AST_Node_Ptr;
               Saved_Vars : Variable_Maps.Map;
            begin
               -- Handle built-in global functions
               if Func_Name = "print" then
                  -- print() function for REPL compatibility
                  if Node.Arguments /= null and then Node.Arg_Count > 0 then
                     declare
                        Arg_Val : constant JS_Value := Eval (Node.Arguments (1));
                     begin
                        Ada.Text_IO.Put_Line (Value_To_String (Arg_Val));
                     end;
                  end if;
                  return (Kind => Val_Undefined);
               elsif Func_Name = "parseInt" then
                  if Node.Arguments /= null and then Node.Arg_Count > 0 then
                     declare
                        Arg_Val : constant JS_Value := Eval (Node.Arguments (1));
                     begin
                        if Arg_Val.Kind = Val_String then
                           declare
                              Str : constant String := Arg_Val.Str (1 .. Arg_Val.Str_Length);
                              Result : Integer := 0;
                              Sign : Integer := 1;
                              Start : Positive := 1;
                           begin
                              -- Skip leading whitespace
                              while Start <= Str'Length and then (Str (Start) = ' ' or Str (Start) = ASCII.HT) loop
                                 Start := Start + 1;
                              end loop;

                              -- Check for sign
                              if Start <= Str'Length and then Str (Start) = '-' then
                                 Sign := -1;
                                 Start := Start + 1;
                              elsif Start <= Str'Length and then Str (Start) = '+' then
                                 Start := Start + 1;
                              end if;

                              -- Parse digits
                              while Start <= Str'Length and then Str (Start) >= '0' and then Str (Start) <= '9' loop
                                 Result := Result * 10 + (Character'Pos (Str (Start)) - Character'Pos ('0'));
                                 Start := Start + 1;
                              end loop;

                              return (Kind => Val_Number, Number => Float (Result * Sign));
                           exception
                              when others =>
                                 return (Kind => Val_Number, Number => 0.0);
                           end;
                        elsif Arg_Val.Kind = Val_Number then
                           return (Kind => Val_Number, Number => Float (Integer (Float'Floor (Arg_Val.Number))));
                        end if;
                     end;
                  end if;
                  return (Kind => Val_Number, Number => 0.0);
               elsif Func_Name = "parseFloat" then
                  if Node.Arguments /= null and then Node.Arg_Count > 0 then
                     declare
                        Arg_Val : constant JS_Value := Eval (Node.Arguments (1));
                     begin
                        if Arg_Val.Kind = Val_String then
                           declare
                              Str : constant String := Arg_Val.Str (1 .. Arg_Val.Str_Length);
                              Result : Float := 0.0;
                              Sign : Float := 1.0;
                              Start : Positive := 1;
                              Decimal_Places : Natural := 0;
                              In_Decimal : Boolean := False;
                           begin
                              -- Skip whitespace
                              while Start <= Str'Length and then (Str (Start) = ' ' or Str (Start) = ASCII.HT) loop
                                 Start := Start + 1;
                              end loop;

                              -- Check sign
                              if Start <= Str'Length and then Str (Start) = '-' then
                                 Sign := -1.0;
                                 Start := Start + 1;
                              elsif Start <= Str'Length and then Str (Start) = '+' then
                                 Start := Start + 1;
                              end if;

                              -- Parse number
                              while Start <= Str'Length loop
                                 if Str (Start) >= '0' and then Str (Start) <= '9' then
                                    if In_Decimal then
                                       Decimal_Places := Decimal_Places + 1;
                                       Result := Result + Float (Character'Pos (Str (Start)) - Character'Pos ('0')) / (10.0 ** Decimal_Places);
                                    else
                                       Result := Result * 10.0 + Float (Character'Pos (Str (Start)) - Character'Pos ('0'));
                                    end if;
                                    Start := Start + 1;
                                 elsif Str (Start) = '.' and then not In_Decimal then
                                    In_Decimal := True;
                                    Start := Start + 1;
                                 else
                                    exit;
                                 end if;
                              end loop;

                              return (Kind => Val_Number, Number => Result * Sign);
                           exception
                              when others =>
                                 return (Kind => Val_Number, Number => 0.0);
                           end;
                        elsif Arg_Val.Kind = Val_Number then
                           return Arg_Val;
                        end if;
                     end;
                  end if;
                  return (Kind => Val_Number, Number => 0.0);
               elsif Func_Name = "isNaN" then
                  -- In JavaScript, NaN is a special value, but we don't have it
                  -- So we'll just return false for numbers, true for non-numbers
                  if Node.Arguments /= null and then Node.Arg_Count > 0 then
                     declare
                        Arg_Val : constant JS_Value := Eval (Node.Arguments (1));
                     begin
                        if Arg_Val.Kind = Val_Number then
                           return (Kind => Val_Boolean, Bool => False);
                        else
                           return (Kind => Val_Boolean, Bool => True);
                        end if;
                     end;
                  end if;
                  return (Kind => Val_Boolean, Bool => True);
               elsif Func_Name = "isFinite" then
                  -- Check if value is a finite number
                  if Node.Arguments /= null and then Node.Arg_Count > 0 then
                     declare
                        Arg_Val : constant JS_Value := Eval (Node.Arguments (1));
                     begin
                        if Arg_Val.Kind = Val_Number then
                           -- In Ada, all Float values are finite (no infinity)
                           return (Kind => Val_Boolean, Bool => True);
                        else
                           return (Kind => Val_Boolean, Bool => False);
                        end if;
                     end;
                  end if;
                  return (Kind => Val_Boolean, Bool => False);
               end if;

               -- Get function from variables
               Func_Val := Get_Variable (Func_Name);

               -- Check if it's a function
               if Func_Val.Kind /= Val_Function then
                  return (Kind => Val_Undefined);
               end if;

               Func_Node := Func_Val.Func_Node;

               -- Save current variables for scope isolation
               Saved_Vars := Variables.Copy;

               -- Restore closure environment (captured variables from function definition)
               if Func_Val.Kind = Val_Function and then Func_Val.Closure_Env /= null then
                  declare
                     Closure : constant Object_Map_Ptr := Func_Val.Closure_Env;
                  begin
                     for Cursor in Closure.Iterate loop
                        Variables.Include (
                           Object_Maps.Key (Cursor),
                           Object_Maps.Element (Cursor).all
                        );
                     end loop;
                  end;
               end if;

               -- Bind parameters to arguments based on function type
               if Func_Node.Kind = AST.Node_Function_Declaration then
                  -- Regular function
                  if Node.Arguments /= null and Func_Node.Params /= null then
                     for I in 1 .. Integer'Min (Node.Arg_Count, Func_Node.Param_Count) loop
                        declare
                           Param_Name : constant String :=
                              Func_Node.Params (I).Id_Name (1 .. Func_Node.Params (I).Id_Length);
                           Arg_Val : constant JS_Value := Eval (Node.Arguments (I));
                        begin
                           Set_Variable (Param_Name, Arg_Val);
                        end;
                     end loop;
                  end if;

                  -- Execute function body and catch return
                  begin
                     Eval_Statement (Func_Node.Func_Body);
                     -- No explicit return, return undefined
                     Variables := Saved_Vars;
                     return (Kind => Val_Undefined);
                  exception
                     when Return_Exception =>
                        -- Restore variables and return the value
                        Variables := Saved_Vars;
                        return Return_Val;
                  end;
               elsif Func_Node.Kind = AST.Node_Arrow_Function then
                  -- Arrow function
                  if Node.Arguments /= null and Func_Node.Arrow_Params /= null then
                     for I in 1 .. Integer'Min (Node.Arg_Count, Func_Node.Arrow_Param_Count) loop
                        declare
                           Param_Name : constant String :=
                              Func_Node.Arrow_Params (I).Id_Name (1 .. Func_Node.Arrow_Params (I).Id_Length);
                           Arg_Val : constant JS_Value := Eval (Node.Arguments (I));
                        begin
                           Set_Variable (Param_Name, Arg_Val);
                        end;
                     end loop;
                  end if;

                  -- Execute arrow function body
                  if Func_Node.Is_Expression_Body then
                     -- Expression body: implicit return
                     declare
                        Result : constant JS_Value := Eval (Func_Node.Arrow_Body);
                     begin
                        Variables := Saved_Vars;
                        return Result;
                     end;
                  else
                     -- Block body: explicit return
                     begin
                        Eval_Statement (Func_Node.Arrow_Body);
                        Variables := Saved_Vars;
                        return (Kind => Val_Undefined);
                     exception
                        when Return_Exception =>
                           Variables := Saved_Vars;
                           return Return_Val;
                     end;
                  end if;
               end if;

               Variables := Saved_Vars;
               return (Kind => Val_Undefined);
            end;

         when AST.Node_Method_Call =>
            -- Handle method calls like arr.push(5) or obj.method()
            declare
               Callee_Val : JS_Value;
            begin
               -- Check if it's a member access (method call)
               if Node.Callee.Kind = AST.Node_Member_Access then
                  declare
                     Object_Val : JS_Value := Eval (Node.Callee.Object_Expr);
                     Method_Name : constant String :=
                        Node.Callee.Member_Name (1 .. Node.Callee.Member_Length);
                  begin
                     -- Handle array methods
                     if Object_Val.Kind = Val_Array then
                        if Method_Name = "push" then
                           -- Add element to end
                           if Node.Method_Arguments /= null and Node.Method_Arg_Count > 0 then
                              declare
                                 New_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                 New_Length : constant Natural := Object_Val.Array_Length + 1;
                                 New_Array : constant Value_Array_Ptr := new Value_Array (1 .. New_Length);
                              begin
                                 -- Copy existing elements
                                 for I in 1 .. Object_Val.Array_Length loop
                                    New_Array (I) := Object_Val.Array_Elements (I);
                                 end loop;
                                 -- Add new element
                                 New_Array (New_Length) := new JS_Value'(New_Val);
                                 Object_Val.Array_Elements := New_Array;
                                 Object_Val.Array_Length := New_Length;

                                 -- Update the variable
                                 if Node.Callee.Object_Expr.Kind = AST.Node_Identifier then
                                    declare
                                       Var_Name : constant String :=
                                          Node.Callee.Object_Expr.Id_Name (1 .. Node.Callee.Object_Expr.Id_Length);
                                    begin
                                       Set_Variable (Var_Name, Object_Val);
                                    end;
                                 end if;

                                 return (Kind => Val_Number, Number => Float (New_Length));
                              end;
                           end if;
                        elsif Method_Name = "pop" then
                           -- Remove and return last element
                           if Object_Val.Array_Length > 0 then
                              declare
                                 Last_Val : constant JS_Value := Object_Val.Array_Elements (Object_Val.Array_Length).all;
                                 New_Length : constant Natural := Object_Val.Array_Length - 1;
                              begin
                                 if New_Length > 0 then
                                    declare
                                       New_Array : constant Value_Array_Ptr := new Value_Array (1 .. New_Length);
                                    begin
                                       for I in 1 .. New_Length loop
                                          New_Array (I) := Object_Val.Array_Elements (I);
                                       end loop;
                                       Object_Val.Array_Elements := New_Array;
                                    end;
                                 else
                                    Object_Val.Array_Elements := null;
                                 end if;
                                 Object_Val.Array_Length := New_Length;

                                 -- Update the variable
                                 if Node.Callee.Object_Expr.Kind = AST.Node_Identifier then
                                    declare
                                       Var_Name : constant String :=
                                          Node.Callee.Object_Expr.Id_Name (1 .. Node.Callee.Object_Expr.Id_Length);
                                    begin
                                       Set_Variable (Var_Name, Object_Val);
                                    end;
                                 end if;

                                 return Last_Val;
                              end;
                           end if;
                           return (Kind => Val_Undefined);
                        elsif Method_Name = "shift" then
                              -- shift(): remove and return first element
                              if Object_Val.Array_Length > 0 then
                                 declare
                                    First_Val : constant JS_Value := Object_Val.Array_Elements (1).all;
                                    New_Length : constant Natural := Object_Val.Array_Length - 1;
                                 begin
                                    if New_Length > 0 then
                                       declare
                                          New_Array : constant Value_Array_Ptr := new Value_Array (1 .. New_Length);
                                       begin
                                          for I in 1 .. New_Length loop
                                             New_Array (I) := Object_Val.Array_Elements (I + 1);
                                          end loop;
                                          Object_Val.Array_Elements := New_Array;
                                       end;
                                    else
                                       Object_Val.Array_Elements := null;
                                    end if;
                                    Object_Val.Array_Length := New_Length;

                                    -- Update the variable
                                    if Node.Callee.Object_Expr.Kind = AST.Node_Identifier then
                                       declare
                                          Var_Name : constant String :=
                                             Node.Callee.Object_Expr.Id_Name (1 .. Node.Callee.Object_Expr.Id_Length);
                                       begin
                                          Set_Variable (Var_Name, Object_Val);
                                       end;
                                    end if;

                                    return First_Val;
                                 end;
                              end if;
                              return (Kind => Val_Undefined);
                           elsif Method_Name = "unshift" then
                              -- unshift(element): add element to beginning, return new length
                              if Node.Method_Arguments /= null and then Node.Method_Arg_Count > 0 then
                                 declare
                                    New_Length : constant Natural := Object_Val.Array_Length + 1;
                                    New_Array : constant Value_Array_Ptr := new Value_Array (1 .. New_Length);
                                    New_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                 begin
                                    -- Add new element at beginning
                                    New_Array (1) := new JS_Value'(New_Val);
                                    -- Copy old elements shifted by one
                                    for I in 1 .. Object_Val.Array_Length loop
                                       New_Array (I + 1) := Object_Val.Array_Elements (I);
                                    end loop;

                                    Object_Val.Array_Elements := New_Array;
                                    Object_Val.Array_Length := New_Length;

                                    -- Update the variable
                                    if Node.Callee.Object_Expr.Kind = AST.Node_Identifier then
                                       declare
                                          Var_Name : constant String :=
                                             Node.Callee.Object_Expr.Id_Name (1 .. Node.Callee.Object_Expr.Id_Length);
                                       begin
                                          Set_Variable (Var_Name, Object_Val);
                                       end;
                                    end if;

                                    return (Kind => Val_Number, Number => Float (New_Length));
                                 end;
                              end if;
                              return (Kind => Val_Undefined);
                           elsif Method_Name = "slice" then
                              -- slice(start, end): extract subarray without modifying original
                              declare
                                 Start_Idx : Integer := 0;
                                 End_Idx : Integer := Object_Val.Array_Length;
                              begin
                                 -- Parse start argument
                                 if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 1 then
                                    declare
                                       Start_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                    begin
                                       if Start_Val.Kind = Val_Number then
                                          Start_Idx := Integer (Start_Val.Number);
                                          -- Handle negative indices
                                          if Start_Idx < 0 then
                                             Start_Idx := Object_Val.Array_Length + Start_Idx;
                                             if Start_Idx < 0 then
                                                Start_Idx := 0;
                                             end if;
                                          end if;
                                       end if;
                                    end;
                                 end if;

                                 -- Parse end argument
                                 if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 2 then
                                    declare
                                       End_Val : constant JS_Value := Eval (Node.Method_Arguments (2));
                                    begin
                                       if End_Val.Kind = Val_Number then
                                          End_Idx := Integer (End_Val.Number);
                                          -- Handle negative indices
                                          if End_Idx < 0 then
                                             End_Idx := Object_Val.Array_Length + End_Idx;
                                          end if;
                                       end if;
                                    end;
                                 end if;

                                 -- Clamp indices
                                 if Start_Idx > Object_Val.Array_Length then
                                    Start_Idx := Object_Val.Array_Length;
                                 end if;
                                 if End_Idx > Object_Val.Array_Length then
                                    End_Idx := Object_Val.Array_Length;
                                 end if;
                                 if Start_Idx < 0 then
                                    Start_Idx := 0;
                                 end if;

                                 -- Create new array
                                 declare
                                    Slice_Length : constant Integer := Integer'Max (0, End_Idx - Start_Idx);
                                    Result_Array : JS_Value (Val_Array);
                                 begin
                                    Result_Array.Array_Length := Slice_Length;
                                    if Slice_Length > 0 then
                                       Result_Array.Array_Elements := new Value_Array (1 .. Slice_Length);
                                       for I in 1 .. Slice_Length loop
                                          Result_Array.Array_Elements (I) :=
                                             new JS_Value'(Object_Val.Array_Elements (Start_Idx + I).all);
                                       end loop;
                                    else
                                       Result_Array.Array_Elements := null;
                                    end if;
                                    return Result_Array;
                                 end;
                              end;
                           elsif Method_Name = "join" then
                              -- join(separator): convert array to string
                              declare
                                 Separator : String (1 .. 256);
                                 Sep_Len : Natural := 1;
                              begin
                                 -- Default separator is comma
                                 Separator (1) := ',';

                                 -- Parse separator argument
                                 if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 1 then
                                    declare
                                       Sep_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                    begin
                                       if Sep_Val.Kind = Val_String then
                                          Sep_Len := Sep_Val.Str_Length;
                                          Separator (1 .. Sep_Len) := Sep_Val.Str (1 .. Sep_Len);
                                       end if;
                                    end;
                                 end if;

                                 -- Build result string
                                 declare
                                    Result : String (1 .. 2048);
                                    Pos : Natural := 0;
                                 begin
                                    for I in 1 .. Object_Val.Array_Length loop
                                       if I > 1 then
                                          Result (Pos + 1 .. Pos + Sep_Len) := Separator (1 .. Sep_Len);
                                          Pos := Pos + Sep_Len;
                                       end if;

                                       declare
                                          Elem_Str : constant String := Value_To_String (Object_Val.Array_Elements (I).all);
                                       begin
                                          Result (Pos + 1 .. Pos + Elem_Str'Length) := Elem_Str;
                                          Pos := Pos + Elem_Str'Length;
                                       end;
                                    end loop;

                                    declare
                                       Result_Val : JS_Value (Val_String);
                                    begin
                                       Result_Val.Str_Length := Pos;
                                       Result_Val.Str (1 .. Pos) := Result (1 .. Pos);
                                       return Result_Val;
                                    end;
                                 end;
                              end;
                           elsif Method_Name = "indexOf" then
                              -- indexOf(value): find index of element, return -1 if not found
                              if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 1 then
                                 declare
                                    Search_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                 begin
                                    for I in 1 .. Object_Val.Array_Length loop
                                       declare
                                          Elem : constant JS_Value := Object_Val.Array_Elements (I).all;
                                       begin
                                          -- Simple equality check
                                          if Elem.Kind = Search_Val.Kind then
                                             case Elem.Kind is
                                                when Val_Number =>
                                                   if Elem.Number = Search_Val.Number then
                                                      return (Kind => Val_Number, Number => Float (I - 1));
                                                   end if;
                                                when Val_String =>
                                                   if Elem.Str (1 .. Elem.Str_Length) =
                                                      Search_Val.Str (1 .. Search_Val.Str_Length) then
                                                      return (Kind => Val_Number, Number => Float (I - 1));
                                                   end if;
                                                when Val_Boolean =>
                                                   if Elem.Bool = Search_Val.Bool then
                                                      return (Kind => Val_Number, Number => Float (I - 1));
                                                   end if;
                                                when others =>
                                                   null;
                                             end case;
                                          end if;
                                       end;
                                    end loop;
                                    -- Not found
                                    return (Kind => Val_Number, Number => -1.0);
                                 end;
                              end if;
                              return (Kind => Val_Number, Number => -1.0);
                           elsif Method_Name = "includes" then
                              -- includes(value): check if array contains value
                              if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 1 then
                                 declare
                                    Search_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                 begin
                                    for I in 1 .. Object_Val.Array_Length loop
                                       declare
                                          Elem : constant JS_Value := Object_Val.Array_Elements (I).all;
                                       begin
                                          if Elem.Kind = Search_Val.Kind then
                                             case Elem.Kind is
                                                when Val_Number =>
                                                   if Elem.Number = Search_Val.Number then
                                                      return (Kind => Val_Boolean, Bool => True);
                                                   end if;
                                                when Val_String =>
                                                   if Elem.Str (1 .. Elem.Str_Length) =
                                                      Search_Val.Str (1 .. Search_Val.Str_Length) then
                                                      return (Kind => Val_Boolean, Bool => True);
                                                   end if;
                                                when Val_Boolean =>
                                                   if Elem.Bool = Search_Val.Bool then
                                                      return (Kind => Val_Boolean, Bool => True);
                                                   end if;
                                                when others =>
                                                   null;
                                             end case;
                                          end if;
                                       end;
                                    end loop;
                                    return (Kind => Val_Boolean, Bool => False);
                                 end;
                              end if;
                              return (Kind => Val_Boolean, Bool => False);
                           elsif Method_Name = "map" then
                           -- map(callback): transform each element
                           if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 1 then
                              declare
                                 Callback_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                 Result_Array : Value_Array_Ptr;
                                 Saved_Vars : Variable_Maps.Map;
                              begin
                                 if Callback_Val.Kind /= Val_Function then
                                    return (Kind => Val_Undefined);
                                 end if;

                                 Result_Array := new Value_Array (1 .. Object_Val.Array_Length);

                                 -- Map each element
                                 for I in 1 .. Object_Val.Array_Length loop
                                    Saved_Vars := Variables.Copy;

                                    declare
                                       Func_Node : constant AST.AST_Node_Ptr := Callback_Val.Func_Node;
                                       Elem_Val : constant JS_Value := Object_Val.Array_Elements (I).all;
                                    begin
                                       if Func_Node.Kind = AST.Node_Arrow_Function and then Func_Node.Is_Expression_Body then
                                          if Func_Node.Arrow_Params /= null and Func_Node.Arrow_Param_Count > 0 then
                                             Set_Variable (
                                                Func_Node.Arrow_Params (1).Id_Name (1 .. Func_Node.Arrow_Params (1).Id_Length),
                                                Elem_Val);
                                          end if;
                                          Result_Array (I) := new JS_Value'(Eval (Func_Node.Arrow_Body));
                                       else
                                          -- Regular or block arrow function
                                          if Func_Node.Kind = AST.Node_Function_Declaration then
                                             if Func_Node.Params /= null and Func_Node.Param_Count > 0 then
                                                Set_Variable (
                                                   Func_Node.Params (1).Id_Name (1 .. Func_Node.Params (1).Id_Length),
                                                   Elem_Val);
                                             end if;
                                             begin
                                                Eval_Statement (Func_Node.Func_Body);
                                                Result_Array (I) := new JS_Value'((Kind => Val_Undefined));
                                             exception
                                                when Return_Exception =>
                                                   Result_Array (I) := new JS_Value'(Return_Val);
                                             end;
                                          else
                                             -- Arrow with block
                                             if Func_Node.Arrow_Params /= null and Func_Node.Arrow_Param_Count > 0 then
                                                Set_Variable (
                                                   Func_Node.Arrow_Params (1).Id_Name (1 .. Func_Node.Arrow_Params (1).Id_Length),
                                                   Elem_Val);
                                             end if;
                                             begin
                                                Eval_Statement (Func_Node.Arrow_Body);
                                                Result_Array (I) := new JS_Value'((Kind => Val_Undefined));
                                             exception
                                                when Return_Exception =>
                                                   Result_Array (I) := new JS_Value'(Return_Val);
                                             end;
                                          end if;
                                       end if;
                                    end;
                                    Variables := Saved_Vars;
                                 end loop;

                                 return (Kind => Val_Array,
                                         Array_Elements => Result_Array,
                                         Array_Length => Object_Val.Array_Length);
                              end;
                           end if;
                           return (Kind => Val_Undefined);
                        elsif Method_Name = "filter" then
                           -- filter(callback): select elements where callback returns true
                           if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 1 then
                              declare
                                 Callback_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                 Temp_Results : array (1 .. Object_Val.Array_Length) of JS_Value_Ptr;
                                 Result_Count : Natural := 0;
                                 Saved_Vars : Variable_Maps.Map;
                              begin
                                 if Callback_Val.Kind /= Val_Function then
                                    return (Kind => Val_Undefined);
                                 end if;

                                 for I in 1 .. Object_Val.Array_Length loop
                                    Saved_Vars := Variables.Copy;
                                    declare
                                       Func_Node : constant AST.AST_Node_Ptr := Callback_Val.Func_Node;
                                       Elem_Val : constant JS_Value := Object_Val.Array_Elements (I).all;
                                       Test_Result : JS_Value;
                                    begin
                                       if Func_Node.Kind = AST.Node_Arrow_Function and then Func_Node.Is_Expression_Body then
                                          if Func_Node.Arrow_Params /= null and Func_Node.Arrow_Param_Count > 0 then
                                             Set_Variable (Func_Node.Arrow_Params (1).Id_Name (1 .. Func_Node.Arrow_Params (1).Id_Length), Elem_Val);
                                          end if;
                                          Test_Result := Eval (Func_Node.Arrow_Body);
                                       elsif Func_Node.Kind = AST.Node_Function_Declaration then
                                          if Func_Node.Params /= null and Func_Node.Param_Count > 0 then
                                             Set_Variable (Func_Node.Params (1).Id_Name (1 .. Func_Node.Params (1).Id_Length), Elem_Val);
                                          end if;
                                          begin
                                             Eval_Statement (Func_Node.Func_Body);
                                             Test_Result := (Kind => Val_Undefined);
                                          exception
                                             when Return_Exception => Test_Result := Return_Val;
                                          end;
                                       else
                                          if Func_Node.Arrow_Params /= null and Func_Node.Arrow_Param_Count > 0 then
                                             Set_Variable (Func_Node.Arrow_Params (1).Id_Name (1 .. Func_Node.Arrow_Params (1).Id_Length), Elem_Val);
                                          end if;
                                          begin
                                             Eval_Statement (Func_Node.Arrow_Body);
                                             Test_Result := (Kind => Val_Undefined);
                                          exception
                                             when Return_Exception => Test_Result := Return_Val;
                                          end;
                                       end if;

                                       if Value_To_Boolean (Test_Result) then
                                          Result_Count := Result_Count + 1;
                                          Temp_Results (Result_Count) := Object_Val.Array_Elements (I);
                                       end if;
                                    end;
                                    Variables := Saved_Vars;
                                 end loop;

                                 if Result_Count > 0 then
                                    declare
                                       Result_Array : constant Value_Array_Ptr := new Value_Array (1 .. Result_Count);
                                    begin
                                       for I in 1 .. Result_Count loop
                                          Result_Array (I) := Temp_Results (I);
                                       end loop;
                                       return (Kind => Val_Array, Array_Elements => Result_Array, Array_Length => Result_Count);
                                    end;
                                 else
                                    return (Kind => Val_Array, Array_Elements => null, Array_Length => 0);
                                 end if;
                              end;
                           end if;
                           return (Kind => Val_Undefined);
                        elsif Method_Name = "forEach" then
                           -- forEach(callback): iterate over elements
                           if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 1 then
                              declare
                                 Callback_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                 Saved_Vars : Variable_Maps.Map;
                              begin
                                 if Callback_Val.Kind /= Val_Function then
                                    return (Kind => Val_Undefined);
                                 end if;

                                 for I in 1 .. Object_Val.Array_Length loop
                                    Saved_Vars := Variables.Copy;
                                    declare
                                       Func_Node : constant AST.AST_Node_Ptr := Callback_Val.Func_Node;
                                       Elem_Val : constant JS_Value := Object_Val.Array_Elements (I).all;
                                    begin
                                       if Func_Node.Kind = AST.Node_Arrow_Function and then Func_Node.Is_Expression_Body then
                                          if Func_Node.Arrow_Params /= null and Func_Node.Arrow_Param_Count > 0 then
                                             Set_Variable (Func_Node.Arrow_Params (1).Id_Name (1 .. Func_Node.Arrow_Params (1).Id_Length), Elem_Val);
                                          end if;
                                          declare
                                             Dummy : constant JS_Value := Eval (Func_Node.Arrow_Body);
                                          begin
                                             null;
                                          end;
                                       elsif Func_Node.Kind = AST.Node_Function_Declaration then
                                          if Func_Node.Params /= null and Func_Node.Param_Count > 0 then
                                             Set_Variable (Func_Node.Params (1).Id_Name (1 .. Func_Node.Params (1).Id_Length), Elem_Val);
                                          end if;
                                          begin
                                             Eval_Statement (Func_Node.Func_Body);
                                          exception
                                             when Return_Exception => null;
                                          end;
                                       else
                                          if Func_Node.Arrow_Params /= null and Func_Node.Arrow_Param_Count > 0 then
                                             Set_Variable (Func_Node.Arrow_Params (1).Id_Name (1 .. Func_Node.Arrow_Params (1).Id_Length), Elem_Val);
                                          end if;
                                          begin
                                             Eval_Statement (Func_Node.Arrow_Body);
                                          exception
                                             when Return_Exception => null;
                                          end;
                                       end if;
                                    end;
                                    Variables := Saved_Vars;
                                 end loop;
                                 return (Kind => Val_Undefined);
                              end;
                           end if;
                           return (Kind => Val_Undefined);
                        elsif Method_Name = "find" then
                           -- find(callback): find first element where callback returns true
                           if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 1 then
                              declare
                                 Callback_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                 Saved_Vars : Variable_Maps.Map;
                              begin
                                 if Callback_Val.Kind /= Val_Function then
                                    return (Kind => Val_Undefined);
                                 end if;

                                 for I in 1 .. Object_Val.Array_Length loop
                                    Saved_Vars := Variables.Copy;
                                    declare
                                       Func_Node : constant AST.AST_Node_Ptr := Callback_Val.Func_Node;
                                       Elem_Val : constant JS_Value := Object_Val.Array_Elements (I).all;
                                       Test_Result : JS_Value;
                                    begin
                                       if Func_Node.Kind = AST.Node_Arrow_Function and then Func_Node.Is_Expression_Body then
                                          if Func_Node.Arrow_Params /= null and Func_Node.Arrow_Param_Count > 0 then
                                             Set_Variable (Func_Node.Arrow_Params (1).Id_Name (1 .. Func_Node.Arrow_Params (1).Id_Length), Elem_Val);
                                          end if;
                                          Test_Result := Eval (Func_Node.Arrow_Body);
                                       elsif Func_Node.Kind = AST.Node_Function_Declaration then
                                          if Func_Node.Params /= null and Func_Node.Param_Count > 0 then
                                             Set_Variable (Func_Node.Params (1).Id_Name (1 .. Func_Node.Params (1).Id_Length), Elem_Val);
                                          end if;
                                          begin
                                             Eval_Statement (Func_Node.Func_Body);
                                             Test_Result := (Kind => Val_Undefined);
                                          exception
                                             when Return_Exception => Test_Result := Return_Val;
                                          end;
                                       else
                                          if Func_Node.Arrow_Params /= null and Func_Node.Arrow_Param_Count > 0 then
                                             Set_Variable (Func_Node.Arrow_Params (1).Id_Name (1 .. Func_Node.Arrow_Params (1).Id_Length), Elem_Val);
                                          end if;
                                          begin
                                             Eval_Statement (Func_Node.Arrow_Body);
                                             Test_Result := (Kind => Val_Undefined);
                                          exception
                                             when Return_Exception => Test_Result := Return_Val;
                                          end;
                                       end if;

                                       if Value_To_Boolean (Test_Result) then
                                          Variables := Saved_Vars;
                                          return Elem_Val;
                                       end if;
                                    end;
                                    Variables := Saved_Vars;
                                 end loop;
                                 return (Kind => Val_Undefined);
                              end;
                           end if;
                           return (Kind => Val_Undefined);
                        elsif Method_Name = "reduce" then
                           -- reduce(callback, initialValue): reduce array to single value
                           if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 2 then
                              declare
                                 Callback_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                 Accumulator : JS_Value := Eval (Node.Method_Arguments (2));
                                 Saved_Vars : Variable_Maps.Map;
                              begin
                                 if Callback_Val.Kind /= Val_Function then
                                    return (Kind => Val_Undefined);
                                 end if;

                                 for I in 1 .. Object_Val.Array_Length loop
                                    Saved_Vars := Variables.Copy;
                                    declare
                                       Func_Node : constant AST.AST_Node_Ptr := Callback_Val.Func_Node;
                                       Elem_Val : constant JS_Value := Object_Val.Array_Elements (I).all;
                                    begin
                                       if Func_Node.Kind = AST.Node_Function_Declaration then
                                          if Func_Node.Params /= null and Func_Node.Param_Count >= 1 then
                                             Set_Variable (Func_Node.Params (1).Id_Name (1 .. Func_Node.Params (1).Id_Length), Accumulator);
                                          end if;
                                          if Func_Node.Params /= null and Func_Node.Param_Count >= 2 then
                                             Set_Variable (Func_Node.Params (2).Id_Name (1 .. Func_Node.Params (2).Id_Length), Elem_Val);
                                          end if;
                                          begin
                                             Eval_Statement (Func_Node.Func_Body);
                                             Accumulator := (Kind => Val_Undefined);
                                          exception
                                             when Return_Exception => Accumulator := Return_Val;
                                          end;
                                       elsif Func_Node.Kind = AST.Node_Arrow_Function then
                                          if Func_Node.Arrow_Params /= null and Func_Node.Arrow_Param_Count >= 1 then
                                             Set_Variable (Func_Node.Arrow_Params (1).Id_Name (1 .. Func_Node.Arrow_Params (1).Id_Length), Accumulator);
                                          end if;
                                          if Func_Node.Arrow_Params /= null and Func_Node.Arrow_Param_Count >= 2 then
                                             Set_Variable (Func_Node.Arrow_Params (2).Id_Name (1 .. Func_Node.Arrow_Params (2).Id_Length), Elem_Val);
                                          end if;
                                          if Func_Node.Is_Expression_Body then
                                             Accumulator := Eval (Func_Node.Arrow_Body);
                                          else
                                             begin
                                                Eval_Statement (Func_Node.Arrow_Body);
                                                Accumulator := (Kind => Val_Undefined);
                                             exception
                                                when Return_Exception => Accumulator := Return_Val;
                                             end;
                                          end if;
                                       end if;
                                    end;
                                    Variables := Saved_Vars;
                                 end loop;
                                 return Accumulator;
                              end;
                           end if;
                           return (Kind => Val_Undefined);
                        end if;
                     elsif Object_Val.Kind = Val_Object and then not Object_Val.Is_Class_Instance then
                        -- Built-in object methods (Math, console, etc.)
                        declare
                           Object_Name : String (1 .. 256);
                           Obj_Name_Len : Natural := 0;
                        begin
                           -- Try to get the object name from the identifier
                           if Node.Callee.Object_Expr.Kind = AST.Node_Identifier then
                              Obj_Name_Len := Node.Callee.Object_Expr.Id_Length;
                              Object_Name (1 .. Obj_Name_Len) :=
                                 Node.Callee.Object_Expr.Id_Name (1 .. Obj_Name_Len);

                              if Object_Name (1 .. Obj_Name_Len) = "Math" then
                                 -- Math object methods
                                 if Method_Name = "floor" then
                                    if Node.Method_Arg_Count > 0 then
                                       declare
                                          Arg_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                       begin
                                          if Arg_Val.Kind = Val_Number then
                                             return (Kind => Val_Number, Number => Float (Integer (Float'Floor (Arg_Val.Number))));
                                          end if;
                                       end;
                                    end if;
                                 elsif Method_Name = "ceil" then
                                    if Node.Method_Arg_Count > 0 then
                                       declare
                                          Arg_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                       begin
                                          if Arg_Val.Kind = Val_Number then
                                             return (Kind => Val_Number, Number => Float (Integer (Float'Ceiling (Arg_Val.Number))));
                                          end if;
                                       end;
                                    end if;
                                 elsif Method_Name = "round" then
                                    if Node.Method_Arg_Count > 0 then
                                       declare
                                          Arg_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                       begin
                                          if Arg_Val.Kind = Val_Number then
                                             return (Kind => Val_Number, Number => Float (Integer (Float'Rounding (Arg_Val.Number))));
                                          end if;
                                       end;
                                    end if;
                                 elsif Method_Name = "abs" then
                                    if Node.Method_Arg_Count > 0 then
                                       declare
                                          Arg_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                       begin
                                          if Arg_Val.Kind = Val_Number then
                                             return (Kind => Val_Number, Number => abs (Arg_Val.Number));
                                          end if;
                                       end;
                                    end if;
                                 elsif Method_Name = "sqrt" then
                                    if Node.Method_Arg_Count > 0 then
                                       declare
                                          Arg_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                       begin
                                          if Arg_Val.Kind = Val_Number and then Arg_Val.Number >= 0.0 then
                                                return (Kind => Val_Number, Number => Sqrt(Arg_Val.Number));
                                          end if;
                                       end;
                                    end if;
                                 elsif Method_Name = "pow" then
                                    if Node.Method_Arg_Count >= 2 then
                                       declare
                                          Base_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                          Exp_Val : constant JS_Value := Eval (Node.Method_Arguments (2));
                                       begin
                                          if Base_Val.Kind = Val_Number and Exp_Val.Kind = Val_Number then
                                             declare
                                                Base : constant Float := Base_Val.Number;
                                                Exponent : constant Float := Exp_Val.Number;
                                                Result : Float;
                                             begin
                                                -- Use Ada's ** operator for integer exponents
                                                if Exponent = Float(Integer(Exponent)) then
                                                   Result := (abs Base) ** Integer(Exponent);
                                                   if Base < 0.0 then
                                                      Result := -Result;
                                                   end if;
                                                else
                                                   -- For fractional exponents, use exp(exponent * log(base))
                                                   Result := Ada.Numerics.Elementary_Functions.Exp(
                                                      Exponent * Ada.Numerics.Elementary_Functions.Log(abs Base));
                                                   if Base < 0.0 then
                                                      Result := -Result;
                                                   end if;
                                                end if;
                                                return (Kind => Val_Number, Number => Result);
                                             end;
                                          end if;
                                       end;
                                    end if;
                                 elsif Method_Name = "min" then
                                    if Node.Method_Arg_Count >= 2 then
                                       declare
                                          Min_Val : Float := Float'Last;
                                       begin
                                          for I in 1 .. Node.Method_Arg_Count loop
                                             declare
                                                Arg : constant JS_Value := Eval (Node.Method_Arguments (I));
                                             begin
                                                if Arg.Kind = Val_Number and then Arg.Number < Min_Val then
                                                   Min_Val := Arg.Number;
                                                end if;
                                             end;
                                          end loop;
                                          return (Kind => Val_Number, Number => Min_Val);
                                       end;
                                    end if;
                                 elsif Method_Name = "max" then
                                    if Node.Method_Arg_Count >= 2 then
                                       declare
                                          Max_Val : Float := Float'First;
                                       begin
                                          for I in 1 .. Node.Method_Arg_Count loop
                                             declare
                                                Arg : constant JS_Value := Eval (Node.Method_Arguments (I));
                                             begin
                                                if Arg.Kind = Val_Number and then Arg.Number > Max_Val then
                                                   Max_Val := Arg.Number;
                                                end if;
                                             end;
                                          end loop;
                                          return (Kind => Val_Number, Number => Max_Val);
                                       end;
                                    end if;
                                 elsif Method_Name = "random" then
                                    -- Simple pseudo-random using clock fractional seconds
                                    declare
                                       use Ada.Calendar;
                                       Now : constant Time := Clock;
                                       Split_Secs : constant Duration := Seconds (Now);
                                       -- Get fractional part by taking modulo 1.0
                                       Int_Part : constant Integer := Integer (Float'Floor (Float (Split_Secs)));
                                       Fractional : constant Float := Float (Split_Secs) - Float (Int_Part);
                                    begin
                                       return (Kind => Val_Number, Number => Fractional);
                                    end;
                                 end if;
                              elsif Object_Name (1 .. Obj_Name_Len) = "console" then
                                 -- console object methods
                                 if Method_Name = "log" then
                                    -- console.log(): print all arguments
                                    if Node.Method_Arg_Count > 0 then
                                       for I in 1 .. Node.Method_Arg_Count loop
                                          declare
                                             Val : constant JS_Value := Eval (Node.Method_Arguments (I));
                                          begin
                                             Ada.Text_IO.Put (Value_To_String (Val));
                                             if I < Node.Method_Arg_Count then
                                                Ada.Text_IO.Put (" ");
                                             end if;
                                          end;
                                       end loop;
                                       Ada.Text_IO.New_Line;
                                    else
                                       Ada.Text_IO.New_Line;
                                    end if;
                                    return (Kind => Val_Undefined);
                                 end if;
                              end if;
                           end if;
                        end;
                        return (Kind => Val_Undefined);
                     elsif Object_Val.Kind = Val_Object and then Object_Val.Is_Class_Instance then
                        -- Class instance method calls
                        declare
                           Method_Found : Boolean := False;
                           Saved_This : constant JS_Value_Ptr := Current_This;
                           Obj_Ptr : constant JS_Value_Ptr := new JS_Value'(Object_Val);
                           Current_Class : AST.AST_Node_Ptr := Object_Val.Class_Def;
                        begin
                           Current_This := Obj_Ptr;

                           -- Search for method in class hierarchy (child first, then parents)
                           while Current_Class /= null and not Method_Found loop
                              -- Find method in current class
                              if Current_Class.Method_Count > 0 then
                                 for I in 1 .. Current_Class.Method_Count loop
                                    declare
                                       Method : constant AST.AST_Node_Ptr := Current_Class.Class_Methods (I);
                                       MName : constant String := Method.Func_Name (1 .. Method.Func_Name_Length);
                                    begin
                                       if MName = Method_Name then
                                          Method_Found := True;

                                          -- Save variables
                                          declare
                                             Saved_Vars : constant Variable_Maps.Map := Variables;
                                          begin
                                             -- Bind parameters
                                             if Node.Method_Arg_Count > 0 and Method.Param_Count > 0 then
                                                for J in 1 .. Integer'Min (Node.Method_Arg_Count, Method.Param_Count) loop
                                                   declare
                                                      Param_Name : constant String :=
                                                         Method.Params (J).Id_Name (1 .. Method.Params (J).Id_Length);
                                                      Arg_Val : constant JS_Value := Eval (Node.Method_Arguments (J));
                                                   begin
                                                      Set_Variable (Param_Name, Arg_Val);
                                                   end;
                                                end loop;
                                             end if;

                                             -- Execute method body
                                             declare
                                                Result : JS_Value;
                                             begin
                                                begin
                                                   Eval_Statement (Method.Func_Body);
                                                   Result := (Kind => Val_Undefined);
                                                exception
                                                   when Return_Exception =>
                                                      Result := Return_Val;
                                                end;

                                                Variables := Saved_Vars;
                                                Current_This := Saved_This;
                                                return Result;
                                             end;
                                          end;
                                       end if;
                                    end;
                                 end loop;
                              end if;

                              -- Move to parent class if method not found
                              if not Method_Found and Current_Class.Parent_Class_Name_Length > 0 then
                                 declare
                                    Parent_Name : constant String :=
                                       Current_Class.Parent_Class_Name (1 .. Current_Class.Parent_Class_Name_Length);
                                    Parent_Class_Val : constant JS_Value := Get_Variable (Parent_Name);
                                 begin
                                    if Parent_Class_Val.Kind = Val_Class then
                                       Current_Class := Parent_Class_Val.Class_Node;
                                    else
                                       Current_Class := null;  -- Stop if parent not found
                                    end if;
                                 end;
                              else
                                 Current_Class := null;  -- No more parents
                              end if;
                           end loop;

                           Current_This := Saved_This;

                           if not Method_Found then
                              raise Runtime_Error with "Method '" & Method_Name & "' not found";
                           end if;
                           return (Kind => Val_Undefined);
                        end;
                     elsif Object_Val.Kind = Val_String then
                        -- String methods
                        if Method_Name = "split" then
                              -- split(separator): split string into array
                              declare
                                 Separator : String (1 .. 256);
                                 Sep_Len : Natural := 0;
                              begin
                                 -- Parse separator argument (default: empty = split every char)
                                 if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 1 then
                                    declare
                                       Sep_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                    begin
                                       if Sep_Val.Kind = Val_String then
                                          Sep_Len := Sep_Val.Str_Length;
                                          Separator (1 .. Sep_Len) := Sep_Val.Str (1 .. Sep_Len);
                                       end if;
                                    end;
                                 end if;

                                 -- Split the string
                                 declare
                                    Parts : array (1 .. 100) of JS_Value_Ptr;
                                    Part_Count : Natural := 0;
                                    Current_Part : String (1 .. 256);
                                    Part_Len : Natural := 0;
                                    I : Positive := 1;
                                 begin
                                    if Sep_Len = 0 then
                                       -- Split into individual characters
                                       for J in 1 .. Object_Val.Str_Length loop
                                          Part_Count := Part_Count + 1;
                                          declare
                                             Char_Val : JS_Value (Val_String);
                                          begin
                                             Char_Val.Str_Length := 1;
                                             Char_Val.Str (1) := Object_Val.Str (J);
                                             Parts (Part_Count) := new JS_Value'(Char_Val);
                                          end;
                                       end loop;
                                    else
                                       -- Split by separator
                                       while I <= Object_Val.Str_Length loop
                                          -- Check if separator matches at current position
                                          if I + Sep_Len - 1 <= Object_Val.Str_Length and then
                                             Object_Val.Str (I .. I + Sep_Len - 1) = Separator (1 .. Sep_Len) then
                                             -- Found separator, save current part
                                             if Part_Len > 0 or Part_Count = 0 then
                                                Part_Count := Part_Count + 1;
                                                declare
                                                   Part_Val : JS_Value (Val_String);
                                                begin
                                                   Part_Val.Str_Length := Part_Len;
                                                   Part_Val.Str (1 .. Part_Len) := Current_Part (1 .. Part_Len);
                                                   Parts (Part_Count) := new JS_Value'(Part_Val);
                                                end;
                                             end if;
                                             Part_Len := 0;
                                             I := I + Sep_Len;
                                          else
                                             -- Add character to current part
                                             Part_Len := Part_Len + 1;
                                             Current_Part (Part_Len) := Object_Val.Str (I);
                                             I := I + 1;
                                          end if;
                                       end loop;

                                       -- Add final part
                                       Part_Count := Part_Count + 1;
                                       declare
                                          Part_Val : JS_Value (Val_String);
                                       begin
                                          Part_Val.Str_Length := Part_Len;
                                          Part_Val.Str (1 .. Part_Len) := Current_Part (1 .. Part_Len);
                                          Parts (Part_Count) := new JS_Value'(Part_Val);
                                       end;
                                    end if;

                                    -- Create result array
                                    declare
                                       Result_Array : JS_Value (Val_Array);
                                    begin
                                       Result_Array.Array_Length := Part_Count;
                                       Result_Array.Array_Elements := new Value_Array (1 .. Part_Count);
                                       for J in 1 .. Part_Count loop
                                          Result_Array.Array_Elements (J) := Parts (J);
                                       end loop;
                                       return Result_Array;
                                    end;
                                 end;
                              end;
                           elsif Method_Name = "substring" then
                              -- substring(start, end): extract substring
                              declare
                                 Start_Idx : Integer := 0;
                                 End_Idx : Integer := Object_Val.Str_Length;
                              begin
                                 if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 1 then
                                    declare
                                       Start_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                    begin
                                       if Start_Val.Kind = Val_Number then
                                          Start_Idx := Integer (Start_Val.Number);
                                       end if;
                                    end;
                                 end if;

                                 if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 2 then
                                    declare
                                       End_Val : constant JS_Value := Eval (Node.Method_Arguments (2));
                                    begin
                                       if End_Val.Kind = Val_Number then
                                          End_Idx := Integer (End_Val.Number);
                                       end if;
                                    end;
                                 end if;

                                 -- Clamp indices
                                 if Start_Idx < 0 then
                                    Start_Idx := 0;
                                 end if;
                                 if Start_Idx > Object_Val.Str_Length then
                                    Start_Idx := Object_Val.Str_Length;
                                 end if;
                                 if End_Idx < Start_Idx then
                                    End_Idx := Start_Idx;
                                 end if;
                                 if End_Idx > Object_Val.Str_Length then
                                    End_Idx := Object_Val.Str_Length;
                                 end if;

                                 declare
                                    Substr_Len : constant Natural := End_Idx - Start_Idx;
                                    Result : JS_Value (Val_String);
                                 begin
                                    Result.Str_Length := Substr_Len;
                                    if Substr_Len > 0 then
                                       Result.Str (1 .. Substr_Len) := Object_Val.Str (Start_Idx + 1 .. End_Idx);
                                    end if;
                                    return Result;
                                 end;
                              end;
                           elsif Method_Name = "charAt" then
                              -- charAt(index): get character at index
                              if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 1 then
                                 declare
                                    Index_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                 begin
                                    if Index_Val.Kind = Val_Number then
                                       declare
                                          Index : constant Integer := Integer (Index_Val.Number);
                                          Result : JS_Value (Val_String);
                                       begin
                                          if Index >= 0 and then Index < Object_Val.Str_Length then
                                             Result.Str_Length := 1;
                                             Result.Str (1) := Object_Val.Str (Index + 1);
                                             return Result;
                                          else
                                             Result.Str_Length := 0;
                                             return Result;
                                          end if;
                                       end;
                                    end if;
                                 end;
                              end if;
                              return (Kind => Val_String, Str_Length => 0, Str => (others => ' '));
                           elsif Method_Name = "toUpperCase" then
                              -- toUpperCase(): convert to uppercase
                              declare
                                 Result : JS_Value (Val_String);
                              begin
                                 Result.Str_Length := Object_Val.Str_Length;
                                 for I in 1 .. Object_Val.Str_Length loop
                                    declare
                                       C : constant Character := Object_Val.Str (I);
                                    begin
                                       if C >= 'a' and C <= 'z' then
                                          Result.Str (I) := Character'Val (Character'Pos (C) - 32);
                                       else
                                          Result.Str (I) := C;
                                       end if;
                                    end;
                                 end loop;
                                 return Result;
                              end;
                           elsif Method_Name = "toLowerCase" then
                              -- toLowerCase(): convert to lowercase
                              declare
                                 Result : JS_Value (Val_String);
                              begin
                                 Result.Str_Length := Object_Val.Str_Length;
                                 for I in 1 .. Object_Val.Str_Length loop
                                    declare
                                       C : constant Character := Object_Val.Str (I);
                                    begin
                                       if C >= 'A' and C <= 'Z' then
                                          Result.Str (I) := Character'Val (Character'Pos (C) + 32);
                                       else
                                          Result.Str (I) := C;
                                       end if;
                                    end;
                                 end loop;
                                 return Result;
                              end;
                           elsif Method_Name = "trim" then
                              -- trim(): remove whitespace from both ends
                              declare
                                 Start_Pos : Positive := 1;
                                 End_Pos : Natural := Object_Val.Str_Length;
                                 Result : JS_Value (Val_String);
                              begin
                                 -- Find first non-whitespace
                                 while Start_Pos <= Object_Val.Str_Length and then
                                       (Object_Val.Str (Start_Pos) = ' ' or
                                        Object_Val.Str (Start_Pos) = ASCII.HT or
                                        Object_Val.Str (Start_Pos) = ASCII.LF or
                                        Object_Val.Str (Start_Pos) = ASCII.CR) loop
                                    Start_Pos := Start_Pos + 1;
                                 end loop;

                                 -- Find last non-whitespace
                                 while End_Pos >= Start_Pos and then
                                       (Object_Val.Str (End_Pos) = ' ' or
                                        Object_Val.Str (End_Pos) = ASCII.HT or
                                        Object_Val.Str (End_Pos) = ASCII.LF or
                                        Object_Val.Str (End_Pos) = ASCII.CR) loop
                                    End_Pos := End_Pos - 1;
                                 end loop;

                                 if Start_Pos <= End_Pos then
                                    Result.Str_Length := End_Pos - Start_Pos + 1;
                                    Result.Str (1 .. Result.Str_Length) := Object_Val.Str (Start_Pos .. End_Pos);
                                 else
                                    Result.Str_Length := 0;
                                 end if;
                                 return Result;
                              end;
                           elsif Method_Name = "replace" then
                              -- replace(search, replacement): replace first occurrence
                              if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 2 then
                                 declare
                                    Search_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                    Replace_Val : constant JS_Value := Eval (Node.Method_Arguments (2));
                                    Result : JS_Value (Val_String);
                                 begin
                                    if Search_Val.Kind = Val_String and Replace_Val.Kind = Val_String then
                                       declare
                                          Search_Str : constant String := Search_Val.Str (1 .. Search_Val.Str_Length);
                                          Replace_Str : constant String := Replace_Val.Str (1 .. Replace_Val.Str_Length);
                                          Found_Pos : Natural := 0;
                                       begin
                                          -- Find first occurrence
                                          if Search_Val.Str_Length > 0 and Search_Val.Str_Length <= Object_Val.Str_Length then
                                             for I in 1 .. Object_Val.Str_Length - Search_Val.Str_Length + 1 loop
                                                if Object_Val.Str (I .. I + Search_Val.Str_Length - 1) = Search_Str then
                                                   Found_Pos := I;
                                                   exit;
                                                end if;
                                             end loop;
                                          end if;

                                          if Found_Pos > 0 then
                                             -- Replace: before + replacement + after
                                             Result.Str_Length := Found_Pos - 1 + Replace_Val.Str_Length +
                                               (Object_Val.Str_Length - (Found_Pos + Search_Val.Str_Length - 1));
                                             if Result.Str_Length <= 256 then
                                                if Found_Pos > 1 then
                                                   Result.Str (1 .. Found_Pos - 1) := Object_Val.Str (1 .. Found_Pos - 1);
                                                end if;
                                                if Replace_Val.Str_Length > 0 then
                                                   Result.Str (Found_Pos .. Found_Pos + Replace_Val.Str_Length - 1) := Replace_Str;
                                                end if;
                                                if Found_Pos + Search_Val.Str_Length <= Object_Val.Str_Length then
                                                   Result.Str (Found_Pos + Replace_Val.Str_Length .. Result.Str_Length) :=
                                                     Object_Val.Str (Found_Pos + Search_Val.Str_Length .. Object_Val.Str_Length);
                                                end if;
                                                return Result;
                                             end if;
                                          else
                                             -- Not found, return original
                                             Result.Str_Length := Object_Val.Str_Length;
                                             Result.Str (1 .. Result.Str_Length) := Object_Val.Str (1 .. Object_Val.Str_Length);
                                             return Result;
                                          end if;
                                       end;
                                    end if;
                                 end;
                              end if;
                              return (Kind => Val_Undefined);
                           elsif Method_Name = "repeat" then
                              -- repeat(count): repeat string N times
                              if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 1 then
                                 declare
                                    Count_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                    Result : JS_Value (Val_String);
                                 begin
                                    if Count_Val.Kind = Val_Number then
                                       declare
                                          Count : constant Integer := Integer (Count_Val.Number);
                                          Result_Len : Natural := 0;
                                       begin
                                          if Count > 0 and Count * Object_Val.Str_Length <= 256 then
                                             for I in 1 .. Count loop
                                                Result.Str (Result_Len + 1 .. Result_Len + Object_Val.Str_Length) :=
                                                  Object_Val.Str (1 .. Object_Val.Str_Length);
                                                Result_Len := Result_Len + Object_Val.Str_Length;
                                             end loop;
                                             Result.Str_Length := Result_Len;
                                             return Result;
                                          end if;
                                       end;
                                    end if;
                                 end;
                              end if;
                              return (Kind => Val_String, Str_Length => 0, Str => (others => ' '));
                           elsif Method_Name = "startsWith" then
                              -- startsWith(prefix): check if string starts with prefix
                              if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 1 then
                                 declare
                                    Prefix_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                 begin
                                    if Prefix_Val.Kind = Val_String then
                                       if Prefix_Val.Str_Length <= Object_Val.Str_Length and Prefix_Val.Str_Length > 0 then
                                          if Object_Val.Str (1 .. Prefix_Val.Str_Length) =
                                             Prefix_Val.Str (1 .. Prefix_Val.Str_Length) then
                                             return (Kind => Val_Boolean, Bool => True);
                                          end if;
                                       end if;
                                    end if;
                                 end;
                              end if;
                              return (Kind => Val_Boolean, Bool => False);
                           elsif Method_Name = "endsWith" then
                              -- endsWith(suffix): check if string ends with suffix
                              if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 1 then
                                 declare
                                    Suffix_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                 begin
                                    if Suffix_Val.Kind = Val_String then
                                       if Suffix_Val.Str_Length <= Object_Val.Str_Length and Suffix_Val.Str_Length > 0 then
                                          declare
                                             Start_Pos : constant Positive :=
                                               Object_Val.Str_Length - Suffix_Val.Str_Length + 1;
                                          begin
                                             if Object_Val.Str (Start_Pos .. Object_Val.Str_Length) =
                                                Suffix_Val.Str (1 .. Suffix_Val.Str_Length) then
                                                return (Kind => Val_Boolean, Bool => True);
                                             end if;
                                          end;
                                       end if;
                                    end if;
                                 end;
                              end if;
                              return (Kind => Val_Boolean, Bool => False);
                           elsif Method_Name = "indexOf" then
                              -- indexOf(substring): find position (0-indexed, -1 if not found)
                              if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 1 then
                                 declare
                                    Search_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                 begin
                                    if Search_Val.Kind = Val_String then
                                       if Search_Val.Str_Length = 0 then
                                          return (Kind => Val_Number, Number => 0.0);
                                       elsif Search_Val.Str_Length <= Object_Val.Str_Length then
                                          for I in 1 .. Object_Val.Str_Length - Search_Val.Str_Length + 1 loop
                                             if Object_Val.Str (I .. I + Search_Val.Str_Length - 1) =
                                                Search_Val.Str (1 .. Search_Val.Str_Length) then
                                                return (Kind => Val_Number, Number => Float (I - 1));
                                             end if;
                                          end loop;
                                       end if;
                                    end if;
                                 end;
                              end if;
                              return (Kind => Val_Number, Number => -1.0);
                           elsif Method_Name = "lastIndexOf" then
                              -- lastIndexOf(substring): find last position
                              if Node.Method_Arguments /= null and then Node.Method_Arg_Count >= 1 then
                                 declare
                                    Search_Val : constant JS_Value := Eval (Node.Method_Arguments (1));
                                    Last_Pos : Integer := -1;
                                 begin
                                    if Search_Val.Kind = Val_String then
                                       if Search_Val.Str_Length = 0 then
                                          return (Kind => Val_Number, Number => Float (Object_Val.Str_Length));
                                       elsif Search_Val.Str_Length <= Object_Val.Str_Length then
                                          for I in 1 .. Object_Val.Str_Length - Search_Val.Str_Length + 1 loop
                                             if Object_Val.Str (I .. I + Search_Val.Str_Length - 1) =
                                                Search_Val.Str (1 .. Search_Val.Str_Length) then
                                                Last_Pos := I - 1;
                                             end if;
                                          end loop;
                                       end if;
                                    end if;
                                    return (Kind => Val_Number, Number => Float (Last_Pos));
                                 end;
                              end if;
                              return (Kind => Val_Number, Number => -1.0);
                           end if;
                     end if;
                  end;
               elsif Node.Callee.Kind = AST.Node_Identifier then
                  -- Regular function call
                  declare
                     Func_Name : constant String := Node.Callee.Id_Name (1 .. Node.Callee.Id_Length);
                     Func_Val : JS_Value;
                     Func_Node : AST.AST_Node_Ptr;
                     Saved_Vars : Variable_Maps.Map;
                  begin
                     -- Get function from variables
                     Func_Val := Get_Variable (Func_Name);

                     if Func_Val.Kind /= Val_Function then
                        return (Kind => Val_Undefined);
                     end if;

                     Func_Node := Func_Val.Func_Node;
                     Saved_Vars := Variables.Copy;

                     -- Bind parameters based on function type
                     if Func_Node.Kind = AST.Node_Function_Declaration then
                        if Node.Method_Arguments /= null and Func_Node.Params /= null then
                           for I in 1 .. Integer'Min (Node.Method_Arg_Count, Func_Node.Param_Count) loop
                              declare
                                 Param_Name : constant String :=
                                    Func_Node.Params (I).Id_Name (1 .. Func_Node.Params (I).Id_Length);
                                 Arg_Val : constant JS_Value := Eval (Node.Method_Arguments (I));
                              begin
                                 Set_Variable (Param_Name, Arg_Val);
                              end;
                           end loop;
                        end if;

                        -- Execute function
                        begin
                           Eval_Statement (Func_Node.Func_Body);
                           Variables := Saved_Vars;
                           return (Kind => Val_Undefined);
                        exception
                           when Return_Exception =>
                              Variables := Saved_Vars;
                              return Return_Val;
                        end;
                     elsif Func_Node.Kind = AST.Node_Arrow_Function then
                        if Node.Method_Arguments /= null and Func_Node.Arrow_Params /= null then
                           for I in 1 .. Integer'Min (Node.Method_Arg_Count, Func_Node.Arrow_Param_Count) loop
                              declare
                                 Param_Name : constant String :=
                                    Func_Node.Arrow_Params (I).Id_Name (1 .. Func_Node.Arrow_Params (I).Id_Length);
                                 Arg_Val : constant JS_Value := Eval (Node.Method_Arguments (I));
                              begin
                                 Set_Variable (Param_Name, Arg_Val);
                              end;
                           end loop;
                        end if;

                        -- Execute arrow function body
                        if Func_Node.Is_Expression_Body then
                           declare
                              Result : constant JS_Value := Eval (Func_Node.Arrow_Body);
                           begin
                              Variables := Saved_Vars;
                              return Result;
                           end;
                        else
                           begin
                              Eval_Statement (Func_Node.Arrow_Body);
                              Variables := Saved_Vars;
                              return (Kind => Val_Undefined);
                           exception
                              when Return_Exception =>
                                 Variables := Saved_Vars;
                                 return Return_Val;
                           end;
                        end if;
                     end if;

                     Variables := Saved_Vars;
                     return (Kind => Val_Undefined);
                  end;
               end if;

               return (Kind => Val_Undefined);
            end;

         when AST.Node_Arrow_Function =>
            -- Arrow function evaluates to a function value
            declare
               Func_Val : JS_Value (Kind => Val_Function);
               Closure : Object_Map_Ptr := new Object_Maps.Map;
            begin
               -- Capture current environment (shallow copy of variable values)
               for Cursor in Variables.Iterate loop
                  Closure.Include (
                     Variable_Maps.Key (Cursor),
                     new JS_Value'(Variable_Maps.Element (Cursor))
                  );
               end loop;

               Func_Val.Func_Node := Node;
               Func_Val.Closure_Env := Closure;
               return Func_Val;
            end;

         when AST.Node_Array_Literal =>
            -- Evaluate array elements
            declare
               Array_Val : JS_Value (Val_Array);
            begin
               Array_Val.Array_Length := Node.Element_Count;
               if Node.Element_Count > 0 then
                  Array_Val.Array_Elements := new Value_Array (1 .. Node.Element_Count);
                  for I in 1 .. Node.Element_Count loop
                     Array_Val.Array_Elements (I) := new JS_Value'(Eval (Node.Elements (I)));
                  end loop;
               else
                  Array_Val.Array_Elements := null;
               end if;
               return Array_Val;
            end;

         when AST.Node_Object_Literal =>
            -- Evaluate object properties
            declare
               Obj_Val : JS_Value (Val_Object);
            begin
               Obj_Val.Object_Properties := new Object_Maps.Map;

               for I in 1 .. Node.Property_Count loop
                  declare
                     Prop : constant AST.AST_Node_Ptr := Node.Properties (I);
                     Key : constant String := Prop.Prop_Key (1 .. Prop.Prop_Key_Length);
                     Value : constant JS_Value := Eval (Prop.Prop_Value);
                  begin
                     Obj_Val.Object_Properties.Insert (Key, new JS_Value'(Value));
                  end;
               end loop;

               return Obj_Val;
            end;

         when AST.Node_Array_Index =>
            -- Array indexing: arr[index], string indexing: str[index], or object property: obj["key"]
            declare
               Val : constant JS_Value := Eval (Node.Array_Expr);
               Index_Val : constant JS_Value := Eval (Node.Index_Expr);
            begin
               if Val.Kind = Val_Array and then Index_Val.Kind = Val_Number then
                  declare
                     Index : constant Integer := Integer (Index_Val.Number);
                  begin
                     if Index >= 0 and then Index < Val.Array_Length then
                        return Val.Array_Elements (Index + 1).all;  -- Convert 0-based to 1-based
                     else
                        return (Kind => Val_Undefined);  -- Out of bounds
                     end if;
                  end;
               elsif Val.Kind = Val_String and then Index_Val.Kind = Val_Number then
                  -- String indexing
                  declare
                     Index : constant Integer := Integer (Index_Val.Number);
                     Char_Result : JS_Value (Val_String);
                  begin
                     if Index >= 0 and then Index < Val.Str_Length then
                        Char_Result.Str_Length := 1;
                        Char_Result.Str (1) := Val.Str (Index + 1);  -- Convert 0-based to 1-based
                        return Char_Result;
                     else
                        return (Kind => Val_Undefined);  -- Out of bounds
                     end if;
                  end;
               elsif Val.Kind = Val_Object and then Index_Val.Kind = Val_String then
                  -- Object property access with bracket notation: obj["key"]
                  declare
                     Key : constant String := Index_Val.Str (1 .. Index_Val.Str_Length);
                  begin
                     if Val.Object_Properties.Contains (Key) then
                        return Val.Object_Properties.Element (Key).all;
                     else
                        return (Kind => Val_Undefined);
                     end if;
                  end;
               end if;
               return (Kind => Val_Undefined);
            end;

         when AST.Node_Member_Access =>
            -- Member access: obj.property
            declare
               Obj_Val : constant JS_Value := Eval (Node.Object_Expr);
               Member : constant String := Node.Member_Name (1 .. Node.Member_Length);
            begin
               if Member = "length" then
                  if Obj_Val.Kind = Val_Array then
                     return (Kind => Val_Number, Number => Float (Obj_Val.Array_Length));
                  elsif Obj_Val.Kind = Val_String then
                     return (Kind => Val_Number, Number => Float (Obj_Val.Str_Length));
                  end if;
               elsif Obj_Val.Kind = Val_Object then
                  -- Object property access: obj.key
                  if Obj_Val.Object_Properties.Contains (Member) then
                     return Obj_Val.Object_Properties.Element (Member).all;
                  else
                     return (Kind => Val_Undefined);
                  end if;
               end if;
               return (Kind => Val_Undefined);
            end;

         when AST.Node_This_Expression =>
            -- Return the current 'this' context
            if Current_This /= null then
               return Current_This.all;
            else
               return (Kind => Val_Undefined);  -- No 'this' context
            end if;

         when AST.Node_New_Expression =>
            -- Create a new class instance
            declare
               Class_Name : constant String := Node.New_Class_Name (1 .. Node.New_Class_Name_Length);
               Class_Val : constant JS_Value := Get_Variable (Class_Name);
               Instance : JS_Value (Kind => Val_Object);
               Instance_Ptr : JS_Value_Ptr;
               Saved_This : constant JS_Value_Ptr := Current_This;
               Constructor_Found : Boolean := False;
            begin
               if Class_Val.Kind /= Val_Class then
                  raise Runtime_Error with Class_Name & " is not a class";
               end if;

               -- Create new object instance
               Instance.Object_Properties := new Object_Maps.Map;
               Instance.Is_Class_Instance := True;
               Instance.Class_Def := Class_Val.Class_Node;
               Instance_Ptr := new JS_Value'(Instance);

               -- Set 'this' to the new instance
               Current_This := Instance_Ptr;

               -- Set constructor class context
               Current_Constructor_Class := Class_Val.Class_Node;

               -- Find and call constructor
               if Class_Val.Class_Node.Method_Count > 0 then
                  for I in 1 .. Class_Val.Class_Node.Method_Count loop
                     declare
                        Method : constant AST.AST_Node_Ptr := Class_Val.Class_Node.Class_Methods (I);
                        Method_Name : constant String := Method.Func_Name (1 .. Method.Func_Name_Length);
                     begin
                        if Method_Name = "constructor" then
                           Constructor_Found := True;

                           -- Save current variables
                           declare
                              Saved_Variables : constant Variable_Maps.Map := Variables;
                           begin
                              -- Bind constructor parameters
                              if Node.Constructor_Arg_Count > 0 and Method.Param_Count > 0 then
                                 for J in 1 .. Integer'Min (Node.Constructor_Arg_Count, Method.Param_Count) loop
                                    declare
                                       Param_Name : constant String :=
                                          Method.Params (J).Id_Name (1 .. Method.Params (J).Id_Length);
                                       Arg_Val : constant JS_Value := Eval (Node.Constructor_Args (J));
                                    begin
                                       Set_Variable (Param_Name, Arg_Val);
                                    end;
                                 end loop;
                              end if;

                              -- Execute constructor body
                              begin
                                 Eval_Statement (Method.Func_Body);
                              exception
                                 when Return_Exception =>
                                    null;  -- Constructor can return early
                              end;

                              -- Restore variables (but keep 'this' changes in instance)
                              Variables := Saved_Variables;
                           end;

                           exit;
                        end if;
                     end;
                  end loop;
               end if;

               -- Restore previous 'this' and constructor class context
               Current_This := Saved_This;
               Current_Constructor_Class := null;

               return Instance_Ptr.all;
            end;

         when AST.Node_Super_Call =>
            -- Call parent class constructor
            -- This should only be called from within a constructor
            if Current_This = null then
               raise Runtime_Error with "super() can only be called in a constructor";
            end if;

            if Current_Constructor_Class = null then
               raise Runtime_Error with "super() called outside constructor context";
            end if;

            -- Use Current_Constructor_Class to find parent, not Current_This.Class_Def
            if Current_Constructor_Class.Parent_Class_Name_Length = 0 then
               raise Runtime_Error with "super() called but no parent class";
            end if;

            -- Look up parent class
            declare
               Parent_Name : constant String :=
                  Current_Constructor_Class.Parent_Class_Name (1 .. Current_Constructor_Class.Parent_Class_Name_Length);
               Parent_Class_Val : constant JS_Value := Get_Variable (Parent_Name);
               Saved_Constructor_Class : constant AST.AST_Node_Ptr := Current_Constructor_Class;
            begin
                  if Parent_Class_Val.Kind /= Val_Class then
                     raise Runtime_Error with Parent_Name & " is not a class";
                  end if;

                  -- Set constructor class to parent before calling parent constructor
                  Current_Constructor_Class := Parent_Class_Val.Class_Node;

                  -- Find and call parent constructor
                  if Parent_Class_Val.Class_Node.Method_Count > 0 then
                     for I in 1 .. Parent_Class_Val.Class_Node.Method_Count loop
                        declare
                           Method : constant AST.AST_Node_Ptr := Parent_Class_Val.Class_Node.Class_Methods (I);
                           Method_Name : constant String := Method.Func_Name (1 .. Method.Func_Name_Length);
                        begin
                           if Method_Name = "constructor" then
                              -- Save current variables
                              declare
                                 Saved_Variables : constant Variable_Maps.Map := Variables;
                              begin
                                 -- Bind constructor parameters
                                 if Node.Super_Arg_Count > 0 and Method.Param_Count > 0 then
                                    for J in 1 .. Integer'Min (Node.Super_Arg_Count, Method.Param_Count) loop
                                       declare
                                          Param_Name : constant String :=
                                             Method.Params (J).Id_Name (1 .. Method.Params (J).Id_Length);
                                          Arg_Val : constant JS_Value := Eval (Node.Super_Arguments (J));
                                       begin
                                          Set_Variable (Param_Name, Arg_Val);
                                       end;
                                    end loop;
                                 end if;

                                 -- Execute parent constructor body (with same 'this')
                                 begin
                                    Eval_Statement (Method.Func_Body);
                                 exception
                                    when Return_Exception =>
                                       null;  -- Constructor can return early
                                 end;

                                 -- Restore variables
                                 Variables := Saved_Variables;
                              end;

                              -- Restore constructor class context
                              Current_Constructor_Class := Saved_Constructor_Class;
                              return (Kind => Val_Undefined);
                           end if;
                        end;
                     end loop;
                  end if;

                  -- Restore constructor class even if no constructor found
                  Current_Constructor_Class := Saved_Constructor_Class;
               end;

            return (Kind => Val_Undefined);

         when AST.Node_Try_Statement =>
            -- Execute try block with exception handling
            declare
               Return_Caught : Boolean := False;
               Break_Caught : Boolean := False;
               Continue_Caught : Boolean := False;
            begin
               -- Execute try block
               begin
                  if Node.Try_Body /= null then
                     Eval_Statement (Node.Try_Body);
                  end if;
               exception
                  when JS_Exception =>
                     -- JavaScript exception was thrown
                     if Node.Catch_Body /= null then
                        -- Execute catch block with error binding
                        declare
                           Saved_Variables : constant Variable_Maps.Map := Variables;
                           Catch_Param : constant String :=
                              Node.Catch_Param (1 .. Node.Catch_Param_Length);
                        begin
                           -- Bind the caught value to the catch parameter
                           if Thrown_Value /= null then
                              Set_Variable (Catch_Param, Thrown_Value.all);
                           else
                              Set_Variable (Catch_Param, (Kind => Val_Undefined));
                           end if;

                           -- Execute catch block
                           Eval_Statement (Node.Catch_Body);

                           -- Restore variables (catch param goes out of scope)
                           Variables := Saved_Variables;
                        end;
                     end if;
                  when Return_Exception =>
                     Return_Caught := True;
                  when Break_Exception =>
                     Break_Caught := True;
                  when Continue_Exception =>
                     Continue_Caught := True;
               end;

               -- Always execute finally block (even after return/break/continue)
               if Node.Finally_Body /= null then
                  Eval_Statement (Node.Finally_Body);
               end if;

               -- Re-raise control flow exceptions after finally
               if Return_Caught then
                  raise Return_Exception;
               elsif Break_Caught then
                  raise Break_Exception;
               elsif Continue_Caught then
                  raise Continue_Exception;
               end if;

               return (Kind => Val_Undefined);
            end;

         when AST.Node_Throw_Statement =>
            -- Evaluate the expression to throw
            declare
               Throw_Val : constant JS_Value := Eval (Node.Throw_Expression);
            begin
               -- Store the thrown value
               Thrown_Value := new JS_Value'(Throw_Val);

               -- Raise the JavaScript exception
               raise JS_Exception;
            end;

         when others =>
            null;
      end case;

      return (Kind => Val_Undefined);
   end Eval;

   -- Convert a JavaScript value to its string representation
   function Value_To_String (Val : JS_Value) return String is
   begin
      case Val.Kind is
         when Val_Number =>
            -- Check if it's an integer
            if Val.Number = Float'Floor(Val.Number) and then
               abs(Val.Number) < 2.0E9 then
               -- It's an integer, display without decimals
               declare
                  Int_Val : constant Integer := Integer(Val.Number);
               begin
                  return Ada.Strings.Fixed.Trim (Integer'Image (Int_Val), Ada.Strings.Both);
               end;
            else
               -- It's a float - format with limited decimal places
               declare
                  Buffer : String (1 .. 50);
                  Abs_Val : constant Float := abs(Val.Number);
               begin
                  -- Use Float_IO to format with specific precision
                  if Abs_Val >= 0.0001 and then Abs_Val < 1_000_000.0 then
                     -- Normal range - use fixed point notation
                     Float_IO.Put (Buffer, Val.Number, Aft => 6, Exp => 0);
                     declare
                        Trimmed : constant String := Ada.Strings.Fixed.Trim (Buffer, Ada.Strings.Both);
                        -- Remove trailing zeros after decimal point
                        Last_Significant : Natural := Trimmed'Last;
                     begin
                        -- Find last non-zero digit after decimal
                        if Ada.Strings.Fixed.Index (Trimmed, ".") > 0 then
                           for I in reverse Trimmed'First .. Trimmed'Last loop
                              if Trimmed(I) /= '0' and then Trimmed(I) /= ' ' then
                                 Last_Significant := I;
                                 exit;
                              end if;
                           end loop;
                           -- Don't leave trailing decimal point
                           if Last_Significant > Trimmed'First and then
                              Trimmed(Last_Significant) = '.' then
                              Last_Significant := Last_Significant - 1;
                           end if;
                           return Trimmed(Trimmed'First .. Last_Significant);
                        else
                           return Trimmed;
                        end if;
                     end;
                  else
                     -- Very large or very small - use scientific notation
                     Float_IO.Put (Buffer, Val.Number, Aft => 2, Exp => 3);
                     return Ada.Strings.Fixed.Trim (Buffer, Ada.Strings.Both);
                  end if;
               end;
            end if;
         when Val_String =>
            return Val.Str (1 .. Val.Str_Length);
         when Val_Boolean =>
            if Val.Bool then
               return "true";
            else
               return "false";
            end if;
         when Val_Null =>
            return "null";
         when Val_Undefined =>
            return "undefined";
         when Val_Array =>
            -- Print array as comma-separated values like JavaScript
            declare
               Result : String (1 .. 1024);
               Pos : Natural := 0;
            begin
               Result (1) := '[';
               Pos := 1;
               for I in 1 .. Val.Array_Length loop
                  if I > 1 then
                     Pos := Pos + 1;
                     Result (Pos) := ',';
                     Pos := Pos + 1;
                     Result (Pos) := ' ';
                  end if;
                  declare
                     Elem_Str : constant String := Value_To_String (Val.Array_Elements (I).all);
                  begin
                     Result (Pos + 1 .. Pos + Elem_Str'Length) := Elem_Str;
                     Pos := Pos + Elem_Str'Length;
                  end;
               end loop;
               Pos := Pos + 1;
               Result (Pos) := ']';
               return Result (1 .. Pos);
            end;
         when Val_Object =>
            -- Print object as {key: value, ...}
            declare
               Result : String (1 .. 2048);
               Pos : Natural := 1;
               First : Boolean := True;
               use Object_Maps;
               Cursor : Object_Maps.Cursor := Val.Object_Properties.First;
            begin
               Result (1) := '{';
               while Has_Element (Cursor) loop
                  if not First then
                     Pos := Pos + 1;
                     Result (Pos) := ',';
                     Pos := Pos + 1;
                     Result (Pos) := ' ';
                  end if;
                  First := False;

                  declare
                     Prop_Key : constant String := Object_Maps.Key (Cursor);
                     Val_Str : constant String := Value_To_String (Element (Cursor).all);
                  begin
                     Result (Pos + 1 .. Pos + Prop_Key'Length) := Prop_Key;
                     Pos := Pos + Prop_Key'Length;
                     Pos := Pos + 1;
                     Result (Pos) := ':';
                     Pos := Pos + 1;
                     Result (Pos) := ' ';
                     Result (Pos + 1 .. Pos + Val_Str'Length) := Val_Str;
                     Pos := Pos + Val_Str'Length;
                  end;

                  Next (Cursor);
               end loop;
               Pos := Pos + 1;
               Result (Pos) := '}';
               return Result (1 .. Pos);
            end;
         when Val_Function =>
            return "[Function]";
         when Val_Class =>
            return "[Class]";
      end case;
   end Value_To_String;

end Evaluator;
