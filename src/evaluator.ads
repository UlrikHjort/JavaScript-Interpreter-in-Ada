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

with AST;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Strings.Hash;

package Evaluator is

   type Value_Type is (Val_Number, Val_String, Val_Boolean, Val_Null, Val_Undefined, Val_Array, Val_Object, Val_Function, Val_Class);
   
   type JS_Value;
   type JS_Value_Ptr is access JS_Value;
   
   type Value_Array is array (Positive range <>) of JS_Value_Ptr;
   type Value_Array_Ptr is access Value_Array;
   
   -- Object property map
   package Object_Maps is new Ada.Containers.Indefinite_Hashed_Maps
     (Key_Type => String,
      Element_Type => JS_Value_Ptr,
      Hash => Ada.Strings.Hash,
      Equivalent_Keys => "=");
   
   type Object_Map_Ptr is access Object_Maps.Map;

   type JS_Value (Kind : Value_Type := Val_Undefined) is record
      case Kind is
         when Val_Number =>
            Number : Float;
         when Val_String =>
            Str : String (1 .. 2048);
            Str_Length : Natural;
         when Val_Boolean =>
            Bool : Boolean;
         when Val_Array =>
            Array_Elements : Value_Array_Ptr;
            Array_Length : Natural;
         when Val_Object =>
            Object_Properties : Object_Map_Ptr;
            Is_Class_Instance : Boolean := False;
            Class_Def : AST.AST_Node_Ptr := null;  -- Points to class declaration
         when Val_Function =>
            Func_Node : AST.AST_Node_Ptr;  -- The function declaration AST node
            Closure_Env : Object_Map_Ptr;  -- Captured variables from enclosing scope
         when Val_Class =>
            Class_Node : AST.AST_Node_Ptr;  -- The class declaration AST node
         when others =>
            null;
      end case;
   end record;

   -- Evaluate an expression node and return its JavaScript value
   function Eval (Node : AST.AST_Node_Ptr) return JS_Value;
   
   -- Execute a statement node (no return value)
   procedure Eval_Statement (Node : AST.AST_Node_Ptr);
   
   -- Execute a statement node with optional expression printing for REPL mode
   procedure Eval_Statement (Node : AST.AST_Node_Ptr; Print_Expr : Boolean);
   
   -- Convert a JavaScript value to its string representation
   function Value_To_String (Val : JS_Value) return String;
   
   -- Convert a JavaScript value to boolean (for conditionals)
   function Value_To_Boolean (Val : JS_Value) return Boolean;
   
   -- Store a variable in the global scope
   procedure Set_Variable (Name : String; Val : JS_Value);
   
   -- Retrieve a variable from the global scope
   function Get_Variable (Name : String) return JS_Value;
   
   -- Clear all variables (used for REPL reset)
   procedure Clear_Variables;
   
   -- Initialize built-in objects and functions (Math, console, etc.)
   procedure Initialize_Builtins;
   
   -- JavaScript exception for throw statements
   JS_Exception : exception;
   
   -- Storage for thrown JavaScript values
   Thrown_Value : JS_Value_Ptr := null;

end Evaluator;
