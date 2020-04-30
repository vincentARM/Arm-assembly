/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* création fenetre X11 avec fonction XCreateWindow */
/* centrage de la fenêtre  et changement de la couleur de ligne */
/*********************************************/
/*constantes                                 */
/********************************************/
@ le ficher des constantes générales est en fin du programme
.equ LARGEUR, 600    @ largeur de la fenêtre
.equ HAUTEUR, 400    @ hauteur de la fenêtre
.equ LGBUFFER, 100   @ longueur du biffer 
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../../asm/ficmacros.s"
/***********************************/
/* description des structures */
/***********************************/
.include "../../asm/descStruct.inc"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szNomFenetre: .asciz "Fenetre Raspberry"
szRetourligne: .asciz  "\n"
szMessDebutPgm: 	.asciz "Début du programme. \n"
szMessFinPgm:	.asciz "Fin normale du programme. \n" 
szMessErreur: .asciz "Serveur X non trouvé.\n"
szMessErrfen: .asciz "Création fenetre impossible.\n"
szMessErreurX11: .asciz  "Erreur fonction X11. \n"
szMessErrGc: .asciz "Création contexte graphique impossible.\n"
szTitreFenRed: .asciz "Pi"    
szTexte1: .asciz "Ceci est mon premier texte."
.equ LGTEXTE1, . - szTexte1
/* libellé special pour correction pb fermeture */
szLibDW: .asciz "WM_DELETE_WINDOW"
.align 4
/* liste de noms */
ListeNom:  .int szNomFenetre    @ necessaire pour maj du titre
hauteur: .int HAUTEUR
largeur: .int LARGEUR

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
ptDisplay:  .skip 4     @ pointeur display
ptEcranDef: .skip 4     @ pointeur ecarn par défaut
ptFenetre: .skip 4      @ pointeur fenêtre
ptGC:        .skip 4      @ pointeur contexte graphique
ptGC1:        .skip 4      @ pointeur contexte graphique 1
key: .skip 4              @ code touche
wmDeleteMessage: .skip 8   /* identification message de fermeture */ 
event: .skip 400      /* revoir cette taille */
PrpNomFenetre: .skip 100  @ proprieté titre de la fenêtre
buffer:  .skip LGBUFFER 
iWhite: .skip 4
iBlack: .skip 4
.align 4
stAttributs:  .skip Att_fin        @ reservation place structure Attibuts 
.align 4
stXGCValues:  .skip XGC_fin        @ reservation place structure XGCValues
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
	/* attention r6  pointeur display*/
	/* attention r7  pointeur ecran   */
	/* attention r8  pointeur contexte graphique   */
	/* attention r9 identification fenêtre */
	/*ouverture du serveur X */
	mov r0,#0
	bl XOpenDisplay
	cmp r0,#0
	beq erreurServeur
	ldr r1,iAdrptDisplay
	str r0,[r1]     @ stockage adresse du DISPLAY 
	mov r6,r0       @ mais aussi dans le registre r6
	@ recup ecran par defaut
	ldr r2,[r0,#Disp_default_screen]
	ldr r1,iAdrptEcranDef
	str r2,[r1]    @stockage   default_screen
	mov r3,r0
	ldr r0,[r3,#Disp_screens]    @ pointeur de la liste des écrans
    add r7,r0,r2,lsl #2                @ récup du pointeur de l'écran par defaut

	@zones ecran
	ldr r5,[r7,#Screen_white_pixel]  @ white pixel
	ldr r4,iAdriWhite
	str r5,[r4]
	ldr r3,[r7,#Screen_black_pixel]  @ black pixel
	ldr r4,iAdriBlack
	str r3,[r4]
	
	/* Préparation des attributs de la fenêtre */
	ldr r2,iAdrstAttributs
	ldr r3,iAdriWhite
	ldr r3,[r3]
	str r3,[r2,#Att_background_pixel]
	ldr r3,iAdriBlack
	ldr r3,[r3]
	str r3,[r2,#Att_border_pixel]
	ldr r3,iAttMask
	str r3,[r2,#Att_event_mask]
	
	@ calcul de la position X pour centrer la fenetre
	@  ne fonctionne pas !!!!
	ldr r2,[r7,#Screen_width]   @ récupération de la largeur de l'écran racine
	sub r2,#LARGEUR              @ soustraction de la largeur de notre fenêtre
	lsr r2,#1                      @ division par 2 et résultat pour le parametre 3
	ldr r3,[r7,#Screen_height]  @ récupération de la hauteur de l'écran racine
	sub r3,#HAUTEUR               @ soustraction de la hauteur de notre fenêtre
	lsr r3,#1                       @ division par 2 et résultat pour le parametre 4
	vidregtit prepecran
	
	/* CREATION DE LA FENETRE */
	mov r0,r6          @ display
	ldr r1,[r7,#Screen_root]  @ identification écran racine

	ldr r8,iAdrstAttributs
	push {r8}
	ldr r8,iValeurMask
	push {r8}
	ldr r8,[r7,#Screen_root_visual]
	push {r8}
	mov r8,#0      @ VERIFIER CETTE VALEUR SI PB (InputOutput, InputOnly)
	push {r8}      @ car pas trouvé les valeurs de ces codifications
	ldr r8,[r7,#Screen_root_depth]  @ bits par pixel
	push {r8}
	mov r8,#2      @ bordure
	push {r8}
	mov r8,#HAUTEUR       @ hauteur
	push {r8}
	mov r8,#LARGEUR     @ largeur 
	push {r8}   
	bl XCreateWindow
	add sp,#32     @ remise à niveau pile car 8 push
	cmp r0,#0
	beq erreurF
	
	ldr r1,iAdrptFenetre
	str r0,[r1]    @ stockage adresse fenetre
	mov r9,r0      @ et aussi dans le registre r9
	
	//vidmemtit fenetre r0 2
	
		/* ajout de proprietes de la fenêtre */
	mov r0,r6          /* adresse du display */
	mov r1,r9          /* adresse fenetre */
	ldr r2,iAdrszNomFenetre   @ titre de la fenêtre */
	ldr r3,iAdrszTitreFenRed  @ titre de la fenêtre reduite 
	mov r4,#0
	push {r4}          /* TODO à voir */
	push {r4}
	push {r4}
	push {r4}
	bl XSetStandardProperties
	add sp,sp,#16   @ pour les 4 push

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
	
	/*  creation du contexte graphique */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse fenetre
	mov r2,#0
	mov r3,#0
	bl XCreateGC
	cmp r0,#0
	beq erreurGC	
	ldr r1,iAdrptGC
	str r0,[r1]   @ stockage adresse contexte graphique 
	mov r8,r0     @ et dans r8   
	
	/*creation  autre contexte graphique */
	mov r0,r6          @ adresse du display 
	mov r1,r9          @ adresse fenetre 
	ldr r2,iGC1mask   @ identifie les zones de XGCValues à mettre à jour */
	ldr r4,iRouge  /* Couleur dutexte du contexte graphique */
	ldr r3,iAdrstXGCValues  /* maj dans la zone de XGCValues */
	str r4,[r3,#XGC_foreground]
	mov r4,#1              @ ligne en pointillé 
	str r4,[r3,#XGC_line_style]
	mov r4,#4                 @ largeur de la ligne
	str r4,[r3,#XGC_line_width]
	ldr r3,iAdrstXGCValues   /* la zone complete est passée en paramètre */
	bl XCreateGC
	cmp r0,#0
	beq erreurGC	
	ldr r1,iAdrptGC1
	str r0,[r1]   /* stockage adresse contexte graphique dans zone gc1 */
	vidregtit creationGC1
	ldr r0,iAdrstXGCValues
	vidmemtit GCValues r0 2
	
	/* modif du fond de fenêtre */
	mov r0,r6          @ adresse du display 
	mov r1,r9             @ adresse fenêtre 
	ldr r2,iGris1         @ couleur du fond 
	bl XSetWindowBackground   
	cmp r0,#0
	ble erreurX11
	
	/* affichage de la fenetre */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse fenetre
	bl XMapWindow
	
		@ calcul de la position X et Y pour centrer la fenetre
		@ et ça fonctionne !!!
	ldr r2,[r7,#Screen_width]   
	sub r2,#LARGEUR
	lsr r2,#1
	ldr r3,[r7,#Screen_height]
	sub r3,#HAUTEUR
	lsr r3,#1
	mov r0,r6          /* adresse du display */
	mov r1,r9          /* adresse fenetre */
	bl XMoveWindow
	
	/* ecriture de texte dans la fenetre */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	mov r2,r8          @ adresse du contexte graphique 
	mov r3,#50          @ position x 
	sub sp,#4      @ alignement pile
	mov r4,#LGTEXTE1  - 1     @ longueur de la chaine a ecrire 
	push {r4}                @ passé en paramètre sur la pilé
	ldr r4,=szTexte1       @ adresse du texte a afficher 
	push {r4}
	mov r4,#20              @ position y 
	push {r4}
	bl XDrawString
	add sp,sp,#16      @ pour les 3 push et l'alignement pile
	cmp r0,#0
	blt erreurX11
		/* dessin d'une ligne */
	bl dessinLigne
   /* dessin d'un rectangle */
	bl dessinRectangle

	/* autorisation des saisies */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	ldr r2,iFenetreMask    @ masque pour autoriser saisies
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
	ldr r1,iAdrbuffer      @ buffer
	mov r2,#LGBUFFER        @ longueur du buffer
	ldr r3,iAdrkey          @ zone code de la touche appuyée
	mov r4,#0                 @ argument NULL
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
	beq 7f
	b 6f
2:	
	cmp r0,#ButtonPress   @ cas d'un clic sur un bouton souris
	bne 3f
	ldr r0,iAdrevent     @ evenement de type XButtonEvent
	ldr r1,[r0,#XBE_x]    @ position X du clic souris
	ldr r2,[r0,#XBE_y]    @ position Y
    vidregtit souris
	b 6f
3:
	cmp r0,#ClientMessage   @ cas pour fermeture fenetre sans erreur
	bne 4f
	ldr r0,iAdrevent      @ evenement de type XClientMessageEvent
	ldr r1,[r0,#XClient_data]   @ position code message
	ldr r2,iAdrwmDeleteMessage
	ldr r2,[r2]
	cmp r1,r2
	beq 7f
	b 6f
4:
	cmp r0,#ConfigureNotify   /* cas pour modification de la fenetre */
	bne 6f
	
	ldr r0,iAdrevent
	ldr r1,[r0,#+XConfigureEvent_height]
	ldr r2,iAdrhauteur
	ldr r2,[r2]
	cmp r1,r2     @ modification de la hauteur ?
	beq 5f
	bl dessinLigne
	bl dessinRectangle
5:
    ldr r0,iAdrevent
	ldr r1,[r0,#+XConfigureEvent_width]
	ldr r2,iAdrlargeur
	ldr r2,[r2]
	cmp r1,r2     @ modification de la largeur ?
	beq 6f
	bl dessinLigne
	bl dessinRectangle
	b 6f
6:  @ boucle sur autre evenement
	b 1b
7:	 @ liberation des ressources   
	mov r0,r6          @ adresse du display 
	ldr r1,iAdrptGC
	ldr r1,[r1]        @ adresse du contexte 
	bl XFreeGC
	cmp r0,#0
	blt erreurX11
	mov r0,r6          @ adresse du display 
	ldr r1,iAdrptGC1
	ldr r1,[r1]        @ adresse du contexte 
	bl XFreeGC
	cmp r0,#0
	blt erreurX11
	mov r0,r6          @ adresse du display 
	mov r1,r9          @ adresse de la fenetre 
	bl XDestroyWindow
	cmp r0,#0
	blt erreurX11
	mov r0,r6
	bl XCloseDisplay
	cmp r0,#0
	blt erreurX11
	ldr r0,iAdrszMessFinPgm   @ fin programme OK
	bl affichageMess  @ affichage message dans console   
	mov r0,#0     @ code retour OK  
	b 100f
erreurF:
	   /* erreur creation fenêtre mais ne sert peut être à rien car erreur directe X11  */
	ldr r1,iAdrszMessErrfen   /* r0 ← adresse chaine */
    bl   afficheerreur   /*appel affichage message  */		
	mov r0,#1       /* code erreur */
	b 100f
erreurGC:
	   /* erreur creation contexte graphique  */
	ldr r1,iAdrszMessErrGc   /* r0 ← adresse chaine */
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
iAttMask: .int ExposureMask | StructureNotifyMask 
iFenetreMask: 	.int  KeyPressMask|ButtonPressMask|StructureNotifyMask
iValeurMask: .int CWBackPixel | CWBorderPixel | CWEventMask
iAdriWhite: .int iWhite
iAdriBlack:  .int iBlack
iGris1: 			.int 0xFFA0A0A0
iRouge: 			.int 0xFFFF0000
iAdrptDisplay:  .int ptDisplay
iAdrptEcranDef: .int ptEcranDef
iAdrptFenetre: .int ptFenetre
iAdrptGC:   .int ptGC
iAdrptGC1:   .int ptGC1
iAdrevent:     .int event
iAdrbuffer:     .int buffer
iAdrkey:         .int key
iAdrstAttributs:  .int stAttributs
iAdrszLibDW:   .int szLibDW
iAdrszMessDebutPgm: .int szMessDebutPgm
iAdrszMessFinPgm: .int szMessFinPgm
iAdrszMessErreurX11: .int szMessErreurX11
iAdrszMessErrGc: .int szMessErrGc
iAdrszMessErreur: .int szMessErreur
iAdrszMessErrfen: .int szMessErrfen
iAdrszNomFenetre: .int  szNomFenetre
iAdrszTitreFenRed: .int szTitreFenRed
iAdrListeNom: .int ListeNom
iAdrPrpNomFenetre: .int PrpNomFenetre
iAdrwmDeleteMessage: .int wmDeleteMessage
iAdrhauteur: .int hauteur
iAdrlargeur: .int largeur
iGC1mask: .int GCLine_width|GCLine_style|GCForeground
iAdrstXGCValues: .int stXGCValues

/********************************************************************/
/*   Dessin d'une ligne droite                                    ***/
/********************************************************************/
@ pas de sauvegarde des registres
dessinLigne:
	push {fp,lr}      @ save des  2 registres 
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	ldr r2,iAdrptGC1  @ adresse du contexte graphique 1
	ldr r2,[r2]
	//mov r2,r8          @ adresse du contexte graphique 
	mov r3,#50         @ position x 
	sub sp,sp,#4
	mov r4,#250        @ position y1 
	push {r4}          @en parametre 
	mov r4,#150        @ position x1 
	push {r4}
	mov r4,#100        @ position y 
	push {r4}
	bl XDrawLine
	add sp,sp,#16       @ pour les 3 push et l'alignement
	100:
    pop {fp,lr}
    bx lr        	
/********************************************************************/
/*   Dessin d'un rectangle                                        ***/
/********************************************************************/
@ pas de sauvegarde des registres
dessinRectangle:
	push {fp,lr}      @ save des  2 registres 
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	mov r2,r8          @ adresse du contexte graphique 
	mov r3,#180        @ position x 
	sub sp,sp,#4
	mov r4,#250        @ position y1 
	push {r4}          @ en parametre 
	mov r4,#250        @ position x1 
	push {r4}
	mov r4,#120        @ position y 
	push {r4}
	bl XFillRectangle
	add sp,sp,#16     @ pour les 3 push et l'alignement
100:
    pop {fp,lr}
    bx lr        	

/*********************************************************************/
/* constantes Générales              */
.include "../../asm/constantesARM.inc"
	