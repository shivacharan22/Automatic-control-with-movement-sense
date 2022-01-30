
@ The program
        .text
        .align  2
        .global reci

@ receiver
@ function to receiver data.
@ Calling sequence:
@      bl receiver


reci:
@ creating a socket as per the protocal
mov r7,#281 @sys_call socket
mov r0,#2                   @ data stream TCP/IP
mov r1,#1                   @ data gram
mov r2,#0                   @ flags
swi 0                       @ interrupt
mov r4, r0                  @ SAVING THE SOCKET IN r4

@ creating a blind as per the protocal
    ldr  r1,=s              @ loading the struct
    strb r2, [r1, #1]       @ loading the protocal number
    strb r2, [r1, #4]       @ port number
    strb r2, [r1, #5]       @ IP
    strb r2, [r1, #6]
    strb r2, [r1, #7]
    mov r2, #16             @ len of the struct
    add r7, #1              @ sys_call for blind
    swi 0                   @ interrupt

@ enabling listen as per the protocal
    mov r0, r4              @ socket descripter
    mov r1, #3              @ max people who can connect
    mov r7, #284            @ sys_call for listen
    swi 0                   @ interrupt

loop:
@ accepting any connections from listen
    mov r0,r4
    mov r1,#0
    mov r2,#0
    mov r3,#0
    mov r7, #285
    swi 0

    mov r5, r0

@ recv
    mov r0, r5
    ldr r1,=buffer
    mov r2,#5
    mov r3,#0
    mov r7,#291
    swi 0
@ print
    mov r7,#4
    mov r0,#1
    ldr r1,=buffer
    mov r2,#9
    swi 0
    b loop

.section .data
        s: .ascii "\x02\xff"
           .byte 20,96
           .byte  192,168,1,3
        buffer: .skip 10