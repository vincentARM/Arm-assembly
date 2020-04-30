/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* création fenetre X11 modification forme du curseur souris */
/* tentative traitement icone, et structure dessin XPM   non concluant */
/*********************************************/
/*constantes                                 */
/********************************************/
@ le ficher des constantes générales est en fin du programme
.equ LARGEUR, 600    @ largeur de la fenêtre
.equ HAUTEUR, 400    @ hauteur de la fenêtre
.equ LGBUFFER, 1000   @ longueur du buffer 


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
szBlack:		 .asciz "black"
szWhite:		 .asciz "white"
//szNomFichier:  .asciz "img2"
szNomIcone: .asciz "iconeasm.btm"
szNomImage1: .asciz "Coquelicots.bmp"
/* libellé special pour correction pb fermeture */
szLibDW: .asciz "WM_DELETE_WINDOW"

/* polices de caracteres */
szNomPolice: .asciz  "-*-helvetica-bold-*-normal-*-14-*"
szNomPolice1: .asciz  "-*-fixed-bold-*-normal-*-14-*"
.align 4
hauteur: .int HAUTEUR
largeur: .int LARGEUR
/* dessin du curseur souris en forme de flèche */
iArrow_width: .int  16
iArrow_height: .int  16
arrow_bits:
.byte 0x00 , 0x00 , 0x06 , 0x00 , 0x0e , 0x00 , 0x3c , 0x00 , 0xf8 , 0x00 , 0xf8 , 0x01 
.byte 0xf0 , 0x07 , 0xf0 , 0x0f , 0xf0 , 0x1f , 0xe0 , 0x7f , 0xe0 , 0x7f , 0xc0 , 0x7f
.byte 0x80 , 0x7f , 0x80 , 0x7f , 0x00 , 0x7f , 0x00 , 0x00
.align 4
/* dessin du masque du curseur souris */
iArrowmask_width: .int 16
iArrowmask_height: .int 16
iArrowmask_x_hot: .int 0
iArrowmask_y_hot:  .int 0
arrowmask_bits:
.byte 0x1f , 0x00 , 0x3f , 0x00 , 0xff , 0x00 , 0xff , 0x03 , 0xff , 0x07 , 0xfe , 0x0f
.byte 0xfc , 0x1f , 0xfc , 0x3f , 0xf8 , 0x7f , 0xf8 , 0xff , 0xf0 , 0xff , 0xf0 , 0xff
.byte 0xe0 , 0xff , 0xc0 , 0xff , 0x80 , 0xff , 0x80 , 0xff

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
ptDisplay:  .skip 4     @ pointeur display
ptEcran: .skip 4     @ pointeur ecran standard
ptGC:        .skip 4      @ pointeur contexte graphique
ptGC1:        .skip 4      @ pointeur contexte graphique 1
ptGC2:        .skip 4      @ pointeur contexte graphique 2
ptPolice:   .skip 4      @ pointeur police de caractères
ptPolice1:  .skip 4     @ pointeur police de caractères 1
ptCurseur:  .skip 4     @ pointeur curseur
ptImg1:     .skip 4      @ pointeur image
ptImg2:     .skip 4
ptIcone: .skip 4
ptIcone2: .skip 4
iLargeurIcone:  .skip 4
iHauteurIcone:	.skip 4
x_hot:				.skip 4
y_hot:				.skip 4


wmDeleteMessage: .skip 8   @ identification message de fermeture


