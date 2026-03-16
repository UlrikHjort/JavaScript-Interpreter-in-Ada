-- ***************************************************************************
--               JavaScript interpreter - terminal
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

package Terminal is

   Max_History : constant := 100;
   
   type History_Array is array (1 .. Max_History) of String (1 .. 1024);
   type History_Lengths is array (1 .. Max_History) of Natural;
   
   -- Initialize terminal for raw input mode
   procedure Init_Terminal;
   
   -- Restore terminal to normal mode
   procedure Restore_Terminal;
   
   -- Read a line with command history support (up/down arrows)
   procedure Read_Line_With_History (Prompt : String; Line : out String; Length : out Natural);
   
   -- Add a command line to history buffer
   procedure Add_To_History (Line : String);

end Terminal;
