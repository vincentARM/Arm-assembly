/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* création fenetre X11 avec creation d'image bitmap */
/* lecture image créee avec bitmap */
/*********************************************/
/*constantes                                 */
/********************************************/
@ le ficher des constantes générales est en fin du programme
.equ LARGEUR, 600    @ largeur de la fenêtre
.equ HAUTEUR, 400    @ hauteur de la fenêtre
.equ LGBUFFER, 100   @ longueur du buffer 


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
szRouge:		 .asciz "red"
szNomFichier:  .asciz "img2"
/* libellé special pour correction pb fermeture */
szLibDW: .asciz "WM_DELETE_WINDOW"
.align 4
hauteur: .int HAUTEUR
largeur: .int LARGEUR

/* polices de caracteres */
szNomPolice: .asciz  "-*-helvetica-bold-*-normal-*-14-*"
szNomPolice1: .asciz  "-*-fixed-bold-*-normal-*-14-*"
.align 4					
iLargeurImg: .int 50
iHauteurImg: .int 25
PixelsImg1:  
.byte 0x00 , 0x00 , 0x00 , 0x00 , 0x00 , 0x00 , 0x00 , 0x00 , 0x00 , 0x00 , 0x00 , 0x00 
.byte 0x00 , 0x00 , 0x00 , 0x00 , 0x00 , 0x1f , 0x00 , 0x00 , 0x00 , 0x00 , 0x00 , 0xc0 
.byte 0x7f , 0x00 , 0x00 , 0x00 , 0x00 , 0x00 , 0xe0 , 0xff , 0x00 , 0x0e , 0x00 , 0x00 
.byte 0x1f , 0xe0 , 0xff , 0xc0 , 0x7f , 0x00 , 0xc0 , 0x60 , 0xf0 , 0xff , 0xe1 , 0xff 
.byte 0x00 , 0x30 , 0x80 , 0xf1 , 0xff , 0xf1 , 0xff , 0x01 , 0x08 , 0x00 , 0xf2 , 0xff 
.byte 0xf9 , 0xff , 0x03 , 0x08 , 0x00 , 0xf2 , 0xff , 0xfd , 0xff , 0x03 , 0x04 , 0x00 
.byte 0xf4 , 0xff , 0xfd , 0xf  , 0x03 , 0x04 , 0x00 , 0xe4 , 0xff , 0xfc , 0xff , 0x03 
.byte 0xfa , 0x03 , 0xe8 , 0xff , 0xfe , 0xff , 0x03 , 0xfe , 0x07 , 0xc8 , 0x7f , 0xfe 
.byte 0xff , 0x03 , 0xfe , 0x0f , 0x08 , 0x1f , 0xfe , 0xff , 0x03 , 0xfe , 0x0f , 0x08 
.byte 0x00 , 0xfc , 0xff , 0x03 , 0xfe , 0x0f , 0x08 , 0x18 , 0xfc , 0xff , 0x03 , 0xfe 
.byte 0x0f , 0x04 , 0x3c , 0xfc , 0xff , 0x03 , 0xfe , 0x0f , 0x04 , 0x3e , 0xf8 , 0xff 
.byte 0x03 , 0xfe , 0x0f , 0x02 , 0x7f , 0xf0 , 0xff , 0x01 , 0xfe , 0x0f , 0x02 , 0xff 
.byte 0xe0 , 0xff , 0x00 , 0xfc , 0x87 , 0x81 , 0xff , 0xc0 , 0x7f , 0x00 , 0xf8 , 0x63 
.byte 0xc0 , 0xff , 0x01 , 0x0e , 0x00 , 0x00 , 0x1f , 0xe0 , 0xff , 0x01 , 0x00 , 0x00 
.byte 0x00 , 0x00 , 0x00 , 0xf0 , 0x03 , 0x00 , 0x00

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
ptImg1:     .skip 4 
ptImg2:     .skip 4
iLargeurImg2:  .skip 4
iHauteurImg2:		.skip 4
x_hot:				.skip 4
y_hot:				.skip 4