event: .skip 400          @ TODO revoir cette taille 
sBuffer:  .skip LGBUFFER 

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
stWmHints:   .skip  Hints_fin   @ reservation place pour structure XWMHints 
.align 4
stAttrSize:   .skip XSize_fin      @ reservation place structure XSizeHints
.align 4
stImageBMP1:   .skip BMP_fin
.align 4
Closest:  .skip XColor_fin     @ reservation place structure XColor
Exact:   .skip XColor_fin
Front:   .skip XColor_fin
Backing:   .skip XColor_fin
TableFenetres:
stFenetrePrinc:  .skip  Win_fin    @ reservation place structure fenêtre
stFenetreSec1:   .skip  Win_fin    @ reservation place structure fenêtre
stFenetreSec2:   .skip  Win_fin    @ reservation place structure fenêtre
stFenetreSec3:   .skip  Win_fin    @ reservation place structure fenêtre
stFenetreSec4:   .skip  Win_fin    @ reservation place structure fenêtre
stFenetreFin:    .skip   Win_fin    @ structure de la fin de la table des fenetre
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

	/* création de la fenetre principale */
	mov r0,r6
	mov r1,r7
	ldr r2,iAdrstFenetrePrinc
	bl creationFenetrePrincipale
	cmp r0,#0
	beq erreurF
	mov r9,r0      @ adresse fenêtre dans r9

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
	bl creationImages
	
	/* création curseur */
	mov r0,r6
	mov r1,r9
	mov r2,r7
	bl creationCurseur
	
	/* création des 3 fenêtres secondaires */
	mov r0,r6
	mov r1,r9
	mov r2,r7
	ldr r3,iAdrstFenetreSec1
	bl creationFenetreSec1
	mov r0,r6
	mov r1,r9
	mov r2,r7
	ldr r3,iAdrstFenetreSec2
	bl creationFenetreSec2

	mov r0,r6
	mov r1,r9
	mov r2,r7
	ldr r3,iAdrstFenetreSec3
	bl creationFenetreSec3
	
	/*   chargement image BMP */
	ldr r0,iAdrszNomImage1   @ pointeur nom du fichier à charger
	ldr r1,iAdrstImageBMP1   @ pointeur structure image
	bl chargeImageBMP
	cmp r0,#0            @ erreur chargement ?
	bne 100f
	
	/* création de l'image X11   */
	mov r0,r6
	mov r1,r7
	ldr r2,iAdrstImageBMP1   @ pointeur structure image
	bl creationImageBMP
	
	/* création fenetre 4 avec dimension de l'image BMP et affichage image */
	mov r0,r6
	mov r1,r9
	mov r2,r7
	ldr r3,iAdrstFenetreSec4
	bl creationFenetreSec4
	
	
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
iAdrstFenetrePrinc:	.int stFenetrePrinc
iAdrstFenetreSec1:		.int stFenetreSec1
iAdrstFenetreSec2:		.int stFenetreSec2
iAdrstFenetreSec3:		.int stFenetreSec3
iAdrstFenetreSec4:		.int stFenetreSec4
iAdrszNomImage1: 		.int szNomImage1
iAdrstImageBMP1:  		.int stImageBMP1
/********************************************************************/
/*   Connexion serveur X et recupération informations du display  ***/
/********************************************************************/	
@ retourne dans r0 le pointeur vers le Display
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
	push {r6-r8}
	mov r6,r0    @ save Display
	mov r7,r1    @ save ecran
	/* chargement couleurs */
	mov r0,r6
	mov r1,#0
	vidregtit color
	bl XDefaultColormap
	cmp r0,#0
	beq 2f
	mov r8,r0    @ save colormap
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
	/* couleur noir */
	mov r1,r8    @ pointeur colormap
	mov r0,r6    @ display
	ldr r2,iAdrszBlack
	ldr r3,iAdrExact
	mov r4,#0
	push {r4}
	ldr r4,iAdrFront
	push {r4}
	bl XAllocNamedColor
	add sp,#8     @ remise à  niveau pile car 2 push
	cmp r0,#0
	beq 2f
	/* couleur blanc */
	mov r1,r8    @ pointeur colormap
	mov r0,r6    @ display
	ldr r2,iAdrszWhite
	ldr r3,iAdrExact
	mov r4,#0
	push {r4}
	ldr r4,iAdrBacking
	push {r4}
	bl XAllocNamedColor
	add sp,#8     @ remise à  niveau pile car 2 push
	cmp r0,#0
	beq 2f
	
	b 100f
2:   @ pb couleur 
	ldr r1,iAdrszMessErreurX11 
    bl   afficheerreur   
	mov r0,#0       /* code erreur */
100:	
    pop {r6-r8}
    pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */	
