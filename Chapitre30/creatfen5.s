/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* création fenetre X11 avec un bouton */
/* utilisation d'une police de caractère difèrente*/
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
szMessDebutPgm: 	.asciz "Début du programme. \n"
szMessFinPgm:	.asciz "Fin normale du programme. \n" 
szMessErreur: .asciz "Serveur X non trouvé.\n"
szMessErrfen: .asciz "Création fenetre impossible.\n"
szMessErreurX11: .asciz  "Erreur fonction X11. \n"
szMessErrGc: .asciz "Création contexte graphique impossible.\n"
szMessErrGcBT: .asciz "Création contexte graphique Bouton impossible.\n"
szMessErrbt: .asciz "Création bouton impossible.\n"
szMessErrGPolice: .asciz "Chargement police impossible.\n"
szTitreFenRed: .asciz "Pi"    
szTexte1: .asciz "Ceci est mon premier texte."
.equ LGTEXTE1, . - szTexte1
szTexte2: .ascii "Bravo ! Vous avez cliqué sur le bouton."
.equ LGTEXTE2, . - szTexte2
/* libellé special pour correction pb fermeture */
szLibDW: .asciz "WM_DELETE_WINDOW"
.align 4
/* liste de noms */
ListeNom:  .int szNomFenetre    @ necessaire pour maj du titre
hauteur: .int HAUTEUR
largeur: .int LARGEUR
szTexteBouton1: .asciz  "OK"
/* test police de caracteres */
szNomPolice: .asciz  "-*-helvetica-bold-*-normal-*-14-*"
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
ptDisplay:  .skip 4     @ pointeur display
ptEcran: .skip 4     @ pointeur ecran standard
ptFenetre: .skip 4      @ pointeur fenêtre
ptGC:        .skip 4      @ pointeur contexte graphique
ptGC1:        .skip 4      @ pointeur contexte graphique 1
ptGC2:        .skip 4      @ pointeur contexte graphique 2
ptPolice:   .skip 4      @ pointeur police de caractères
key: .skip 4              @ code touche
wmDeleteMessage: .skip 8   @ identification message de fermeture  
event: .skip 400          @ TODO revoir cette taille 
PrpNomFenetre: .skip 100  @ proprieté titre de la fenêtre
buffer:  .skip LGBUFFER 
iWhite: .skip 4            @ code RGB pixel blanc
iBlack: .skip 4			 @ code RGB pixel noir
.align 4
stAttributs:  .skip Att_fin        @ reservation place structure Attibuts 
.align 4
stXGCValues:  .skip XGC_fin        @ reservation place structure XGCValues
.align 4
stBouton1:  .skip BT_fin            @ reservation place structure bouton
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
	/* attention r8  pointeur contexte graphique   */
	/* attention r9 identification fenêtre */
	/* attention r12 est utilisé par les fonctions X11 */
	/*ouverture du serveur X */
	bl ConnexionServeur
	cmp r0,#0
	beq erreurServeur

	bl creationfenetre
	cmp r0,#0
	beq erreurF
	
	/*  creation des contextes graphiques */
	bl creationGC
	cmp r0,#0
	beq erreurGC
	
	/* ecriture de texte dans la fenetre */
	bl ecritureTexte

	/* dessin d'une ligne */
	bl dessinLigne

	
	/* création d'un bouton */
	ldr r0,iAdrstBouton1  		@ adresse structure bouton
	ldr r1,iAdrszTexteBouton1  	@ texte du Bouton
	mov r2,#40  					@ position x  
	mov r3,#200  					@ position y  
	mov r4,#30  					@ hauteur  
	mov r5,#80  					@ largeur  
	bl creationbouton

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
iAdrstBouton1: 			.int stBouton1
iAdrszTexteBouton1: 	.int szTexteBouton1

