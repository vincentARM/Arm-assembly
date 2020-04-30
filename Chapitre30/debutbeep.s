/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/*  */
/* premier test pour vérification serveur X11 */
/* XBell (mydisplay , 1 0 0 ) ; */
/*********************************************/
/*constantes */
/********************************************/
.include "../../asm/constantesARM.inc"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne: .asciz  "\n"
szMessErreur: .asciz "Serveur X non trouvé.\n"
szMessErreurX11: .asciz  "Erreur fonction X11. \n"
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
ptDisplay:  .skip 4      /* pointeur vers Display */

buffer:  .skip 500 

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text           
.global main      /* 'main' point d'entrée doit être  global */

main:             /* programme principal */
    push {fp,lr}    /* save des  2 registres */
	/*ouverture du serveur X */
	mov r0,#0
	bl XOpenDisplay
	cmp r0,#0
	ble erreurServeur
	/*  Ok retour zone display */
	ldr r1,iAdrptDisplay
	str r0,[r1]   @ stockage adresse du DISPLAY pour futur usage
	mov r1,#100
	bl XBell
	cmp r0,#0
	blt erreurX11
	ldr r1,iAdrptDisplay
	ldr r0,[r1]   @ récup du DISPLAY 
	bl XCloseDisplay  @ fermeture
	cmp r0,#0
	blt erreurX11
	ldr r0,iAdrptDisplay        
	ldr r0,[r0]  
	mov r1,#5  /* nombre de bloc a afficher */
    push {r0} /* adresse memoire */	
	push {r1}
    bl affmemoire

	b 100f   /* saut vers fin normale du programme */
erreurX11:    /* erreur X11  */
	ldr r1,iAdrszMessErreurX11   /* r1 ← adresse chaine */
    bl   afficheerreur   /*appel affichage message  */		
	mov r0,#1       /* code erreur */
	b 100f
erreurServeur:
	   /* erreur car pas de serveur X   (voir doc putty et serveur Xming )*/
	ldr r1,iAdrszMessErreur   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */		
	mov r0,#1       /* code erreur */
	b 100f	
100:		/* fin de programme standard  */
	pop {fp,lr}   /* restaur des  2 registres */
	mov r0,#0     /* code retour  */
	mov r7, #EXIT /* appel fonction systeme pour terminer */
    swi 0 
iAdrptDisplay:  .int ptDisplay
iAdrszMessErreurX11: .int szMessErreurX11
iAdrszMessErreur: .int szMessErreur
/************************************/	   
	