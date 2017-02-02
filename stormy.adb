----------------------------------------------------------------------------
--                                                                        --
--  Stormy                                                                --
--                                                                        --
--  Lightning Protocol Decoder                                            --
--                                                                        --
--  Copyright (C) 2017, John Leimon                                       --
--                                                                        --
-- Permission to use, copy, modify, and/or distribute                     --
-- this software for any purpose with or without fee                      --
-- is hereby granted, provided that the above copyright                   --
-- notice and this permission notice appear in all copies.                --
--                                                                        --
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR                        --
-- DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE                  --
-- INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY                    --
-- AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE                    --
-- FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL                    --
-- DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS                  --
-- OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF                       --
-- CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING                 --
-- OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF                 --
-- THIS SOFTWARE.                                                         --
--                                                                        --
----------------------------------------------------------------------------
with Ada.Text_IO;       use Ada.Text_IO;
with Ada.Float_Text_IO;
with Ada.Command_Line;  use Ada.Command_Line;

procedure Stormy is
  file : Ada.Text_IO.File_Type;

  Byte_Length : constant := 8;

  type Byte_Array is array ( 1 .. 8 ) of Boolean;
  pragma pack(Byte_Array);
  for Byte_Array'size use Byte_Length;

  type Byte is mod 2**8;
  for Byte'size use Byte_Length;

  type Time is delta 0.000000000001 range 0.0 .. 2_000_000.0;
  type SymbolType is (NewSequence, ByteSymbol, NoSymbol);

  type Symbol is record
    t     : SymbolType;
    value : Byte;    
  end record;

  package X_IO is new Ada.Text_IO.Fixed_IO(Time);
  package M_IO is new Ada.Text_IO.Modular_IO(Byte);

  new_symbol        : Symbol;
  this              : Time;
  last              : Time;
  first_line        : Boolean := True;

  reset_state       : Boolean := False;
  first_chip        : Boolean;
  bit_index         : Integer;
  byte_buffer_bits  : Byte_Array;
  byte_buffer       : Byte;
  for byte_buffer'address use byte_buffer_bits'address;

  input_filename    : String ( 1 .. 256 ) := (others => Character'Val(0));
  verbose           : Boolean := False;

  ------------------------------------------------------

  function parse_arguments return boolean is
  begin
    if argument_count < 1 then
      put_line("Usage: decode [-v] <filename>");
      return false;
    end if;

    if argument_count = 1 then
      input_filename(argument(1)'First..argument(1)'Last) := argument(1);
    end if;
    
    if argument_count = 2 then
      if argument(1)(argument(1)'First..argument(1)'First + 1) = "-v" then
        verbose := true;
        input_filename(argument(2)'First..argument(2)'Last) := argument(2);
      else
        put_line("Error: Unknown argument '" & argument(1) & "'");
        return false;
      end if;
    end if;
    
    return true;
  end parse_arguments;

  ------------------------------------------------------
  
  function to_hex_string ( b : Byte ) return String is
    hex    : String (1 .. 6);
    output : String (1 .. 2);
    start  : Integer;
    length : Integer;
  begin
    M_IO.put(hex, b, 16);
    for i in 1 .. 6 loop
      if hex(i) = '#' then
        start := i + 1;
        exit;
      end if;
    end loop;
    output := "00";
    length := 6 - start;
    output(3 - length .. 2) := hex(6 - length .. 5);
    return output;
  end to_hex_string;
  
  ------------------------------------------------------

  function get_timestamp ( line : String ) return Time is
  begin
    if line(line'first) = '#' then
      return Time(0);
    end if;
   
    for i in line'first .. line'Last loop
      if line(i) = ',' then
        return Time'value(line(line'first..i-1));
      end if;
    end loop;
    
    return Time(0);
  end get_timestamp;

  ------------------------------------------------------

  function get_state ( line : String ) return Integer is
    str : String (1..1);
  begin
    if line(line'first) = '#' then
      return 0;
    end if;
    
    str(1) := line(line'Last - 1);
    return Integer'Value(str);

  end get_state;

  ------------------------------------------------------

  function event_decode ( state : Integer ) return Symbol is
    return_symbol : Symbol;
  begin

        if this - last < 0.000_010 then
           if first_chip = true then
              -- First chip --
              if state = 1 then
                 if this - last > 0.000_005 then
                    -- bit is ZERO --
                    byte_buffer_bits(bit_index) := False;
                    if verbose = true then
                      put(" ... 0");
                    end if;
                 else
                    -- bit is ONE --
                    byte_buffer_bits(bit_index) := True;
                    if verbose = true then
                      put(" ... 1");
                    end if;
                 end if;
   
                 -- Byte complete --
                 if bit_index = 8 then
                    return_symbol.t     := ByteSymbol;
                    return_symbol.value := byte_buffer;
                    return return_symbol;
                 end if;
   
                 reset_state := false;
                 bit_index   := bit_index + 1;
                 first_chip  := true;
              end if;
           else
              first_chip := false;
           end if;
        elsif this - last > 0.000_010 and state = 0 then
           first_chip      := true;
           bit_index       := 1;
           if reset_state = true then
             -- Reset is true (send a New Sequence symbol) --
             return_symbol.t := NewSequence;
             first_chip      := true;
             bit_index       := 1;
             reset_state     := false;
             return return_symbol;
           end if;
           reset_state := true;
        else
           first_chip := true;
           bit_index  := 1;
        end if;
   
     return_symbol.t := NoSymbol;
     return return_symbol;

  end event_decode;

begin

  if parse_arguments = false then
    -- Error parsing arguments --
    return;
  end if;

  open(file, In_File, input_filename);

  last := Time(0);
  this := Time(0);

  while not End_Of_File(file) loop
    declare
      line : String := Get_Line(file);
    begin
     
      -- Each iteration of this loop reads one line of the input file --

      if first_line then
        -- First line is skipped because we're only processing time deltas --
        first_line := false;
      else
        this := get_timestamp(line);
       
        if verbose = true then
          put("+delta: "); 
          X_IO.put((this - last) * 1_000_000);
          put(" us");
          put(Integer'Image(get_state(line)));
        end if;

        new_symbol := event_decode(get_state(line));
        
        if new_symbol.t = NewSequence then
          if verbose = true then
            put(" [NewSequence]");
          else
            new_line;
          end if;
        end if;
        
        if new_symbol.t = ByteSymbol then
          if verbose = true then
            put(" [Byte: " & to_hex_string(new_symbol.value) & "]");
          else
            put(to_hex_string(new_symbol.value) & " ");
          end if;
        end if;
       
        if verbose = true then
          new_line;
        end if;
        
        last := this;
      end if;
    end;
  end loop;

  close(file);

end Stormy;
