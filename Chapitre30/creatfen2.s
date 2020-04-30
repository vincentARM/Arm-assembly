/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* fenetre X11 avec gestion des evenements   */
/* correction du message d'erreur lors de la fermeture de la fenêtre */
/*********************************************/
/*constantes */
/********************************************/
@ le ficher des constantes générales est en fin du programme
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../../asm/ficmacros.s"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szNomFenetre: .asciz "Fenetre 1"
szRetourligne: .asciz  "\n"
szMessDebutPgm: 	.asciz "Début du programme. \n"
szMessErreur: .asciz "Serveur X non trouvé.\n"
szMessErrfen: .asciz "Création fenetre impossible.\n"
szMessErreurX11: .asciz  "Erreur fonction X11. \n"
/* libellé special pour correction pb fermeture */
szLibDW: .asciz "WM_DELETE_WINDOW"
/* liste de noms */
ListeNom:  .int szNomFenetre    @ necessaire pour maj du titre

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
ptDisplay:  .skip 4     @ pointeur display
ptEcranDef: .skip 4     @ pointeur ecarn par défaut
ptFenetre: .skip 4      @ pointeur fenêtre
key: .skip 4              @ code touche
wmDeleteMessage: .skip 8   /* identification message de fermeture */ 
event: .skip 400      /* revoir cette taille */
PrpNomFenetre: .skip 100  @ proprieté titre de la fenêtre
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
	/* attention r7 sert de compteur  */
	// mov r7,#0
	/*ouverture du serveur X */
	mov r0,#0
	bl XOpenDisplay
	cmp r0,#0
	beq erreurServeur
	ldr r1,iAdrptDisplay
	str r0,[r1]     @ stockage adresse du DISPLAY 
	mov r6,r0       @ mais aussi dans le registre r6
	@ recup ecran par defaut
	ldr r2,[r0,#+132]
	ldr r1,iAdrptEcranDef
	str r2,[r1]    @stockage   default_screen
	mov r2,r0
	ldr r0,[r2,#+140]    @ pointeur de la liste des écrans

	@zones ecran
	ldr r5,[r0,#+52]  @ white pixel
	ldr r3,[r0,#+56]  @ black pixel
	ldr r4,[r0,#+28]  @ bits par pixel
	ldr r1,[r0,#+8]  @ root windows
	vidregtit ecran
	/* CREATION DE LA FENETRE */
	mov r0,r6          @ display
	mov r2,#20         @ position X
	mov r3,#50         @ position Y
	mov r8,#0       @ alignement pile
	push {r8}
	push {r3}       @  fond  = black pixel
	push {r5}      @   bordure = white pixel
	mov r8,#2      @ bordure
	push {r8}
	mov r8,#400       @ hauteur
	push {r8}
	mov r8,#600     @ largeur 
	push {r8}   
	bl XCreateSimpleWindow
	add sp,#24     @ remise à niveau pile car 6 push
	cmp r0,#0
	beq erreurF
	
	ldr r1,iAdrptFenetre
	str r0,[r1]    @ stockage adresse fenetre
	mov r9,r0      @ et aussi dans le registre r9
	@ mise à jour du titre de la fenêtre
	ldr r0,iAdrListeNom    @ contient le nom sous forme de chaine de caractères
	mov r1,#1
	ldr r2,iAdrPrpNomFenetre
	bl XStringListToTextProperty   @ transforme le nom en propietés !!
	mov r0,r6     @ adresse du display
	mov r1,r9     @ adresse de la fenetre
	ldr r2,iAdrPrpNomFenetre
	bl XSetWMName                @ met à jour le titre de la fenêtre 
	
	/* Correction erreur fermeture fenetre */
	mov r0,r6             @ adresse du display
	ldr r1,iAdrszLibDW        @ adresse nom de l'atome
	mov r2,#1                    @ False  création de l'atome s'il n'existe pas
	bl XInternAtom
	cmp r0,#0
	ble erreurX11
	ldr r1,iAdrwmDeleteMessage  @ adresse de reception
	str r0,[r1]
	mov r2,r1          @ adresse zone retour precedente
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse fenetre
	mov r3,#1          @ nombre de protocoles 
	bl XSetWMProtocols
	cmp r0,#0
	ble erreurX11
	/* affichage de la fenetre */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse fenetre
	bl XMapWindow

	/* autorisation des saisies */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	ldr r2,iFenetreMask    @ masque pour autoriser saisies KeyPressMask et ButtonPressMask
	vidregtit imput
	bl XSelectInput
	cmp r0,#0
	ble erreurX11
	
1:	/* boucle des évenements */
	mov r0,r6            @ adresse du display
	ldr r1,iAdrevent         @ adresse evenements
	bl XNextEvent
	ldr r0,iAdrevent
	vidmemtit ApresEvent r0 4
	ldr r0,iAdrevent
	ldr r0,[r0]
	cmp r0,#KeyPressed
	bne 2f
	/* cas d'une touche */
	ldr r0,iAdrevent
	ldr r1,iAdrbuffer
	mov r2,#255
	ldr r3,iAdrkey
	mov r4,#0
	push {r4}    @ alignement pile
	push {r4}
	bl XLookupString 
	add sp,#8     @ remise à niveau pile car 2 push
	vidregtit lookup
	cmp r0,#1           /* touche caractères */
	bne 2f
	ldr r0,iAdrbuffer
	vidmemtit saisiecle r0 4

	ldr r0,iAdrbuffer
	ldrb r0,[r0]
	cmp r0,#0x71     @ caractere q   pour quitter
	beq 5f
	b 4f
2:	
	cmp r0,#ButtonPress   @ cas d'un clic sur un bouton souris
	bne 3f
	ldr r0,iAdrevent
	ldr r1,[r0,#+32]    @ position X du clic souris
	ldr r2,[r0,#+36]    @ position Y
    vidregtit souris
	b 4f
3:
	cmp r0,#ClientMessage   @ cas pour fermeture fenetre sans erreur
	bne 4f
	ldr r0,iAdrevent
	ldr r1,[r0,#+28]   @ position code message
	ldr r2,iAdrwmDeleteMessage
	ldr r2,[r2]
	cmp r1,r2
	beq 5f
	//add r7,r7,#1     @comptage fermeture
	//cmp r7,#1
	//b 5f         @ fin du programme
4:	  @ boucle sur autre evenement
	b 1b
5:	@ fermeture de la fenêtre donc fermeture de la connexion
	vidregtit fin
	mov r0,r6
	bl XCloseDisplay
	cmp r0,#0
	blt erreurX11
	
	mov r0,#0     /* code retour OK  */
	b 100f
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

100:		/* fin de programme standard  */
	pop {fp,lr}   /* restaur des  2 registres */
	mov r7, #EXIT /* appel fonction systeme pour terminer */
    swi 0 
iFenetreMask: .int  KeyPressMask|ButtonPressMask
iAdrptDisplay:  .int ptDisplay
iAdrptEcranDef: .int ptEcranDef
iAdrptFenetre: .int ptFenetre
iAdrevent:     .int event
iAdrbuffer:     .int buffer
iAdrkey:         .int key
iAdrszLibDW:   .int szLibDW
iAdrszMessDebutPgm: .int szMessDebutPgm
iAdrszMessErreurX11: .int szMessErreurX11
iAdrszMessErreur: .int szMessErreur
iAdrszMessErrfen: .int szMessErrfen
iAdrListeNom: .int ListeNom
iAdrPrpNomFenetre: .int PrpNomFenetre
iAdrwmDeleteMessage: .int wmDeleteMessage
/*********************************************************************/
/* constantes Générales              */
.include "../../asm/constantesARM.inc"
	