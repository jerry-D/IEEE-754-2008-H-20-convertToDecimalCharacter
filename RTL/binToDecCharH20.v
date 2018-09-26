// binToDecCharH20.v
 `timescale 1ns/100ps
 // Author:  Jerry D. Harthcock
 // Version:  1.00  Sept. 14, 2018
 // Copyright (C) 2018.  All rights reserved.
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                Open-Source                                                       //
//                                        SYMPL 64-Bit OpCodeless CPU                                               //
//                                Evaluation and Product Development License                                        //
//                                                                                                                  //
//                                                                                                                  //
// Open-source means that this source code may be freely downloaded, copied, modified, distributed and used in      //
// accordance with the terms and conditons of the licenses provided herein.                                         //
//                                                                                                                  //
// Provided that you comply with all the terms and conditions set forth herein, Jerry D. Harthcock ("licensor"),    //
// the original author and exclusive copyright owner of this SYMPL 64-Bit OpCodeless CPU and related development    //
// software ("this IP") hereby grants recipient of this IP ("licensee"), a world-wide, paid-up, non-exclusive       //
// license to implement this IP within the programmable fabric of Xilinx, Intel, MicroSemi or Lattice               //
// Semiconductor brand FPGAs only and used only for the purposes of evaluation, education, and development of end   //
// products and related development tools.  Furthermore, limited to the purposes of prototyping, evaluation,        //
// characterization and testing of implementations in a hard, custom or semi-custom ASIC, any university or         //
// institution of higher education may have their implementation of this IP produced for said limited purposes at   //
// any foundary of their choosing provided that such prototypes do not ever wind up in commercial circulation,      //
// with such license extending to said foundary and is in connection with said academic pursuit and under the       //
// supervision of said university or institution of higher education.                                               //            
//                                                                                                                  //
// Any copying, distribution, customization, modification, or derivative work of this IP must include an exact copy //
// of this license and original copyright notice at the very top of each source file and any derived netlist, and,  //
// in the case of binaries, a printed copy of this license and/or a text format copy in a separate file distributed //
// with said netlists or binary files having the file name, "LICENSE.txt".  You, the licensee, also agree not to    //
// remove any copyright notices from any source file covered or distributed under this Evaluation and Product       //
// Development License.                                                                                             //
//                                                                                                                  //
// LICENSOR DOES NOT WARRANT OR GUARANTEE THAT YOUR USE OF THIS IP WILL NOT INFRINGE THE RIGHTS OF OTHERS OR        //
// THAT IT IS SUITABLE OR FIT FOR ANY PURPOSE AND THAT YOU, THE LICENSEE, AGREE TO HOLD LICENSOR HARMLESS FROM      //
// ANY CLAIM BROUGHT BY YOU OR ANY THIRD PARTY FOR YOUR SUCH USE.                                                   //
//                                                                                                                  //
//                                               N O T I C E                                                        //
//                                                                                                                  //
// Certain implementations of this IP involving certain floating-point operators may comprise IP owned by certain   //
// contributors and developers at FloPoCo.  FloPoCo's licensing terms can be found at this website:                 //
//                                                                                                                  //
//    http://flopoco.gforge.inria.fr                                                                                //
//                                                                                                                  //
// Licensor reserves all his rights, including, but in no way limited to, the right to change or modify the terms   //
// and conditions of this Evaluation and Product Development License anytime without notice of any kind to anyone.  //
// By using this IP for any purpose, you agree to all the terms and conditions set forth in this Evaluation and     //
// Product Development License.                                                                                     //
//                                                                                                                  //
// This Evaluation and Product Development License does not include the right to sell products that incorporate     //
// this IP or any IP derived from this IP. If you would like to obtain such a license, please contact Licensor.     //           
//                                                                                                                  //
// Licensor can be contacted at:  SYMPL.gpu@gmail.com                                                               //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module binToDecCharH20(
    RESET ,
    CLK   ,
    wren,
    Away,
    round_mode,
    wrdata,
    ascOut
    );   

input RESET;
input CLK;
input wren;
input Away;
input [1:0] round_mode;
input [63:0] wrdata;
output [273:0] ascOut; 

// exception codes for two MSBs of result
parameter _no_excpt_   = 2'b00;  
parameter _underFlowExact_ = 2'b01;
parameter _underFlowInexact_  = 2'b10;  
parameter _inexact_    = 2'b11;                     

parameter char_0 = 8'h30;
parameter char_Plus = 8'h2B;
parameter char_Minus = 8'h2D;
parameter char_e = 8'h65;
parameter inf_string = 24'h696E66;
parameter nan_string = 24'h6E616E;
parameter snan_string = 32'h736E616E;

reg [63:0] wrdata_del_1,
           wrdata_del_2,
           wrdata_del_3,
           wrdata_del_4,
           wrdata_del_5,
           wrdata_del_6,
           wrdata_del_7,
           wrdata_del_8,
           wrdata_del_9,
           wrdata_del_10,
           wrdata_del_11,
           wrdata_del_12,
           wrdata_del_13,
           wrdata_del_14,
           wrdata_del_15,
           wrdata_del_16,
           wrdata_del_17;       

reg inexact_q1,
    inexact_q2,
    inexact_q3,
    inexact_q4,
    inexact_q5,
    inexact_q6,
    inexact_q7,
    inexact_q8;

reg [8:0] resultExponent;
reg [7:0] resultSign;
reg [7:0] expSign;
reg [273:0] ascOut;

reg [4:0] intTrailZeros;                          
                          
reg [223:0] integerFractFinal; //28 bytes  (max 8 int digits plus max 20 fract digits
reg [4:0] fractTrailZeros;                          

wire [39:0] expString;

wire [3:0] intDigit20;
wire [3:0] intDigit19;
wire [3:0] intDigit18;
wire [3:0] intDigit17;
wire [3:0] intDigit16;
wire [3:0] intDigit15;
wire [3:0] intDigit14;
wire [3:0] intDigit13;
wire [3:0] intDigit12;
wire [3:0] intDigit11;
wire [3:0] intDigit10;
wire [3:0] intDigit9 ;
wire [3:0] intDigit8 ;
wire [3:0] intDigit7 ;
wire [3:0] intDigit6 ;
wire [3:0] intDigit5 ;
wire [3:0] intDigit4 ;
wire [3:0] intDigit3 ;
wire [3:0] intDigit2 ;
wire [3:0] intDigit1 ;
wire [3:0] intDigit0 ;

wire [3:0] fractDigit19;
wire [3:0] fractDigit18;
wire [3:0] fractDigit17;
wire [3:0] fractDigit16;
wire [3:0] fractDigit15;
wire [3:0] fractDigit14;
wire [3:0] fractDigit13;
wire [3:0] fractDigit12;
wire [3:0] fractDigit11;
wire [3:0] fractDigit10;
wire [3:0] fractDigit9 ;
wire [3:0] fractDigit8 ;
wire [3:0] fractDigit7 ;
wire [3:0] fractDigit6 ;
wire [3:0] fractDigit5 ;
wire [3:0] fractDigit4 ;
wire [3:0] fractDigit3 ;
wire [3:0] fractDigit2 ;
wire [3:0] fractDigit1 ;
wire [3:0] fractDigit0 ;

wire [20:0] intTrailZeroSel;

wire [127:0] payloadStr;                          
wire [327:0] integerFractWork;   

wire [3:0] finalSel;
wire [3:0] expDigit2;
wire [3:0] expDigit1;
wire [3:0] expDigit0;
wire [67:0] bcdFractOut; 
wire fractInexact; 
wire inexact;

wire [67:0] bcdIntOut; 
wire intInexact; 

wire [19:0] fracTrailZeroSel;

wire input_is_infinite_del;
wire input_is_underflow_del;
wire input_is_nan_del;
wire input_is_snan_del;
wire input_is_qnan_del;

assign input_is_infinite_del = &wrdata_del_16[62:52] && ~|wrdata_del_16[51:0];
assign input_is_underflow_del = ~|wrdata_del_16[62:52] && |wrdata_del_16[51:0];
assign input_is_nan_del = &wrdata_del_16[62:52] && |wrdata_del_16[50:0];
assign input_is_snan_del = input_is_nan_del && ~wrdata_del_16[51];
assign input_is_qnan_del = input_is_nan_del && wrdata_del_16[51];


assign intTrailZeroSel = {|intDigit0,
                          |intDigit1,
                          |intDigit2,
                          |intDigit3,
                          |intDigit4,
                          |intDigit5,
                          |intDigit6,
                          |intDigit7,
                          |intDigit8, 
                          |intDigit9, 
                          |intDigit10,
                          |intDigit11,
                          |intDigit12,
                          |intDigit13,
                          |intDigit14,
                          |intDigit15,
                          |intDigit16,
                          |intDigit17,
                          |intDigit18,
                          |intDigit19,
                          |intDigit20  
                         };
    
assign fracTrailZeroSel = {|fractDigit0, 
                           |fractDigit1,
                           |fractDigit2,
                           |fractDigit3,
                           |fractDigit4,
                           |fractDigit5,
                           |fractDigit6,
                           |fractDigit7,
                           |fractDigit8, 
                           |fractDigit9, 
                           |fractDigit10,
                           |fractDigit11,
                           |fractDigit12,
                           |fractDigit13,
                           |fractDigit14,
                           |fractDigit15,
                           |fractDigit16,
                           |fractDigit17,
                           |fractDigit18,
                           |fractDigit19};
                                            
assign inexact = fractInexact || intInexact;                  
assign finalSel = {input_is_infinite_del,
                   input_is_qnan_del,
                   input_is_snan_del,
                   input_is_underflow_del
                  };
                   
assign expString = {char_e, expSign, {4'b0, expDigit2} | char_0, {4'b0, expDigit1} | char_0, {4'b0, expDigit0} | char_0};

wire fractAllZeros;

assign fractAllZeros = ~|{fractDigit19,
                          fractDigit18,
                          fractDigit17,
                          fractDigit16,
                          fractDigit15,
                          fractDigit14,
                          fractDigit13,
                          fractDigit12,
                          fractDigit11,
                          fractDigit10,
                          fractDigit9, 
                          fractDigit8, 
                          fractDigit7, 
                          fractDigit6, 
                          fractDigit5, 
                          fractDigit4, 
                          fractDigit3, 
                          fractDigit2, 
                          fractDigit1, 
                          fractDigit0}; 

wire [167:0] integerPart;
assign integerPart = {{4'b0000, intDigit20} | char_0,
                      {4'b0000, intDigit19} | char_0,
                      {4'b0000, intDigit18} | char_0,
                      {4'b0000, intDigit17} | char_0,
                      {4'b0000, intDigit16} | char_0,
                      {4'b0000, intDigit15} | char_0,
                      {4'b0000, intDigit14} | char_0,
                      {4'b0000, intDigit13} | char_0,
                      {4'b0000, intDigit12} | char_0,
                      {4'b0000, intDigit11} | char_0,
                      {4'b0000, intDigit10} | char_0,
                      {4'b0000, intDigit9}  | char_0,
                      {4'b0000, intDigit8}  | char_0,
                      {4'b0000, intDigit7}  | char_0,
                      {4'b0000, intDigit6}  | char_0,
                      {4'b0000, intDigit5}  | char_0,
                      {4'b0000, intDigit4}  | char_0,
                      {4'b0000, intDigit3}  | char_0,
                      {4'b0000, intDigit2}  | char_0,
                      {4'b0000, intDigit1}  | char_0,
                      {4'b0000, intDigit0}  | char_0};
                                            
 wire [159:0] fractPart;
 assign fractPart =  {{4'b0000, fractDigit19} | char_0, 
                      {4'b0000, fractDigit18} | char_0, 
                      {4'b0000, fractDigit17} | char_0, 
                      {4'b0000, fractDigit16} | char_0, 
                      {4'b0000, fractDigit15} | char_0, 
                      {4'b0000, fractDigit14} | char_0, 
                      {4'b0000, fractDigit13} | char_0, 
                      {4'b0000, fractDigit12} | char_0, 
                      {4'b0000, fractDigit11} | char_0, 
                      {4'b0000, fractDigit10} | char_0, 
                      {4'b0000, fractDigit9}  | char_0, 
                      {4'b0000, fractDigit8}  | char_0, 
                      {4'b0000, fractDigit7}  | char_0, 
                      {4'b0000, fractDigit6}  | char_0, 
                      {4'b0000, fractDigit5}  | char_0, 
                      {4'b0000, fractDigit4}  | char_0, 
                      {4'b0000, fractDigit3}  | char_0, 
                      {4'b0000, fractDigit2}  | char_0, 
                      {4'b0000, fractDigit1}  | char_0, 
                      {4'b0000, fractDigit0}  | char_0};
                      

assign integerFractWork = {integerPart, fractPart};

wire [51:0] fractMask;
wire fractionOnly;
wire [8:0] baseExp;

payloadH20 payloadH20(
    .payloadIn (wrdata_del_16[50:0]),
    .payloadStr(payloadStr)
    );                                          

binToDecH20Engine H20Eng(
    .CLK           (CLK           ),
    .RESET         (RESET         ),
    .round_mode    (round_mode    ),
    .Away          (Away          ),
    .wren          (wren          ),
    .wrdata        (wrdata        ),
    .intDigit20    (intDigit20    ),
    .intDigit19    (intDigit19    ),
    .intDigit18    (intDigit18    ),
    .intDigit17    (intDigit17    ),
    .intDigit16    (intDigit16    ),
    .intDigit15    (intDigit15    ),
    .intDigit14    (intDigit14    ),
    .intDigit13    (intDigit13    ),
    .intDigit12    (intDigit12    ),
    .intDigit11    (intDigit11    ),
    .intDigit10    (intDigit10    ),
    .intDigit9     (intDigit9     ),
    .intDigit8     (intDigit8     ),
    .intDigit7     (intDigit7     ),
    .intDigit6     (intDigit6     ),
    .intDigit5     (intDigit5     ),
    .intDigit4     (intDigit4     ),
    .intDigit3     (intDigit3     ),
    .intDigit2     (intDigit2     ),
    .intDigit1     (intDigit1     ),
    .intDigit0     (intDigit0     ),
    .fractDigit19  (fractDigit19  ),
    .fractDigit18  (fractDigit18  ),
    .fractDigit17  (fractDigit17  ),
    .fractDigit16  (fractDigit16  ),
    .fractDigit15  (fractDigit15  ),
    .fractDigit14  (fractDigit14  ),
    .fractDigit13  (fractDigit13  ),
    .fractDigit12  (fractDigit12  ),
    .fractDigit11  (fractDigit11  ),
    .fractDigit10  (fractDigit10  ),
    .fractDigit9   (fractDigit9   ),
    .fractDigit8   (fractDigit8   ),
    .fractDigit7   (fractDigit7   ),
    .fractDigit6   (fractDigit6   ),
    .fractDigit5   (fractDigit5   ),
    .fractDigit4   (fractDigit4   ),
    .fractDigit3   (fractDigit3   ),
    .fractDigit2   (fractDigit2   ),
    .fractDigit1   (fractDigit1   ),
    .fractDigit0   (fractDigit0   ),
    .expDigit2     (expDigit2     ),
    .expDigit1     (expDigit1     ),
    .expDigit0     (expDigit0     ),
    .fractInexact  (fractInexact  ),
    .intInexact    (intInexact    ),
    .fractionOnly  (fractionOnly  ),
    .resultExponent(resultExponent),
    .baseExp       (baseExp       )
);


always @(*)
//    (* parallel_case *)
    casex(intTrailZeroSel)
        21'b1xxxxxxxxxxxxxxxxxxxx : intTrailZeros = 0;
        21'b01xxxxxxxxxxxxxxxxxxx : intTrailZeros = 1;
        21'b001xxxxxxxxxxxxxxxxxx : intTrailZeros = 2;
        21'b0001xxxxxxxxxxxxxxxxx : intTrailZeros = 3;
        21'b00001xxxxxxxxxxxxxxxx : intTrailZeros = 4;
        21'b000001xxxxxxxxxxxxxxx : intTrailZeros = 5;
        21'b0000001xxxxxxxxxxxxxx : intTrailZeros = 6;
        21'b00000001xxxxxxxxxxxxx : intTrailZeros = 7;
        21'b000000001xxxxxxxxxxxx : intTrailZeros = 8;                        
        21'b0000000001xxxxxxxxxxx : intTrailZeros = 9;                        
        21'b00000000001xxxxxxxxxx : intTrailZeros = 10;                          
        21'b000000000001xxxxxxxxx : intTrailZeros = 11;                          
        21'b0000000000001xxxxxxxx : intTrailZeros = 12;                          
        21'b00000000000001xxxxxxx : intTrailZeros = 13;                          
        21'b000000000000001xxxxxx : intTrailZeros = 14;                          
        21'b0000000000000001xxxxx : intTrailZeros = 15;                        
        21'b00000000000000001xxxx : intTrailZeros = 16;                        
        21'b000000000000000001xxx : intTrailZeros = 17;                        
        21'b0000000000000000001xx : intTrailZeros = 18;                        
        21'b00000000000000000001x : intTrailZeros = 19;                        
        21'b000000000000000000001 : intTrailZeros = 20;                        
                          default : intTrailZeros = 21;                     
    endcase     
    
                     
always @(*)
//    (* parallel_case *)
    casex(fracTrailZeroSel)
        20'b1xxxxxxxxxxxxxxxxxxx : fractTrailZeros = 0;
        20'b01xxxxxxxxxxxxxxxxxx : fractTrailZeros = 1;
        20'b001xxxxxxxxxxxxxxxxx : fractTrailZeros = 2;
        20'b0001xxxxxxxxxxxxxxxx : fractTrailZeros = 3;
        20'b00001xxxxxxxxxxxxxxx : fractTrailZeros = 4;
        20'b000001xxxxxxxxxxxxxx : fractTrailZeros = 5;
        20'b0000001xxxxxxxxxxxxx : fractTrailZeros = 6;
        20'b00000001xxxxxxxxxxxx : fractTrailZeros = 7;                           
        20'b000000001xxxxxxxxxxx : fractTrailZeros = 8;                           
        20'b0000000001xxxxxxxxxx : fractTrailZeros = 9;                           
        20'b00000000001xxxxxxxxx : fractTrailZeros = 10;                          
        20'b000000000001xxxxxxxx : fractTrailZeros = 11;                          
        20'b0000000000001xxxxxxx : fractTrailZeros = 12;                          
        20'b00000000000001xxxxxx : fractTrailZeros = 13;                          
        20'b000000000000001xxxxx : fractTrailZeros = 14;                          
        20'b0000000000000001xxxx : fractTrailZeros = 15;                          
        20'b00000000000000001xxx : fractTrailZeros = 16;                          
        20'b000000000000000001xx : fractTrailZeros = 17;                          
        20'b0000000000000000001x : fractTrailZeros = 18;                          
        20'b00000000000000000001 : fractTrailZeros = 19;                          
                         default : fractTrailZeros = 20;                      
    endcase                      

always @(*)                                                                                      
    if (~|wrdata_del_16[62:0]) begin //zero
          expSign = char_Plus;
          resultSign = wrdata_del_16[63] ? char_Minus : char_Plus;    
          resultExponent = 9'b0;
          integerFractFinal = {28{8'h30}};
    end                            
    else if (fractAllZeros) begin //integer only
          expSign = char_Plus;
          resultSign = wrdata_del_16[63] ? char_Minus : char_Plus;                                          
          resultExponent = baseExp + |intDigit20;                                                           
          integerFractFinal = {{20{8'h30}}, integerPart};                                                   
    end                                                                                                     
    else begin //fraction part present with or without integer part 
          expSign = char_Minus;
          resultSign = wrdata_del_16[63] ? char_Minus : char_Plus;
          resultExponent = (20 - fractTrailZeros) + baseExp - fractionOnly;
          integerFractFinal = {{20{8'h30}}, integerFractWork} >> (fractTrailZeros * 8);                                                   
    end
    
always @(posedge CLK) begin
    if (RESET) begin
        inexact_q1 <= 0;                        
        inexact_q2 <= 0;
        inexact_q3 <= 0;
        inexact_q4 <= 0;
        inexact_q5 <= 0;
        inexact_q6 <= 0;
        inexact_q7 <= 0;
        inexact_q8 <= 0;
    end
    else begin
        inexact_q1 <= inexact;                          
        inexact_q2 <= inexact_q1;
        inexact_q3 <= inexact_q2;
        inexact_q4 <= inexact_q3;
        inexact_q5 <= inexact_q4;
        inexact_q6 <= inexact_q5;
        inexact_q7 <= inexact_q6;
        inexact_q8 <= inexact_q7;
    end
end    

always @(posedge CLK) begin
   if (RESET) begin
      wrdata_del_1  <= 0;
      wrdata_del_2  <= 0;
      wrdata_del_3  <= 0;
      wrdata_del_4  <= 0;
      wrdata_del_5  <= 0; 
      wrdata_del_6  <= 0;
      wrdata_del_7  <= 0;
      wrdata_del_8  <= 0;
      wrdata_del_9  <= 0;
      wrdata_del_10 <= 0;
      wrdata_del_11 <= 0;
      wrdata_del_12 <= 0;
      wrdata_del_13 <= 0;
      wrdata_del_14 <= 0;
      wrdata_del_15 <= 0;
      wrdata_del_16 <= 0;
   end      
   else begin
       wrdata_del_1  <= wrdata;
       wrdata_del_2  <= wrdata_del_1;
       wrdata_del_3  <= wrdata_del_2 ;
       wrdata_del_4  <= wrdata_del_3 ;
       wrdata_del_5  <= wrdata_del_4 ; 
       wrdata_del_6  <= wrdata_del_5 ;
       wrdata_del_7  <= wrdata_del_6 ;
       wrdata_del_8  <= wrdata_del_7 ;
       wrdata_del_9  <= wrdata_del_8 ;
       wrdata_del_10 <= wrdata_del_9 ;
       wrdata_del_11 <= wrdata_del_10;
       wrdata_del_12 <= wrdata_del_11;
       wrdata_del_13 <= wrdata_del_12;
       wrdata_del_14 <= wrdata_del_13;
       wrdata_del_15 <= wrdata_del_14;
       wrdata_del_16 <= wrdata_del_15;
   end
end 
  

always @(posedge CLK)    //16th clock from first write enable at front end
    (* parallel_case *)
    casex(finalSel)
        4'b1xxx : ascOut = {1'b0, 1'b1, {30{8'h20}}, resultSign, inf_string};
        4'b01xx : ascOut = {2'b00, {13{8'h20}}, resultSign, nan_string, 8'h20, payloadStr[127:0]};
        4'b001x : ascOut = {2'b00, {12{8'h20}}, resultSign, snan_string, 8'h20, payloadStr[127:0]};
        4'b0001 : ascOut = {1'b1, 1'b0, resultSign, integerFractFinal[223:0], expString};  //with this H=20 format, all underflows are inexact                                        
        default : ascOut = {inexact_q8, inexact_q8, resultSign, integerFractFinal[223:0], expString};  
    endcase

endmodule

