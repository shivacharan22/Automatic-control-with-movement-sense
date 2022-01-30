@ The program
        .text
        .align  2
        .global sender  @ function


@ sender
@ function to snd data.
@ Calling sequence:
@       bl sender

sender:
@ socket section to start the TCP/IP connection
mov r7,#281                 @ sys_call socket
mov r0,#2                   @ data stream TCP/IP
mov r1,#1                   @ data gram
mov r2,#0                   @ flags
swi 0                       @ interrupt
mov r3, r0                  @ save the socket descripter in r3

@ This is used to connect in the protocal
ldr   r1,= struct_sock_addr @ loading struct address 
strb  r2, [r1, #1]          @ port number 
mov   r2, #16               @ len of the struct
add   r7, #2                @ sys_call_number
swi 0                       @ interrupt

@ this is used to send given message 
mov r7,#289 @ send          @ sys_call for send
mov r0,r3                   @ socket which was made to r0 
ldr r1,=message             @ load message address
mov r2,#17 @len_of _mess    @ len of the message = 17
mov r3,#0                   @ flag = 0
swi 0                       @ interrupt
bx      lr 

.section .data
        message:
	        .asciz	"vibration detected\n" @ meassage
        struct_sock_addr:                   
            .ascii "\x02\xff"              @ 2 protocal number
            .ascii "\x11\x5c"              @ port 4046
            .byte  192,168,1,3             @ ip address of server