/********************************************************************/
/*   Connexion serveur X et recupération informations du display  ***/
/********************************************************************/	
ConnexionServeur:
	push {fp,lr}    /* save des  2 registres */
	/*ouverture du serveur X */
	mov r0,#0
	bl XOpenDisplay
	cmp r0,#0
	beq 100f    @ serveur non actif 
	ldr r1,iAdrptDisplay
	str r0,[r1]     @ stockage adresse du DISPLAY 
	mov r6,r0       @ mais aussi dans le registre r6
	@ recup ecran par defaut
	ldr r2,[r0,#Disp_default_screen]
	mov r3,r0
	ldr r0,[r3,#Disp_screens]    @ pointeur de la liste des écrans
    add r7,r0,r2,lsl #2                @ récup du pointeur de l'écran par defaut
	ldr r1,iAdrptEcran
	str r7,[r1]    @stockage  pointeur ecran
   	@zones ecran
	ldr r5,[r7,#Screen_white_pixel]  @ white pixel
	ldr r4,iAdriWhite
	str r5,[r4]
	ldr r3,[r7,#Screen_black_pixel]  @ black pixel
	ldr r4,iAdriBlack
	str r3,[r4]
	mov r0,r6    @ connexion ok retourne le pointeur 

100:	
    pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */	
iAdrptDisplay:  	.int ptDisplay
iAdriWhite: 		.int iWhite
iAdriBlack:  	.int iBlack
iAdrptEcran: 	.int ptEcran
/********************************************************************/
/*   Creation d 'une fenêtre                                    ***/
/********************************************************************/
/* r6 contient le Display, r9 retourne le pointeur fenetre */
/* pas de sauvegarde des registres   */
creationfenetre:
	push {fp,lr}    /* save des  2 registres */
	ldr r7,iAdrptEcran      @ récuperation du pointeur de l'écran 
	ldr r7,[r7]
	@ calcul de la position X pour centrer la fenetre
	@  ne fonctionne pas !!!!
	ldr r2,[r7,#Screen_width]   @ récupération de la largeur de l'écran racine
	sub r2,#LARGEUR              @ soustraction de la largeur de notre fenêtre
	lsr r2,#1                      @ division par 2 et résultat pour le parametre 3
	ldr r3,[r7,#Screen_height]  @ récupération de la hauteur de l'écran racine
	sub r3,#HAUTEUR               @ soustraction de la hauteur de notre fenêtre
	lsr r3,#1                       @ division par 2 et résultat pour le parametre 4
	
	/* CREATION DE LA FENETRE */
	mov r0,r6          @ display
	ldr r1,[r7,#Screen_root]  @ identification écran racine
	@ r2 er r3 ont été calculés plus haut
    mov r8,#0       /* alignement pile */
	push {r8}
	ldr r8,iGris1    @ couleur du fond
	push {r8}
	ldr r8,iAdriBlack
	ldr r8,[r8]        @ couleur bordure
	push {r8}
	mov r8,#2      @ bordure
	push {r8}
	mov r8,#HAUTEUR       @ hauteur
	push {r8}
	mov r8,#LARGEUR     @ largeur 
	push {r8}   
	bl XCreateSimpleWindow
	add sp,#24     @ remise à  niveau pile car 6 push
	cmp r0,#0
	beq 2f
	ldr r1,iAdrptFenetre
	str r0,[r1]    @ stockage adresse fenetre
	mov r9,r0      @ et aussi dans le registre r9
	
		/* ajout de proprietes de la fenêtre */
	mov r0,r6          @ adresse du display 
	mov r1,r9          @ adresse fenetre 
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
	mov r1,r9          @ adresse fenetre
	mov r3,#1          @ nombre de protocoles 
	bl XSetWMProtocols
	cmp r0,#0
	ble 3f
	
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
	mov r0,r6          @ adresse du display 
	mov r1,r9          @ adresse fenetre 
	bl XMoveWindow
	
	/* autorisation des saisies */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	ldr r2,iFenetreMask    @ masque pour autoriser saisies
	bl XSelectInput
	cmp r0,#0
	ble 3f
1: @ pas d'erreur
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
	pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */	
iAdrptFenetre: 			.int ptFenetre
iFenetreMask: 			.int  KeyPressMask|ButtonPressMask|StructureNotifyMask|ExposureMask
iGris1: 					.int 0xFFA0A0A0
iAdrhauteur: 			.int hauteur
iAdrlargeur: 			.int largeur
iAdrszNomFenetre: 		.int  szNomFenetre
iAdrszTitreFenRed: 		.int szTitreFenRed
iAdrszMessErreurX11: 	.int szMessErreurX11
iAdrszMessErrfen: 		.int szMessErrfen
iAdrszLibDW:   			.int szLibDW
iAdrwmDeleteMessage: 	.int wmDeleteMessage
/********************************************************************/
/*   Création contexte graphique                                  ***/
/********************************************************************/	
/* r6 contient le display, r9 la feneêtre */
/* le GC simple est retournée dans r8   */
creationGC:
	push {fp,lr}    /* save des  2 registres */
	/* creation contexte graphique simple */
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse fenetre
	mov r2,#0
	mov r3,#0
	bl XCreateGC
	cmp r0,#0
	beq 2f	
	ldr r1,iAdrptGC
	str r0,[r1]   @ stockage adresse contexte graphique 
	mov r8,r0     @ et dans r8   
	
	/*creation  autre contexte graphique */
	mov r0,r6          			@ adresse du display 
	mov r1,r9          			@ adresse fenetre 
	ldr r2,iGC1mask   		@ identifie les zones de XGCValues à  mettre à  jour 
	ldr r4,iRouge  			@ Couleur dutexte du contexte graphique 
	ldr r3,iAdrstXGCValues  @ maj dans la zone de XGCValues 
	str r4,[r3,#XGC_foreground]
	mov r4,#1              @ ligne en pointillé 
	str r4,[r3,#XGC_line_style]
	mov r4,#4                 @ largeur de la ligne
	str r4,[r3,#XGC_line_width]
	ldr r3,iAdrstXGCValues   @ la zone complete est passée en paramètre 
	bl XCreateGC
	cmp r0,#0
	beq 2f	
	ldr r1,iAdrptGC1
	str r0,[r1]   @ stockage adresse contexte graphique dans zone gc1 
	
	/* création contexte graphique avec autre police */
	/* et autre couleur */
	/* chargement police de caractères */
	mov r0,r6          @ adresse du display 
	ldr r1,iAdrszNomPolice 		@ nom de la police 
	bl XLoadQueryFont
	cmp r0,#0
	beq 1f	         @ police non trouvée  
	ldr r1,iptPolice
	str r0,[r1]
	vidregtit police
	/* creation nouveau contexte graphique 2 */
	mov r0,r6          @ adresse du display 
	mov r1,r9          @ adresse fenetre 
	ldr r2,iGC2mask   @ identifie les zones de XGCValues à  mettre à  jour 
	ldr r4,iRouge  	@ Couleur du texte du contexte graphique 
	ldr r3,iAdrstXGCValues  @ maj dans la zone de XGCValues 
	str r4,[r3,#XGC_foreground]
	ldr r4,iptPolice    @ recup du pointeur sur la police
    ldr r4,[r4]	
	ldr r4,[r4,#XFontST_fid]   @ identification police dans adresse police + 4  
	str r4,[r3,#XGC_font]     @ maj dans la zone de XGCValues 

	ldr r3,iAdrstXGCValues   @ la zone complete est passée en paramètre 
	bl XCreateGC
	cmp r0,#0
	beq 2f	
	ldr r1,iAdrptGC2
	str r0,[r1]   @ stockage adresse contexte graphique dans zone gc2 
	
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
    pop {fp,lr}
    bx lr        	
iRouge: 					.int 0xFFFF0000
iAdrptGC:   				.int ptGC
iAdrptGC1:   				.int ptGC1	
iAdrptGC2:  				.int ptGC2
iAdrszMessErrGc: 		.int szMessErrGc
iAdrszMessErrGPolice: 	.int szMessErrGPolice
iGC1mask: 				.int GCLine_width|GCLine_style|GCForeground
iGC2mask: 				.int GCFont|GCForeground
iAdrstXGCValues: 		.int stXGCValues
iAdrszNomPolice: 		.int szNomPolice
iptPolice:   				.int ptPolice
/********************************************************************/
/*   Creation bouton                                        ***/
/********************************************************************/
/* r0 adresse structure bouton r1 adresse du texte */ 
/*  r2 x r3 y r4 hauteur r5 longueur */
/*  r6 display r9 fenetre  */
creationbouton:
	push {fp,lr}    @ save des  2 registres 
	mov r10,r0      @ save pointeur structure
	str r1,[r10,#+BT_texte]  @ save texte du bouton 
	/* CREATION DE LA FENETRE BOUTON */
	mov r0,#0       @ alignement pile 
	push {r0}
	ldr r0,iAdriWhite
	ldr r0,[r0]
	push {r0}       	@ pixel  du fond 
	str r0,[r10,#+BT_background]
	ldr r0,iAdriBlack
	ldr r0,[r0]
	push {r0}      @ pixel  de la bordure 
	str r0,[r10,#+BT_border]
	mov r0,#1      @ largeur bordure 
	push {r0}
	str r4,[r10,#+BT_height]
	push {r4}      			@ hauteur  
	str r5,[r10,#+BT_width]
	push {r5}       		@largeur 
    mov r0,r6          		@ Display 
	mov r1,r9        		@ fenetre parent 
	bl XCreateSimpleWindow
	add sp,sp,#24   		@ pour les 6 push 
	cmp r0,#0
	beq 99f
	/* alimentation donnees du bouton */
	str r0,[r10,#+BT_adresse]
	ldr r0,iAdrboutonAppel       @ adresse de la fonction à appeler
	str r0,[r10,#+BT_release]   @ fonction a appeler 
	mov r0,#0
	str r0,[r10,#+BT_cbdata]  @ pas de donnees complementaires 
	/* autorisation des saisies */
	mov r0,r6          					@ adresse du display 
	ldr r1,[r10,#+BT_adresse]          @ adresse du bouton 
	ldr r2,iBoutonMask
	//ldr r2,[r2]
	bl XSelectInput
	/*  creation du contexte graphique du bouton */
	mov r0,r6             @ adresse du display 
	ldr r1,[r10,#+BT_adresse]          @ adresse du bouton 
	mov r2,#0
	mov r3,#0
	bl XCreateGC
	cmp r0,#0
	beq 98f	
	str r0,[r10,#+BT_GC]    @ stockage contexte graphique
	/* affichage du bouton */
	mov r0,r6         					@ adresse du display 
	ldr r1,[r10,#+BT_adresse]      	@ adresse du bouton 
	bl XMapWindow
	/* ecriture du texte du bouton */
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
    pop {fp,lr}
    bx lr
iAdrboutonAppel: 		.int boutonAppel   @ attention, c'est l'adresse d'une routine
iAdrszMessErrGcBT: 		.int szMessErrGcBT
iAdrszMessErrbt: 		.int szMessErrbt
iBoutonMask: 			.int ButtonPressMask|ButtonReleaseMask|StructureNotifyMask|ExposureMask|LeaveWindowMask|EnterWindowMask
/********************************************************************/
/*   Ecriture du libellé du bouton                         ***/
/********************************************************************/
@ pas de sauvegarde des registres
ecritureTexteBouton:
	push {fp,lr}      @ save des  2 registres 
	ldr r10,iAdrstBouton1    @ recup structure bouton
	/* calcul longueur texte du bouton */
	ldr r1,[r10,#+BT_texte]  @ recup texte du bouton 
	mov r4,#0
1:  
	ldrb r3,[r1,r4]
	cmp r3,#0
	addne r4,#1
	bne 1b
	/* centrage du texte du bouton */
	ldr r5,[r10,#+BT_width]
	sub r3,r5,r4  @ on enleve la taille du texte de la lingeur du bouton
	lsr r3,#1    @ et on divise par 2 pour avoir la position x 
	/* ecriture du texte du bouton */
	mov r0,r6          @  adresse du display
	ldr r1,[r10,#BT_adresse]          @ adresse du bouton
    ldr r2,[r10,#BT_GC]       @ adresse du contexte graphique 
	 @ longueur de la chaine a ecrire dans r4
	push {r4}      @ en parametre 
	push {r4}
	ldr r4,[r10,#+BT_texte]  @ recup texte du bouton 
	push {r4}
	mov r4,#20              @ position y 
	push {r4}
	bl XDrawString
	add sp,sp,#16         @ pour les 4 push
100:	
    pop {fp,lr}
    bx lr                       
/********************************************************************/
/*   Gestion des évenements de la fenêtre                         ***/
/********************************************************************/
@ pas de sauvegarde des registres
gestionEvenements:
	push {fp,lr}      @ save des  2 registres 
	mov r0,r6            @ adresse du display
	ldr r1,iAdrevent         @ adresse evenements
	bl XNextEvent
	ldr r0,iAdrevent
	//vidmemtit ApresEvent r0 4
	ldr r0,[r0,#XAny_type]
	cmp r0,#KeyPressed     @ cas d'une touche
	beq touche
	cmp r0,#ButtonPress    @ cas d'un bouton souris 
	beq bouton
	cmp r0,#ClientMessage   @ cas pour fermeture fenetre sans erreur 
	beq fermeture
	cmp r0,#ConfigureNotify   @ cas pour modification de la fenetre 
	beq configure
	cmp r0,#Expose          @ cas d'une modification de la fenetre ou son masquage
	beq evtexpose
	cmp r0,#EnterNotify    @ la souris passe sur une fenêtre
	beq evtenter
	cmp r0,#LeaveNotify   @ la souris quitte une fenêtre
	beq evtleave
	/* autre evenement à traiter */
	b suiteBoucleEvt
	
/************************************************/	
touche:	/* appui sur une touche */
	ldr r0,iAdrevent
	ldr r1,iAdrbuffer      @ buffer
	mov r2,#LGBUFFER        @ longueur du buffer
	ldr r3,iAdrkey          @ zone code de la touche appuyée
	mov r4,#0                 @ argument NULL
	push {r4}    @ alignement pile
	push {r4}
	bl XLookupString 
	add sp,#8     @ remise à  niveau pile car 2 push
	cmp r0,#1             @ touche caractères 
	bne autretouche
	ldr r0,iAdrbuffer
	ldrb r0,[r0]
	cmp r0,#0x71     @ caractere q   pour quitter
	beq finBoucleEve   @ fin des évenements
autretouche:	
	b suiteBoucleEvt
/***************************************/	

bouton:	
	ldr r0,iAdrevent     @ evenement de type XButtonEvent
	bl boutonAppel
	b suiteBoucleEvt
	
/***************************************/	
fermeture:    /* clic sur menu systeme */
	ldr r0,iAdrevent      @ evenement de type XClientMessageEvent
	ldr r1,[r0,#XClient_data]   @ position code message
	ldr r2,iAdrwmDeleteMessage
	ldr r2,[r2]
	cmp r1,r2
	beq finBoucleEve    @ fin du programme
	b suiteBoucleEvt
	
/***************************************/	
configure:	/* modification de la fenetre */
	ldr r0,iAdrevent
	ldr r1,[r0,#+XConfigureEvent_height]
	ldr r2,iAdrhauteur
	ldr r3,[r2]
	cmp r1,r3     @ modification de la hauteur ?
	beq suiteConfigure
	str r1,[r2]     @ maj nouvelle hauteur
		@ le dessin sera effectué par l'évenement expose
	b suiteBoucleEvt
suiteConfigure:
    ldr r0,iAdrevent
	ldr r1,[r0,#+XConfigureEvent_width]
	ldr r2,iAdrlargeur
	ldr r3,[r2]
	cmp r1,r3     @ modification de la largeur ?
	beq suiteConfigure1
	str r1,[r2]     @ maj nouvelle largeur
	@ le dessin sera effectué par l'évenement expose
suiteConfigure1:
	b suiteBoucleEvt
/***************************************/	
evtexpose:   /* masquage ou modification fenetre */
	bl dessinLigne
	bl ecritureTexte
	bl ecritureTexteBouton
	b suiteBoucleEvt
/***************************************/	
evtenter:  /* passage de la souris sur le bouton */
	b suiteBoucleEvt
/***************************************/	
evtleave:  /* sortie de la souris du bouton */
	ldr r0,iAdrevent
	bl modifBoutonSortie
	b suiteBoucleEvt
/***************************************/	
suiteBoucleEvt:  /* suite de la boucle des evenements */
	mov  r0,#0
	pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */	
/**************************************************/	
/*  Fin boucle des évenements de la fenêtre  */
finBoucleEve:	
    mov  r0,#1
    pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */
iAdrevent:     .int event
iAdrbuffer:     .int buffer
iAdrkey:         .int key

/********************************************************************/
/*   Appui sur le bouton                                          ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ pas de sauvegarde des registres
boutonAppel:
	push {fp,lr}      @ save des  2 registres 
	ldr r3,iAdrstBouton1  @ adresse structure bouton
	ldr r1,[r3,#BT_adresse]
	ldr r2,[r0,#XAny_window]
	cmp r1,r2
	bne 100f
	mov r5,r0     @ save pointeur event
	bl ecritureTexte2
	mov r0,r5     @ restaur pointeur event
	bl modifBoutonAppui
100:
    pop {fp,lr}
    bx lr
/********************************************************************/
/*   Ecriture du texte                                            ***/
/********************************************************************/
@ pas de sauvegarde des registres
ecritureTexte:
	push {fp,lr}      @ save des  2 registres 
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	mov r2,r8          @ adresse du contexte graphique 
	mov r3,#50          @ position x 
	sub sp,#4      @ alignement pile
	mov r4,#LGTEXTE1  - 1     @ longueur de la chaine a ecrire 
	push {r4}                @ passé en paramètre sur la pile
	ldr r4,iAdrszTexte1       @ adresse du texte a afficher 
	push {r4}
	mov r4,#50              @ position y 
	push {r4}
	bl XDrawString
	add sp,sp,#16      @ pour les 3 push et l'alignement pile
100:
    pop {fp,lr}
    bx lr        	
iAdrszTexte1: .int szTexte1
/********************************************************************/
/*   Ecriture du texte  appui sur le bouton                       ***/
/********************************************************************/
@ pas de sauvegarde des registres
ecritureTexte2:
	push {fp,lr}      @ save des  2 registres 
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	ldr r2,iAdrptGC2    @ adresse du contexte graphique 
	ldr r2,[r2]          @ adresse du contexte graphique 
	mov r3,#50          @ position x 
	sub sp,#4      @ alignement pile
	mov r4,#LGTEXTE2  - 1     @ longueur de la chaine a ecrire 
	push {r4}                @ passé en paramètre sur la pile
	ldr r4,iAdrszTexte2       @ adresse du texte a afficher 
	push {r4}
	mov r4,#100              @ position y 
	push {r4}
	bl XDrawString
	add sp,sp,#16      @ pour les 3 push et l'alignement pile

100:
    pop {fp,lr}
    bx lr        	
iAdrszTexte2: .int szTexte2
/********************************************************************/
/*   Dessin d'une ligne droite                                    ***/
/********************************************************************/
@ pas de sauvegarde des registres
dessinLigne:
	push {fp,lr}      @ save des  2 registres 
	mov r0,r6          @ adresse du display
	mov r1,r9          @ adresse de la fenetre
	mov r2,r8          @ adresse du contexte graphique 
	mov r3,#0         @ position x 
	sub sp,sp,#4
	mov r4,#20        @ position y1 
	push {r4}          @en parametre 
	ldr r4,iAdrlargeur      @ sur toute la largeur de l'écran
	ldr r4,[r4] 
	push {r4}
	mov r4,#20        @ position y 
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
/********************************************************************/
/*   Modification du dessin du bouton lors du clic                ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ pas de sauvegarde des registres
modifBoutonAppui:
	push {fp,lr}      @ save des  2 registres 
	ldr r3,iAdrstBouton1  @ structure du bouton 
	ldr r4,iAdrstAttributs    @ structure des attributs 
	ldr r1,[r3,#+BT_background]          @ inversion du fond 
	vidregtit appuibouton
	str r1,[r4,#+Att_border_pixel]
	ldr r1,[r3,#+BT_border]          @  et de la bordure 
	str r1,[r4,#+Att_background_pixel]
	mov r5,r0  						@ pointeur vers evenement 
	ldr r0,[r5,#+XAny_display]
	ldr r1,[r5,#+XAny_window]
	ldr r2,iAttrsMask
	ldr r3,iAdrstAttributs    @ structure des attributs 
	bl XChangeWindowAttributes  @ changement des attributs  
	mov r4,#true
	push {r4}        /* pour alignement de la pile */
	push {r4}
	ldr r3,iAdrstBouton1  /* structure du bouton */
	ldr r4,[r3,#+BT_height] /* hauteur */
	push {r4}
	ldr r4,[r3,#+BT_width]   /* largeur */
	push {r4}
	mov r3,#0
	mov r2,#0
	ldr r0,[r5,#+XAny_display]
	ldr r1,[r5,#+XAny_window]
	bl XClearArea      /* redessin du bouton */
	add sp,sp,#16   /* alignement pile  pour les 4 push  */
	
100:
    pop {fp,lr}
    bx lr        	
	
iAdrstAttributs:  .int stAttributs
iAttrsMask: .int CWBackPixel|CWBorderPixel
/********************************************************************/
/*   Modification du dessin du bouton si sortie de la souris                ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ pas de sauvegarde des registres
modifBoutonSortie:
	push {fp,lr}      @ save des  2 registres 
	ldr r3,iAdrstBouton1  /* structure du bouton */
	ldr r4,iAdrstAttributs    /* structure des attributs */
	ldr r1,[r3,#+BT_border]          /*  et de la bordure */
	vidregtit appuibouton
	str r1,[r4,#+Att_border_pixel]
	ldr r1,[r3,#+BT_background]          /* inversion du fond */
	str r1,[r4,#+Att_background_pixel]
	mov r5,r0  /* pointeur vers evenement */
	ldr r0,[r5,#+XAny_display]
	ldr r1,[r5,#+XAny_window]
	ldr r2,iAttrsMask
	ldr r3,iAdrstAttributs    /* structure des attributs */
	vidregtit appuibouton
	bl XChangeWindowAttributes /* changement des attributs */  
	mov r4,#true
	push {r4}        /* pour alignement de la pile */
	push {r4}
	ldr r3,iAdrstBouton1  /* structure du bouton */
	ldr r4,[r3,#+BT_height] /* hauteur */
	push {r4}
	ldr r4,[r3,#+BT_width]   /* largeur */
	push {r4}
	mov r3,#0
	mov r2,#0
	ldr r0,[r5,#+XAny_display]
	ldr r1,[r5,#+XAny_window]
	bl XClearArea      /* redessin du bouton */
	add sp,sp,#16   /* alignement pile  pour les 4 push  */
	
100:
    pop {fp,lr}
    bx lr        	
/*********************************************************************/
/* constantes Générales              */
.include "../../asm/constantesARM.inc"
	