.ORIG x3000

; ** 'MAIN' METHOD ** 
    START LEA R0 startmsg       ; load address of startmsg
        PUTS                    ; print startmsg to output (step 0)
    
    QUERYMSG LEA R0 query       ; load address of query (step 1)
        PUTS                    ; print query
        GETC                    ; get user input 
    
    ; if input is D, this section will get the key from the user (step 2)
    LD R1 D                     ; load value of ASCII D 
    ADD R1 R1 R0                ; check user input against ASCII
    BRnp inputE                 ; if user input is not D, check for E 
    ST R7 SaveR7
    LD R2 toDECRYPT             ; if user input is D, store address of decrypt subroutine
    JSRR R2                     ; go to decrypt subroutine
    LD R7 SaveR7
    BRnzp QUERYMSG              ; go back to start
    
    ; if input is E, this section will get the key from the user (step 2)
    inputE LD R1 E              ; load value of ASCII E 
    ADD R1 R1 R0                ; check user input against ASCII
    BRnp inputX                 ; if user input is not E, check for X 
    ST R7 SaveR7                ; Store R7
    LD R2 toENCRYPT             ; if user input is E, store address of encrypt subroutine
    JSRR R2                     ; go to encrypt subroutine
    LD R7 SaveR7                ; load R7
    BRnzp QUERYMSG              ; go back to start 
    
    ; if input is X, this section will exit the program (step 5)
    inputX LD R1 EXIT           ; load value of ASCII X 
    ADD R1 R1 R0                ; check user input against ASCII
    BRnp subINVALID             ; if user input is not X, go to invalid input 
    ST R7 SaveR7                ; Store R7
    LD R2 toEXIT                ; if user input is X, store address of exit subroutine
    JSRR R2                     ; go to exit subroutine
    LD R7 SaveR7                ; load R7
    
    HALT                        ; stop 
    
    
; ** INVALID INPUT SUBROUTINE **
subINVALID
    LEA R0 invalid              ; store invalid msg 
    PUTS                        ; print to console 
    BRnzp QUERYMSG              ; go back to query, re-enter 
    
; ** ENCRYPTION SUBROUTINE **
subENCRYPT
    ST R7 SaveR7             ; save R7 and get ready for JSRR
    LD R2 toKEYIN            ; load address of key input subroutine
    JSRR R2                  ; go to key input subroutine 
    LD R7 SaveR7             ; return from JSRR
    
    LD R5 encryptAddr           ; load address x4000
    LEA R0 promptmsg            ; load address of promptmsg       
    PUTS                        ; print promptmsg to console 
    AND R4 R4 #0                ; clear out R4 
    ADD R4 R4 #10               ; initialize R4 (counter) to 10 
        promptLoop GETC         ; loop and get character 
            ;LD R1 convert               ; load ASCII converter value (-48)
            ;ADD R0 R0 R1                ; convert from ASCII to binary
            STR R0 R5 #0        ; store user input to memory 
            ADD R5 R5 #1        ; increment address
            ADD R4 R4 #-1       ; decrement counter
                BRp promptLoop  ; end loop when counter runs out
                
    ST R7 SaveR7                ; save R7 and get ready for JSRR
    LD R2 toXOR                 ; load address of subXOR
    JSRR R2                     ; jump to XOR subroutine
    LD R7 SaveR7                ; return from JSRR
    
    ST R7 SaveR7                ; save R7 and get ready for JSRR
    LD R2 toCAESAR              ; load address of subCAESAR
    JSRR R2                     ; jump to CAESAR subroutine
    LD R7 SaveR7                ; return from JSRR

    ST R7 SaveR7                ; save R7
    LD R2 toERK                 ; load address of subERK (to erase the key)
    JSRR R2                     ; jump to erase routine
    LD R7 SaveR7                ; return from JSRR
    
    RET
    
; ** DECRYPTION SUBROUTINE **
subDECRYPT
    ST R7 SaveR7             ; save R7 and get ready for JSRR
    LD R2 toKEYIN            ; load address of key input subroutine
    JSRR R2                  ; go to key input subroutine 
    LD R7 SaveR7             ; return from JSRR
    
    LD R5 encryptAddr        ; method to copy over the encrypted message to decrypt 
    LD R2 decryptAddr
    AND R4 R4 #0
    ADD R4 R4 #10
    cpyLp LDR R0 R5 #0
        STR R0 R2 #0
        ADD R5 R5 #1
        ADD R2 R2 #1
        ADD R4 R4 #-1
        BRp cpyLp
    
    
    ST R7 SaveR7            ; Store R7
    LD R2 toCAESARDEC       ; go to caesar decrypt
    JSRR R2
    LD R7 SaveR7
    
    ST R7 SaveR7
    LD R2 toXORDEC          ; go to xor decrypt
    JSRR R2 
    LD R7 SaveR7
    
    ST R7 SaveR7            
    LD R2 toERK             ; go to the error key 
    JSRR R2
    LD R7 SaveR7
    
    RET