key: .skip 4              @ code touche
iLongTexte: .skip 4
wmDeleteMessage: .skip 8   @ identification message de fermeture


event: .skip 400          @ TODO revoir cette taille 
buffer:  .skip LGBUFFER 

/* Structures des données */  
.align 4
stAttributs:  .skip Att_fin        @ reservation place structure Attibuts 
.align 4
stXGCValues:  .skip XGC_fin        @ reservation place structure XGCValues
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

.align 4
Closest:  .skip XColor_fin     @ reservation place structure XColor
Exact:   .skip XColor_fin

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
	
	/* chargement couleurs */
	mov r0,r6
	mov r1,r7
	bl chargementCouleurs
	cmp r0,#0
	beq 100f
	
	vidregtit fincolor

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
	mov r2,r7
	bl creationGC
	cmp r0,#0
	beq erreurGC

	/* creation image */
	mov r0,r6
	mov r1,r9
	mov r2,r7
	bl creationImage
	/* lecture image */
	mov r0,r6
	mov r1,r9
	mov r2,r7
	bl lectureImage
	
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
	beq 99f	         @ police non trouvée  
	ldr r1,iAdrptPolice
	str r0,[r1]
	mov r0,r6        @ Display
	ldr r1,iAdrszNomPolice1 		@ nom de la police 
	bl XLoadQueryFont
	cmp r0,#0
	beq 99f	         @ police non trouvée  
	ldr r1,iAdrptPolice1
	str r0,[r1]
	
	b 100f
	
