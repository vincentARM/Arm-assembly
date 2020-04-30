/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */

/* Fonctions de la mini uart raspberry pi 1 B   */
/* Attention utilisation exclusive pour developpement hors raspbian */
/*********************************************/
/*           CONSTANTES                      */
/********************************************/
.include "src/constantes.inc"
/*********************************************/
/*constantes particulières au programme     */
/********************************************/
.equ AUX_ENABLES,     0x0004
.equ AUX_MU_IO_REG,   0x0040
.equ AUX_MU_IER_REG,  0x0044
.equ AUX_MU_IIR_REG,  0x0048
.equ AUX_MU_LCR_REG,  0x004C
.equ AUX_MU_MCR_REG,  0x0050
.equ AUX_MU_LSR_REG,  0x0054
.equ AUX_MU_MSR_REG,  0x0058
.equ AUX_MU_SCRATCH,  0x005C
.equ AUX_MU_CNTL_REG, 0x0060
.equ AUX_MU_STAT_REG, 0x0064
.equ AUX_MU_BAUD_REG, 0x0068



/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
@ les fonctions doivent être globales
.global uart_recv,uart_send_string,uart_send,uart_init        

/***************************************/
/* Attention la pile doit être créee   */
/***************************************/

/***************************************************/
/*   Fonction reception              */
/***************************************************/
uart_recv:
	push {r1,r2,lr}    @ save des registres  
	ldr r0,iST_BASE_UART    @ adresse de base de la mini uart
	add r1,r0,#AUX_MU_LSR_REG
	add r2,r0,#AUX_MU_IO_REG
1:   @ début de boucle pour vérif donnée présente
	ldr r0,[r1]
	tst r0,#1
	beq 1b
	ldr r0,[r2]     @ si oui récupération donnée
	and r0,#0xFF   @ et un seul caractère
100:   /* fin standard de la fonction  */
   	pop {r1,r2,lr}   /* restaur des  registres  */
    bx lr                   /* retour de la fonction en utilisant lr  */
iST_BASE_UART: .int ST_BASE_UART
/***************************************************/
/*   Envoi chaine de caractères vers uart          */
/***************************************************/
/* r0 contient l'adresse du début de la chaine */
uart_send_string:
	push {r1,r2,lr}    @ save  3 registres
	mov r1,r0   			@ save adresse de la chaine
    mov r2,#0   				@ indice position caractère dans la chaine
1:      	@ boucle de balayage des caractères de la chaine
    ldrb r0,[r1,r2]  			@ lecture caractère base + position
    cmp r0,#0       			@ si égal à zéro, c'est terminé
	beq 100f
	bl uart_send              @ envoi caractère   registre r0
    add r2,r2,#1   			    @ caractère suivant
    b 1b          			    @ et boucle
	
100:   @ fin standard de la fonction  
   	pop {r1,r2,lr}   @ restaur des  3 registres  
    bx lr                   /* retour de la fonction en utilisant lr  */
/***************************************************/
/*   Envoi 1 caractère vers uart          */
/***************************************************/
/* r0 contient le caractère à envoyer */
uart_send:
	push {r1-r3,lr}    @ save registres
	ldr r2,iST_BASE_UART
	add r3,r2,#AUX_MU_LSR_REG
1:   @ boucle d'attente de l'état de l'uart
	ldr r1,[r3]
	tst r1,#0x20
	beq 1b
	
	add r3,r2,#AUX_MU_IO_REG
	str r0,[r3]         @ envoi du caractère
	
100: @ fin standard de la fonction  
   	pop {r1-r3,lr}   @ restaur des registres  
    bx lr                   @ retour de la fonction en utilisant lr  
	
/***************************************************/
/*   Initialisation uart          */
/***************************************************/
/* r0 contient l'adresse de base UART    */
/* r1 contient l'adresse de base du GPIO   */
uart_init:
	push {r1-r4,lr}    @ save registres
	ldr r3,iST_BASE_UART
	ldr r4,iST_BASE_GPIO
	mov r0,r4    @ Adresse de base du GPIO  
	mov r1,#14
	mov r2,#2       @ 010 = GPIO  takes alternate function 5
	bl selectPin
	mov r0,r4
	mov r1,#15
	mov r2,#2       @ 010 = GPIO  takes alternate function 5
	bl selectPin
	@
	mov r0,#0           @ 00 = Off – disable pull-up/down
	add r1,r4,#GPPUD 
	str r0,[r1]
	mov r0,#150
	bl delai
	
	ldr r0,iCodeFonction1
	add r1,r4,#GPPUDCLK0
	str r0,[r1]
	mov r0,#150
	bl delai
	
	mov r0,#0
	add r1,r4,#GPPUDCLK0
	str r0,[r1]

	mov r0,#1
	add r1,r3,#AUX_ENABLES  @Enable mini uart (this also enables access to it registers)
	str r0,[r1]

	mov r0,#0
	add r1,r3,#AUX_MU_CNTL_REG  @Disable auto flow control and disable receiver and transmitter (for now)
	str r0,[r1]
	
	mov r0,#0
	add r1,r3,#AUX_MU_IER_REG  @Disable receive and transmit interrupts
	str r0,[r1]
	
	mov r0,#3
	add r1,r3,#AUX_MU_LCR_REG  @Enable 8 bit mode
	str r0,[r1]
	
	mov r0,#0
	add r1,r3,#AUX_MU_MCR_REG  @Set RTS line to be always high
	str r0,[r1]
	
	ldr r0,iBaud
	add r1,r3,#AUX_MU_BAUD_REG  @Set baud rate to 115200
	str r0,[r1]
	
	mov r0,#3
	add r1,r3,#AUX_MU_CNTL_REG  @Finally, enable transmitter and receiver
	str r0,[r1]
	
100:   /* fin standard de la fonction  */
   	pop {r1-r4,lr}    @ save registres
    bx lr                   /* retour de la fonction en utilisant lr  */	
iST_BASE_GPIO: 		.int ST_BASE_GPIO
iCodeFonction: 		.int 2<<12
iCodeFonction1: 	.int 1<<14| 1<<15   @ valeurs ok
iBaud: 				.int 270             @ valeur pour 115200
iGPPUD:   			.int GPPUD
iGPPUDCLK0: 			.int GPPUDCLK0
iAUX_ENABLES:  		.int AUX_ENABLES
iAUX_MU_CNTL_REG: 	.int AUX_MU_CNTL_REG
iAUX_MU_IER_REG:  	.int AUX_MU_IER_REG
iAUX_MU_LCR_REG: 	.int AUX_MU_LCR_REG
iAUX_MU_MCR_REG: 	.int AUX_MU_MCR_REG
iAUX_MU_BAUD_REG: 	.int AUX_MU_BAUD_REG


/***************************************************/
/*   delai d'attente                               */
/***************************************************/
/* r0 contient le nombre de boucle d'attente   */
delai:
1:
	subs r0, r0, #1
	bgt 1b

    bx lr                   /* retour de la fonction en utilisant lr  */


	