; ** KEY INPUT SUBROUTINE **
subKEYIN
getKey AND R4 R4 #0             ; clear out R4, it will be our counter 
    LEA R0 keymsg               ; load address of the keymsg 
    PUTS                     ; print the keymsg to the console
    LD R5 keyAddr               ; load x3500 (starting addr) into R5
    ADD R4 R4 #5                ; initialize loop counter length to 5 
        keyLoop GETC                    ; read in the first character 
            LD R1 convert               ; load ASCII converter value (-48)
            ADD R0 R0 R1                ; convert from ASCII to binary
            STR R0 R5 #0                ; store user input to memory 
            ADD R5 R5 #1                ; increment key address in memory ("index")
            ADD R4 R4 #-1               ; decrement counter 
                BRp keyLoop             ; while R4 > 0, repeat loop 
        
    AND R5 R5 #0                ; clear out R5 
    LDI R5 keyAddr              ; load first index into R5 

    checkZ              ; check if z is 0-7
        LD R1 zLower                ; Load lower bound 
        ADD R2 R5 R1                ; Add R1, R5, store in R2
        BRn InvRange                ; If below lower bound, go to InvRange
        LD R1 zUpper                ; Load upper bound 
        ADD R2 R5 R1                ; Add R1, R5, store in R2
        BRp InvRange                ; If result is positive, val greater in magnitude than 7, so go to InvRange
            
    checkX              ; check if x is NOT 1-9 
        LDI R5 xAddr                ; load address of x3501
        ADD R5 R5 #0
        BRz zero
        LD  R1 xLower               ; load lower bound (decimal -1)
        ADD R2 R1 R5                ; Store sum of R1 + R5 in R2 
        BRp secondCondition         ; check second condition for invalidity - is it above 1 AND below 9?
        BRz InvRange                ; if zero, we know automatically it is invalid 
        secondCondition             
            LD R1 xUpper                ; load upper bound       
            ADD R2 R1 R5                ; check to see if value is below 9
            BRnz InvRange               ; Sum is <= 9 so our value is invalid, go to InvRange
            zero
            BRp checkY
            
    checkY            ; check if y is 0-127   
        AND R6 R6 #0        ; clear out our result register. 
        BRnzp subMULT       ; go to the multiplication "subroutine" (a loop)
        afterMULT           ; label to continue checkY
        LDI R5 yAddr        ; load address of (multiplied) y 
        LD R1 zLower        ; load lower bound (zero)
        ADD R2 R1 R5        ; add R1 and R5, store in R2 
        BRn InvRange        ; value is less than zero (negative) so go to invalid 
        LD R1 yUpper        ; load upper bound (127)
        ADD R2 R1 R5        ; add R1 and R5, store in R2
        BRp InvRange        ; result is positive, val greater in magnitude than 127, so go to invalid
        BRnzp goodKey           ; key is valid, go to goodKey
    
        
        subMULT                 ; subroutine to get 3-digit y-value from 3 separate inputs. 
            LDI R5 y1Addr       ; load value of y1 into R5
            LD R1 mplyHundred   ; load first multiplier into R1 
            LDI R2 y1Addr       ; load counter value (y1) into R2 
            BRz check           ; if value is zero skip to tens place (handling 0 case)
        
            
  multLoop1 ADD R6 R6 R1        ; Add R1 to R6, store in R6
            ADD R2 R2 #-1       ; decrement counter
            BRp multLoop1       ; control for multiplier loop 1 
            
    check   LDI R5 y2Addr       ; load value of y2 into R5
            LD R1 mplyTen       ; load second multiplier into R1 
            LDI R2 y2Addr       ; load counter value (y2) into R2 
            BRz check2          ; same check for zero, skip to ones place
            
  multLoop2 ADD R6 R6 R1        ; Add R1 to R6, store in R6 
            ADD R2 R2 #-1       ; decrement counter 
            BRp multLoop2       ; control for multiplier loop 2 
            
    check2  LDI R4 y3Addr       ; load value of y3 into R4
            AND R0 R0 #0        ; clear out R0
            ADD R0 R6 R4        ; add (y1+y2) + y3 and store in R0
            STI R0 yAddr        ; store at address of yAddr
        BRnzp afterMULT         ; go out of the multiplication loop
    
    InvRange LEA R0 invalid         ; store invalid msg 
        PUTS                        ; print to console
        BRnzp getKey            
    
    goodKey 
        RET
        
