![](https://github.com/jerry-D/IEEE-754-2008_ISA_CPU/blob/master/images/SYMPL_CPU_LOGO.png)

## IEEE 754-2008  H=20 "convertToDecimalCharacter"  
### Double-Precision FLoating-Point Operator for Xilinx UltraScale and UltraScale+ FPGAs

(September 26, 2018) Since publishing yesterday, an IEEE 754-2008 expert discovered a couple issues with the design that are presently being corrected.  Namely, inadeqate number of bits used for computing 20 decimal digits and gradual underflow representation of subnormals.  Another issue, discovered post-facto, is the manner in which values are computed.  It is anticipated that corrections will result in a more simplified design and lower gate utilization.

(September 25, 2018) Written in Verilog RTL for implementation in Xilinx UltraScale and UltraScale+ brand FPGAs, this is probably the world's only synthesizable IEEE 754-2008 compliant, H=20 binary64 format "convertFromDecimalCharacter" floating-point operator.  It is designed for ready incorporation into the new 64-bit, IEEE 754-2008 Floating-Point Instruction Set Architecture (ISA) CPU presently in development.

Its pipeline is only 17 clocks deep, meaning that up to sixteen 34-byte results will be available for reading after 17 clocks from the first write of a binary64 format operand into each of this operator's sixteen 64-bit memory-mapped inputs.  

Since the new IEEE 754-2008 ISA CPU design includes new instructions that can read and write a 16-byte, 32-byte, 64-byte, 128-byte or 256-byte "gob" every clock cycle, up to sixteen 34-byte character sequences can be computed and written back out to system memory in as few as 34 clocks, which includes pushing each binary64 representation number into each operator input and reading each result out from their corresponding memory-mapped input/output address.

Stated another way, this design features sixteen memory-mapped inputs with corresponding result buffers that the 34-byte results automatically spill into.  When used with the SYMPL CPU "REPEAT" instruction, the effective/apparent latency is only one clock per conversion.  This is because by the time the CPU has written each of the sixteen operands, the results from the first writes are already available for reading.

To accommodate easier implementation of its companion "convertFromDecimalCharacter" operator, the result character string format is fixed, right justified with up to 20 fraction-part digits, 21 integer-part digits or combination of up to 28 decimal character digits for results having both an integer part and fraction part.

The exponent value is referenced relative to the last digit in the significand of the decimalCharacterSequence.  

Here is some example code written in SYMPL Intermediate Language (IL) that computes sixteen, correctly rounded, binary64 format decimalCharacterSequences and writes the computed results out byte-addressable system memory:

    uw AR0 = uw:#listStart           ;load read pointer with starting address of list
    uw AR1 = uw:#cnvTDCS.0           ;load write pointer with address of first operator input buffer
       REPEAT uw:#15                 ;load repeat counter with number of extra times the following instruction is to be executed              
    ud *AR1++[8]  = convertToDecimalCharacter:(ud:*AR0++[8], ub:#0)      ;push sixteen binary64 numbers into the operator

    uw AR2 = uw:#cnvTDCS.0           ;load read pointer with address of first operator result buffer
    uw AR3 = uw:#dest                ;load write pointer with first address of where the 64-byte "gob" will be stored in system memory
       REPEAT uw:#15                 ;load repeat counter with number results to read out                  
    g64 *AR3++[64] = g64:*AR2++[64]  ;pull sixteen 34-byte character sequences from their respective result buffers and write them to byte-addressable system memory

Note that the above code for converting all sixteen binary64 numbers to decimalcharacterSequences requires only eight 64-bit instructions and consumes roughly 38 clocks to complete.

Below are actual results of sixteen consecutive pushes into the operator, one every clock, as demonstrated in the Verilog test bench provided in this repository.  The easiest way to see results for yourself is to run the simulation on the "free" version of Xilinx Vivado using the files provided at this repository.  Then, in the Vivado simulation environment, simply click on the twoport RAM module in the design and scroll down to the first sixteen locations.  Set radix to ASCII to read the contents.
```
      34-byte Character Sequence Result        Binary64 Input     Comment

      +3355443194222818687558174133e-020       417FFFFFFF135DDD   //33554431.94222818687558174133
      
      +0000000179769313486231570815e+289       7FEFFFFFFFFFFFFF   //largest integer

                   +nan 0 C001 FEED C0DE       7FF8C001FEEDC0DE   //quiet NaN with payload
                   
      +0000000049406564584124654418e-343       0000000000000001   //smallest (subnormal) number 
        
                  +snan 0 FEE1 600D C0DE       7FF0FEE1600DC0DE   //sNaN with payload
                  
      +0000000001298074214633707008e+000       43B203AF9EE75616   //1298074214633707008

      +0000000055751862996326554871e+072       52FB5E7E08CA3A8F   //5.5751862996326554871e91

                                    -inf       FFF0000000000000   //-infinity
                                    
      +0000000078919994320999994169e-086       323546DB9A6A41D7   //78919994321e-77

      -0000000000000000000000000000e+000       8000000000000000   //-0

      +0000000000000000000000000015e-001       3FF8000000000000   //+1.5

      -0000000188815458970875003821e+270       FBFF000000000001   //-1.88815458970875003821e250

      +0000000073786976294838206464e+000       4410000000000000   //73786976294838206464

      +000000002225073858507200889e-326       000FFFFFFFFFFFFF   //largest (subnormal)

      -0000000000000000000000000015e-001       BFF8000000000000   //-1.5

                                    +inf       7FF0000000000000   //+infinity
                                    

```
