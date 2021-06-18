;///////////////////////////////////////////////////////////////////////
;
;	Windows arm64 dynamic function call
;	Code adapted from http://www.dyncall.org/ by fo
;
;///////////////////////////////////////////////////////////////////////

;//////////////////////////////////////////////////////////////////////////////
;
; Copyright (c) 2007-2009 Daniel Adler <dadler@uni-goettingen.de>, 
;                         Tassilo Philipp <tphilipp@potion-studios.com>
;
; Permission to use, copy, modify, and distribute this software for any
; purpose with or without fee is hereby granted, provided that the above
; copyright notice and this permission notice appear in all copies.
;
; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
; WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
; MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
; ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
; WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
; ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
; OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
;
;//////////////////////////////////////////////////////////////////////////////

#include "ksarm64.h"


       TEXTAREA

;++
;
; PerformDynaCall(...);
;

        LEAF_ENTRY  PerformDynaCall

; // input:
; //   x0: target   (address of target)
; //   x1: data     (address of stack copy data)
; //   x2: size     (number of 'pair' 16-byte units)
; //   x3: regdata  (address of register data)

; prolog:
         stp x29, x30, [sp, #-16]!    ; // allocate frame
         mov x29, sp

; // load 64-bit floating-point registers
         ldr d0, [x3,#0 ]
         ldr d1, [x3,#8 ]
         ldr d2, [x3,#16]
         ldr d3, [x3,#24]
         ldr d4, [x3,#32]
         ldr d5, [x3,#40]
         ldr d6, [x3,#48]
         ldr d7, [x3,#56]
; // copy to stack
         sub sp, sp, x2     ; // create call-frame
         eor x4, x4, x4     ; // x4: cnt = 0

         mov x5, x1         ; // x5: read pointer = data
         mov x6, sp         ; // x6: write pointer = sp

dcCall_arm64_next
         cmp x4, x2
         b.ge dcCall_arm64_done

         ldp x7, x9, [x5], #16  ; // get pair from data
         stp x7, x9, [x6], #16  ; // put to stack
         add x4, x4, 16         ; // advance 16 bytes
         b dcCall_arm64_next
dcCall_arm64_done

; // rescue temp int registers
         mov x9 , x0            ; // x9: target
         add x10, x3, 64        ; // x3: integer reg buffer

; // load 64-bit integer registers ( 8 x 64-bit )

;   // load register set
         ldr x0, [x10, #0]
         ldr x1, [x10, #8]
         ldr x2, [x10, #16]
         ldr x3, [x10, #24]
         ldr x4, [x10, #32]
         ldr x5, [x10, #40]
         ldr x6, [x10, #48]
         ldr x7, [x10, #56]

; // call target:
         blr x9

; // epilog:
         mov sp, x29
         ldp x29, x30, [sp], 16
         ret

        LEAF_END    PerformDynaCall


        LEAF_ENTRY  read_xmm0_float
        	; Nothing is actually done here - we just declare the appropriate return type in C++.
	        ret
        LEAF_END    read_xmm0_float

        LEAF_ENTRY  read_xmm0_double
        	; Nothing is actually done here - we just declare the appropriate return type in C++.
	        ret
        LEAF_END    read_xmm0_double


        LEAF_ENTRY  RegisterCallbackAsmStub
        stp x29, x30, [sp, #-16]!    ; // allocate frame
        mov x29, sp
        
        PROLOG_STACK_ALLOC 8*9

        ; For the 'mov' further below
        add sp, sp, #8 

        ; Save the parameters in the spill area for consistency
        
        ; // save integer registers

	    stp x0, x1, [sp, #0 ]
	    stp x2, x3, [sp, #16]
	    stp x4, x5, [sp, #32]
        stp x6, x7, [sp, #48]

        ; Set parameters for the upcoming function call

        mov x0, sp
        mov x1, x9

        ldr x11, [x9 , #24]

        sub sp, sp, #64

	    blr  x11

        mov sp, x29
        ldp x29, x30, [sp], 16
        ret

        LEAF_END    RegisterCallbackAsmStub
        
        END
