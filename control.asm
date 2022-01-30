@ Constants for assembler
        .equ    PERIPH,0x3f000000   		@ RPi 2 & 3 peripherals
        .equ    GPIO_OFFSET,0x200000  		@ start of GPIO device

@ The following are defined in /usr/include/asm-generic/fcntl.h:
@ Note that the values are specified in octal.
        .equ    O_RDWR,00000002   		@ open for read/write
        .equ    O_DSYNC,00010000
        .equ    __O_SYNC,04000000
        .equ    O_SYNC,__O_SYNC|O_DSYNC

@ The following are defined in /usr/include/asm-generic/mman-common.h:
        .equ    PROT_READ,0x1   		@ page can be read
        .equ    PROT_WRITE,0x2  		@ page can be written
        .equ    MAP_SHARED,0x01 		@ share changes

@ The following are defined by me:
        .equ    O_FLAGS,O_RDWR|O_SYNC 	@ open file flags
        .equ    PROT_RDWR,PROT_READ|PROT_WRITE
        .equ    NO_PREF,0
        .equ    PAGE_SIZE,4096  		@ Raspbian memory page
        .equ    INPUT,0         		@ use pin for input
        .equ    OUTPUT,1        		@ use pin for ouput
        .equ    PIN_BTN,17        		@ button pin
	.equ	MAX, 10				@ maximum value of the counter

@ Constant program data
        .section .rodata
        .align  2
device:
        .asciz  "/dev/gpiomem"
devErr:
        .asciz  "Cannot open /dev/gpiomem\n"
memErr:
        .asciz  "Cannot map /dev/gpiomem\n"
message:
	.asciz	"vibration detected \n"


@ The program
        .text
        .align  2
        .global main
        .type   main, %function
main:
	push	{r4, r5, r6, r7, r8, lr}

@ Open /dev/gpiomem for read/write and syncing        
        ldr     r0, deviceAddr  		@ address of /dev/gpiomem
        ldr     r1, openMode    		@ flags for accessing device
        bl      open
        cmp     r0, #-1          		@ check for error
        bne     gpiomemOK       		@ no error, continue
        ldr     r0, devErrAddr  		@ error, tell user
        bl      printf
        b       allDone         		@ and end program
        
gpiomemOK:      
        mov     r4, r0          		@ use r4 for file descriptor

@ Map the GPIO registers to a main memory location so we can access them
        ldr	r5, gpio			@ address of the GPIO
	push	{r4, r5}
        mov     r0, #NO_PREF     		@ let kernel pick memory
        mov     r1, #PAGE_SIZE   		@ get 1 page of memory
        mov     r2, #PROT_RDWR   		@ read/write this memory
        mov     r3, #MAP_SHARED  		@ share with other processes
        bl      mmap
	pop	{r4, r5}
        cmp     r0, #-1          		@ check for error
        bne     mmapOK          		@ no error, continue
        ldr     r0, memErrAddr 			@ error, tell user
        bl      printf
        b       closeDev        		@ and close /dev/gpiomem
        
@ All OK, configure 
mmapOK:        
        mov     r5, r0          		@ use r5 for programming memory address
        mov     r0, r5          		@ programming memory
        mov     r1, #PIN_BTN       		@ pin
        mov     r2, #INPUT     			@ it's an input
        bl      gpioPinFSelect  		@ select function

@ Initialization  of the current and old level of the pin	
	mov     r6, #10
        mov 	r8, #0				@ r8= current level of the pin 
	mov 	r7, #0				@ r7= old level of the pin
	
countLoop:

readAgain:
	ldr	r0, =1				
	bl	usleep
		
	mov 	r7, r8				@ save old level of the pin in r7
	
	mov 	r0, r5				@ GPIO programming memory
	mov 	r1,#PIN_BTN			@ pin to read
	bl 	gpioPinRead	

@ If a rising edge is detected
@ Rising edge(transition from 0 to 1): _|¯
	mov 	r8, r0				@ r8=new level of the pin
	cmp	r8, #1		 		@ r8=1 if high		
	cmpeq	r7, #0				
	bne	readAgain			@ if not rising edge
	bl sender
        subs    r6, r6, #1       		@ decrement counter
        bgt     countLoop          		@ loop until 0


unmap:        
        mov     r0, r5          		@ memory to unmap
        mov     r1, #PAGE_SIZE   		@ amount we mapped
        bl      munmap          		@ unmap it

closeDev:
        mov     r0, r4          		@ /dev/gpiomem file descriptor
        bl      close           		@ close the file

allDone:        
        mov     r0, #0           		@ return 0;
	pop	{r4, r5, r6, r7, r8, lr}
        bx      lr              		@ return
        
        .align  2

@ addresses of messages
deviceAddr:
        .word   device
openMode:
        .word   O_FLAGS
gpio:
        .word   PERIPH+GPIO_OFFSET
devErrAddr:
        .word   devErr
memErrAddr:
        .word   memErr
messageAddr:
	.word	message