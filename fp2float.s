        // CES30 FP2float assignment template
        // 
        // Your name: Vincent Liang
        // your pid: A15946763
        //
        // Describe target Hardware to the assembler
        .arch   armv6
        .cpu    cortex-a53
        .syntax unified
        /////////////////////////////////////////////////////////

        .text                       // start of the text segment
        /////////////////////////////////////////////////////////
        // function FP2float
        /////////////////////////////////////////////////////////
        .type   FP2float, %function // define as a function
        .global FP2float            // export function name
        .equ    FP_OFF_FP2, 28      // (regs - 1) * 4
        /////////////////////////////////////////////////////////

        // put any .equ for FP2float here - delete this line

        /////////////////////////////////////////////////////////
FP2float:
        push    {r4-r9, fp, lr}     // use r4-r9 protected regs
        add     fp, sp, FP_OFF_FP2  // locate our frame pointer
        // do not edit the prologue above
        // You can use temporary r0-r3 and preserved r4-r9
        // Store return value (results) in r0
        /////////////////////////////////////////////////////////
        
        //check for denorm values
        CMP r0, 0x00000000 // if(r0 == 0) {
        BNE case2           // .
        BL zeroFP2float    // zeroFP2float();
        b end              // }
        
case2:  CMP r0, 0x00000080 // else if(r0 == -0) {
        BNE main           // .
        BL zeroFP2float    // zeroFP2float();
        b end              // }

main:                      // else
        //r1 needs to contain first value from r0, we can LSR 7 times to get first value at end
        LSR R1, R0, #7         // R[1] = R[0] >> 7
        
        //r2 will contain the next 3 bits, we can achieve this using AND and LSR
        AND R2, R0, 0x00000070 // R[2] = R[0] & 0x00000070
        
        //r2 = exponent to unbiased exponent
        LSR R2, R2, #4      // R[2] = R[2] >> 4
        CMP R2, 0x0000000   // if(bias == 0) {
        BNE normal          // .
        
        
        
denorm:  
        SUB R2, R2, #3         // R[2] = R[2] - 3
        //add 127(bias) to exponent now
        ADD R2, R2, #127       // R[2] = R[2] + 127
        //let r3 contain mantissa and last 4 bits
        AND R3, R0, 0x0000000F // R[3] = R[0] & 0x0000000F

        //check mantissa for the first "1" and move exponent
        CMP r3, #1          // if(R[3] == 1) {
        BNE c1              // .
        SUB R2, R2, #3      // R[2] = R[2] - 3;
        LSL R3, R3, #4      // R[3] = R[3] << 4;
        AND R3, R3, 0x0000000F  // R[3] = R[3] & 0x0000000F
        B add               // }
c1:     
        CMP r3, #4         // else if(R[3] < 4) {
        BGE c2             // .
        SUB R2, R2, #2     // R[2] = R[2] - 2;     
        LSL R3, R3, #3    // R[3] = R[3] << 3;
        AND R3, R3, 0x0000000F  // R[3] = R[3] & 0x0000000F
        B add              // }
        
c2:
        CMP r3, #8         // else if(R[3] < 8) {
        BGE c3            // .
        SUB R2, R2, #1     //R[2] = R[2] - 1;
        LSL R3, R3, #2    // R[3] = R[3] << 2;
        AND R3, R3, 0x0000000F  // R[3] = R[3] & 0x0000000F
        B add              //{
                            // else {
c3:     LSL R3, R3, #1      // R[3] = R[3] << 1;
        AND R3, R3, 0x0000000F  // R[3] = R[3] & 0x0000000F
        B add                  //.}
        
add:                           
          
        LSL R3, R3, #19        // R[3] = R[1] << 19
        LSL R1, R1, #31        // R[1] = R[1] << 31
        LSL R2, R2, #23        // R[2] = R[2] << 23
        
        ADD R1, R1, R2         // R[1] = R[1] + R[2]
        ADD R0, R1, R3         // R[0] = R[1] + R[3]  
        
        b end
        
        
normal:                        //else
        //subtract 3 from bias
        SUB R2, R2, #3         // R[2] = R[2] - 3
        //add 127 to exponent now
        ADD R2, R2, #127       // R[2] = R[2] + 127
        //r3 will contain mantissa, which we can AND everything but the last 4 bits
        //then we can 
        AND R3, R0, 0x0000000F // R[3] = R[0] & 0x0000000F

        //want to add all three parts together now
        //R1, the first value, should be the first bit
        LSL R1, R1, #31        // R[1] = R[1] << 31
        //R2, exponent bit shifted to the left
        LSL R2, R2, #23        // R[2] = R[2] << 23
        //R3, mantissa bit shifted to left
        LSL R3, R3, #19        // R[3] = R[3] << 19
        
        ADD R1, R1, R2         // R[1] = R[1] + R[2]
        ADD R0, R1, R3         // R[0] = R[1] + R[3]              
end:
        /////////////////////////////////////////////////////////
        // do not edit the epilogue below
        sub     sp, fp, FP_OFF_FP2  // restore sp
        pop     {r4-r9,fp, lr}      // restore saved registers
        bx      lr                  // function return 
        .size   FP2float,(. - FP2float)

        /////////////////////////////////////////////////////////
        // function zeroFP2float
        /////////////////////////////////////////////////////////
        .type   zeroFP2float, %function // define as a function
        .global FP2float                // export function name
        .equ    FP_OFF_ZER, 4           // (regs - 1) * 4
        /////////////////////////////////////////////////////////

        // put any .equ for zeroFP2float here - delete this line

        /////////////////////////////////////////////////////////
zeroFP2float:
        push    {fp, lr}            // 
        add     fp, sp, FP_OFF_ZER  // locate our frame pointer
        // do not edit the prologue above
        // You can use temporary registers r0-r3
        // Store return value (results) in r0
        /////////////////////////////////////////////////////////
        
        // so if we have a 0, we return a 0, if we have -0, return 0x800
        CMP r0, 0x00000000         // if(r0 == 0) {
        BNE neg_zero               // .
        MOV R0, 0x00000000         // r0 = 0; }
        b over                     // else
neg_zero:MOV R0, 0x80000000        // r0 = 0x80000000;
over:                              // }

        /////////////////////////////////////////////////////////
        // do not edit the epilogue below
        sub     sp, fp, FP_OFF_ZER  // restore sp
        pop     {fp, lr}            // restore saved registers
        bx      lr                  // function return
        .size   zeroFP2float,(. - zeroFP2float)

.end
