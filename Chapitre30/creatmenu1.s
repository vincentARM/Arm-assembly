/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* création fenetre X11 avec gestion de menus */
/* dessin de cercle et polygone, fonctions du contexte graphique */
/*********************************************/
/*constantes                                 */
/********************************************/
@ le ficher des constantes générales est en fin du programme
.equ LARGEUR, 600    @ largeur de la fenêtre
.equ HAUTEUR, 400    @ hauteur de la fenêtre
.equ LGBUFFER, 100   @ longueur du buffer 
.equ HAUTEURMESSAGE,    200 @ hauteur de la fenêtre des messages
.equ LARGEURMESSAGE,    400 @ largeur de la fenêtre des messages
.equ POSLIGNE,       50   @ position de la ligne des menus
.equ SEPXMENU,       10   @ separation entre 2 menus principal
.equ HAUTMENU,       20   @ hauteur menu
.equ LARGMENU,       70   @ largeur menu
/* fonctions du Contexte Graphique */
.equ GXand,   				1
.equ GXandReverse, 		2
.equ GXcopy,				3
.equ GXandInverted,		4
.equ GXnoop,				5
.equ GXxor,				6
.equ GXor,					7
.equ GXnor,				8
.equ GXequiv,				9
.equ GXinvert,			10
.equ GXorReverse,		11
.equ GXcopyInverted,		12
.equ GXorInverted,		13
.equ GXnand,				14
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
szMessDebutPgm: 	.asciz "Debut du programme. \n"
szMessFinPgm:	.asciz "Fin normale du programme. \n" 
szMessErreur: .asciz "Serveur X non trouvé.\n"
szMessErrfen: .asciz "Création fenetre impossible.\n"
szMessErreurX11: .asciz  "Erreur fonction X11. \n"
szMessErrGc: .asciz "Création contexte graphique impossible.\n"
szMessErrGcBT: .asciz "Création contexte graphique Bouton impossible.\n"
szMessErrbt: .asciz "Création bouton impossible.\n"
szMessErrGPolice: .asciz "Chargement police impossible.\n"
szTitreFenRed: .asciz "Pi"   
szTitreFenRedS: .asciz "PiS"  
szTexteBoutonOK: .asciz "OK"
sTexteAide: .ascii "Programme de gestion de menus.  Version V1" 
.equ LGTEXTEAIDE, . - sTexteAide
/* libellé special pour correction pb fermeture */
szLibDW: .asciz "WM_DELETE_WINDOW"
.align 4
/* liste de noms */
hauteur: .int HAUTEUR
largeur: .int LARGEUR
szTexteBouton1: .asciz  "OK"
/* libellés des menus  */
szTexteMenu1: .asciz  "Fichier"
szTexteMenu1_1: .asciz  "Quitter"
szTexteMenu1_2: .asciz  "Cercle"
szTexteMenu1_3: .asciz  "Polygone"
szTexteMenu2: .asciz  "Fonction"
szTexteMenu2_1: .asciz  "GCxor"
szTexteMenu2_2: .asciz  "GCand"
szTexteMenu3: .asciz  "Aide"
/* polices de caracteres */
szNomPolice: .asciz  "-*-helvetica-bold-*-normal-*-14-*"
szNomPolice1: .asciz  "-*-fixed-bold-*-normal-*-14-*"
.align 4
PointsPoly:    	.hword 100,100
					.hword 100,250
					.hword 300,350
					.hword 480,250
					.hword 150,150
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
ptDisplay:  .skip 4     @ pointeur display
ptEcran: .skip 4     @ pointeur ecran standard
ptFenetre: .skip 4      @ pointeur fenêtre
ptFenetreM: .skip 4      @ pointeur fenêtre Message
ptGC:        .skip 4      @ pointeur contexte graphique
ptGC1:        .skip 4      @ pointeur contexte graphique 1
ptGC2:        .skip 4      @ pointeur contexte graphique 2
ptPolice:   .skip 4      @ pointeur police de caractères
ptPolice1:  .skip 4     @ pointeur police de caractères 1
key: .skip 4              @ code touche
iLongTexte: .skip 4
wmDeleteMessage: .skip 8   @ identification message de fermeture
@ données necessaire au calcul de la hauteur d'un texte
direction: .skip 4
font_ascent: .skip 4
font_descent:		.skip 4
overall:		.skip 4

event: .skip 400          @ TODO revoir cette taille 
buffer:  .skip LGBUFFER 

/* Structures des données */  
.align 4
stMenu1:  .skip BT_fin            @ reservation place structure menu
.align 4
stMenu1_1:  .skip BT_fin            @ reservation place structure menu
.align 4
stMenu1_2:  .skip BT_fin            @ reservation place structure menu
.align 4
stMenu1_3:  .skip BT_fin            @ reservation place structure menu
.align 4
stMenu2:  .skip BT_fin            @ reservation place structure menu
.align 4
stMenu2_1:  .skip BT_fin            @ reservation place structure menu
.align 4
stMenu2_2:  .skip BT_fin            @ reservation place structure menu
.align 4
stMenu3:  .skip BT_fin            @ reservation place structure menu
.align 4
stAttributs:  .skip Att_fin        @ reservation place structure Attibuts 
.align 4
stXGCValues:  .skip XGC_fin        @ reservation place structure XGCValues
.align 4
stBoutonOKMessage:  .skip BT_fin            @ reservation place structure bouton 3 
.align 4
stFenetreAtt:   .skip Win_fin      @ reservation place attributs fenêtre
.align 4  
stFenetreChge:  .skip XWCH_fin      @ reservation place   XWindowChanges
.align 4
stTexteAff: .skip XTI_fin             @ reservation place  XTextItem
.align 4
stWmHints:   .skip  Hints_fin   @ reservation place pour structure XWMHints 
.align 4
stAttrSize:   .skip XSize_fin      @ reservation place structure XSizeHints

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text           
.global main      @ 'main' point d'entrée doit être  global 

main:             /* programme principal */
    push {fp,lr}    @ save des  2 registres 
	add fp,sp,#8    @ fp <- adresse début 
	ldr r0,iAdrszMessDebutPgm   @ adresse message debut 
	bl affichageMess  			@ affichage message dans console  
	/* attention r6  pointeur display*/
	/* attention r7  pointeur ecran   */
	/* attention r12 est utilisé par les fonctions X11 */
	/*ouverture du serveur X */
	bl ConnexionServeur
	cmp r0,#0
	beq erreurServeur
	ldr r2,iAdrptDisplay
	str r0,[r2]     @ stockage adresse du DISPLAY 
	mov r6,r0       @ mais aussi dans le registre r6
	ldr r2,iAdrptEcran
	str r1,[r2]    @stockage  pointeur ecran
	mov r7,r1      @ mais aussi dans le registre r7
	
	/* chargement des polices */
	bl chargementPolices
	cmp r0,#0
	beq 100f

	/* création de la fenetre */
	mov r0,r6
	mov r1,r7
	bl creationFenetrePrincipale
	cmp r0,#0
	beq erreurF
	ldr r1,iAdrptFenetre
	str r0,[r1]    @ stockage adresse fenetre
	mov r9,r0      @ et dans r9

	/*  creation des contextes graphiques */
	mov r0,r6
	mov r1,r9
	bl creationGC
	cmp r0,#0
	beq erreurGC

	/* création du menu Fichier */
	mov r0,r6       @ display
	mov r1,r9       @ fenetre
	mov r2,r7       @ ecran 
	bl creationMenuFichier
	/* création du menu Fonction */
	mov r0,r6		@ display
	mov r1,r9		@ fenetre
	mov r2,r7		@ ecran
	bl creationMenuFonction
	/* création du menu Aide */
	mov r0,r6		@ display
	mov r1,r9		@ fenetre
	mov r2,r7		@ ecran
	bl creationMenuAide
	/* Création des sous menus  */
	mov r0,r6		@ display
	mov r1,r9		@ fenetre
	mov r2,r7		@ ecran
	bl creationSousMenuQuitter
	mov r0,r6		@ display
	mov r1,r9		@ fenetre
	mov r2,r7		@ ecran
	bl creationSousMenuCercle
	mov r0,r6		@ display
	mov r1,r9		@ fenetre
	mov r2,r7		@ ecran
	bl creationSousMenuPoly
	mov r0,r6		@ display
	mov r1,r9		@ fenetre
	mov r2,r7		@ ecran
	bl creationSousMenuGCxor
	mov r0,r6		@ display
	mov r1,r9		@ fenetre
	mov r2,r7		@ ecran
	bl creationSousMenuGCand
	/* creation d'une ligne de séparation des menus */
	bl dessinLigne
	
	/* boucle des evenements */     
boucleevt:  
    bl gestionEvenements
    cmp r0,#0         @ si zero on boucle sinon on termine 
	beq  boucleevt
    /* fin des évenements */
	
    @ liberation des ressources   
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
	bl affichageMess  		@ affichage message dans console   
	mov r0,#0     				@ code retour OK  
	b 100f
erreurF:
	   /* erreur creation fenêtre mais ne sert peut être à  rien car erreur directe X11  */
	ldr r1,iAdrszMessErrfen   
    bl   afficheerreur   
	mov r0,#1       /* code erreur */
	b 100f
erreurGC:  /* erreur creation contexte graphique  */
	ldr r1,iAdrszMessErrGc  
    bl   afficheerreur  
	mov r0,#1       /* code erreur */
	b 100f
