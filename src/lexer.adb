-- ***************************************************************************
--               JavaScript interpreter - lexer
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

package body Lexer is

   Source_Code : String (1 .. 65536);
   Source_Length : Natural := 0;
   Current_Pos : Positive := 1;
   Line_Number : Positive := 1;
   Column_Number : Positive := 1;

   procedure Init (Source : String) is
   begin
      Source_Length := Source'Length;
      Source_Code (1 .. Source_Length) := Source;
      Current_Pos := 1;
      Line_Number := 1;
      Column_Number := 1;
   end Init;

   function Current_Line return Positive is
   begin
      return Line_Number;
   end Current_Line;

   function Current_Column return Positive is
   begin
      return Column_Number;
   end Current_Column;

   function At_End return Boolean is
   begin
      return Current_Pos > Source_Length;
   end At_End;

   function Peek return Character is
   begin
      if At_End then
         return ASCII.NUL;
      end if;
      return Source_Code (Current_Pos);
   end Peek;

   function Peek_Next return Character is
   begin
      if Current_Pos + 1 > Source_Length then
         return ASCII.NUL;
      end if;
      return Source_Code (Current_Pos + 1);
   end Peek_Next;

   procedure Advance is
   begin
      if not At_End then
         if Source_Code (Current_Pos) = ASCII.LF then
            Line_Number := Line_Number + 1;
            Column_Number := 1;
         else
            Column_Number := Column_Number + 1;
         end if;
         Current_Pos := Current_Pos + 1;
      end if;
   end Advance;

   procedure Skip_Whitespace is
      C : Character;
   begin
      loop
         C := Peek;
         exit when C /= ' ' and C /= ASCII.HT and C /= ASCII.CR and C /= ASCII.LF;
         Advance;
      end loop;
   end Skip_Whitespace;

   function Is_Digit (C : Character) return Boolean is
   begin
      return C >= '0' and C <= '9';
   end Is_Digit;

   function Is_Alpha (C : Character) return Boolean is
   begin
      return (C >= 'a' and C <= 'z') or (C >= 'A' and C <= 'Z') or C = '_' or C = '$';
   end Is_Alpha;

   function Is_Alphanumeric (C : Character) return Boolean is
   begin
      return Is_Alpha (C) or Is_Digit (C);
   end Is_Alphanumeric;

   function Make_Token (Kind : Token_Type; Lexeme : String; Line : Positive; Col : Positive) return Token is
      T : Token;
   begin
      T.Kind := Kind;
      T.Length := Lexeme'Length;
      T.Lexeme (1 .. T.Length) := Lexeme;
      T.Line := Line;
      T.Column := Col;
      return T;
   end Make_Token;

   function Scan_Number return Token is
      Start_Pos : constant Positive := Current_Pos;
      Start_Line : constant Positive := Line_Number;
      Start_Col : constant Positive := Column_Number;
   begin
      while Is_Digit (Peek) loop
         Advance;
      end loop;

      if Peek = '.' and Is_Digit (Peek_Next) then
         Advance;
         while Is_Digit (Peek) loop
            Advance;
         end loop;
      end if;

      return Make_Token (Token_Number, Source_Code (Start_Pos .. Current_Pos - 1), Start_Line, Start_Col);
   end Scan_Number;

   function Scan_Identifier return Token is
      Start_Pos : constant Positive := Current_Pos;
      Start_Line : constant Positive := Line_Number;
      Start_Col : constant Positive := Column_Number;
      Identifier : String (1 .. 256);
      Len : Natural := 0;
   begin
      while Is_Alphanumeric (Peek) loop
         Advance;
      end loop;

      Len := Current_Pos - Start_Pos;
      Identifier (1 .. Len) := Source_Code (Start_Pos .. Current_Pos - 1);

      if Identifier (1 .. Len) = "let" then
         return Make_Token (Token_Let, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "const" then
         return Make_Token (Token_Const, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "var" then
         return Make_Token (Token_Var, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "function" then
         return Make_Token (Token_Function, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "return" then
         return Make_Token (Token_Return, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "if" then
         return Make_Token (Token_If, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "else" then
         return Make_Token (Token_Else, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "for" then
         return Make_Token (Token_For, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "while" then
         return Make_Token (Token_While, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "do" then
         return Make_Token (Token_Do, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "switch" then
         return Make_Token (Token_Switch, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "case" then
         return Make_Token (Token_Case, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "default" then
         return Make_Token (Token_Default, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "break" then
         return Make_Token (Token_Break, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "continue" then
         return Make_Token (Token_Continue, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "typeof" then
         return Make_Token (Token_Typeof, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "class" then
         return Make_Token (Token_Class, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "new" then
         return Make_Token (Token_New, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "this" then
         return Make_Token (Token_This, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "extends" then
         return Make_Token (Token_Extends, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "super" then
         return Make_Token (Token_Super, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "try" then
         return Make_Token (Token_Try, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "catch" then
         return Make_Token (Token_Catch, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "finally" then
         return Make_Token (Token_Finally, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "throw" then
         return Make_Token (Token_Throw, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "true" then
         return Make_Token (Token_True, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "false" then
         return Make_Token (Token_False, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "null" then
         return Make_Token (Token_Null, Identifier (1 .. Len), Start_Line, Start_Col);
      elsif Identifier (1 .. Len) = "undefined" then
         return Make_Token (Token_Undefined, Identifier (1 .. Len), Start_Line, Start_Col);
      else
         return Make_Token (Token_Identifier, Identifier (1 .. Len), Start_Line, Start_Col);
      end if;
   end Scan_Identifier;

   function Scan_String (Quote : Character) return Token is
      Start_Line : constant Positive := Line_Number;
      Start_Col : constant Positive := Column_Number;
      Result : String (1 .. 256);
      Len : Natural := 0;
   begin
      Advance;

      while not At_End and then Peek /= Quote loop
         if Peek = '\' then
            Advance;
            if not At_End then
               Advance;
            end if;
         else
            Len := Len + 1;
            Result (Len) := Peek;
            Advance;
         end if;
      end loop;

      if At_End then
         return Make_Token (Token_Error, "Unterminated string", Start_Line, Start_Col);
      end if;

      Advance;
      return Make_Token (Token_String, Result (1 .. Len), Start_Line, Start_Col);
   end Scan_String;

   -- Get the next token from the source code
   function Next_Token return Token is
      C : Character;
      Start_Line : Positive;
      Start_Col : Positive;
   begin
      Skip_Whitespace;

      if At_End then
         return Make_Token (Token_EOF, "", Line_Number, Column_Number);
      end if;

      Start_Line := Line_Number;
      Start_Col := Column_Number;
      C := Peek;

      if Is_Digit (C) then
         return Scan_Number;
      end if;

      if Is_Alpha (C) then
         return Scan_Identifier;
      end if;

      Advance;

      case C is
         when '(' => return Make_Token (Token_Left_Paren, "(", Start_Line, Start_Col);
         when ')' => return Make_Token (Token_Right_Paren, ")", Start_Line, Start_Col);
         when '{' => return Make_Token (Token_Left_Brace, "{", Start_Line, Start_Col);
         when '}' => return Make_Token (Token_Right_Brace, "}", Start_Line, Start_Col);
         when '[' => return Make_Token (Token_Left_Bracket, "[", Start_Line, Start_Col);
         when ']' => return Make_Token (Token_Right_Bracket, "]", Start_Line, Start_Col);
         when ';' => return Make_Token (Token_Semicolon, ";", Start_Line, Start_Col);
         when ',' => return Make_Token (Token_Comma, ",", Start_Line, Start_Col);
         when '.' => return Make_Token (Token_Dot, ".", Start_Line, Start_Col);
         when '?' => return Make_Token (Token_Question, "?", Start_Line, Start_Col);
         when ':' => return Make_Token (Token_Colon, ":", Start_Line, Start_Col);
         when '+' =>
            if Peek = '+' then
               Advance;
               return Make_Token (Token_Plus_Plus, "++", Start_Line, Start_Col);
            else
               return Make_Token (Token_Plus, "+", Start_Line, Start_Col);
            end if;
         when '-' =>
            if Peek = '-' then
               Advance;
               return Make_Token (Token_Minus_Minus, "--", Start_Line, Start_Col);
            else
               return Make_Token (Token_Minus, "-", Start_Line, Start_Col);
            end if;
         when '*' => return Make_Token (Token_Star, "*", Start_Line, Start_Col);
         when '/' =>
            -- Check for comment (we've already advanced past first /)
            if Peek = '/' then
               Advance;  -- past second /
               -- Skip rest of line
               while not At_End and then Peek /= ASCII.LF loop
                  Advance;
               end loop;
               -- Recursively get next real token
               return Next_Token;
            else
               return Make_Token (Token_Slash, "/", Start_Line, Start_Col);
            end if;
         when '%' => return Make_Token (Token_Percent, "%", Start_Line, Start_Col);
         when '<' =>
            if Peek = '=' then
               Advance;
               return Make_Token (Token_Less_Equal, "<=", Start_Line, Start_Col);
            else
               return Make_Token (Token_Less, "<", Start_Line, Start_Col);
            end if;
         when '>' =>
            if Peek = '=' then
               Advance;
               return Make_Token (Token_Greater_Equal, ">=", Start_Line, Start_Col);
            else
               return Make_Token (Token_Greater, ">", Start_Line, Start_Col);
            end if;
         when '=' =>
            if Peek = '=' then
               Advance;
               if Peek = '=' then
                  Advance;
                  return Make_Token (Token_Equal_Equal_Equal, "===", Start_Line, Start_Col);
               else
                  return Make_Token (Token_Equal_Equal, "==", Start_Line, Start_Col);
               end if;
            elsif Peek = '>' then
               Advance;
               return Make_Token (Token_Arrow, "=>", Start_Line, Start_Col);
            else
               return Make_Token (Token_Equal, "=", Start_Line, Start_Col);
            end if;
         when '!' =>
            if Peek = '=' then
               Advance;
               if Peek = '=' then
                  Advance;
                  return Make_Token (Token_Bang_Equal_Equal, "!==", Start_Line, Start_Col);
               else
                  return Make_Token (Token_Bang_Equal, "!=", Start_Line, Start_Col);
               end if;
            else
               return Make_Token (Token_Bang, "!", Start_Line, Start_Col);
            end if;
         when '&' =>
            if Peek = '&' then
               Advance;
               return Make_Token (Token_And_And, "&&", Start_Line, Start_Col);
            end if;
         when '|' =>
            if Peek = '|' then
               Advance;
               return Make_Token (Token_Or_Or, "||", Start_Line, Start_Col);
            end if;
         when '"' | ''' =>
            Current_Pos := Current_Pos - 1;
            return Scan_String (C);
         when others =>
            null;
      end case;

      return Make_Token (Token_Error, "Unexpected character", Start_Line, Start_Col);
   end Next_Token;

end Lexer;
