/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */

/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "src/ficmacros.s"

/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessage: 			.asciz "Debut démarrage Raspberry V1.c.\n\r"
szMessageFin:	.asciz "Fin normale du programme. Vous pouvez éteindre le Raspberry. \n\r"
szMessageCommande:	.asciz "Taper une commande : \n\r"
szLigneEtoiles: .fill 79,1,'*'
                    .asciz " "

/* libellés des commandes */
szLibComFin:  		.asciz "fin"

/*******************************************/
/* DONNEES INITIALISEES A ZERO             */
/*******************************************/ 
.bss
sBuffer:  .skip 100

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global kernel_main      /* 'kernel_main' point d'entrée doit être  global */

/***************************************************/
/*   PROGRAMME PRINCIPAL                           */
/***************************************************/

kernel_main:

	bl uart_init         @ initialisation mini uart

	ldr r0,iAdrszMessage
	bl uart_send_string @ envoi du message
	@ test affichage contenu du registre r0
	mov r1,#16
	bl vidregistre
	@ pour voir l'adresse de la pile
	mov r0,sp
	mov r1,#16
	bl vidregistre
	vidregtit test1  @ appel macro vidage tous les registres
	mrs r0,cpsr        @ move du registre d'état  dans r0 
	mov r1,#2
	bl vidregistre
	ldr r0,=.data
	vidmemtit test2 r0 4  @ appel macro vidage mémoire
	
1:   @ debut de boucle des commandes
	ldr r0,iAdrszMessageCommande
	bl uart_send_string
	
	ldr r0,iAdrsBuffer
	bl lectureChaine
	
	ldr r0,iAdrsBuffer
	vidmemtit vidagebuffer r0 5
	ldr r0,iAdrsBuffer
	ldr r1,iAdrszLibComFin
	bl comparaison
	cmp r0,#0
	beq 2f  @ fin des commandes
	@ ici suite des tests autres commandes
	
	b 1b  @ et boucle
2:
	@ ici l'opérateur à tapé fin et il faut finaliser les tâches !!!
	
	@ fin sur l'envoi du message final
	ldr r0,iAdrszLigneEtoiles
	bl uart_send_string
	ldr r0,iAdrszMessageFin
	bl uart_send_string
	ldr r0,iAdrszLigneEtoiles
	bl uart_send_string
	
3: @ boucle finale, le raspberry ne fait plus rien
	b 3b
	


iAdrszMessage: 				.int szMessage
iAdrszMessageFin:			.int szMessageFin
iAdrszMessageCommande: 	.int szMessageCommande
iAdrszLibComFin:			.int szLibComFin
iAdrsBuffer:					.int sBuffer
iAdrszLigneEtoiles:		.int szLigneEtoiles