erreurX11:    /* erreur X11  */
	ldr r1,iAdrszMessErreurX11   
    bl   afficheerreur   
	mov r0,#1       /* code erreur */
	b 100f
erreurServeur:
	   /* erreur car pas de serveur X   (voir doc putty et serveur Xming )*/
	ldr r1,iAdrszMessErreur  
    bl   afficheerreur   
	mov r0,#1       /* code erreur */
	b 100f	

100:		/* fin de programme standard  */
	pop {fp,lr}   /* restaur des  2 registres */
	mov r7, #EXIT /* appel fonction systeme pour terminer */
    swi 0 

iAdrszMessDebutPgm: 	.int szMessDebutPgm
iAdrszMessFinPgm: 		.int szMessFinPgm
iAdrszMessErreur: 		.int szMessErreur
iAdrptDisplay:  			.int ptDisplay
iAdrptEcran: 			.int ptEcran
/********************************************************************/
/*   Connexion serveur X et recupération informations du display  ***/
/********************************************************************/	
@ retourne dans r0 le ointeur vers le Display
@ retourne dans r1 le pointeur vers l'écran 
ConnexionServeur:
	push {fp,lr}    /* save des  2 registres */
	/*ouverture du serveur X */
	mov r0,#0
	bl XOpenDisplay
	cmp r0,#0
	beq 100f    @ serveur non actif 
	@ recup ecran par defaut
	ldr r2,[r0,#Disp_default_screen]
	ldr r1,[r0,#Disp_screens]    @ pointeur de la liste des écrans
    add r1,r2,lsl #2                @ récup du pointeur de l'écran par defaut

100:	
    pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */	 
/********************************************************************/
/*   Chargement des polices utilisées                             ***/
/********************************************************************/	
@ r0 pointeur vers le Display
@ sauvegarde des registres
chargementPolices:
	push {fp,lr}    /* save des  2 registres */
	push {r6}
	mov r6,r0    @ save Display
	ldr r1,iAdrszNomPolice 		@ nom de la police 
	bl XLoadQueryFont
	cmp r0,#0
	beq 2f	         @ police non trouvée  
	ldr r1,iAdrptPolice
	str r0,[r1]
	mov r0,r6        @ Display
	ldr r1,iAdrszNomPolice1 		@ nom de la police 
	bl XLoadQueryFont
	cmp r0,#0
	beq 2f	         @ police non trouvée  
	ldr r1,iAdrptPolice1
	str r0,[r1]
	
	b 100f
	
2:   @ police non trouvée 
	ldr r1,iAdrszMessErrGPolice  
    bl   afficheerreur   
	mov r0,#0       /* code erreur */
100:	
    pop {r6}
    pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */	
iAdrszNomPolice: .int szNomPolice
iAdrszNomPolice1: .int szNomPolice1
iAdrptPolice:   .int ptPolice
iAdrptPolice1:   .int ptPolice1
iAdrszMessErrGPolice: .int szMessErrGPolice
/********************************************************************/
/*   Creation d 'une fenêtre                                    ***/
/********************************************************************/
/* r0 contient le Display */
/* r1 le pointeur écran */
/* sauvegarde des registres   */
creationFenetrePrincipale:
	push {fp,lr}    /* save des  2 registres */
	mov r6,r0   @ save du Display
	mov r7,r1   @ save de l'écran

	@ calcul de la position X pour centrer la fenetre
	ldr r2,[r7,#Screen_width]   @ récupération de la largeur de l'écran racine
	sub r2,#LARGEUR              @ soustraction de la largeur de notre fenêtre
	lsr r2,#1                      @ division par 2 et résultat pour le parametre 3
	ldr r3,[r7,#Screen_height]  @ récupération de la hauteur de l'écran racine
	sub r3,#HAUTEUR               @ soustraction de la hauteur de notre fenêtre
	lsr r3,#1                       @ division par 2 et résultat pour le parametre 4
	
	/* CREATION DE LA FENETRE */
	mov r0,r6          @ display
	ldr r1,[r7,#Screen_root]  @ identification écran racine
	@ r2 et r3 ont été calculés plus haut
    mov r4,#0       /* alignement pile */
	push {r4}
	ldr r4,iGris1    @ couleur du fond
	push {r4}
	ldr r4,[r7,#Screen_black_pixel]   @ couleur bordure
	push {r4}
	mov r4,#2      @ bordure
	push {r4}
	mov r4,#HAUTEUR       @ hauteur
	push {r4}
	mov r4,#LARGEUR     @ largeur 
	push {r4}   
	bl XCreateSimpleWindow
	add sp,#24     @ remise à  niveau pile car 6 push
	cmp r0,#0
	beq 2f
	mov r5,r0      @ stockage adresse fenetre dans le registre r5 pour usage ci dessous

	/* ajout directives pour le serveur */
	mov r0,r6          @ display
	mov r1,r5          @ adresse fenêtre
	ldr r2,iAdrstAttrSize  @ structure des attributs 
	ldr r3,atribmask        @ masque des attributs
	str r3,[r2,#XSize_flags]
	bl XSetWMNormalHints
	/* ajout directives pour etat de la fenêtre */
	ldr r2,iAdrstWmHints         @   structure des attributs 
	mov r3,#NormalState     @ etat normal pour la fenêtre
	str r3,[r2,#Hints_initial_state]
	mov r3,#StateHint       @ etat initial
	str r3,[r2,#Hints_flags]
	mov r0,r6          @ adresse du display 
	mov r1,r5          @ adresse fenetre 
	bl XSetWMHints
	
		/* ajout de proprietes de la fenêtre */
	mov r0,r6          @ adresse du display 
	mov r1,r5          @ adresse fenetre 
	ldr r2,iAdrszNomFenetre   @ titre de la fenêtre 
	ldr r3,iAdrszTitreFenRed  @ titre de la fenêtre reduite 
	mov r4,#0
	push {r4}          /* TODO à  voir */
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
	ble 3f
	ldr r1,iAdrwmDeleteMessage  @ adresse de reception
	str r0,[r1]
	mov r2,r1          @ adresse zone retour precedente
	mov r0,r6          @ adresse du display
	mov r1,r5          @ adresse fenetre
	mov r3,#1          @ nombre de protocoles 
	bl XSetWMProtocols
	cmp r0,#0
	ble 3f
	
	/* affichage de la fenetre */
	mov r0,r6          @ adresse du display
	mov r1,r5          @ adresse fenetre
	bl XMapWindow
	
	/* autorisation des saisies */
	mov r0,r6          @ adresse du display
	mov r1,r5          @ adresse de la fenetre
	ldr r2,iFenetreMask    @ masque pour autoriser saisies
	bl XSelectInput
	cmp r0,#0
	ble 3f
1: @ pas d'erreur
	mov r0,r5     @ retourne l'identification de la fenetre
	b 100f
2:  @ erreur fenetre 
	ldr r1,iAdrszMessErrfen   
    bl   afficheerreur  
	mov r0,#0       @ code erreur 
	b 100f
3:    @ erreur X11
	ldr r1,iAdrszMessErreurX11  
    bl   afficheerreur  
	mov r0,#0       @ code erreur 
	b 100f
	
100:
	pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */	
iAdrptFenetre: 			.int ptFenetre
iFenetreMask: 			.int  KeyPressMask|ButtonPressMask|StructureNotifyMask|ExposureMask|EnterWindowMask
iGris1: 					.int 0xFFA0A0A0
iAdrhauteur: 			.int hauteur
iAdrlargeur: 			.int largeur
iAdrszNomFenetre: 		.int  szNomFenetre
iAdrszTitreFenRed: 		.int szTitreFenRed
iAdrszMessErreurX11: 	.int szMessErreurX11
iAdrszMessErrfen: 		.int szMessErrfen
iAdrszLibDW:   			.int szLibDW
iAdrwmDeleteMessage: 	.int wmDeleteMessage
iAdrstAttrSize:			.int stAttrSize
atribmask: 				.int USPosition | USSize
iAdrstWmHints :			.int stWmHints 
/********************************************************************/
/*   Création contexte graphique                                  ***/
/********************************************************************/	
/* r0 contient le display, r1 la fenêtre */
creationGC:
	push {fp,lr}    /* save des  2 registres */
	push {r4-r6}
	/* creation contexte graphique simple */
	mov r6,r0          @ save adresse du display
	mov r5,r1          @ adresse fenetre
	mov r2,#0
	mov r3,#0
	bl XCreateGC
	cmp r0,#0
	beq 2f	
	ldr r1,iAdrptGC
	str r0,[r1]   @ stockage adresse contexte graphique   
	mov r8,r0     @ et stockage dans r8
	/* création contexte graphique avec autre police */
	mov r0,r6          @ adresse du display 
	mov r1,r5          @ adresse fenetre 
	ldr r2,iGC1mask   @ identifie les zones de XGCValues à  mettre à  jour 
	ldr r4,iAdrptPolice1    @ recup du pointeur sur la police
    ldr r4,[r4]	
	ldr r4,[r4,#XFontST_fid]   @ identification police dans adresse police + 4 
	ldr r3,iAdrstXGCValues	
	str r4,[r3,#XGC_font]     @ maj dans la zone de XGCValues 

	ldr r3,iAdrstXGCValues   @ la zone complete est passée en paramètre 
	bl XCreateGC
	cmp r0,#0
	beq 2f	
	ldr r1,iAdrptGC1
	str r0,[r1]   @ stockage adresse contexte graphique dans zone gc2 
	/* creation contexte graphique simple BIS */
	mov r0,r6          @ adresse du display
	mov r1,r5          @ adresse fenetre
	mov r2,#0
	mov r3,#0
	bl XCreateGC
	cmp r0,#0
	beq 2f	
	ldr r1,iAdrptGC2
	str r0,[r1]   @ stockage adresse contexte graphique  
	
	
	b 100f
1:  @ erreur récupération police
	ldr r1,iAdrszMessErrGPolice   
    bl   afficheerreur  
	mov r0,#0       /* code erreur */

	b 100f
2:   /* erreur creation contexte graphique  */
	ldr r1,iAdrszMessErrGc  
    bl   afficheerreur  
	mov r0,#0       /* code erreur */
	b 100f
100:
	pop {r4-r6}
    pop {fp,lr}
    bx lr        	
iRouge: 					.int 0xFFFF0000
iAdrptGC:   				.int ptGC
iAdrptGC1:  				.int ptGC1
iAdrptGC2:				.int ptGC2
iAdrszMessErrGc: 		.int szMessErrGc
iGC1mask: 				.int GCFont
iGCmask: 					.int GCFont
iAdrstXGCValues: 		.int stXGCValues

/********************************************************************/
/*   Creation Menu Fichier                                        ***/
/********************************************************************/
/* r0 adresse du display */
/* r1 adresse de la fenêtre */
/* r2 adresse ecran   */
creationMenuFichier:
	push {fp,lr}    @ save des  2 registres 
	mov r3,r1  @ save fenêtre
	ldr r1,iAdrstMenu1  		@ adresse structure bouton
	str r3,[r1,#BT_windows]
	mov r3,r2   @ save ecran
	ldr r2,iAdrszTexteMenu1  	@ texte du Bouton
	str r2,[r1,#BT_texte]
	mov r2,#SEPXMENU   @ position x
	str r2,[r1,#BT_x]
	mov r2,#POSLIGNE
	sub r2,#HAUTMENU
	sub r2,#20            @ position y en fonction position ligne de séparation
	str r2,[r1,#BT_y]
	mov r2,#HAUTMENU  					@ hauteur  
	str r2,[r1,#BT_height]
	mov r2,#LARGMENU  					@ largeur  
	str r2,[r1,#BT_width]
	ldr r2,iGris1        
	str r2,[r1,#+BT_background]   @ pixel  du fond 
	ldr r2,[r3,#Screen_black_pixel]
	str r2,[r1,#+BT_border]   @ pixel  de la bordure 
	ldr r2,iAdrptPolice1
	ldr r2,[r2]
	str r2,[r1,#BT_Font]   @    Police bouton
	@ r0 Contient l'adresse du display
	@ et r1 contient l'adresse de la structure
	bl creationbouton

100:
    pop {fp,lr}
    bx lr        	
iAdrstMenu1:   .int stMenu1
iAdrszTexteMenu1: .int szTexteMenu1
/********************************************************************/
/*   Creation Sous menu Menu Fichier                                        ***/
/********************************************************************/
/* r0 adresse du display */
/* r1 adresse de la fenêtre */
/* r2 adresse ecran   */
creationSousMenuQuitter:
	push {fp,lr}    @ save des  2 registres 
	mov r3,r1  @ save fenêtre
	ldr r1,iAdrstMenu1_1  		@ adresse structure bouton
	str r3,[r1,#BT_windows]
	mov r3,r2   @ save ecran
	ldr r2,iAdrszTexteMenu1_1  	@ texte du Bouton
	str r2,[r1,#BT_texte]
	mov r2,#LARGMENU
	str r2,[r1,#BT_x]       @ position x
	mov r2,#POSLIGNE
	sub r2,#HAUTMENU       @ position y en fonction position ligne de séparation
	str r2,[r1,#BT_y]
	mov r2,#HAUTMENU  					@ hauteur  
	str r2,[r1,#BT_height]
	mov r2,#LARGMENU  					@ largeur  
	str r2,[r1,#BT_width]
	ldr r2,iGris1        
	str r2,[r1,#+BT_background]   @ pixel  du fond 
	ldr r2,[r3,#Screen_black_pixel]
	str r2,[r1,#+BT_border]   @ pixel  de la bordure 
	ldr r2,iAdrptPolice1
	ldr r2,[r2]
	str r2,[r1,#BT_Font]   @    Police bouton
	@ r0 Contient l'adresse du display
	@ et r1 contient l'adresse de la structure
	bl creationSousMenu

100:
    pop {fp,lr}
    bx lr        	
iAdrstMenu1_1:   .int stMenu1_1
iAdrszTexteMenu1_1: .int szTexteMenu1_1
/********************************************************************/
/*   Creation Sous menu Couleur Cercle                                        ***/
/********************************************************************/
/* r0 adresse du display */
/* r1 adresse de la fenêtre */
/* r2 adresse ecran   */
creationSousMenuCercle:
	push {fp,lr}    @ save des  2 registres 
	mov r3,r1  @ save fenêtre
	ldr r1,iAdrstMenu1_2  		@ adresse structure bouton
	str r3,[r1,#BT_windows]
	mov r3,r2   @ save ecran
	ldr r2,iAdrszTexteMenu1_2  	@ texte du Bouton
	str r2,[r1,#BT_texte]
	mov r2,#LARGMENU
	str r2,[r1,#BT_x]     @ position x
	mov r2,#POSLIGNE     @ position y en fonction position ligne de séparation
	str r2,[r1,#BT_y]
	mov r2,#HAUTMENU  					@ hauteur  
	str r2,[r1,#BT_height]
	mov r2,#LARGMENU  					@ largeur  
	str r2,[r1,#BT_width]
	ldr r2,iGris1        
	str r2,[r1,#+BT_background]   @ pixel  du fond 
	ldr r2,[r3,#Screen_black_pixel]
	str r2,[r1,#+BT_border]   @ pixel  de la bordure 
	ldr r2,iAdrptPolice1
	ldr r2,[r2]
	str r2,[r1,#BT_Font]   @    Police bouton
	@ r0 Contient l'adresse du display
	@ et r1 contient l'adresse de la structure
	bl creationSousMenu

100:
    pop {fp,lr}
    bx lr        	
iAdrstMenu1_2:   .int stMenu1_2
iAdrszTexteMenu1_2: .int szTexteMenu1_2
/********************************************************************/
/*   Creation Sous menu Polygone                                       ***/
/********************************************************************/
/* r0 adresse du display */
/* r1 adresse de la fenêtre */
/* r2 adresse ecran   */
creationSousMenuPoly:
	push {fp,lr}    @ save des  2 registres 
	mov r3,r1  @ save fenêtre
	ldr r1,iAdrstMenu1_3  		@ adresse structure bouton
	str r3,[r1,#BT_windows]
	mov r3,r2   @ save ecran
	ldr r2,iAdrszTexteMenu1_3  	@ texte du Bouton
	str r2,[r1,#BT_texte]
	mov r2,#LARGMENU
	str r2,[r1,#BT_x]      @ position x
	mov r2,#POSLIGNE
	add r2,#HAUTMENU
	str r2,[r1,#BT_y]       @ position y en fonction position ligne de séparation
	mov r2,#HAUTMENU  					@ hauteur  
	str r2,[r1,#BT_height]
	mov r2,#LARGMENU  					@ largeur  
	str r2,[r1,#BT_width]
	ldr r2,iGris1        
	str r2,[r1,#+BT_background]   @ pixel  du fond 
	ldr r2,[r3,#Screen_black_pixel]
	str r2,[r1,#+BT_border]   @ pixel  de la bordure 
	ldr r2,iAdrptPolice1
	ldr r2,[r2]
	str r2,[r1,#BT_Font]   @    Police bouton
	@ r0 Contient l'adresse du display
	@ et r1 contient l'adresse de la structure
	bl creationSousMenu

100:
    pop {fp,lr}
    bx lr        	
iAdrstMenu1_3:   .int stMenu1_3
iAdrszTexteMenu1_3: .int szTexteMenu1_3
/********************************************************************/
/*   Creation Menu Fonction                                       ***/
/********************************************************************/
/* r0 adresse du display */
/* r1 adresse de la fenêtre */
/* r2 adresse ecran */
creationMenuFonction:
	push {fp,lr}    @ save des  2 registres 
	mov r3,r1   @ save fenêtre
	ldr r1,iAdrstMenu2  		@ adresse structure bouton
	str r3,[r1,#BT_windows]
	mov r3,r2   @ save ecran
	ldr r2,iAdrszTexteMenu2  	@ texte du Bouton
	str r2,[r1,#BT_texte]
	mov r2,#SEPXMENU   @ separation menu
	add r2,#LARGMENU   @ largeur du menu 1
	add r2,#SEPXMENU   @ separation menu
	str r2,[r1,#BT_x]   @ position x
	mov r2,#POSLIGNE
	sub r2,#HAUTMENU
	sub r2,#20            @ position y en fonction position ligne de séparation
	str r2,[r1,#BT_y]
	mov r2,#HAUTMENU  					@ hauteur  
	str r2,[r1,#BT_height]
	mov r2,#LARGMENU  					@ largeur  
	str r2,[r1,#BT_width]
	ldr r2,iGris1        
	str r2,[r1,#+BT_background]   @ pixel  du fond 
	ldr r2,[r3,#Screen_black_pixel]
	str r2,[r1,#+BT_border]   @ pixel  de la bordure 
	ldr r2,iAdrptPolice1
	ldr r2,[r2]
	str r2,[r1,#BT_Font]   @    Police bouton
	@ r0 contient adresse du display
	@ et r1 contient l'adresse de la structure
	bl creationbouton

100:
    pop {fp,lr}
    bx lr        	
iAdrstMenu2:   .int stMenu2
iAdrszTexteMenu2: .int szTexteMenu2
/********************************************************************/
/*   Creation Sous menu GCxor                                        ***/
/********************************************************************/
/* r0 adresse du display */
/* r1 adresse de la fenêtre */
/* r2 adresse ecran   */
creationSousMenuGCxor:
	push {fp,lr}    @ save des  2 registres 
	mov r3,r1  @ save fenêtre
	ldr r1,iAdrstMenu2_1  		@ adresse structure bouton
	str r3,[r1,#BT_windows]
	mov r3,r2   @ save ecran
	ldr r2,iAdrszTexteMenu2_1  	@ texte du Bouton
	str r2,[r1,#BT_texte]
	mov r2,#LARGMENU     @ largeur du menu 1
	add r2,#SEPXMENU
	add r2,#LARGMENU      @ largeur du menu 2
	str r2,[r1,#BT_x]     @ position x
	mov r2,#POSLIGNE
	sub r2,#HAUTMENU
	str r2,[r1,#BT_y]		 @ position y en fonction position ligne de séparation
	mov r2,#HAUTMENU  					@ hauteur  
	str r2,[r1,#BT_height]
	mov r2,#LARGMENU  					@ largeur  
	str r2,[r1,#BT_width]
	ldr r2,iGris1        
	str r2,[r1,#+BT_background]   @ pixel  du fond 
	ldr r2,[r3,#Screen_black_pixel]
	str r2,[r1,#+BT_border]   @ pixel  de la bordure 
	ldr r2,iAdrptPolice1
	ldr r2,[r2]
	str r2,[r1,#BT_Font]   @    Police bouton
	@ r0 Contient l'adresse du display
	@ et r1 contient l'adresse de la structure
	bl creationSousMenu

100:
    pop {fp,lr}
    bx lr        	
iAdrstMenu2_1:   .int stMenu2_1
iAdrszTexteMenu2_1: .int szTexteMenu2_1
/********************************************************************/
/*   Creation Sous menu GCand                                        ***/
/********************************************************************/
/* r0 adresse du display */
/* r1 adresse de la fenêtre */
/* r2 adresse ecran   */
creationSousMenuGCand:
	push {fp,lr}    @ save des  2 registres 
	mov r3,r1  @ save fenêtre
	ldr r1,iAdrstMenu2_2  		@ adresse structure bouton
	str r3,[r1,#BT_windows]
	mov r3,r2   @ save ecran
	ldr r2,iAdrszTexteMenu2_2  	@ texte du Bouton
	str r2,[r1,#BT_texte]
	mov r2,#LARGMENU     @ largeur du menu 1
	add r2,#SEPXMENU
	add r2,#LARGMENU
	str r2,[r1,#BT_x]    @ position x
	mov r2,#POSLIGNE
	str r2,[r1,#BT_y]     @ position y en fonction position ligne de séparation
	mov r2,#HAUTMENU  					@ hauteur  
	str r2,[r1,#BT_height]
	mov r2,#LARGMENU  					@ largeur  
	str r2,[r1,#BT_width]
	ldr r2,iGris1        
	str r2,[r1,#+BT_background]   @ pixel  du fond 
	ldr r2,[r3,#Screen_black_pixel]
	str r2,[r1,#+BT_border]   @ pixel  de la bordure 
	ldr r2,iAdrptPolice1
	ldr r2,[r2]
	str r2,[r1,#BT_Font]   @    Police bouton
	@ r0 Contient l'adresse du display
	@ et r1 contient l'adresse de la structure
	bl creationSousMenu

100:
    pop {fp,lr}
    bx lr        	
iAdrstMenu2_2:   .int stMenu2_2
iAdrszTexteMenu2_2: .int szTexteMenu2_2
/********************************************************************/
/*   Creation Menu Aide                                       ***/
/********************************************************************/
/* r0 adresse du display */
/* r1 adresse de la fenêtre */
/* r2 adresse ecran */
creationMenuAide:
	push {fp,lr}    @ save des  2 registres 
	mov r3,r1   @ save fenêtre
	ldr r1,iAdrstMenu3  		@ adresse structure bouton
	str r3,[r1,#BT_windows]
	mov r3,r2   @ save ecran
	ldr r2,iAdrszTexteMenu3  	@ texte du Bouton
	str r2,[r1,#BT_texte]
	mov r2,#SEPXMENU   @ separation menu
	add r2,#LARGMENU   @ largeur du menu 1
	add r2,#SEPXMENU   @ separation menu
	add r2,#LARGMENU   @ largeur du menu 2
	add r2,#SEPXMENU   @ separation menu
	str r2,[r1,#BT_x]   @ position x
	mov r2,#POSLIGNE
	sub r2,#HAUTMENU
	sub r2,#20            @ position y en fonction position ligne de séparation
	str r2,[r1,#BT_y]
	mov r2,#HAUTMENU  					@ hauteur  
	str r2,[r1,#BT_height]
	mov r2,#LARGMENU  					@ largeur  
	str r2,[r1,#BT_width]
	ldr r2,iGris1        
	str r2,[r1,#+BT_background]   @ pixel  du fond 
	ldr r2,[r3,#Screen_black_pixel]
	str r2,[r1,#+BT_border]   @ pixel  de la bordure 
	ldr r2,iAdrptPolice1
	ldr r2,[r2]
	str r2,[r1,#BT_Font]   @    Police bouton
	@ r0 contient adresse du display
	@ et r1 contient l'adresse de la structure
	bl creationbouton
	vidregtit creMenu

100:
    pop {fp,lr}
    bx lr        	
iAdrstMenu3:   .int stMenu3
iAdrszTexteMenu3: .int szTexteMenu3
/********************************************************************/
/*   Creation d 'une fenêtre  d'affichage d'un message            ***/
/********************************************************************/
/* r0 contient le Display */
/* r1 l'adresse du message à afficher */
/* r2 la longueur du message
/* r3 code bouton  : 0 un bouton ok  1:  2 boutons oui Non  */
/* 2 : 3 boutons oui non annuler  */ 
/* sauvegarde des registres   */
creationFenetreMessage:
	push {fp,lr}    /* save des  2 registres */
	push {r4-r9}
	mov r6,r0          @ display
	mov r8,r1  @ save du message
	mov r9,r2  @ save longueur
	ldr r7,iAdrptEcran      @ récuperation du pointeur de l'écran 
	ldr r7,[r7]
		/* Centrage de la fenetre */
	ldr r2,[r7,#Screen_width]   @ récupération de la largeur de l'écran racine
	ldr r3,iLargeurMessage
	sub r2,r3              @ soustraction de la largeur de notre fenêtre
	lsr r2,#1                      @ division par 2 et résultat pour le parametre 3
	ldr r3,[r7,#Screen_height]  @ récupération de la hauteur de l'écran racine
	ldr r1,iHauteurMessage
	sub r3,r1               @ soustraction de la hauteur de notre fenêtre
	lsr r3,#1                       @ division par 2 et résultat pour le parametre 4
	
	/* CREATION DE LA FENETRE */
	mov r0,r6          @ display
	ldr r1,[r7,#Screen_root]  @ identification écran racine
	@ position X et Y calculées plus haut pour le centrage
    mov r4,#0          @alignement pile 
	push {r4}
	ldr r4,iGris1    @ couleur du fond
	push {r4}
	ldr r4,[r7,#Screen_black_pixel] @ couleur bordure
	push {r4}
	mov r4,#1      @ bordure
	push {r4}
	ldr r4,iHauteurMessage       @ hauteur
	push {r4}
	ldr r4,iLargeurMessage     @ largeur 
	push {r4}   
	bl XCreateSimpleWindow
	add sp,#24     @ remise à  niveau pile car 6 push
	cmp r0,#0
	beq 2f
	ldr r1,iAdrptFenetreM
	str r0,[r1]    @ stockage adresse fenetre
	mov r5,r0      @ et aussi dans r5 pour les usages ci dessous
	
		/* ajout directives pour le serveur */
	mov r0,r6          @ display
	mov r1,r5          @ adresse fenêtre
	ldr r2,iAdrstAttrSize  @ structure des attributs 
	ldr r3,atribmask        @ masque des attributs
	str r3,[r2,#XSize_flags]
	bl XSetWMNormalHints
	
		/* ajout de proprietes de la fenêtre */
	mov r0,r6          @ adresse du display 
	mov r1,r5          @ adresse fenetre 
	ldr r2,iAdrszNomFenetreM   @ titre de la fenêtre 
	mov r3,#0  @ titre de la fenêtre reduite 
	mov r4,#0
	push {r4}          /* TODO à  voir */
	push {r4}
	push {r4}
	push {r4}
	bl XSetStandardProperties
	add sp,sp,#16   @ pour les 4 push

	/* Correction erreur fermeture fenetre */
	mov r0,r6          @ adresse du display
	mov r1,r5          @ adresse fenetre
	ldr r2,iAdrwmDeleteMessage  @ adresse atome crée lors de la fenetre principale
	mov r3,#1          @ nombre de protocoles 
	bl XSetWMProtocols
	cmp r0,#0
	ble 3f
	
	/* affichage de la fenetre */
	mov r0,r6          @ adresse du display
	mov r1,r5          @ adresse fenetre
	bl XMapWindow
	
	/* affichage du texte du message */
	mov r0,r6          @ adresse du display
	mov r1,r5          @ adresse de la fenetre
	mov r2,r8
	mov r3,r9
	bl afficheTexteMessage
	
	/* autorisation des saisies */
	mov r0,r6          @ adresse du display
	mov r1,r5          @ adresse de la fenetre
	ldr r2,iFenetreMaskM    @ masque pour autoriser saisies
	bl XSelectInput
	cmp r0,#0
	ble 3f

	
	/* création d'un bouton Ok  */
	ldr r1,iAdrstBoutonOKMessage  		@ adresse structure bouton
	str r5,[r1,#BT_windows]
	ldr r2,iAdrszTexteBoutonOK  	@ texte du Bouton   OK
	str r2,[r1,#BT_texte]
	ldr r2,iLargeurMessage     @ largeur fenetre
	lsr r2,#1                      @ TODO revoir position x
	str r2,[r1,#BT_x]
	ldr r2,iHauteurMessage     @ hauteur fenetre
	sub r2,#35  					@ position y 
	str r2,[r1,#BT_y]
	mov r2,#20  					@ hauteur  
	str r2,[r1,#BT_height]
	mov r2,#80  					@ largeur  
	str r2,[r1,#BT_width]
	ldr r2,[r7,#Screen_white_pixel]         
	str r2,[r1,#+BT_background]   @ pixel  du fond 
	ldr r2,[r7,#Screen_black_pixel]
	str r2,[r1,#+BT_border]   @ pixel  de la bordure 
	ldr r2,iAdrptPolice1
	ldr r2,[r2]
	str r2,[r1,#BT_Font]   @    Police bouton
	mov r0,r6                       @ adresse du display
	@ et r1 contient l'adresse de la structure
	bl creationbouton
	
1: @ pas d'erreur
	mov r0,#1     @ retourne OK
	b 100f
2:  @ erreur fenetre 
	ldr r1,iAdrszMessErrfen   
    bl   afficheerreur  
	mov r0,#0       @ code erreur 
	b 100f
3:    @ erreur X11
	ldr r1,iAdrszMessErreurX11  
    bl   afficheerreur  
	mov r0,#0       @ code erreur 
	b 100f
	
100:
	pop {r4-r9}
	pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */	
iHauteurMessage:   .int HAUTEURMESSAGE
iLargeurMessage:   .int LARGEURMESSAGE
iAdrptFenetreM: 			.int ptFenetreM
iFenetreMaskM: 			.int  KeyPressMask|ButtonPressMask|StructureNotifyMask|ExposureMask
iAdrszNomFenetreM: 		.int  szNomFenetreMessage
iAdrszTexteBoutonOK:  .int szTexteBoutonOK
iAdrstBoutonOKMessage:            .int stBoutonOKMessage
szNomFenetreMessage: .asciz "Message"
.align 4
/********************************************************************/
/*   Affichage du texte du message                                        ***/
/********************************************************************/
/* r0 adresse du display */
/* r1 adresse de la fenetre des messages */
/* r2 adresse du texte */
/* r3 longueur du texte */
afficheTexteMessage:
	push {fp,lr}    @ save des  2 registres 
	push {r4-r5}
	mov r4,r2  @ save adresse texte 
	mov r5,r3  @ save longueur
	ldr r2,iAdrptEcran
	ldr r2,[r2]
	ldr r2,[r2,#Screen_default_gc]          @ adresse du contexte graphique par defaut
	mov r3,#5          @ position x 
	sub sp,#4      @ alignement pile
	push {r5}                @ longueur du texte
	push {r4}   @ adresse du texte a afficher 
	mov r4,#50              @ position y 
	push {r4}
	bl XDrawString
	add sp,sp,#16      @ pour les 3 push et l'alignement pile
	
100:
	pop {r4-r5}
	pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */	

/********************************************************************/
/*   Creation bouton                                        ***/
/********************************************************************/
/* r0 adresse du display */
/* r1 adresse de la structure Bouton */
creationbouton:
	push {fp,lr}    @ save des  2 registres 
	push {r4-r7}
	mov r6,r0      @ save display
	mov r5,r1      @ save pointeur structure

	/* CREATION DE LA FENETRE BOUTON */
	ldr r1,[r5,#BT_windows]    @ fenetre parent 
	ldr r2,[r5,#BT_x]            @ position X
	ldr r3,[r5,#BT_y]            @ position Y
	mov r4,#0       @ alignement pile 
	push {r4}
	ldr r4,[r5,#+BT_background]
	push {r4}       	@ pixel  du fond 
	ldr r4,[r5,#+BT_border]
	push {r4}      @ pixel  de la bordure 
	mov r4,#1      @ largeur bordure 
	push {r4}
	ldr r4,[r5,#BT_height]
	push {r4}      			@ hauteur  
	ldr r4,[r5,#BT_width]
	push {r4}       		@largeur 
	bl XCreateSimpleWindow
	add sp,sp,#24   		@ pour les 6 push 
	cmp r0,#0
	beq 99f
	/* alimentation donnees du bouton */
	str r0,[r5,#+BT_adresse]
	mov r7,r0    @ save pointeur bouton
	/* autorisation des saisies */
	mov r0,r6          					@ adresse du display 
	mov r1,r7          @ adresse du bouton 
	ldr r2,iBoutonMask      @ 
	bl XSelectInput
	/*  creation du contexte graphique du bouton */
    ldr r4,[r5,#BT_Font]	
	ldr r4,[r4,#XFontST_fid]   @ identification police dans adresse police + 4 
	ldr r3,iAdrstXGCValues	
	str r4,[r3,#XGC_font]     @ maj dans la zone de XGCValues 
	ldr r3,iAdrstXGCValues   @ la zone complete est passée en paramètre 
	mov r0,r6             @ adresse du display 
	mov r1,r7             @ adresse du bouton 
	ldr r2,iGCBTmask
	bl XCreateGC
	cmp r0,#0
	beq 98f	
	str r0,[r5,#+BT_GC]    @ stockage contexte graphique
	/* affichage du bouton */
	mov r0,r6         					@ adresse du display 
	mov r1,r7      	@ adresse du bouton 
	bl XMapWindow
	/* ecriture du texte du bouton */
	mov r0,r6        @ Display
	mov r1,r5        @ adresse de la structure
	bl ecritureTexteBouton
	
	b 100f
98:   @ pb creation contexte graphique
	ldr r1,iAdrszMessErrGcBT   
	bl   afficheerreur   /*appel affichage message  */	
	b 100f
99:	@ pb creation bouton
	ldr r1,iAdrszMessErrbt  
    bl   afficheerreur   /*appel affichage message  */	
	
100:	
	pop {r4-r7}
    pop {fp,lr}
    bx lr
iAdrszMessErrGcBT: 		.int szMessErrGcBT
iAdrszMessErrbt: 		.int szMessErrbt
iBoutonMask: 			.int ButtonPressMask|ButtonReleaseMask|StructureNotifyMask|ExposureMask|LeaveWindowMask|EnterWindowMask
iGCBTmask: 				.int GCFont
/********************************************************************/
/*   Creation Sous Menu                                        ***/
/********************************************************************/
/* r0 adresse du display */
/* r1 adresse de la structure Bouton */
creationSousMenu:
	push {fp,lr}    @ save des  2 registres 
	push {r4-r7}
	mov r6,r0      @ save display
	mov r5,r1      @ save pointeur structure

	/* CREATION DE LA FENETRE Sous Menu */
	ldr r1,[r5,#BT_windows]    @ fenetre parent 
	ldr r2,[r5,#BT_x]            @ position X
	ldr r3,[r5,#BT_y]            @ position Y
	mov r4,#0       @ alignement pile 
	push {r4}
	ldr r4,[r5,#+BT_background]
	push {r4}       	@ pixel  du fond 
	ldr r4,[r5,#+BT_border]
	push {r4}      @ pixel  de la bordure 
	mov r4,#1      @ largeur bordure 
	push {r4}
	ldr r4,[r5,#BT_height]
	push {r4}      			@ hauteur  
	ldr r4,[r5,#BT_width]
	push {r4}       		@largeur 
	bl XCreateSimpleWindow
	add sp,sp,#24   		@ pour les 6 push 
	cmp r0,#0
	beq 99f
	/* alimentation donnees du bouton */
	str r0,[r5,#+BT_adresse]
	mov r7,r0    @ save pointeur bouton
	/* autorisation des saisies */
	mov r0,r6          					@ adresse du display 
	mov r1,r7          @ adresse du bouton 
	ldr r2,iMenuMask      @ 
	bl XSelectInput
	/*  creation du contexte graphique du bouton */
    ldr r4,[r5,#BT_Font]	
	ldr r4,[r4,#XFontST_fid]   @ identification police dans adresse police + 4 
	ldr r3,iAdrstXGCValues	
	str r4,[r3,#XGC_font]     @ maj dans la zone de XGCValues 
	ldr r3,iAdrstXGCValues   @ la zone complete est passée en paramètre 
	mov r0,r6             @ adresse du display 
	mov r1,r7             @ adresse du bouton 
	ldr r2,iGCMenumask
	bl XCreateGC
	cmp r0,#0
	beq 98f	
	str r0,[r5,#+BT_GC]    @ stockage contexte graphique

	b 100f
98:   @ pb creation contexte graphique
	ldr r1,iAdrszMessErrGcBT   
	bl   afficheerreur   /*appel affichage message  */	
	b 100f
99:	@ pb creation bouton
	ldr r1,iAdrszMessErrbt  
    bl   afficheerreur   /*appel affichage message  */	
	
100:	
	pop {r4-r7}
    pop {fp,lr}
    bx lr

iMenuMask: 			.int ButtonPressMask|ButtonReleaseMask|StructureNotifyMask|ExposureMask|LeaveWindowMask|EnterWindowMask
iGCMenumask: 				.int GCFont
/********************************************************************/
/*   Ecriture du libellé du bouton                         ***/
/********************************************************************/
@ r0 contient le display
@ r1 la structure du bouton
@ sauvegarde des registres
ecritureTexteBouton:
	push {fp,lr}      @ save des  2 registres 
	push {r4-r8}
	mov r6,r0
	mov  r5,r1    @ recup structure bouton
	/* calcul longueur texte du bouton */
	ldr r1,[r5,#+BT_texte]  @ recup texte du bouton 
	mov r4,#0
1:  
	ldrb r3,[r1,r4]
	cmp r3,#0
	addne r4,#1
	bne 1b
	/* centrage du texte du bouton */
	@calcul de la longueur en pixel du texte
	ldr r0,[r5,#BT_Font]   @ c'est bien la structure de la police 
	mov r2,r4
	bl XTextWidth         @ calcul de la longueur en pixel du texte
	ldr r2,[r5,#+BT_width]
	sub r3,r2,r0 					@ on enleve la taille du texte de la longueur du bouton
	lsr r7,r3,#1    				@ et on divise par 2 pour avoir la position x 
	mov r8,r4

    ldr r0,[r5,#BT_Font]   @ c'est bien la structure de la police 
	ldr r1,[r5,#+BT_texte]  @ recup texte du bouton 
	mov r2,r4
	ldr r3,iAdrdirection
	mov r4,#0
	push {r4}
	ldr r4,iAdroverall
	push {r4}
	ldr r4,iAdrfont_descent
	push {r4}
	ldr r4,iAdrfont_ascent
	push {r4}
	bl XTextExtents      @ pour calculer la hauteur du texte en pixel
	add sp,sp,#16         @ pour les 4 push

	ldr r1,iAdrfont_descent
	ldr r1,[r1]
	ldr r2,iAdrfont_ascent
	ldr r2,[r2]
	//add r4,r1,r2      @ TODO : calcul à améliorer car pb de compréhennsation
	mov r4,r2
	/* ecriture du texte du bouton */
	ldr r1,[r5,#BT_adresse]          @ adresse du bouton
    ldr r2,[r5,#BT_GC]       @ adresse du contexte graphique 
	mov r3,r7
	
	 @ longueur de la chaine a ecrire dans r8
	mov r7,#0
	push {r7}     @ alignement pile
	push {r8}      @ en parametre 
	ldr r8,[r5,#+BT_texte]  @ recup texte du bouton 
	push {r8}
	ldr r8,[r5,#+BT_height]   @ taille du bouton
	sub r8,r4                   @ moins taille du texte
	lsr r8,#1               @ TODO  divisé par 2 pour l'espacement
	add r8,r4               @ et ajout de la taille du texte
	push {r8}               @ pour avoir la position Y
	mov r0,r6
	bl XDrawString
	add sp,sp,#16         @ pour les 4 push
100:	
	pop {r4-r8}
    pop {fp,lr}
    bx lr      
iAdrdirection:  .int direction
iAdrfont_ascent:  .int font_ascent
iAdrfont_descent:  .int font_descent
iAdroverall:   .int overall

/********************************************************************/
/*   Dessin d'une ligne droite                                    ***/
/********************************************************************/
@ pas de sauvegarde des registres
dessinLigne:
	push {fp,lr}      @ save des  2 registres 
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	mov r2,r8          @ adresse du contexte graphique simple 
	mov r3,#0         @ position x 
	sub sp,sp,#4
	mov r4,#POSLIGNE        @ position y1 
	push {r4}          @en parametre 
	ldr r4,iAdrlargeur      @ sur toute la largeur de l'écran
	ldr r4,[r4] 
	push {r4}
	mov r4,#POSLIGNE        @ position y 
	push {r4}
	bl XDrawLine
	add sp,sp,#16       @ pour les 3 push et l'alignement
100:
    pop {fp,lr}
    bx lr     	
/********************************************************************/
/*   Gestion des évenements                                       ***/
/********************************************************************/
@ pas de sauvegarde des registres
gestionEvenements:
	push {fp,lr}      @ save des  2 registres 
	mov r0,r6            @ adresse du display
	ldr r1,iAdrevent         @ adresse evenements
	bl XNextEvent
	ldr r0,iAdrevent
	@Quelle fenêtre est concernée ?
	ldr r0,[r0,#XAny_window]
	ldr r1,iAdrptFenetre   @ fenêtre principale ?
	ldr r1,[r1]
	cmp r0,r1
	bne 1f
	ldr r0,iAdrevent
	bl evtFenetrePrincipale
	@ le code retour dans r0 est positionné dans la routine
	b 100f
1:
	ldr r1,iAdrstMenu1    @ menu fichier ?
	ldr r1,[r1,#BT_adresse]
	cmp r0,r1
	bne 2f
	ldr r0,iAdrevent
	bl gestionEvtMenuFichier
	mov r0,#0
	b 100f
2:
	ldr r1,iAdrstMenu3    @ menu aide ?
	ldr r1,[r1,#BT_adresse]
	cmp r0,r1
	bne 3f
	ldr r0,iAdrevent
	bl gestionEvtMenuAide
	mov r0,#0
	b 100f
3:
	ldr r1,iAdrptFenetreM  @ fenêtre de message ?
	ldr r1,[r1]
	cmp r0,r1
	bne 4f
	ldr r0,iAdrevent
	bl evtFenetreMessage
	mov r0,#0
	b 100f

4:
	ldr r1,iAdrstBoutonOKMessage    @ bouton fenetre message ?
	ldr r1,[r1,#BT_adresse]
	cmp r0,r1
	bne 5f
	ldr r0,iAdrevent
	bl gestionEvtBoutonMessage
	mov r0,#0
	b 100f
	
5:
	ldr r1,iAdrstMenu1_1    @ sous menu fichier = Quitter ?
	ldr r1,[r1,#BT_adresse]
	cmp r0,r1
	bne 6f
	ldr r0,iAdrevent
	bl gestionEvtMenuQuitter
	@ le code retour dans r0 est positionné dans la routine
	b 100f
	
6:
	ldr r1,iAdrstMenu1_2    @ sous menu fichier = Cercle ?
	ldr r1,[r1,#BT_adresse]
	cmp r0,r1
	bne 7f
	ldr r0,iAdrevent
	bl gestionEvtMenuCercle
	mov r0,#0
	b 100f
7:
	ldr r1,iAdrstMenu1_3    @ sous menu fichier = Poly ?
	ldr r1,[r1,#BT_adresse]
	cmp r0,r1
	bne 8f
	ldr r0,iAdrevent
	bl gestionEvtMenuPoly
	mov r0,#0
	b 100f
8:
	ldr r1,iAdrstMenu2    @ menu Fonction ?
	ldr r1,[r1,#BT_adresse]
	cmp r0,r1
	bne 9f
	ldr r0,iAdrevent
	bl gestionEvtMenuFonction
	mov r0,#0
	b 100f
9:
	ldr r1,iAdrstMenu2_1    @ sous menu GCxor ?
	ldr r1,[r1,#BT_adresse]
	cmp r0,r1
	bne 10f
	ldr r0,iAdrevent
	bl gestionEvtMenuGCxor
	mov r0,#0
	b 100f
10:
	ldr r1,iAdrstMenu2_2    @ sous menu GCand ?
	ldr r1,[r1,#BT_adresse]
	cmp r0,r1
	bne 11f
	ldr r0,iAdrevent
	bl gestionEvtMenuGCand
	mov r0,#0
	b 100f
11:  @ si autre bouton ou fenêtre à traiter
	mov r0,#0

/***************************************/	
100:	
    pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */
iAdrevent:     .int event

/********************************************************************/
/*   Evenements de la fenêtre principale                          ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ sauvegarde des registres
evtFenetrePrincipale:
	push {fp,lr}      @ save des  2 registres
	ldr r0,[r0,#XAny_type]
	cmp r0,#ClientMessage   @ cas pour fermeture fenetre sans erreur 
	beq fermeture
	cmp r0,#Expose          @ cas d'une modification de la fenetre ou son masquage
	beq evtexpose
	cmp r0,#ConfigureNotify   @ cas pour modification de la fenetre 
	beq evtconfigure
	cmp r0,#EnterNotify    @ la souris passe sur une fenêtre
	beq evtEnterNotify
	mov r0,#0
	b 100f
/***************************************/	
fermeture:    /* clic sur menu systeme */
	ldr r0,iAdrevent      @ evenement de type XClientMessageEvent
	ldr r1,[r0,#XClient_data]   @ position code message
	ldr r2,iAdrwmDeleteMessage
	ldr r2,[r2]
	cmp r1,r2
	moveq r0,#1
	movne r0,#0
	b 100f
/***************************************/	
evtexpose:   /* masquage ou modification fenetre */
	mov r0,r6     @ adresse du display
	bl dessinLigne
	mov r0,r6     @ adresse du display
	ldr r1,iAdrstMenu1A
	bl ecritureTexteBouton
	mov r0,r6     @ adresse du display
	ldr r1,iAdrstMenu3A
	bl ecritureTexteBouton
	mov r0,#0
	b 100f
evtconfigure:
	ldr r0,iAdrevent
	ldr r1,[r0,#+XConfigureEvent_width]
	ldr r2,iAdrlargeur
	ldr r3,[r2]
	cmp r1,r3     @ modification de la largeur ?
	beq evtConfigure1
	str r1,[r2]     @ maj nouvelle largeur
evtConfigure1:
	mov r0,#0
	b 100f
evtEnterNotify:
	@ desaffichage des sous menus
	mov r0,r6         					@ adresse du display 
	ldr r1,iAdrstMenu1_1A      	@ structure du sous menu
	ldr r1,[r1,#BT_adresse]
	bl XUnmapWindow
	mov r0,r6         					@ adresse du display 
	ldr r1,iAdrstMenu1_2A      	@ structure du sous menu
	ldr r1,[r1,#BT_adresse]
	bl XUnmapWindow
	mov r0,r6         					@ adresse du display 
	ldr r1,iAdrstMenu1_3A      	@ structure du sous menu
	ldr r1,[r1,#BT_adresse]
	bl XUnmapWindow
	mov r0,r6         					@ adresse du display 
	ldr r1,iAdrstMenu2_1A      	@ structure du sous menu
	ldr r1,[r1,#BT_adresse]
	bl XUnmapWindow
	mov r0,r6         					@ adresse du display 
	ldr r1,iAdrstMenu2_2A      	@ structure du sous menu
	ldr r1,[r1,#BT_adresse]
	bl XUnmapWindow
	mov r0,#0
	b 100f
100:
    pop {fp,lr}
    bx lr
iAdrstMenu1A: .int stMenu1
iAdrstMenu3A: .int stMenu3
/********************************************************************/
/*   Evenements du menu Fichier                                      ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ r1 doit contenir l'adresse de la fenetre
@ sauvegarde des registres
gestionEvtMenuFichier:
	push {fp,lr}      @ save des  2 registres
	ldr r0,[r0,#XAny_type]
	cmp r0,#ButtonPress   @ selection menu
	bne 1f
	@ affichage des sous menus
	mov r0,r6         					@ adresse du display 
	ldr r1,iAdrstMenu1_1A      	@ structure du sous menu
	ldr r1,[r1,#BT_adresse]
	bl XMapWindow
	mov r0,r6     @ adresse du display
	ldr r1,iAdrstMenu1_1A
	bl ecritureTexteBouton
	mov r0,r6         					@ adresse du display 
	ldr r1,iAdrstMenu1_2A      	@ structure du sous menu
	ldr r1,[r1,#BT_adresse]
	bl XMapWindow
	mov r0,r6     @ adresse du display
	ldr r1,iAdrstMenu1_2A
	bl ecritureTexteBouton
	mov r0,r6         					@ adresse du display 
	ldr r1,iAdrstMenu1_3A      	@ structure du sous menu
	ldr r1,[r1,#BT_adresse]
	bl XMapWindow
	mov r0,r6     @ adresse du display
	ldr r1,iAdrstMenu1_3A
	bl ecritureTexteBouton
	b 100f
1:
	cmp r0,#EnterNotify    @ la souris passe sur une fenêtre
	bne 2f
	ldr r3,iAdrstFenetreChge
	mov r2,#3
	str r2,[r3,#XWCH_border_width]
	mov r0,r6
	ldr r2,iFenSMask
	bl XConfigureWindow
	b 100f
2:
	cmp r0,#LeaveNotify   @ la souris quitte une fenêtre
	bne 3f
	ldr r3,iAdrstFenetreChge
	mov r2,#1
	str r2,[r3,#XWCH_border_width]
	mov r0,r6
	ldr r2,iFenSMask
	bl XConfigureWindow
	b 100f
3:

100:
    pop {fp,lr}
    bx lr
iAdrstMenu1_1A: .int stMenu1_1
iAdrstMenu1_2A: .int stMenu1_2
iAdrstMenu1_3A: .int stMenu1_3
/********************************************************************/
/*   Evenements du menu Quitter                                      ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ r1 doit contenir l'adresse de la fenetre
@ sauvegarde des registres
gestionEvtMenuQuitter:
	push {fp,lr}      @ save des  2 registres
	ldr r0,[r0,#XAny_type]
	cmp r0,#ButtonPress   @ selection menu
	bne 1f
	mov r0,#1     @ fin du programme
	b 100f
1:
	cmp r0,#EnterNotify    @ la souris passe sur une fenêtre
	bne 2f
	ldr r3,iAdrstFenetreChge
	mov r2,#3
	str r2,[r3,#XWCH_border_width]
	mov r0,r6
	ldr r2,iFenSMask
	bl XConfigureWindow
	mov r0,#0
	b 100f
2:
	cmp r0,#LeaveNotify   @ la souris quitte une fenêtre
	bne 3f
	ldr r3,iAdrstFenetreChge
	mov r2,#1
	str r2,[r3,#XWCH_border_width]
	mov r0,r6
	ldr r2,iFenSMask
	bl XConfigureWindow
	mov r0,#0
	b 100f
3:
	mov r0,#0
100:
    pop {fp,lr}
    bx lr
/********************************************************************/
/*   Evenements du menu Cercle                                      ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ r1 doit contenir l'adresse de la fenetre
@ sauvegarde des registres
gestionEvtMenuCercle:
	push {fp,lr}      @ save des  2 registres
	ldr r0,[r0,#XAny_type]
	cmp r0,#ButtonPress   @ selection menu
	bne 1f
	mov r0,r6
	bl dessinCercle
	b 100f
1:
	cmp r0,#EnterNotify    @ la souris passe sur une fenêtre
	bne 2f
	ldr r3,iAdrstFenetreChge
	mov r2,#3
	str r2,[r3,#XWCH_border_width]
	mov r0,r6
	ldr r2,iFenSMask
	bl XConfigureWindow
	mov r0,#0
	b 100f
2:
	cmp r0,#LeaveNotify   @ la souris quitte une fenêtre
	bne 3f
	ldr r3,iAdrstFenetreChge
	mov r2,#1
	str r2,[r3,#XWCH_border_width]
	mov r0,r6
	ldr r2,iFenSMask
	bl XConfigureWindow
	mov r0,#0
	b 100f
3:
	mov r0,#0
100:
    pop {fp,lr}
    bx lr
/********************************************************************/
/*   Evenements du menu Poly                                     ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ r1 doit contenir l'adresse de la fenetre
@ sauvegarde des registres
gestionEvtMenuPoly:
	push {fp,lr}      @ save des  2 registres
	ldr r0,[r0,#XAny_type]
	cmp r0,#ButtonPress   @ selection menu
	bne 1f
	mov r0,r6
	bl dessinPolygone
	b 100f
1:
	cmp r0,#EnterNotify    @ la souris passe sur une fenêtre
	bne 2f
	ldr r3,iAdrstFenetreChge
	mov r2,#3
	str r2,[r3,#XWCH_border_width]
	mov r0,r6
	ldr r2,iFenSMask
	bl XConfigureWindow
	mov r0,#0
	b 100f
2:
	cmp r0,#LeaveNotify   @ la souris quitte une fenêtre
	bne 3f
	ldr r3,iAdrstFenetreChge
	mov r2,#1
	str r2,[r3,#XWCH_border_width]
	mov r0,r6
	ldr r2,iFenSMask
	bl XConfigureWindow
	mov r0,#0
	b 100f
3:
	mov r0,#0
100:
    pop {fp,lr}
    bx lr
/********************************************************************/
/*   Evenements du menu Fonction                                      ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ r1 doit contenir l'adresse de la fenetre
@ sauvegarde des registres
gestionEvtMenuFonction:
	push {fp,lr}      @ save des  2 registres
	ldr r0,[r0,#XAny_type]
	cmp r0,#ButtonPress   @ selection menu
	bne 1f
	@ affichage des sous menus
	mov r0,r6         					@ adresse du display 
	ldr r1,iAdrstMenu2_1A      	@ structure du sous menu
	ldr r1,[r1,#BT_adresse]
	bl XMapWindow
	mov r0,r6     @ adresse du display
	ldr r1,iAdrstMenu2_1A
	bl ecritureTexteBouton
	mov r0,r6         					@ adresse du display 
	ldr r1,iAdrstMenu2_2A      	@ structure du sous menu
	ldr r1,[r1,#BT_adresse]
	bl XMapWindow
	mov r0,r6     @ adresse du display
	ldr r1,iAdrstMenu2_2A
	bl ecritureTexteBouton
	b 100f
1:
	cmp r0,#EnterNotify    @ la souris passe sur une fenêtre
	bne 2f
	ldr r3,iAdrstFenetreChge
	mov r2,#3
	str r2,[r3,#XWCH_border_width]
	mov r0,r6
	ldr r2,iFenSMask
	bl XConfigureWindow
	mov r0,#0
	b 100f
2:
	cmp r0,#LeaveNotify   @ la souris quitte une fenêtre
	bne 3f
	ldr r3,iAdrstFenetreChge
	mov r2,#1
	str r2,[r3,#XWCH_border_width]
	mov r0,r6
	ldr r2,iFenSMask
	bl XConfigureWindow
	mov r0,#0
	b 100f
3:  @ et il faudrait gerer le masquage du menu
	mov r0,#0
100:
    pop {fp,lr}
    bx lr
iAdrstMenu2_1A: .int stMenu2_1
iAdrstMenu2_2A: .int stMenu2_2
/********************************************************************/
/*   Evenements du menu GCxor                                     ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ r1 doit contenir l'adresse de la fenetre
@ sauvegarde des registres
gestionEvtMenuGCxor:
	push {fp,lr}      @ save des  2 registres
	ldr r0,[r0,#XAny_type]
	cmp r0,#ButtonPress   @ selection menu
	bne 1f
	mov r0,r6          @ adresse du display
	ldr r1,iAdrptGC2A @ adresse du contexte graphique simple bis
	ldr r1,[r1]
	mov r2,#GXxor
	bl XSetFunction

	b 100f
1:
	cmp r0,#EnterNotify    @ la souris passe sur une fenêtre
	bne 2f
	ldr r3,iAdrstFenetreChge
	mov r2,#3
	str r2,[r3,#XWCH_border_width]
	mov r0,r6
	ldr r2,iFenSMask
	bl XConfigureWindow
	mov r0,#0
	b 100f
2:
	cmp r0,#LeaveNotify   @ la souris quitte une fenêtre
	bne 3f
	ldr r3,iAdrstFenetreChge
	mov r2,#1
	str r2,[r3,#XWCH_border_width]
	mov r0,r6
	ldr r2,iFenSMask
	bl XConfigureWindow
	mov r0,#0
	b 100f
3:
	mov r0,#0
100:
    pop {fp,lr}
    bx lr
/********************************************************************/
/*   Evenements du menu GCand                                     ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ r1 doit contenir l'adresse de la fenetre
@ sauvegarde des registres
gestionEvtMenuGCand:
	push {fp,lr}      @ save des  2 registres
	ldr r0,[r0,#XAny_type]
	cmp r0,#ButtonPress   @ selection menu
	bne 1f
	mov r0,r6          @ adresse du display
	ldr r1,iAdrptGC2A @ adresse du contexte graphique simple bis
	ldr r1,[r1]
	mov r2,#GXand
	//mov r2,#10
	bl XSetFunction

	b 100f
1:
	cmp r0,#EnterNotify    @ la souris passe sur une fenêtre
	bne 2f
	ldr r3,iAdrstFenetreChge
	mov r2,#3
	str r2,[r3,#XWCH_border_width]
	mov r0,r6
	ldr r2,iFenSMask
	bl XConfigureWindow
	mov r0,#0
	b 100f
2:
	cmp r0,#LeaveNotify   @ la souris quitte une fenêtre
	bne 3f
	ldr r3,iAdrstFenetreChge
	mov r2,#1
	str r2,[r3,#XWCH_border_width]
	mov r0,r6
	ldr r2,iFenSMask
	bl XConfigureWindow
	mov r0,#0
	b 100f
3:
	mov r0,#0
100:
    pop {fp,lr}
    bx lr

/********************************************************************/
/*   Evenements du menu Aide                                      ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ r1 doit contenir l'adresse de la fenetre
@ sauvegarde des registres
gestionEvtMenuAide:
	push {fp,lr}      @ save des  2 registres
	ldr r0,[r0,#XAny_type]
	cmp r0,#ButtonPress   @ selection menu
	bne 1f
	mov r0,r6
	ldr r1,iAdrsTexteAide
	@ et l'afficher dans une fenetre de message.
	ldr r2,iLongTexteAide
	mov r3,#0
	bl creationFenetreMessage
	b 100f
1:
	cmp r0,#EnterNotify    @ la souris passe sur une fenêtre
	bne 2f
	ldr r3,iAdrstFenetreChge
	mov r2,#3
	str r2,[r3,#XWCH_border_width]
	mov r0,r6
	ldr r2,iFenSMask
	bl XConfigureWindow
	b 100f
2:
	cmp r0,#LeaveNotify   @ la souris quitte une fenêtre
	bne 3f
	ldr r3,iAdrstFenetreChge
	mov r2,#1
	str r2,[r3,#XWCH_border_width]
	mov r0,r6
	ldr r2,iFenSMask
	bl XConfigureWindow
	b 100f
3:
100:
    pop {fp,lr}
    bx lr
iAdrsTexteAide: .int sTexteAide
iLongTexteAide: .int LGTEXTEAIDE
iFenSMask:   .int  CWBorderWidth
iAdrstFenetreChge: .int stFenetreChge
/********************************************************************/
/*   Evenements de la fenêtre des messages                         ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ r1 doit contenir l'adresse de la fenetre
@ sauvegarde des registres
evtFenetreMessage:
	push {fp,lr}      @ save des  2 registres
	ldr r0,[r0,#XAny_type]
	cmp r0,#ClientMessage   @ cas pour fermeture fenetre 
	bne 1f
	mov r0,r6
	bl  XDestroyWindow
	cmp r0,#0
	bgt 100f
	vidregtit EvtFS_ERREUR
	b 100f
1:
	cmp r0,#Expose          @ cas d'une modification de la fenetre ou son masquage
	bne 100f
	mov r5,r1
	mov r0,r6     @ adresse du display
	ldr r1,iAdrstBoutonOKMessage
	bl ecritureTexteBouton
	@ il faut aussi afficher le texte du message
	mov r0,r6          @ adresse du display
	mov r1,r5          @ adresse de la fenetre
	ldr r2,iAdrsTexteAide
	@ et l'afficher dans une fenetre de message.
	ldr r3,iLongTexteAide
	bl afficheTexteMessage
	
100:
    pop {fp,lr}
    bx lr


/********************************************************************/
/*   Evenements du bouton Ok fenetre message                   ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ r1 doit contenir l'adresse de la fenetre
@ pas de sauvegarde des registres
gestionEvtBoutonMessage:
	push {fp,lr}      @ save des  2 registres
	ldr r0,[r0,#XAny_type]
	cmp r0,#ButtonPress    @ cas d'un bouton souris 
	bne 100f
	vidregtit EvtFS_bouton_ok_1
	@ bouton OK fermeture de la fenetre
	mov r0,r6   @ display
	ldr r1,iAdrptFenetreM
	ldr r1,[r1]
	bl  XDestroyWindow
	cmp r0,#0
	bgt 100f
	vidregtit EvtBS_ERREUR
100:
    pop {fp,lr}
    bx lr        	
/********************************************************************/
/*   Dessin d'un Cercle                                    ***/
/********************************************************************/
@ pas de sauvegarde des registres
dessinCercle:
	push {fp,lr}      @ save des  2 registres 
	/* changement de la couleur du GC Bis */
	mov r0,r6          @ adresse du display
	ldr r1,iAdrptGC2A   @ adresse du contexte graphique simple bis
	ldr r1,[r1]
	ldr r2,iCoulBleue
	bl XSetForeground
	/* dessin du cercle */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	ldr r2,iAdrptGC2A @ adresse du contexte graphique simple bis
	ldr r2,[r2]
	mov r3,#200         @ position x 
	sub sp,sp,#4
	mov r4,#360 * 64   @ angle d'arrivée
	push {r4}
	mov r4,#0          @ angle de départ
	push {r4}
	mov r4,#100        @  axe des Y  
	push {r4}         
	mov r4,#100        @ axe des X    si les 2 valeurs sont différentes, ce sera une ellipse
	push {r4}
	mov r4,#150        @ position y 
	push {r4}
	//bl XDrawArc     @ cercle vide
	bl XFillArc        @ cercle plein
	add sp,sp,#24       @ pour les 5 push et l'alignement
100:
    pop {fp,lr}
    bx lr
iCoulBleue: .int 0x000000FF
iAdrptGC2A: .int ptGC2
/********************************************************************/
/*   Dessin d'un Polygone                                    ***/
/********************************************************************/
@ pas de sauvegarde des registres
dessinPolygone:
	push {fp,lr}      @ save des  2 registres 
	/* changement de la couleur du GC Bis */
	@PointsPoly
	ldr r0,iPointsPoly         @ adresse des points
	mov r0,r6          @ adresse du display
	ldr r1,iAdrptGC2A   @ adresse du contexte graphique simple bis
	ldr r1,[r1]
	ldr r2,iCoulVerte
	bl XSetForeground
	/* dessin polygone */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	ldr r2,iAdrptGC2A @ adresse du contexte graphique simple bis
	ldr r2,[r2]
	ldr r3,iPointsPoly         @ adresse des points
	mov r4,#0        @  alignement  
	push {r4}  
	mov r4,#CoordModeOrigin        @  mode  
	push {r4}         
	mov r4,#Convex        @ forme 
	push {r4}
	mov r4,#5        @ nombre de points
	push {r4}
	bl XFillPolygon        @  plein
	add sp,sp,#16       @ pour les 4 push 
100:
    pop {fp,lr}
    bx lr
iCoulVerte: .int 0x0000FF00
iPointsPoly: .int PointsPoly

/*********************************************************************/
/* constantes Générales              */
.include "../../asm/constantesARM.inc"
	