99:   @ police non trouvée 
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
/*   Chargement des polices utilisées                             ***/
/********************************************************************/	
@ r0 pointeur vers le Display
@ r1 pointeur vers l'écran
@ sauvegarde des registres
chargementCouleurs:
	push {fp,lr}    /* save des  2 registres */
	push {r6}
	mov r6,r0    @ save Display
	mov r7,r1    @ save ecran
	/* chargement couleurs */
	mov r0,r6
	mov r1,#0
	vidregtit color
	bl XDefaultColormap
	cmp r0,#0
	beq 2f
	vidregtit color1
	mov r1,r0    @ pointeur colormap
	mov r0,r6    @ display
	ldr r2,iAdrszRouge
	ldr r3,iAdrExact
	mov r4,#0
	push {r4}
	ldr r4,iAdrClosest
	push {r4}
	bl XAllocNamedColor
	add sp,#8     @ remise à  niveau pile car 2 push
	cmp r0,#0
	beq 2f
	ldr r0,iAdrClosest
	ldr r0,[r0,#XColor_pixel]
	vidregtit color2
	
	b 100f
2:   @ pb couleur 
	ldr r1,iAdrszMessErreurX11 
    bl   afficheerreur   
	mov r0,#0       /* code erreur */
100:	
    pop {r6}
    pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */	
iAdrszRouge:  .int  szRouge
iAdrClosest: .int Closest
iAdrExact:   .int Exact
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
	ldr r4,iAdrClosest
	ldr r4,[r4,#XColor_pixel]
	//ldr r4,iGris1    @ couleur du fond
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
	
	/* modif du fond de fenêtre */
	mov r0,r6          @ adresse du display 
	mov r1,r5             @ adresse fenêtre 
	ldr r2,iAdrClosest
	ldr r2,[r2,#XColor_pixel]
//	bl XSetWindowBackground   
//	cmp r0,#0
//	ble   3f
	
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
/*   Création de l'image                                          ***/
/********************************************************************/	
@ r0 pointeur vers le Display
@ r1 pointeur vers fenêtre
@ r2 pointeur ecran
@ sauvegarde des registres
creationImage:
	push {fp,lr}    /* save des  2 registres */
	push {r6}
	mov r6,r0    @ save Display
	mov r9,r1    @ save fenetre
	mov r7,r2    @ save ecran
	ldr r2,iAdrPixelsImg1
	ldr r3,iAdriLargeurImg      @ largeur image
	ldr r3,[r3]
	ldr r4,[r7,#Screen_root_depth]
	push {r4}
	ldr r4,[r7,#Screen_black_pixel]    @ pixel Background
	push {r4}
	ldr r4,[r7,#Screen_white_pixel]    @ pixel Foreground
	push {r4}
	ldr r4,iAdriHauteurImg      @ hauteur image
	ldr r4,[r4]
	push {r4}
	bl XCreatePixmapFromBitmapData
	add sp,sp,#16   @ pour les 4 push
	cmp r0,#0
	beq 99f
	ldr r1,iAdrptImg1
	str r0,[r1]
	vidregtit creaimage
	B 100f
99:
	ldr r1,iAdrszMessErreurX11   @ erreur X11
    bl   afficheerreur   
	mov r0,#0   @ code erreur
100:	
    pop {r6}
    pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */
iAdrPixelsImg1: .int PixelsImg1
iAdrptImg1: .int  ptImg1
/********************************************************************/
/*   Lecture d'un fichier image                                          ***/
/********************************************************************/	
@ r0 pointeur vers le Display
@ r1 pointeur vers fenêtre
@ r2 pointeur ecran
@ sauvegarde des registres
lectureImage:
	push {fp,lr}    /* save des  2 registres */
	push {r6}
	mov r6,r0    @ save Display
	mov r9,r1    @ save fenetre
	mov r7,r2    @ save ecran

	mov r0,r6
	mov r1,r9
	ldr r2,iAdrszNomFichier
	ldr r3,iAdriLargeurImg2
	ldr r4,iAdry_hot
	push {r4}
	ldr r4,iAdrx_hot
	push {r4}
	ldr r4,iAdrptImg2
	push {r4}
	ldr r4,iAdriHauteurImg2
	push {r4}
	bl XReadBitmapFile
	add sp,sp,#16   @ pour les 4 push
	cmp r0,#0
	bne 99f
	@ 
	ldr r1,iAdrptImg2
	ldr r0,[r1]
	vidregtit lectureimage
	b 100f
99:
	ldr r1,iAdrszMessErreurX11   @ erreur X11
    bl   afficheerreur   
	mov r0,#0   @ code erreur
100:	
    pop {r6}
    pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */
iAdrptImg2: .int  ptImg2
iAdrszNomFichier: .int szNomFichier
iAdriLargeurImg2: .int iLargeurImg2
iAdriHauteurImg2: .int iHauteurImg2
iAdrx_hot:    .int x_hot
iAdry_hot:    .int y_hot
/********************************************************************/
/*   Création contexte graphique                                  ***/
/********************************************************************/	
/* r0 contient le display, r1 la fenêtre r2 l 'ecran*/
creationGC:
	push {fp,lr}    /* save des  2 registres */
	push {r4-r7}
	/* creation contexte graphique simple */
	mov r6,r0          @ save adresse du display
	mov r5,r1          @ adresse fenetre
	mov r7,r2
	mov r2,#0
	mov r3,#0
	bl XCreateGC
	cmp r0,#0
	beq 99f	
	ldr r1,iAdrptGC
	str r0,[r1]   @ stockage adresse contexte graphique   
	mov r8,r0     @ et stockage dans r8
	mov r0,r6          @ adresse du display 
	mov r1,r8          @ adresse GC 
	ldr r2,[r7,#Screen_white_pixel]
	bl XSetForeground
	cmp r0,#0
	beq 99f	
	mov r0,r6          @ adresse du display 
	mov r1,r8          @ adresse GC 
	ldr r2,[r7,#Screen_black_pixel]
	bl XSetBackground
	cmp r0,#0
	beq 99f	
	
	/* création contexte graphique avec autre couleur de fond */
	mov r0,r6          @ adresse du display 
	mov r1,r5          @ adresse fenetre 
	mov r2,#0
	mov r3,#0
	bl XCreateGC
	cmp r0,#0
	beq 99f	
	ldr r1,iAdrptGC1
	str r0,[r1]   @ stockage adresse contexte graphique dans zone gc2 
	mov r1,r0     @ adresse du nouveau GC
	mov r0,r6          @ adresse du display 
	ldr r2,iAdrClosest
	ldr r2,[r2,#XColor_pixel]   @ fond rouge identique à la fenêtre principale
	bl XSetBackground
	cmp r0,#0
	beq 99f	
	mov r0,r6          @ adresse du display 
	ldr r1,iAdrptGC1
	ldr r1,[r1]   @ stockage adresse contexte graphique dans zone gc2 
	ldr r2,[r7,#Screen_white_pixel]
	bl XSetForeground
	cmp r0,#0
	beq 99f	
	
	/* creation contexte graphique simple BIS */
	mov r0,r6          @ adresse du display
	mov r1,r5          @ adresse fenetre
	mov r2,#0
	mov r3,#0
	bl XCreateGC
	cmp r0,#0
	beq 99f	
	ldr r1,iAdrptGC2
	str r0,[r1]   @ stockage adresse contexte graphique  
	b 100f

99:   /* erreur creation contexte graphique  */
	ldr r1,iAdrszMessErrGc  
    bl   afficheerreur  
	mov r0,#0       /* code erreur */
	b 100f
100:
	pop {r4-r7}
    pop {fp,lr}
    bx lr        	
//iRouge: 					.int 0xFFFF0000
iAdrptGC:   				.int ptGC
iAdrptGC1:  				.int ptGC1
iAdrptGC2:				.int ptGC2
iAdrszMessErrGc: 		.int szMessErrGc
//iGC1mask: 				.int GCFont
//iGCmask: 					.int GCFont
iAdrstXGCValues: 		.int stXGCValues


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
1:  @ si autre bouton ou fenêtre à traiter
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
@ pas de sauvegarde des registres
evtFenetrePrincipale:
	push {fp,lr}      @ save des  2 registres
	ldr r0,[r0,#XAny_type]
	cmp r0,#ClientMessage   @ cas pour fermeture fenetre sans erreur 
	beq fermeture
	cmp r0,#ButtonPress    @ cas d'un bouton souris
	beq evtboutonsouris
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
	mov r0,r6         					@ adresse du display 

	mov r0,#0
	b 100f
evtboutonsouris:
    ldr r0,iAdrevent
	vidmemtit bouton r0 5
	ldr r0,[r0,#XBE_button]
	cmp r0,#1
	/* appui sur le bouton souris 1 le gauche */
	ldreq r1,iAdrptImg1     @ source = pointeur image 
	ldreq r10,iAdriLargeurImg
	ldreq r11,iAdriHauteurImg
	ldreq r3,iAdrptGC    @ contexte graphique simple
	/* sinon appui sur autre bouton */
	ldrne r1,iAdrptImg2     @ source = pointeur image 
	ldrne r10,iAdriLargeurImg2
	ldrne r11,iAdriHauteurImg2
	ldrne r3,iAdrptGC1    @ contexte graphique 
	ldr r1,[r1]
	mov r2,r9     @ destination = fenêtre  
	ldr r3,[r3]
	mov r4,#0    @ alignement pile
	push {r4}
	mov r4,#1          @ nombre de couche (plane)
	push {r4}
	ldr r0,iAdrevent     @ evenement de type XButtonEvent
	ldr r4,[r0,#XBE_y]    @ position Y du clic souris
	push {r4}
	ldr r4,[r0,#XBE_x]    @ position X du clic souris
	push {r4}
	ldr r4,[r11]
	push {r4}
	ldr r4,[r10]
	push {r4}
	mov r4,#0     @ position Y de l'image dans la source
	push {r4}
	mov r4,#0   @ position X de l'image dans la source
	push {r4}
	mov r0,r6        @ display
	bl XCopyPlane
	add sp,sp,#32       @ pour les 7 push et l'alignement
	cmp r0,#0
	beq 99f
	mov r0,#0
	b 100f

99:
	ldr r1,iAdrszMessErreurX11   @ erreur X11
    bl   afficheerreur   
	mov r0,#0  
100:
    pop {fp,lr}
    bx lr
iAdriLargeurImg:  .int iLargeurImg
iAdriHauteurImg:  .int iHauteurImg




/*********************************************************************/
/* constantes Générales              */
.include "../../asm/constantesARM.inc"
	