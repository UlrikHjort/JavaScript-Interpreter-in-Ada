-- ***************************************************************************
--              JavaScript interpreter - terminal
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

package body Terminal is

   History : History_Array;
   History_Len : History_Lengths := [others => 0];
   History_Count : Natural := 0;
   
   -- Initialize terminal for raw input mode (currently a no-op)
   procedure Init_Terminal is
   begin
      null;
   end Init_Terminal;
   
   -- Restore terminal to normal mode (currently a no-op)
   procedure Restore_Terminal is
   begin
      null;
   end Restore_Terminal;
   
   -- Add a command line to the history buffer
   procedure Add_To_History (Line : String) is
   begin
      if Line'Length = 0 then
         return;
      end if;
      
      if History_Count < Max_History then
         History_Count := History_Count + 1;
      else
         for I in 1 .. Max_History - 1 loop
            History (I) := History (I + 1);
            History_Len (I) := History_Len (I + 1);
         end loop;
      end if;
      
      History_Len (History_Count) := Line'Length;
      History (History_Count) (1 .. Line'Length) := Line;
   end Add_To_History;
   
   -- Read a line with command history support using arrow keys
   procedure Read_Line_With_History (Prompt : String; Line : out String; Length : out Natural) is
      C : Character;
      Pos : Natural := 0;
      Cursor_Pos : Natural := 0;
      History_Pos : Natural := History_Count + 1;
      Temp_Buffer : String (1 .. 1024) := [others => ' '];
      
      procedure Redraw_Line is
      begin
         Put (ASCII.CR);
         Put (Prompt);
         Put (Temp_Buffer (1 .. Pos));
         Put (String'(1 .. Pos - Cursor_Pos => ' '));
         for I in 1 .. Pos - Cursor_Pos loop
            Put (ASCII.BS);
         end loop;
         Flush;
      end Redraw_Line;
      
      procedure Clear_Line is
      begin
         Put (ASCII.CR);
         Put (String'(1 .. Prompt'Length + Pos => ' '));
         Put (ASCII.CR);
         Put (Prompt);
         Flush;
      end Clear_Line;
      
   begin
      Put (Prompt);
      Flush;
      
      loop
         Get_Immediate (C);
         
         if C = ASCII.CR or C = ASCII.LF then
            New_Line;
            Length := Pos;
            Line (Line'First .. Line'First + Pos - 1) := Temp_Buffer (1 .. Pos);
            exit;
         elsif C = ASCII.BS or C = ASCII.DEL then
            if Cursor_Pos > 0 then
               for I in Cursor_Pos .. Pos - 1 loop
                  Temp_Buffer (I) := Temp_Buffer (I + 1);
               end loop;
               Pos := Pos - 1;
               Cursor_Pos := Cursor_Pos - 1;
               Redraw_Line;
            end if;
         elsif C = ASCII.ESC then
            declare
               C2, C3 : Character;
            begin
               Get_Immediate (C2);
               if C2 = '[' then
                  Get_Immediate (C3);
                  
                  if C3 = 'A' then
                     if History_Pos > 1 then
                        History_Pos := History_Pos - 1;
                        Clear_Line;
                        Pos := History_Len (History_Pos);
                        Temp_Buffer (1 .. Pos) := History (History_Pos) (1 .. Pos);
                        Cursor_Pos := Pos;
                        Put (Temp_Buffer (1 .. Pos));
                        Flush;
                     end if;
                  elsif C3 = 'B' then
                     if History_Pos <= History_Count then
                        History_Pos := History_Pos + 1;
                        Clear_Line;
                        if History_Pos <= History_Count then
                           Pos := History_Len (History_Pos);
                           Temp_Buffer (1 .. Pos) := History (History_Pos) (1 .. Pos);
                           Cursor_Pos := Pos;
                           Put (Temp_Buffer (1 .. Pos));
                        else
                           Pos := 0;
                           Cursor_Pos := 0;
                        end if;
                        Flush;
                     end if;
                  elsif C3 = 'C' then
                     if Cursor_Pos < Pos then
                        Cursor_Pos := Cursor_Pos + 1;
                        Put (ASCII.ESC & "[C");
                        Flush;
                     end if;
                  elsif C3 = 'D' then
                     if Cursor_Pos > 0 then
                        Cursor_Pos := Cursor_Pos - 1;
                        Put (ASCII.BS);
                        Flush;
                     end if;
                  elsif C3 = '3' then
                     Get_Immediate (C3);
                     if C3 = '~' then
                        if Cursor_Pos < Pos then
                           for I in Cursor_Pos + 1 .. Pos - 1 loop
                              Temp_Buffer (I) := Temp_Buffer (I + 1);
                           end loop;
                           Pos := Pos - 1;
                           Redraw_Line;
                        end if;
                     end if;
                  elsif C3 = 'H' then
                     while Cursor_Pos > 0 loop
                        Cursor_Pos := Cursor_Pos - 1;
                        Put (ASCII.BS);
                     end loop;
                     Flush;
                  elsif C3 = 'F' then
                     while Cursor_Pos < Pos loop
                        Put (Temp_Buffer (Cursor_Pos + 1));
                        Cursor_Pos := Cursor_Pos + 1;
                     end loop;
                     Flush;
                  end if;
               end if;
            end;
         elsif C >= ' ' and C <= '~' then
            if Pos < Temp_Buffer'Last then
               if Cursor_Pos < Pos then
                  for I in reverse Cursor_Pos + 1 .. Pos loop
                     Temp_Buffer (I + 1) := Temp_Buffer (I);
                  end loop;
                  Pos := Pos + 1;
                  Cursor_Pos := Cursor_Pos + 1;
                  Temp_Buffer (Cursor_Pos) := C;
                  Redraw_Line;
               else
                  Pos := Pos + 1;
                  Cursor_Pos := Cursor_Pos + 1;
                  Temp_Buffer (Cursor_Pos) := C;
                  Put (C);
                  Flush;
               end if;
            end if;
         end if;
      end loop;
   end Read_Line_With_History;

end Terminal;