iAdrszRouge:  .int  szRouge
iAdrszBlack: .int szBlack
iAdrszWhite: .int szWhite
iAdrClosest: .int Closest
iAdrExact:   .int Exact
iAdrBacking:   .int Backing
iAdrFront:   .int Front
/********************************************************************/
/*   Creation de la fenêtre  principale                                   ***/
/********************************************************************/
/* r0 contient le Display */
/* r1 le pointeur écran */
/* r2 le poniteur structure fenêtre */
/* sauvegarde des registres   */
creationFenetrePrincipale:
	push {fp,lr}    /* save des  2 registres */
	push {r4-r9}
	mov r6,r0   @ save du Display
	mov r7,r1   @ save de l'écran
	mov r5,r2   @ save de la structure
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
	mov r4,#3      @ bordure
	push {r4}
	mov r4,#HAUTEUR       @ hauteur
	push {r4}
	mov r4,#LARGEUR     @ largeur 
	push {r4}   
	bl XCreateSimpleWindow
	add sp,#24     @ remise à  niveau pile car 6 push
	cmp r0,#0
	beq 98f
	mov r9,r0      @ stockage adresse fenetre dans le registre r9 pour usage ci dessous
	str r0,[r5,#Win_id]   @ et dans la structure

	/* ajout directives pour le serveur */
	mov r0,r6          @ display
	mov r1,r9          @ adresse fenêtre
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
	mov r1,r9          @ adresse fenetre 
	bl XSetWMHints
	
	/* lecture icone */
	mov r0,r6
	mov r1,r9
	mov r2,r7
	bl lectureImage
		/* ajout de proprietes de la fenêtre */
	mov r0,r6          @ adresse du display 
	mov r1,r9          @ adresse fenetre 
	ldr r2,iAdrszNomFenetre   @ titre de la fenêtre 
	ldr r3,iAdrszTitreFenRed  @ titre de la fenêtre reduite 
	mov r4,#0
	push {r4}          @ pointeur vers XSizeHints éventuellement
	push {r4}          @ nombre d'aguments ligne de commande 
	push {r4}          @ adresse arguments de la ligne de commande
	ldr r4,iAdrptIcone    @ ne fonctionne pas avec ce bitmap
	push {r4}
	bl XSetStandardProperties
	add sp,sp,#16   @ pour les 4 push

	/* Correction erreur fermeture fenetre */
	mov r0,r6             @ adresse du display
	ldr r1,iAdrszLibDW        @ adresse nom de l'atome
	mov r2,#1                    @ False  création de l'atome s'il n'existe pas
	bl XInternAtom
	cmp r0,#0
	ble 99f
	ldr r1,iAdrwmDeleteMessage  @ adresse de reception
	str r0,[r1]
	mov r2,r1          @ adresse zone retour precedente
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse fenetre
	mov r3,#1          @ nombre de protocoles 
	bl XSetWMProtocols
	cmp r0,#0
	ble 99f
	
	/* affichage de la fenetre */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse fenetre
	bl XMapWindow
	
	/* autorisation des saisies */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	ldr r2,iFenetreMask    @ masque pour autoriser saisies
	bl XSelectInput
	cmp r0,#0
	ble 99f
	/* chargement des donnees dans la structure */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	mov r2,r5
	bl XGetWindowAttributes
	cmp r0,#0
	ble 99f
    @ pas d'erreur

	ldr r0,iAdrevtFenetrePrincipale
	str r0,[r5,#Win_procedure]
	mov r0,r9     @ retourne l'identification de la fenetre
	b 100f
	
98:  @ erreur fenetre 
	ldr r1,iAdrszMessErrfen   
    bl   afficheerreur  
	mov r0,#0       @ code erreur 
	b 100f
99:    @ erreur X11
	ldr r1,iAdrszMessErreurX11  
    bl   afficheerreur  
	mov r0,#0       @ code erreur 
	b 100f
	
100:
	push {r4-r9}
	pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */	
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
iAdrevtFenetrePrincipale:  .int evtFenetrePrincipale
/********************************************************************/
/*   Création des images                                          ***/
/********************************************************************/	
@ r0 pointeur vers le Display
@ r1 pointeur vers fenêtre
@ r2 pointeur ecran
@ sauvegarde des registres
creationImages:
	push {fp,lr}    /* save des  2 registres */
	push {r6}
	mov r6,r0    @ save Display
	mov r9,r1    @ save fenetre
	mov r7,r2    @ save ecran
	ldr r2,iAdrarrow_bits
	ldr r3,iAdriArrow_width      @ largeur image
	ldr r3,[r3]
	mov r4,#1     @  spécifie le nombre de couches
	push {r4}
	mov r4,#0
	push {r4}
	mov r4,#1
	push {r4}
	ldr r4,iAdriArrow_height      @ hauteur image
	ldr r4,[r4]
	push {r4}
	bl XCreatePixmapFromBitmapData
	add sp,sp,#16   @ pour les 4 push
	cmp r0,#0
	beq 99f
	ldr r1,iAdrptImg1
	str r0,[r1]
	/* 2ieme image */
	mov r0,r6    @ Display
	mov r1,r9    @ fenetre
	ldr r2,iAdrarrowmask_bits
	ldr r3,iAdriArrowmask_width      @ largeur image
	ldr r3,[r3]
	//ldr r4,[r7,#Screen_root_depth]
	mov r4,#1
	push {r4}
	//ldr r4,[r7,#Screen_black_pixel]    @ pixel Background
	mov r4,#0
	push {r4}
	//ldr r4,[r7,#Screen_white_pixel]    @ pixel Foreground
	mov r4,#1
	push {r4}
	ldr r4,iAdriArrowmask_height      @ hauteur image
	ldr r4,[r4]
	push {r4}
	bl XCreatePixmapFromBitmapData
	add sp,sp,#16   @ pour les 4 push
	cmp r0,#0
	beq 99f
	ldr r1,iAdrptImg2
	str r0,[r1]

	//vidregtit creaimage
	b 100f
99:
	ldr r1,iAdrszMessErreurX11   @ erreur X11
    bl   afficheerreur   
	mov r0,#0   @ code erreur
100:	
    pop {r6}
    pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */
iAdrarrow_bits: .int arrow_bits
iAdriArrow_width: .int iArrow_width
iAdriArrow_height: .int iArrow_height
iAdrarrowmask_bits: .int arrowmask_bits
iAdriArrowmask_width: .int iArrowmask_width
iAdriArrowmask_height: .int iArrowmask_height
iAdrptImg1: .int  ptImg1
iAdrptImg2: .int  ptImg2

/********************************************************************/
/*   Création du curseur                                          ***/
/********************************************************************/	
@ r0 pointeur vers le Display
@ r1 pointeur vers fenêtre
@ r2 pointeur ecran
@ sauvegarde des registres
creationCurseur:
	push {fp,lr}    /* save des  2 registres */
	push {r6}
	mov r6,r0    @ save Display
	mov r9,r1    @ save fenetre
	ldr r1,iAdrptImg1
	ldr r1,[r1]
	ldr r2,iAdrptImg2
	ldr r2,[r2]
	ldr r3,iAdrFront
	//ldr r3,[r3]
	mov r4,#0
	push {r4}
	ldr r4,iAdriArrowmask_y_hot
	ldr r4,[r4]
	push {r4}
	ldr r4,iAdriArrowmask_x_hot
	ldr r4,[r4]
	push {r4}
	ldr r4,iAdrBacking
	//ldr r4,[r4]
	push {r4}
	bl XCreatePixmapCursor
	add sp,sp,#16   @ pour les 4 push
	cmp r0,#0
	beq 99f
	ldr r1,iAdrptCurseur
	str r0,[r1]
	vidregtit creatcurseur
	mov r2,r0    @ pointeur curseur précedent
	mov r0,r6    @ display
	mov r1,r9    @ fenêtre
	vidregtit creatcurseur1
	bl XDefineCursor
	cmp r0,#0
	beq 99f
	@vidregtit creatcurseur2
	b 100f
99:
	ldr r1,iAdrszMessErreurX11   @ erreur X11
    bl   afficheerreur   
	mov r0,#0   @ code erreur
100:	
    pop {r6}
    pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */
iAdriArrowmask_x_hot: .int iArrowmask_x_hot
iAdriArrowmask_y_hot: .int iArrowmask_y_hot
iAdrptCurseur:  .int ptCurseur

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
	ldr r2,iAdrszNomIcone
	ldr r3,iAdriLargeurIcone
	ldr r4,iAdry_hot
	push {r4}
	ldr r4,iAdrx_hot
	push {r4}
	ldr r4,iAdrptIcone
	push {r4}
	ldr r4,iAdriHauteurIcone
	push {r4}
	vidregtit lectureimage1
	bl XReadBitmapFile
	add sp,sp,#16   @ pour les 4 push
	cmp r0,#0
	bne 99f
	@ 
	vidregtit lectureimage @  TODO vérif contenu à faire 
	ldr r1,iAdrptIcone
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
iAdrptIcone: .int  ptIcone
iAdrszNomIcone: .int szNomIcone
iAdriLargeurIcone:  .int iLargeurIcone
iAdriHauteurIcone:  .int iHauteurIcone
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
iRouge: 					.int 0xFFFF0000
iAdrptGC:   				.int ptGC
iAdrptGC1:  				.int ptGC1
iAdrptGC2:				.int ptGC2
iAdrszMessErrGc: 		.int szMessErrGc
iGC1mask: 				.int GCFont
iGCmask: 					.int GCFont
iAdrstXGCValues: 		.int stXGCValues

/********************************************************************/
/*   Creation d 'une fenêtre secondaire 1                        ***/
/********************************************************************/
/* r0 contient le Display */
/* r1 la fenetre mère */
/* r2 l'ecran */
/* r3 la structure de la fenêtre */
/* sauvegarde des registres   */
creationFenetreSec1:
	push {fp,lr}    /* save des  2 registres */
	push {r4-r9}
	mov r6,r0   @ save du Display
	//mov r9,r1   @ save fenêtre
	mov r7,r2   @ save de l'écran
	mov r5,r3   @ save de la structure
	
	/* CREATION DE LA FENETRE */
	mov r0,r6          @ display
	 @ r1 contien l'identification fenêtre mère
	//mov r1,r9 @ identification fenêtre mère
	mov r2,#100    @ position X
	mov r3,#50     @ position Y 
    mov r4,#0       @ alignement pile 
	push {r4}
	ldr r4,[r7,#Screen_white_pixel]   @ couleur du fond
	push {r4}
	ldr r4,[r7,#Screen_black_pixel]   @ couleur bordure
	push {r4}
	mov r4,#1      @ bordure
	push {r4}
	mov r4,#100       @ hauteur
	push {r4}
	mov r4,#100     @ largeur 
	push {r4}   
	bl XCreateSimpleWindow
	add sp,#24     @ remise à  niveau pile car 6 push
	cmp r0,#0
	beq 2f
	mov r9,r0      @ stockage adresse fenetre dans le registre r9 pour usage ci dessous
	str r0,[r5,#Win_id]   @ et dans la structure
	
	/* affichage de la fenetre */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse fenetre locale
	bl XMapWindow
	
	/* autorisation des saisies */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	ldr r2,iFenetreMaskS1    @ masque pour autoriser saisies
	bl XSelectInput
	cmp r0,#0
	ble 3f
	/* chargement des donnees dans la structure */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	mov r2,r5
	bl XGetWindowAttributes
	cmp r0,#0
	ble 3f
1: @ pas d'erreur
	mov r0,r5
	vidmemtit Fenetre r0 8
	ldr r0,iAdrevtFenetreSec1
	str r0,[r5,#Win_procedure]

	mov r0,r9     @ retourne l'identification de la fenetre
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
iFenetreMaskS1: 			.int  ButtonPressMask|StructureNotifyMask|ExposureMask|EnterWindowMask


iAdrevtFenetreSec1:  .int evtFenetreSec1

/********************************************************************/
/*   Creation d 'une fenêtre secondaire 2                        ***/
/********************************************************************/
/* r0 contient le Display */
/* r1 la fenetre mère */
/* r2 l'ecran */
/* r3 la structure de la fenêtre */
/* sauvegarde des registres   */
creationFenetreSec2:
	push {fp,lr}    /* save des  2 registres */
	push {r4-r9}
	mov r6,r0   @ save du Display
	//mov r9,r1   @ save fenêtre
	mov r7,r2   @ save de l'écran
	mov r5,r3   @ save de la structure
	
	/* CREATION DE LA FENETRE */
	mov r0,r6          @ display
	 @ r1 contien l'identification fenêtre mère
	//mov r1,r9 @ identification fenêtre mère
	mov r2,#400    @ position X
	mov r3,#50     @ position Y 
    mov r4,#0       @ alignement pile 
	push {r4}
	ldr r4,[r7,#Screen_black_pixel]   @ couleur du fond
	push {r4}
	ldr r4,[r7,#Screen_white_pixel]   @ couleur bordure
	push {r4}
	mov r4,#1      @ bordure
	push {r4}
	mov r4,#100       @ hauteur
	push {r4}
	mov r4,#100     @ largeur 
	push {r4}   
	bl XCreateSimpleWindow
	add sp,#24     @ remise à  niveau pile car 6 push
	cmp r0,#0
	beq 2f
	mov r9,r0      @ stockage adresse fenetre dans le registre r9 pour usage ci dessous
	str r0,[r5,#Win_id]   @ et dans la structure
	
	/* affichage de la fenetre */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse fenetre locale
	bl XMapWindow
	
	/* autorisation des saisies */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	ldr r2,iFenetreMaskS2    @ masque pour autoriser saisies
	bl XSelectInput
	cmp r0,#0
	ble 3f
	/* chargement des donnees dans la structure */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	mov r2,r5
	bl XGetWindowAttributes
	cmp r0,#0
	ble 3f
1: @ pas d'erreur
	mov r0,r5
	vidmemtit Fenetre r0 8
	ldr r0,iAdrevtFenetreSec2
	str r0,[r5,#Win_procedure]

	mov r0,r9     @ retourne l'identification de la fenetre
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
iFenetreMaskS2: 			.int  ButtonPressMask|StructureNotifyMask|ExposureMask|EnterWindowMask
iAdrevtFenetreSec2:  .int evtFenetreSec2
/********************************************************************/
/*   Creation d 'une fenêtre secondaire 3                        ***/
/********************************************************************/
/* r0 contient le Display */
/* r1 la fenetre mère */
/* r2 l'ecran */
/* r3 la structure de la fenêtre */
/* sauvegarde des registres   */
creationFenetreSec3:
	push {fp,lr}    /* save des  2 registres */
	push {r4-r9}
	mov r6,r0   @ save du Display
	mov r7,r2   @ save de l'écran
	mov r5,r3   @ save de la structure
	
	/* CREATION DE LA FENETRE */
	mov r0,r6          @ display
	 @ r1 contien l'identification fenêtre mère
	mov r2,#400    @ position X
	mov r3,#200     @ position Y 
    mov r4,#0       @ alignement pile 
	push {r4}
	//ldr r4,[r7,#Screen_black_pixel]   @ couleur du fond
	ldr r4,iTestCouleur
	push {r4}
	ldr r4,[r7,#Screen_white_pixel]   @ couleur bordure
	push {r4}
	mov r4,#1      @ bordure
	push {r4}
	mov r4,#100       @ hauteur
	push {r4}
	mov r4,#100     @ largeur 
	push {r4}   
	bl XCreateSimpleWindow
	add sp,#24     @ remise à  niveau pile car 6 push
	cmp r0,#0
	beq 98f
	mov r9,r0      @ stockage adresse fenetre dans le registre r9 pour usage ci dessous
	str r0,[r5,#Win_id]   @ et dans la structure
	
	/* affichage de la fenetre */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse fenetre locale
	bl XMapWindow
	
	/* autorisation des saisies */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	ldr r2,iFenetreMaskS3    @ masque pour autoriser saisies
	bl XSelectInput
	cmp r0,#0
	ble 99f
	/* chargement des donnees dans la structure */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	mov r2,r5
	bl XGetWindowAttributes
	cmp r0,#0
	ble 99f
1: @ pas d'erreur
	ldr r0,iAdrevtFenetreSec3
	//str r0,[r5,#Win_procedure]  pour verif du cas non renseigné
	/* copie image dans fenêtre  */

	mov r0,r6      @ display
	ldr r1,iAdrptIcone     @ source = pointeur image 
	ldr r1,[r1]
	mov r2,r9     @ destination = fenêtre  
	ldr r3,iAdrptGC    @ contexte graphique 
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
	ldr r4,iAdriHauteurIcone
	ldr r4,[r4]
	push {r4}
	ldr r4,iAdriLargeurIcone
	ldr r4,[r4]
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
	
	mov r0,r9     @ retourne l'identification de la fenetre
	b 100f
98:  @ erreur fenetre 
	ldr r1,iAdrszMessErrfen   
    bl   afficheerreur  
	mov r0,#0       @ code erreur 
	b 100f
99:    @ erreur X11
	ldr r1,iAdrszMessErreurX11  
    bl   afficheerreur  
	mov r0,#0       @ code erreur 
	b 100f
	
100:
	pop {r4-r9}
	pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */	
iFenetreMaskS3: 			.int  ButtonPressMask|StructureNotifyMask|ExposureMask|EnterWindowMask
iAdrevtFenetreSec3:  .int evtFenetreSec3
iTestCouleur: .int 0x566220
/********************************************************************/
/*   Creation d 'une fenêtre secondaire 4                        ***/
/********************************************************************/
/* r0 contient le Display */
/* r1 la fenetre mère */
/* r2 l'ecran */
/* r3 la structure de la fenêtre */
/* sauvegarde des registres   */
creationFenetreSec4:
	push {fp,lr}    /* save des  2 registres */
	push {r4-r9}
	mov r6,r0   @ save du Display
	mov r7,r2   @ save de l'écran
	mov r5,r3   @ save de la structure
	
	/* CREATION DE LA FENETRE */
	mov r0,r6          @ display
	 @ r1 contient l'identification fenêtre mère
	mov r2,#50    @ position X
	mov r3,#180     @ position Y 
    mov r4,#0       @ alignement pile 
	push {r4}
	ldr r4,[r7,#Screen_black_pixel]   @ couleur du fond
	push {r4}
	ldr r4,[r7,#Screen_white_pixel]   @ couleur bordure
	push {r4}
	mov r4,#1      @ bordure
	push {r4}
	ldr r4,iAdrstImageBMP1
	ldr r4,[r4,#BMP_hauteur]
	push {r4}
	ldr r4,iAdrstImageBMP1
	ldr r4,[r4,#BMP_largeur]
	push {r4}   
	bl XCreateSimpleWindow
	add sp,#24     @ remise à  niveau pile car 6 push
	cmp r0,#0
	beq 98f
	mov r9,r0      @ stockage adresse fenetre dans le registre r9 pour usage ci dessous
	str r0,[r5,#Win_id]   @ et dans la structure
	
	/* affichage de la fenetre */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse fenetre locale
	bl XMapWindow
	
	/* autorisation des saisies */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	ldr r2,iFenetreMaskS4    @ masque pour autoriser saisies
	bl XSelectInput
	cmp r0,#0
	ble 99f
	/* chargement des donnees dans la structure */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	mov r2,r5
	bl XGetWindowAttributes
	cmp r0,#0
	ble 99f
1: @ pas d'erreur
	ldr r0,iAdrevtFenetreSec4
	str r0,[r5,#Win_procedure] 
	
	mov r0,r6
	mov r1,r9          @ adresse de la fenetre
	ldr r2,iAdrstImageBMP1A
	bl affichageImageBMP

	mov r0,r9     @ retourne l'identification de la fenetre
	b 100f
98:  @ erreur fenetre 
	ldr r1,iAdrszMessErrfen   
    bl   afficheerreur  
	mov r0,#0       @ code erreur 
	b 100f
99:    @ erreur X11
	ldr r1,iAdrszMessErreurX11  
    bl   afficheerreur  
	mov r0,#0       @ code erreur 
	b 100f
	
100:
	pop {r4-r9}
	pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */	
iFenetreMaskS4: 			.int  StructureNotifyMask|ExposureMask
iAdrevtFenetreSec4:  .int evtFenetreSec4
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
	ldr r3,iAdrTableFenetres    @ tables des structures des fenêtres
	mov r2,#0          @ indice de boucle
1:                   @ debut de boucle de recherche de la fenêtre
	mov r4,#Win_fin  @ longueur de chaque structure
	mul r4,r2,r4       @ multiplié par l'indice de boucle
	add r4,r3          @ et ajouté au début de table 
	ldr r1,[r4,#Win_id]   @ recup ident fenêtre dans table des structures
	cmp r1,#0             @ fin de la table ?
	moveq r0,#0          @ on termine la recherche
	beq 100f
	cmp r0,r1             @ fenetre table = fenetre évenement ?
	addne r2,#1          @ non
	bne 1b        @ on boucle
	ldr r2,[r4,#Win_procedure]  @ fenetre trouvée, chargement de la procèdure à executer
	ldr r0,iAdrevent      @ adresse de l'évenement
	cmp r2,#0       @ vérification si procédure est renseigne avant l'appel
	moveq r0,#0          @ on termine la recherche
	beq 100f
	blx r2               @ appel de la procèdure à executer pour la fenêtre
	@ le code retour dans r0 est positionné dans la routine

100:	
    pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */
iAdrevent:     .int event
iAdrTableFenetres: .int TableFenetres
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
	
	@ il faut redessiner l'image BMP

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

	mov r0,#0
	b 100f

99:
	ldr r1,iAdrszMessErreurX11   @ erreur X11
    bl   afficheerreur   
	mov r0,#0  
100:
    pop {fp,lr}
    bx lr

/********************************************************************/
/*   Evenements de la fenêtre secondaire 1                         ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ r1 doit contenir l'identification de la fenêtre
@ sauvegarde des registres
evtFenetreSec1:
	push {fp,lr}      @ save des  2 registres 
	
	vidregtit fensec1
	mov r0,#0
100:
    pop {fp,lr}
    bx lr
/********************************************************************/
/*   Evenements de la fenêtre secondaire 2                         ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ r1 doit contenir l'identification de la fenêtre
@ sauvegarde des registres
evtFenetreSec2:
	push {fp,lr}      @ save des  2 registres 
	
	vidregtit fensec2
	mov r0,#0
100:
    pop {fp,lr}
    bx lr
/********************************************************************/
/*   Evenements de la fenêtre secondaire 3                         ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ r1 doit contenir l'identification de la fenêtre
@ sauvegarde des registres
evtFenetreSec3:
	push {fp,lr}      @ save des  2 registres 
	
	vidregtit fensec3
	mov r0,#0
100:
    pop {fp,lr}
    bx lr
/********************************************************************/
/*   Evenements de la fenêtre secondaire 4                         ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ r1 doit contenir l'identification de la fenêtre
@ sauvegarde des registres
evtFenetreSec4:
	push {fp,lr}      @ save des  2 registres 
	ldr r0,iAdrevent
	ldr r0,[r0,#XAny_type]
	cmp r0,#Expose          @ cas d'une modification de la fenetre ou son masquage
	bne 2f
	mov r0,r6
	ldr r2,iAdrstImageBMP1A
	bl affichageImageBMP
2:
	mov r0,#0
100:
    pop {fp,lr}
    bx lr
iAdrstImageBMP1A: .int stImageBMP1
/***************************************************/
/*   Chargement d'une image au format BMP          */
/***************************************************/
/* r0 pointeur vers nom du fichier */
/* r1 pointeur vers structure image */
/* tous les registres sont utilisés dans cette procédure */
chargeImageBMP:
    push {fp,lr}       @ save des  2 registres fp et retour 
    push {r1-r10}
	mov r10,r1        @ save pointeur structure
   /* ouverture fichier image */
	@r0 contient le pointeur sur le nom du fichier
	mov r1,#O_RDWR   @  flags    
	mov r2,#0  			 @ mode 
	mov r7, #OPEN 		@ appel fonction systeme pour ouvrir 
    swi 0 
	cmp r0,#0          @ si erreur 
	ble erreurCI
	mov r8,r0          @ save du Fd 
	
	/* reservation sur le tas pour la fonction suivante *. */
	mov r0,#0      @ recuperation de l'adresse du tas 
    mov r7, #0x2D              @ code de l'appel systeme 'brk' 
    swi #0                      @ appel systeme 
	cmp r0,#-1              @ erreur call system
	beq erreurCI1
	mov r4,r0              @ save adresse début zone tas
	add r0,#Stat_Fin           @ reserve place pour structure Stat sur le tas 
	mov r7, #0x2D                 @ code de l'appel systeme 'brk' 
    swi #0                      @ appel systeme @ 
	cmp r0,#-1                @ erreur call system
	beq erreurCI1
	
	/* recherche de la taille du fichier image */
	mov r0,r8        @ FD du fichier
	mov r1,r4        @ adresse buffer de reception sur le tas
	mov r7, #0x6c    @ appel fonction systeme pour NEWFSTAT 
    swi 0 
	cmp r0,#0        @ si erreur 
	blt erreurCI4
	ldr r2,[r4,#Stat_size_t] @ taille du fichier
	add r0,r4,r2     @ préparation nouvelle allocation de place sur le tas
	add r9,r0,#10    @ debut d'adresse du buffer pour l'inversion de l'image
	mov r7, #0x2D                 @ code de l'appel systeme 'brk' 
    swi #0                      @ appel systeme 
	cmp r0,#-1                @ erreur call system
	beq erreurCI1
	mov r3,r2,lsr #1          @ calcul de la moitie de la taille
	add r3,r2                 @ ajout de la taille du buffer de lecture
	add r0,r9,r3      			@ nouvelle allocation pour le buffer inverse
							@ car nous allons ajouter un octet tous les 3 octets 
	mov r7, #0x2D                  @ code de l'appel systeme 'brk' 
    swi #0                      @ appel systeme 
	cmp r0,#-1                @ erreur call system
	beq erreurCI1
	
	/* lecture du fichier image et stockage dans la zone du tas */
	mov r0,r8     @ Fd du fichier 
	mov r1,r4     @  adresse du buffer de reception    
                  @ r2 contient la taille du buffer 
	mov r7, #READ  @ appel fonction systeme pour lire le fichier 
    swi 0 
	cmp r0,#0    @ si erreur de lecture 
	ble erreurCI2

	@verification type fichier
	mov r0,r4           @  adresse du buffer de reception   
	ldrh r0,[r0]		@ recup des 2 premiers octets
	ldr r1,iCodeType   @ code type de fichier = BMP
	cmp r0,r1
	bne erreurCI3
	
	@verification nombre de bits par pixel
	mov r0,r4    @  adresse du buffer de reception   
	add r0,#BMFH_fin
	ldr r1,[r0,#BMIH_biBitCount]  @ nombre de bits par Pixel
	cmp r1,#24               @ doit être 24 (3 octets).
	bne erreurCI5
	@ Récupération  taille de l'image
	ldr r2,[r0,#BMIH_biWidth]    @ largeur de la ligne BMP en pixel 
	str r2,[r10,#BMP_largeur]      @ maj de la structure de retour
	mov r6,r2      @ save de la largeur pour les calculs suivants
	ldr r2,[r0,#BMIH_biHeight]    @ hauteur de la ligne BMP en pixel 
	str r2,[r10,#BMP_hauteur]        @ maj de la structure de retour
	str r9,[r10,#BMP_debut_pixel]    @ maj de la structure de retour

	/*********EXTRACTION DES PIXELS DU BUFFER LU ET REMISE EN ORDRE **/
	@ calcul longueur d'une ligne du fichier en octet 
	mov r7,r6,lsl #1    @ on multiplie largeur en pixel par 2 et on ajoute une fois
	add r7,r6    @ car 3 octets par pixel
	@ et si la ligne n'est pas un multiple de 4, il faut la completer 
	mov r11,r7
	mov r10,#4
	ands r11,#0b011    @ verif si la taille se termine par 2 bits à 00
	subne r11,r10,r11   @ sinon on calcule le complement a 4 
	addne r7,r11       @ et on l'ajoute à la ligne (et il va servir plus loin ) 

	mov r0,r4    @  adresse du buffer de reception   
	ldr r4,[r0,#BMFH_bfSize]  @ nombre d'octets total de l'image y compris les entetes
	ldr r2,[r0,#BMFH_bfOffBits] @ offset qui indique le début des bits de l'image
	sub r4,r2    @ donc on enleve l'offset pour avoir la taille exacte
	@ et il faut partir de la fin car l'image en BMP est inversée !!!!!!
	ldr r2,[r0,#BMFH_bfSize]  @ nombre d'octets de l'image
	mov r5,#0        @ compteur total des octets écrits dans le buffer inverse
	mov r10,#0       @ compteur du nombre de pixel par ligne
	@ r0 contient le debut du buffer de lecture de l'image
	@ r9 contient le début du buffer pour l'image inversée
	vidregtit imageBMP
	sub r2,r7    @ on enleve le nombre d'octet de la ligne bmp du total 
	
1:  @ boucle de copie d'une ligne
    ldrb r3,[r0,r2]  @ lecture d'un octet dans le buffer de lecture   rouge
    strb r3,[r9,r5]  @ stockage de l'octet dans le buffer inverse
    add r2,#1         @ maj des compteurs 
	add r5,#1
    ldrb r3,[r0,r2]  @ stockage du 2ième octet   bleu
    strb r3,[r9,r5]
    add r2,#1
	add r5,#1
    ldrb r3,[r0,r2]   @ stockage du 3ième octet  vert
    strb r3,[r9,r5]
    add r2,#1	
	add r5,#1
	mov r3,#0
	strb r3,[r9,r5]   @ et on stocke 0 pour completer l'affichage en 3é bits
	add r5,#1
	add r10,#1
	cmp r10,r6       @ Nombre de pixel d'une ligne image atteint ?
	blt 1b          @ non on boucle
	 @ complement et fin de la ligne
	add r2,r11    @ ajout du complement de la ligne BMP
	sub r2,r7    @ on enleve le nombre d'octet de la ligne bmp pour revenir au debut
	sub r2,r7    @  et on enleve encore le nombre d'octet pour passer à la suivante
	mov r10,#0    @ raz du compteur de pixel de l'image 
	cmp r2,#0     @  C'est fini ?
	bgt 1b       @ non on boucle pour traiter une autre ligne
	
	
	vidregtit imageBMP1
	mov r0,r9
	vidmemtit chimgBMP1 r0  8

	@fermeture fichier de l'image BMP
	mov r0,r8   /* Fd  fichier */
	mov r7, #CLOSE /* appel fonction systeme pour fermer */
    swi 0 
    mov r0,#0    @ retour ok
    b 100f
	
erreurCI:	
	ldr r1,iAdrszMessOuvImg   /* r0 <- adresse chaine */
	bl   afficheerreur 	
	mov r0,#1       /* erreur */
	b 100f
erreurCI1:	
	ldr r1,iAdrszMessAllocTas   /* r0 <- adresse chaine */
	bl   afficheerreur 	
	mov r0,#1       /* erreur */
	b 100f	
erreurCI2:	
	ldr r1,iAdrszMessLectImg   /* r0 <- adresse chaine */
	bl   afficheerreur 	
	mov r0,#1       /* erreur */
	b 100f	
erreurCI3:	
	ldr r1,iAdrszMessErrImg   /* r0 <- adresse chaine */
	bl   afficheerreur 	
	mov r0,#1       /* erreur */
	b 100f		
erreurCI4:	
	ldr r1,iAdrszMesslecTaiImg   /* r0 <- adresse chaine */
	bl   afficheerreur 	
	mov r0,#1       /* erreur */
	b 100f  
erreurCI5:	
	ldr r1,iAdrszMessErrNbBits   /* r0 <- adresse chaine */
	bl   afficheerreur 	
	mov r0,#1       /* erreur */
	b 100f 	

100:   
   /* fin standard de la fonction  */
    pop {r1-r10}
   	pop {fp,lr}   /* restaur des  2 registres	et retour  */
    bx lr            /* retour de la fonction en utilisant lr  */	

iCodeType: .int 0x4D42   @ code type de fichier = BMP
iAdrszMessErrNbBits: .int szMessErrNbBits
iAdrszMesslecTaiImg: .int szMesslecTaiImg
iAdrszMessOuvImg: .int szMessOuvImg
iAdrszMessLectImg: .int szMessLectImg
iAdrszMessErrImg: .int szMessErrImg
iAdrszMessAllocTas: .int szMessAllocTas
szMessAllocTas: .asciz "Erreur allocation du tas. \n"
szMessOuvImg: .asciz "Erreur ouverture fichier image.\n"
szMessLectImg: .asciz "Erreur lecture fichier image.\n"
szMessErrImg: .asciz "Erreur ce fichier image n'a pas le format bmp.\n"
szMesslecTaiImg: .asciz "Erreur de lecture de la taille du fichier.\n"
szMessErrNbBits: .asciz "Taille pixel incompatible avec ce programme (24 bits).\n"
.align 4
/***************************************************/
/*   Création de de XImage à partir image BMP         */
/***************************************************/
/* r0 pointeur vers display */
/* r1 pointeur ecran  */
/* r2 pointeur vers structure image */
/* r0 retourne le pointeur vers l'image crée */
creationImageBMP:
    push {fp,lr}       @ save des  2 registres fp et retour 
    push {r4-r7}
	mov r7,r1       @ save ecran
	mov r6,r2       @ save structure
	ldr r1,[r7,#Screen_root_visual]   @ visual defaut
	ldr r2,[r7,#Screen_root_depth]   @ Nombre de bits par pixel
	mov r3,#ZPixmap
	mov r4,#0         @ nombre de bytes par lines 
	push {r4}
	mov r4,#8       @ nombre de bit de décalage !!!!!!!! à revoir
	push {r4}
	ldr r4,[r6,#BMP_hauteur]
	push {r4}
	ldr r4,[r6,#BMP_largeur]
	push {r4} 
	ldr r4,[r6,#BMP_debut_pixel]
	push {r4}         @ adresse image BMP
	mov r4,#0         @ offset debut image
	push {r4}
	bl XCreateImage
	add sp,#24     @ remise à  niveau pile car 6 push
    str r0,[r6,#BMP_imageX11]    @ maj adresse image X11 dans structure
	
100:    /* fin standard de la fonction  */
    pop {r4-r7}
   	pop {fp,lr}   /* restaur des  2 registres	et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
/***************************************************/
/*   Affichage de XImage dans fenetre        */
/***************************************************/
/* r0 pointeur vers display */
/* r1 pointeur fenêtre  */
/* r2 pointeur vers structure image */
affichageImageBMP:
    push {fp,lr}       @ save des  2 registres fp et retour 
    push {r4-r5} 
	mov r5,r2   @ save structure
	ldr r2,iAdrptGC    @ contexte graphique 
	ldr r2,[r2]
	ldr r3,[r5,#BMP_imageX11]          @ adresse de l'image
	ldr r4,[r5,#BMP_hauteur]
	push {r4}
	ldr r4,[r5,#BMP_largeur]
	push {r4} 
	mov r4,#0     @ position Y de l'image dans la destination
	push {r4}
	mov r4,#0   @ position X de l'image dans la destination
	push {r4}
	mov r4,#0     @ position Y de l'image dans la source
	push {r4}
	mov r4,#0   @ position X de l'image dans la source
	push {r4}
	bl XPutImage
	add sp,sp,#24       @ pour les 6 push 

100:    /* fin standard de la fonction  */
    pop {r4-r5}
   	pop {fp,lr}   /* restaur des  2 registres	et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
/*********************************************************************/
/* constantes Générales              */
.include "../../asm/constantesARM.inc"
	