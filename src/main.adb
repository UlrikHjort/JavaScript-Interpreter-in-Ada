-- ***************************************************************************
--                JavaScript interpreter - main
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

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Interfaces.C; use Interfaces.C;
with Terminal;
with Parser;
with Evaluator;
with AST;

procedure Main is
   
   function isatty (FD : int) return int;
   pragma Import (C, isatty, "isatty");
   
   -- Check if stdin is a terminal (for REPL vs script mode detection)
   function Is_Interactive return Boolean is
   begin
      return isatty (0) /= 0;
   end Is_Interactive;
   
   -- Parse and execute JavaScript code in script mode (no expression printing)
   procedure Eval_And_Print (Source : String) is
      Tree : AST.AST_Node_Ptr;
   begin
      if Source'Length = 0 then
         return;
      end if;
      
      Parser.Init (Source);
      Tree := Parser.Parse;
      
      if Parser.Has_Error then
         Put_Line ("Error: " & Parser.Get_Error_Message);
      else
         Evaluator.Eval_Statement (Tree, False);  -- Script mode: don't print expressions
      end if;
   end Eval_And_Print;
   
   -- Parse and execute JavaScript code in REPL mode (with expression printing)
   procedure Eval_And_Print_REPL (Source : String) is
      Tree : AST.AST_Node_Ptr;
   begin
      if Source'Length = 0 then
         return;
      end if;
      
      Parser.Init (Source);
      Tree := Parser.Parse;
      
      if Parser.Has_Error then
         Put_Line ("Error: " & Parser.Get_Error_Message);
      else
         Evaluator.Eval_Statement (Tree, True);  -- REPL mode: print expressions
      end if;
   end Eval_And_Print_REPL;
   
   procedure Run_REPL is
      Input : Unbounded_String;
      Line : String (1 .. 1024);
      Last : Natural;
   begin
      Put_Line ("JavaScript Interpreter in Ada");
      Put_Line ("Version 1.0");
      Put_Line ("Type 'exit' or 'quit' to exit");
      Put_Line ("Use arrow keys for history");
      Put_Line ("----------------------------");
      New_Line;
      Flush;
      
      Terminal.Init_Terminal;
      
      loop
         Terminal.Read_Line_With_History ("js> ", Line, Last);
         
         if Last > 0 then
            Input := To_Unbounded_String (Line (1 .. Last));
            
            if To_String (Input) = "exit" or To_String (Input) = "quit" then
               Put_Line ("Goodbye!");
               exit;
            end if;
            
            Terminal.Add_To_History (Line (1 .. Last));
            Eval_And_Print_REPL (To_String (Input));
            Flush;
         end if;
      end loop;
      
      Terminal.Restore_Terminal;
   end Run_REPL;
   
   procedure Run_Script is
      Buffer : Unbounded_String;
      Line : String (1 .. 1024);
      Last : Natural;
   begin
      while not End_Of_File loop
         Get_Line (Line, Last);
         if Last > 0 then
            Append (Buffer, Line (1 .. Last));
         end if;
         -- Append newline to preserve line structure
         if not End_Of_File then
            Append (Buffer, "" & ASCII.LF);
         end if;
      end loop;
      
      if Length (Buffer) > 0 then
         Eval_And_Print (To_String (Buffer));
      end if;
   end Run_Script;
   
begin
   -- Initialize built-in objects (Math, console, etc.)
   Evaluator.Initialize_Builtins;
   
   if Ada.Command_Line.Argument_Count > 0 then
      Put_Line ("Usage: jsinterp");
      Put_Line ("  Interactive REPL mode, or pipe script:");
      Put_Line ("  jsinterp < script.js");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   elsif Is_Interactive then
      Run_REPL;
   else
      Run_Script;
   end if;
end Main;
