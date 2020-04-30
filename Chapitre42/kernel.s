/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* programme principal sans utilisation d 'OS  */ 

/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessage: 			.asciz "Debut démarrage Raspberry.\n\r"

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global kernel_main      /* 'kernel_main' point d'entrée doit être  global */

/***************************************************/
/*   test message pour mini uart                   */
/***************************************************/

kernel_main:

	bl uart_init         @ initialisation mini uart

	ldr r0,iAdrszMessage
	bl uart_send_string @ envoi du message

1:   @ boucle finale
	bl uart_recv           @ réception d'un caractère

	bl uart_send           @ puis envoi du caractère 
	b 1b

iAdrszMessage: 		.int szMessage