; ** VARIABLES **
    SaveR1      .FILL #0
    SaveR7      .FILL #0            
    ; caller-save convention 
    toINVALID   .FILL subINVALID    ; initialize a variable to address of subroutine subINVALID
    toENCRYPT   .FILL subENCRYPT    ; initialize a variable to address of subroutine subENCRYPT
    toDECRYPT   .FILL subDECRYPT    ; initialize a variable to address of subroutine subDECRYPT
    toKEYIN     .FILL subKEYIN      ; initialize a variable to address of subroutine subKEYIN
    toEXIT      .FILL subEXIT       ; initialize a variable to address of subroutine subEXIT
    toERK     .FILL subERK          ; initialize a variable to address of subroutine subERK
    toERM    .FILL subERM        
    toMULT      .FILL subMULT       ; initialize a variable to address of subroutine subMULT
    toXOR       .FILL subXOR        ; initialize a variable to address of subroutine subXOR
    toXORDEC    .FILL subXORDEC
    toCAESAR   .FILL subCAESAR      ; initialize a variable to address of subroutine CAESAR
    toCAESARDEC .FILL subCAESARDEC
    
    ; fill variables we can check to read and compare the user input 
    D           .FILL x-44                    ; ASCII D
    E           .FILL x-45                    ; ASCII E
    N           .FILL #128                    ; N for Caesar Cipher 
    EXIT        .FILL x-58                    ; ASCII X
    READloop    .FILL x-35                    ; ASCII 5 
    convert     .FILL #-48                    ; Decimal -48
    convert2    .FILL #48
    zLower      .FILL #0                      ; Decimal 0
    zUpper      .FILL #-7                     ; Decimal 7
    xLower      .FILL #-1                     ; Decimal -1 (Lower bound of X)
    xUpper      .FILL #-9                     ; Decimal -9 (Upper bound of X)
    mplyHundred .FILL #100                    ; Decimal 100 (multiplier for hundreds place)
    mplyTen     .FILL #10                     ; Decimal 10 (multiplier for tens place)
    yUpper      .FILL #-127                    ; Decimal 127 (Upper bound of Y)
    
    keyAddr  .FILL x3500         ; so we know where we are storing our key 
    xAddr    .FILL x3501
    y1Addr   .FILL x3502
    y2Addr   .FILL x3503
    y3Addr   .FILL x3504
    yAddr    .FILL x3506
    encryptAddr .FILL x4000
    decryptADDR .FILL x5000
    counter .FILL #10
    offset  .FILL #0 
    
        ; message prompts
    startmsg    .STRINGZ "\nSTARTING PRIVACY MODULE\n"
    query       .STRINGZ "\nENTER E OR D OR X\n"
    keymsg      .STRINGZ "\nENTER KEY\n"
    promptmsg   .STRINGZ "\nENTER MESSAGE\n"
    invalid     .STRINGZ "\nINVALID INPUT\n"    
    

; ** EXIT SUBROUTINE **
subEXIT
    ST R7 SaveR7
    LD R2 toERM
    JSRR R2         ; go to erase the message
    LD R7 SaveR7
    RET

