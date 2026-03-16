-- ***************************************************************************
--                JavaScript interpreter - lexer
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

package Lexer is

   type Token_Type is (
      -- Literals
      Token_Number,
      Token_String,
      Token_Identifier,
      Token_True,
      Token_False,
      Token_Null,
      Token_Undefined,
      
      -- Keywords
      Token_Let,
      Token_Const,
      Token_Var,
      Token_Function,
      Token_Return,
      Token_If,
      Token_Else,
      Token_For,
      Token_While,
      Token_Do,
      Token_Break,
      Token_Continue,
      Token_Switch,
      Token_Case,
      Token_Default,
      Token_Typeof,
      Token_Class,
      Token_New,
      Token_This,
      Token_Extends,
      Token_Super,
      Token_Try,
      Token_Catch,
      Token_Finally,
      Token_Throw,
      
      -- Operators
      Token_Plus,
      Token_Minus,
      Token_Star,
      Token_Slash,
      Token_Percent,
      Token_Equal,
      Token_Equal_Equal,
      Token_Equal_Equal_Equal,
      Token_Bang,
      Token_Bang_Equal,
      Token_Bang_Equal_Equal,
      Token_Less,
      Token_Less_Equal,
      Token_Greater,
      Token_Greater_Equal,
      Token_And_And,
      Token_Or_Or,
      Token_Plus_Plus,
      Token_Minus_Minus,
      Token_Arrow,
      
      -- Delimiters
      Token_Left_Paren,
      Token_Right_Paren,
      Token_Left_Brace,
      Token_Right_Brace,
      Token_Left_Bracket,
      Token_Right_Bracket,
      Token_Semicolon,
      Token_Comma,
      Token_Dot,
      Token_Question,
      Token_Colon,
      
      -- Special
      Token_EOF,
      Token_Error
   );

   type Token is record
      Kind : Token_Type;
      Lexeme : String (1 .. 256);
      Length : Natural := 0;
      Line : Positive := 1;
      Column : Positive := 1;
   end record;

   -- Initialize lexer with JavaScript source code
   procedure Init (Source : String);
   
   -- Get next token from source
   function Next_Token return Token;
   
   -- Get current line number in source
   function Current_Line return Positive;
   
   -- Get current column number in source
   function Current_Column return Positive;

end Lexer;
