/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* Création d'une première fenêtre X11        */
/*********************************************/
/*constantes                                 */
/********************************************/
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../../asm/ficmacros.s"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne: .asciz  "\n"
szMessDebutPgm: 	.asciz "Début du programme. \n"
szMessErreur: .asciz "Serveur X non trouvé.\n"
szMessErreurX11: .asciz  "Erreur fonction X11. \n"
szMessErrfen: .asciz "Création fenetre impossible.\n"

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
ptDisplay:  .skip 4      /* pointeur vers Display */
ptEcranDef: .skip 4   /* pointeur vers l'écran par defaut */
ptFenetre: .skip 4      /* pointeur vers la fenêtre */
event: .skip 400      /* revoir cette taille */

buffer:  .skip 500 

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text           
.global main      /* 'main' point d'entrée doit être  global */

main:             /* programme principal */
    push {fp,lr}    /* save des  2 registres */
	add fp,sp,#8    /* fp <- adresse début */
	ldr r0,iAdrszMessDebutPgm   /* r0 ← adresse message debut */
	bl affichageMess  /* affichage message dans console   */
	/*ouverture du serveur X */
	mov r0,#0
	bl XOpenDisplay
	cmp r0,#0
	beq erreurServeur
	/*  Ok retour zone display */
	ldr r1,iAdrptDisplay
	str r0,[r1]   @ stockage adresse du DISPLAY 
	mov r10,r0     @ mais aussi dans le registre r10
	/* recup ecran par defaut */
	ldr r2,[r0,#+132]     @ situé à la 132 position 
	ldr r1,iAdrptEcranDef
	str r2,[r1]         @stockage   default_screen
	mov r2,r0
	ldr r0,[r2,#+140]    @ pointeur de la liste des écrans
	@zones ecran
	ldr r5,[r0,#+52]  @ white pixel
	ldr r3,[r0,#+56]  @ black pixel
	ldr r4,[r0,#+36]  @ bits par pixel
	ldr r1,[r0,#+8]   @ root windows
	vidregtit valeurs_ecran
	
	/* CREATION DE LA FENETRE       */
	mov r0,r10          @display
	mov r2,#0           @ position X 
	mov r3,#0           @ position Y
	mov r8,#0           @ alignement pile
	push {r8}
	push {r5}          @ couleur du fond  white pixel
	push {r3}          @ couleur de la bordure black pixel
	mov r8,#5          @ taille de la bordure  mais  à verifier
	push {r8}
	mov r8,#400        @ hauteur
	push {r8}
	mov r8,#600        @ largeur 
	push {r8}   
	bl XCreateSimpleWindow
	add sp,#24     @ remise à niveau pile car 6 push
	cmp r0,#0
	beq erreurF
	
	ldr r1,iAdrptFenetre
	str r0,[r1]       @ stockage adresse fenetre 
	
	/* affichage de la fenetre */
	mov r1,r0            @ adresse fenetre
	mov r0,r10           @ adresse du display
	bl XMapWindow
	cmp r0,#0
	blt erreurX11
1:	
	/* boucle des evenements */
	mov r0,r10           @ adresse du display
	ldr r1,iAdrevent     @ adresse evenements
	bl XNextEvent
	b 1b
	
	b 100f   /* saut vers fin normale du programme */
erreurF:
	   /* erreur creation fenêtre mais ne sert peut être à rien car erreur directe X11  */
	ldr r1,iAdrszMessErrfen   /* r0 ← adresse chaine */
    bl   afficheerreur   /*appel affichage message  */		
	mov r0,#1       /* code erreur */
	b 100f
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
100:	/* fin de programme standard  */
	pop {fp,lr}   /* restaur des  2 registres */
	mov r0,#0     /* code retour  */
	mov r7, #EXIT /* appel fonction systeme pour terminer */
    swi 0 
iAdrptDisplay:  .int ptDisplay
iAdrptEcranDef: .int ptEcranDef
iAdrptFenetre: .int ptFenetre
iAdrevent:     .int event
iAdrszMessDebutPgm: .int szMessDebutPgm
iAdrszMessErreurX11: .int szMessErreurX11
iAdrszMessErreur: .int szMessErreur
iAdrszMessErrfen: .int szMessErrfen
/************************************/	   
/*********************************************/
/*constantes */
/********************************************/
.include "../../asm/constantesARM.inc"


	