; ** XOR SUBROUTINE **
subXOR 
    LD R1 xAddr             ; load xAddr into R1 (B)
    LDR R1 R1 #0            ; load actual value of xAddr into R1
   ; LD R3 convert2
   ; ADD R1 R1 R3
    LD R6 offset            ; load offset into R6
    LD R2 counter           ; load counter into R2
    
    Loop BRnz Done
    LD R0 encryptAddr       ; load x4000 into R0 (A)
    ADD R0 R0 R6            ; add offset to x4000, store into R0 
    LDR R0 R0 #0            ; load the value stored at x4000 + offset into R0
    AND R3 R3 #0            ; clear out R3-R5 
    AND R4 R4 #0
    AND R5 R5 #0
    
    NOT R3 R0               ; A', store in R3
    NOT R4 R1               ; B', store in R4
    AND R3 R1 R3            ; BA'
    AND R4 R0 R4            ; AB'
    NOT R3 R3               ; (AB')'
    NOT R4 R4               ; (BA')'
    AND R5 R3 R4            ; (AB')'(BA')'
    NOT R5 R5               ; A XOR B 
    LD R0 encryptAddr       ; reload address of x4000
    ADD R0 R0 R6            ; add offset to x4000
    STR R5 R0 #0            ; store into R0
    ADD R6 R6 #1            ; increment offset
    ADD R2 R2 #-1           ; decrement counter 
    BRnzp Loop
    Done RET 
    
; ** XOR DECRYPT SUBROUTINE **
subXORDEC
    LD R1 xAddr             ; load xAddr into R1 (B)
    LDR R1 R1 #0            ; load actual value of xAddr into R1
    LD R6 offset            ; load offset into R6
    LD R2 counter           ; load counter into R2
    
    Loopdec BRnz Donedecxor
    LD R0 decryptAddr       ; load x5000 into R0 (A)
    ADD R0 R0 R6            ; add offset to x5000, store into R0 
    LDR R0 R0 #0            ; load the value stored at x5000 + offset into R0
    AND R3 R3 #0            ; clear out R3-R5 
    AND R4 R4 #0
    AND R5 R5 #0
    
    NOT R3 R0               ; A', store in R3
    NOT R4 R1               ; B', store in R4
    AND R3 R1 R3            ; BA'
    AND R4 R0 R4            ; AB'
    NOT R3 R3               ; (AB')'
    NOT R4 R4               ; (BA')'
    AND R5 R3 R4            ; (AB')'(BA')'
    NOT R5 R5               ; A XOR B 
    LD R0 decryptAddr       ; reload address of x5000
    ADD R0 R0 R6            ; add offset to x5000
    STR R5 R0 #0            ; store into R0
    ADD R6 R6 #1            ; increment offset
    ADD R2 R2 #-1           ; decrement counter 
    BRnzp Loopdec
    Donedecxor RET 
    
; ** CAESAR CIPHER SUBROUTINE **
subCAESAR 
    LD R1 yAddr         ; load our "K" / Divisor 
    LDR R1 R1 #0        ; load actual value 
    ST R1 SaveR1        ; store this address 
    
    LD R6 offset        ; load offset
    LD R2 counter       ; load counter 
    
    modLoop BRnz DoneC
    AND R4 R4 #0        ; clear out register R4 to store our result 
    LD R0 encryptAddr   ; load the address of the character we are encrypting
    ADD R0 R0 R6        ; count offset to get to address 
    LDR R0 R0 #0        ; load actual value into R0 

    LD R3 N             ; load N (128) into R3 
    
    ADD R0 R0 R1        ; Add N to R0 (p + k)
    
    NOT R3 R3           ; take 2's complement of 128
    ADD R3 R3 #1
    
    ADD R0 R0 #0
    modSub BRn donemod
        ADD R0 R0 R3    ; repeated subtraction, subtract R0-R1 and store in R4
        BRnzp modSub     
        
    donemod LD R5 N 
    ADD R4 R0 R5
    LD R0 encryptAddr   ; load result into x4000
    ADD R0 R0 R6
    STR R4 R0 #0 
    ADD R6 R6 #1
    ADD R2 R2 #-1
    BRnzp modLoop
    
    DoneC RET
    
    
; ** CAESAR CIPHER DECRYPT SUBROUTINE **
subCAESARDEC
    LD R1 yAddr         ; load our "K" / Divisor 
    LDR R1 R1 #0        ; load actual value 
    ST R1 SaveR1        ; store this address 
    
    NOT R1 R1
    ADD R1 R1 #1
    
    LD R6 offset        ; load offset
    LD R2 counter       ; load counter 
    
    modLoopdec BRnz DoneCdec
    AND R4 R4 #0        ; clear out register R4 to store our result 
    LD R0 decryptAddr   ; load the address of the character we are encrypting
    ADD R0 R0 R6        ; count offset to get to address 
    LDR R0 R0 #0        ; load actual value into R0 

    LD R3 N             ; load N (128) into R3 
    
    ADD R0 R0 R1        ; Add N to R0 (p + k)
    
    NOT R3 R3           ; take 2's complement of 128
    ADD R3 R3 #1
    
    ADD R0 R0 #0
    modSubdec BRn donemoddec
        ADD R0 R0 R3    ; repeated subtraction, subtract R0-R1 and store in R4
        BRnzp modSubdec     
        
    donemoddec LD R5 N 
    ADD R4 R0 R5
    LD R0 decryptAddr       ; load 
    ADD R0 R0 R6
    STR R4 R0 #0 
    ADD R6 R6 #1
    ADD R2 R2 #-1
    BRnzp modLoopdec
    
    DoneCdec RET
    RET

subERM
LD R1 encryptAddr       ; load first index of encrypted message
LD R2 counter           ; reload the counter to iterate through all 10 characters 
ermL AND R0 R0 #0       ; clear out R0
    STR R0 R1 #0        ; store zero into address
    ADD R1 R1 #1        ; increment pointer to next address
    ADD R2 R2 #-1       ; decrement counter
    BRp ermL            ; repeat until our counter = 0
RET

subERK
LD R1 keyAddr
AND R2 R2 #0            ; clear out the index we will use for a counter 
ADD R2 R2 #7            ; load with a value we can use to iterate through all of the key characters
erkL AND R0 R0 #0       ; clear R0
    STR R0 R1 #0        ; store zero into address
    ADD R1 R1 #1        ; increment pointer to next address 
    ADD R2 R2 #-1       ; decrement counter
    BRp erkL            ; repeat until our counter = 0
RET
    
    
.END

