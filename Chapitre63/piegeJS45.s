/* Programme assembleur ARM Raspberry           */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/   */
/* modèle B 512MO                               */
/* fenetre X11                                  */
/* jeu micro Jeux et Stratégies N° 45 1987      */
/*********************************************/
/*constantes */
/********************************************/
.include "../../asm/constantesARM.inc"
.equ LIGNES,          20                 @ nombre de lignes du terrain
.equ COLONNES,        20                 @ nombre de colonnes
.equ LIGNESCASES,     20                 @ nombre de cases
.equ COLONNESCASES,   20                 @ nombres de cases
.equ POSYCARTE,       65                 @ position de la carte dans la fenêtre
.equ POSYLIGNE1,      15                 @ position de la ligne 1 de l'entête
.equ TAILLEPOLICE,    20
.equ TAILLECASE,      15
.equ NBCASESVUES,     15                 @ ??
.equ POSXDESSIN3D,    5
.equ POSYDESSIN3D,    65
.equ TAILLEDESSIN3D,  300
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"

/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne:   .asciz  "\n"
szMessErreur:   .asciz "Serveur X non trouvé.\n"
szMessErrfen:   .asciz "Création fenetre impossible.\n"
szMessErrGc:    .asciz "Création contexte graphique impossible.\n"
szMessErrPol:   .asciz "Chargement police impossible.\n"
szLibDW:        .asciz "WM_DELETE_WINDOW"
.equ LGLIBDW, . - szLibDW  
szTitreFen:     .asciz "Fenetre jeu Piege"
szTitreFenRed:  .asciz "Pi"  
//szTitreFen1:    .asciz "Fenetre Raspberry"
//szTitreFenRed1: .asciz "Pi1"
@liste des noms de fenêtre
listeTitreFen:  .int szTitreFen
                .int 0

/* police de caracteres */
//fontname: .asciz  "-*-helvetica-bold-*-normal-*-24-*"
fontname:      .asciz  "-*-helvetica-medium-r-normal-*-20-*"
fixed:         .asciz  "fixed"
szLibTouche:   .asciz "Appuyer sur une touche (a/A pour avancer k/K gauche l/L droite)"
szLibNiveau:   .ascii "Niveau : "
sNiveau:       .fill 12, 1, ' '
               .byte 0
szLibDensite:  .ascii "Densite : "
sDensite:      .fill 12, 1, ' '
               .byte 0
szLibEnergie:  .ascii "Energie : "
sEnergie:      .fill 12, 1, ' '
               .byte 0
szLibLimite:   .asciz "LIMITE"
szLibMurA:     .asciz "!!!!!!"
szLibDirNord:  .asciz "Direction : Nord "
szLibDirSud:   .asciz "Direction : Sud  "
szLibDirEst:   .asciz "Direction : Est  "
szLibDirOuest: .asciz "Direction : Ouest"
szLibPosition: .ascii "Position X : "
sPosXJoueur:    .fill 12, 1, ' '
               .ascii "Position Y : "
sPosYJoueur:      .fill 12, 1, ' '
               .byte 0
szLibCarte:     .asciz "Carte (O/N) ?"
szLibMurs:      .asciz "Ajout ou suppression de murs (A/S) ?"
szLibMontee:    .asciz "Monter un niveau (O/N) ?"
szLibDescente:  .asciz "Descendre un niveau (O/N) ?" 
szLibFinJeu:    .asciz "Bravo, vous avez gagné."
.align 4
blanc:       .int 0xFFFFFF
gris:        .int 0xFFE0E0E0
gris1:       .int 0xFFA0A0A0
iPosfenX:    .int 0
iPosfenY:    .int 0
hauteur:     .int 400
largeur:     .int 600

/* données jeu */
iNiveau:      .int 10           @ E
iDensite:     .int 6            @ QM
iPosXJoueur:  .int 6            @ XP
iPosYJoueur:  .int 8            @ YP
iDirection:   .int 1            @ Direction DR
iEnergie:     .int 1000         @ Energie SC
iEtatTouches: .int 0     @ etat 0 = mouvement, 1 : action carte 2 : changement 3 : descente 4 : montée
TabGraine:    .int 123456       @ table des graines par niveau pour nombres aléatoires
              .int 234567
              .int 345678
              .int 456789
              .int 567890
              .int 678902
              .int 789012
              .int 890123
              .int 901234
              .int 012345

/******************************************/
.include "../descStruct.inc"

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
iD:              .skip 4
iDrw:            .skip 4
iEcran:          .skip 4
iWindow:         .skip 4
iKey:            .skip 4
ptGC:            .skip 4
police:          .skip 4
gc1:             .skip 4
ptGC1:           .skip 4
iWhite:          .skip 4
iBlack:          .skip 4
ptPolice:        .skip 4
cptFermeture :   .skip 4
wmDeleteMessage: .skip 8
iGraine:         .skip 4
eve:             .skip 400             @ TODO revoir cette taille
bouton1:         .skip BT_fin
attrs:           .skip Att_fin
fenetre:         .skip Win_fin
attrSize:        .skip XSize_fin
wmhints:         .skip Hints_fin
NomFen:          .skip XText_fin
NomFenRed:       .skip XText_fin
stXGCValues:     .skip XGC_fin
sBuffer:         .skip 500 
itTerrain:       .skip 4 * LIGNES * COLONNES
itValeur:        .skip 4 * LIGNESCASES * COLONNESCASES
itCasesVues:     .skip 4 * NBCASESVUES
/**********************************************/
/* -- Code section                            */
/**********************************************/
.text           
.global main                 @ 'main' point d'entrée doit être  global

main:                        @ programme principal
    /* attention r12 n'est pas sauvé par les fonctions X. ne l'utiliser que localement */ 
    /* attention r10 contient id du Display */
    /* attention r9 contient id de la fenetre */
    /* attention r8 contient id du gc  */
    bl ConnexionServeur              @ ouverture du serveur X
    cmp r0,#0
    beq erreur                       @ serveur non actif

    /* CREATION DE LA FENETRE PRINCIPALE */
    bl creationfenetre
    cmp r0,#0
    beq erreur    

    /*  creation des contextes graphiques */
    bl creationGC
    cmp r0,#0
    beq erreur

    /* affichage debut */
    bl afficheentete1
    bl creationTerrain
    bl afficheTerrain
  
/* boucle des evenements */     
boucleevt:  
    bl gestionevenements
    cmp r0,#0            @ si zero on boucle sinon on termine
    beq  boucleevt
    vidregtit finboucleevt
    /* liberation des ressources   */
    mov r0,r10           @ adresse du display
    ldr r1,iAdrptGC
    ldr r1,[r1]          @ adresse du contexte
    bl XFreeGC
    mov r0,r10           @ adresse du display
    ldr r1,iAdrptGC1
    ldr r1,[r1]          @ adresse du contexte
    bl XFreeGC
    mov r0,r10           @ adresse du display
    mov r1,r9            @ adresse de la fenetre
    bl XDestroyWindow
    mov r0,r10           @ adresse du display
    bl XCloseDisplay    

    mov r0,#0            @ code retour OK
    b finnormale
erreur:
    mov r0,#1            @ code retour erreur
finnormale:              @ fin de programme standard
    pop {fp,lr}
    mov r7, #EXIT        @ appel fonction systeme pour terminer
    swi 0 
/********************************************************************/
/*  Gestion des évenements d une fenetre                          ***/
/********************************************************************/
/* r10  contient le Display */
gestionevenements:
    push {fp,lr}                @ save des registres
    mov r0,r10                  @ adresse du display
    ldr r1,iAdreve              @ adresse structure evenements
    bl XNextEvent
    ldr r0,iAdreve
    ldr r0,[r0,#+XAny_type]
    cmp r0,#KeyPressed          @ cas d'une touche
    beq touche

    cmp r0,#ClientMessage       @ cas pour fermeture fenetre sans erreur
    beq fermeture
    cmp r0,#ConfigureNotify     @ cas pour modification de la fenetre
    beq configure
    cmp r0,#Expose              @ évenement expose
    beq evtexpose

    b suiteBoucleEvt            @ autre evenement à traiter
/************************************************/    
touche:                         @ appui sur une touche
    ldr r0,iAdreve              @ adresse structure evenement
    ldr r1,iAdrsBuffer
    mov r2,#255
    ldr r3,iAdriKey
    sub sp,sp,#4
    mov r4,#0
    push {r4}
    bl XLookupString 
    add sp,sp,#8               @ pour les 2 push
    cmp r0,#1                  @ touche caractères ?
    bne autretouche
    ldr r0,iAdrsBuffer
    ldrb r0,[r0]
    cmp r0,#0x71               @ caractere q (pour quitter)
    beq finBoucleEve           @ fin routine
    ldr r2,iAdriEtatTouches
    ldr r1,[r2]                @ chargement etat des touches
    cmp r1,#0                  @ si > zéro
    bgt trtmur                 @ traitement arrivée sur un mur
    bl traitementTouche        @ sinon traitement mouvements
    b suiteBoucleEvt
trtmur:
    bl traitementMur
    mov r0,#0
    str r0,[r2]                @ retour etat mouvement
autretouche:    
    b suiteBoucleEvt

/***************************************/    
fermeture:                      @ clic sur menu systeme
    ldr r0,iAdreve
    ldr r1,[r0,#+28]            @ position code message
    ldr r2,iAdrwmDeleteMessage  @ ces instructions permettent de résoudre une erreur
    ldr r2,[r2]                 @ lors de la fermeture de la fenêtre
    cmp r1,r2
    beq finBoucleEve            @ si egalité -> fin du programme
    b suiteBoucleEvt
/***************************************/    
configure:                      @ modification de la fenetre
    ldr r0,iAdreve
    ldr r1,[r0,#+XConfigureEvent_width]
    ldr r2,iAdrlargeur1
    ldr r2,[r2]
    cmp r1,r2
    beq suiteConfigure
    bl effacerEcran
    bl afficheentete1
    bl afficheTerrain 
suiteConfigure:
    b suiteBoucleEvt
/***************************************/
evtexpose:   /* modification fenetre */
    ldr r0,iAdreve
    b suiteBoucleEvt
/***************************************/    
suiteBoucleEvt:   /* suite de la boucle des evenements */
    mov  r0,#0
    pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */    
/**************************************************/    
    /*  Fin boucle des évenements de la fenetre  */
finBoucleEve:    
    mov  r0,#1
    pop {fp,lr}
    bx lr
iAdreve:             .int eve
iAdrsBuffer:         .int sBuffer
iAdriKey:            .int iKey
iAdrwmDeleteMessage: .int wmDeleteMessage
iAdrhauteur1:        .int hauteur
iAdriEtatTouches:    .int iEtatTouches
/********************************************************************/
/*   Connexion serveur X et recupèration informations du display  ***/
/********************************************************************/    
ConnexionServeur:
    push {fp,lr}                      @ save des registres
    mov r0,#0
    bl XOpenDisplay                   @ ouverture du serveur X
    cmp r0,#0
    beq 1f                            @ serveur non actif
    ldr r1,iAdriD
    str r0,[r1]                       @ stockage adresse du DISPLAY dans zone d
    mov r10,r0                        @ mais aussi dans le registre r10
   
    ldr r2,[r0,#+Disp_default_screen] @ recup ecran par defaut
    ldr r1,iAdriDrw
    str r2,[r1]
    ldr r0,[r0,#+Disp_screens]        @ pointeur de la liste des écrans
    ldr r1,iAdriEcran
    str r0,[r1]
    ldr r5,[r0,#+Screen_white_pixel]  @ recup valeur white pixel
    ldr r4,iAdriWhite
    str r5,[r4]
    ldr r3,[r0,#+Screen_black_pixel]  @ recup valeur black pixel
    ldr r4,iAdriBlack
    str r3,[r4]
    mov r0,r10                        @ connexion ok retourne le pointeur
    b   2f
1:
    ldr r0,iAdrszMessErreur           @ affichage erreur
    bl affichageMess
    mov r0,#0                         @ code erreur
2:    
    pop {fp,lr}                       @ restaur des registres
    bx lr
iAdriDrw:          .int iDrw
iAdriEcran:        .int iEcran
iAdriWhite:        .int iWhite
iAdriBlack:        .int iBlack
iAdrszMessErreur:  .int szMessErreur
/********************************************************************/
/*   Creation d 'une fenètre                                    ***/
/********************************************************************/
/* r10  contient le Display, r9 retourne le pointeur fenetre */
creationfenetre:
    push {fp,lr}               @ save des registres
    mov r0,r10                 @ adresse du display
    ldr r1,iAdriEcran
    ldr r1,[r1]
    ldr r1,[r1,#+Screen_root]  @ root windows trouvée dans l'écran
    ldr r2,iAdriPosfenX
    ldr r2,[r2]                @ position x
    ldr r3,iAdriPosfenY        @ position y
    ldr r3,[r3]
    sub sp,sp,#4               @ alignement pile
    ldr r4,iAdrgris
    ldr r4,[r4]                @ pixel  du fond
    push {r4}
    ldr r4,iAdriBlack
    ldr r4,[r4]                @  pixel  de la bordure
    push {r4}   
    mov r4,#2                  @ largeur bordure
    push {r4}
    ldr r4,iAdrhauteur1
    ldr r4,[r4]                @ hauteur
    push {r4}
    ldr r4,iAdrlargeur1
    ldr r4,[r4]                @ largeur
    push {r4}
    bl XCreateSimpleWindow
    add sp,sp,#24              @ réalignement pile
    cmp r0,#0                  @ erreur ?
    beq 99f    
    ldr r1,iAdriWindow
    str r0,[r1]                @ stockage identification fenetre dans zone mémoire
    mov r9,r0                  @ et dans le registre r9
                               @ ajout de proprietes de la fenêtre
    mov r0,r10                 @ adresse du display
    mov r1,r9                  @ ident fenetre
    ldr r2,iAdrszTitreFen      @ titre de la fenêtre
    ldr r3,iAdrszTitreFenRed   @ titre de la fenêtre reduite
    mov r4,#0                  @ autres paramétres à null
    push {r4}
    push {r4}
    push {r4}
    push {r4}
    bl XSetStandardProperties
    add sp,sp,#16              @ réalignement pile

    /* Préparation correction erreur lors de la fermeture fenetre X11 */
    mov r0,r10                 @ adresse du display
    ldr r1,iAdrszLibDW         @ adresse libelle message à tester
    mov r2,#1                  @ False
    bl XInternAtom             @ creation entité
    ldr r1,iAdrwmDeleteMessage
    str r0,[r1]
    mov r2,r1                  @ adresse zone retour precedente
    mov r0,r10                 @ adresse du display
    mov r1,r9                  @ ident fenetre
    mov r3,#1
    bl XSetWMProtocols         @ voir usage dans documentation xlib
                               @ affichage de la fenetre
    mov r0,r10                 @ adresse du display
    mov r1,r9                  @ ident fenetre
    bl XMapWindow              @ affichage de la fenetre

    /* centrage de la fenetre */
    ldr r1,iAdriEcran          @ recup adresse de l'écran
    ldr r1,[r1]
    ldr r2,[r1,#Screen_width]  @ recup de la largeur de l'écran
    ldr r4,iAdrlargeur1        @ recup de la largeur de la fenêtre
    ldr r4,[r4]
    sub r2,r4                  @ calcul de la différence
    lsr r2,#1                  @ et division par 2
    ldr r3,[r1,#Screen_height] @ même calcul pour la hauteur
    ldr r4,iAdrhauteur1
    ldr r4,[r4]
    sub r3,r4
    lsr r3,#1
    mov r0,r10                 @ adresse du display 
    mov r1,r9                  @ ident fenetre 
    bl XMoveWindow             @ et centrage de la fenêtre sur l'écran

    /* autorisation des saisies */
    mov r0,r10                 @ adresse du display
    mov r1,r9                  @ ident de la fenetre */
    ldr r2,iFenetreMask        @ masque des autorisations
    bl XSelectInput
    mov r0,r9                  @ retourne le pointeur fenêtre
    b 100f
99:                            @ affichage message erreur
    ldr r0,iAdrszMessErrfen
    bl affichageMess
    mov r0,#0                  @ retour erreur
100:    
    pop {fp,lr}                @restaur des registres
    bx lr
/* masque des autorisations */    
iFenetreMask:      .int StructureNotifyMask|ExposureMask|KeyPressMask
//iFenetreMask:      .int KeyPressMask   @masque des autorisations
iAdrgris:          .int gris
iAdriD:            .int iD
iAdriPosfenX:      .int iPosfenX
iAdriPosfenY:      .int iPosfenY
iAdriWindow:       .int iWindow
iAdrszTitreFen:    .int szTitreFen
iAdrszTitreFenRed: .int szTitreFenRed
iAdrszMessErrfen:  .int szMessErrfen
iAdrszLibDW:       .int szLibDW
iAdrlargeur1:      .int largeur

/********************************************************************/
/*   Création des contextes graphiques                            ***/
/********************************************************************/
creationGC:
    push {fp,lr}               @ save  registres
    /*  creation du premier contexte graphique */
    mov r0,r10                 @ adresse du display
    mov r1,r9                  @ ident fenetre
    mov r2,#0                  @ le plus simple
    mov r3,#0
    bl XCreateGC
    cmp r0,#0
    beq 2f                     @ erreur création
    ldr r1,iAdrptGC
    str r0,[r1]                @ stockage adresse contexte graphique dans zone gc
    mov r8,r0                  @ et dans r8

    /* chargement police de caractères */
    mov r0,r10                 @ adresse du display
    ldr r1,iAdrfontname        @ nom de la police
    bl XLoadQueryFont
    cmp r0,#0
    beq 1f                     @ erreur police non trouvée
    ldr r1,iAdrptPolice
    str r0,[r1]

    /* creation nouveau contexte graphique 1 */
    mov r0,r10                 @ adresse du display 
    mov r1,r9                  @ adresse fenetre 
    ldr r2,iGC1mask            @ identifie les zones de XGCValues à  mettre à  jour 
    ldr r4,iAdriBlack          @ Couleur du texte du contexte graphique 
    ldr r3,iAdrstXGCValues     @ maj dans la zone de XGCValues 
    str r4,[r3,#XGC_foreground]
    ldr r4,iAdrptPolice        @ recup du pointeur sur la police
    ldr r4,[r4]    
    ldr r4,[r4,#XFontST_fid]   @ identification police dans adresse police + 4  
    str r4,[r3,#XGC_font]      @ maj dans la zone de XGCValues 

    ldr r3,iAdrstXGCValues     @ la zone complete est passée en paramètre 
    bl XCreateGC
    cmp r0,#0
    beq 2f
    ldr r1,iAdrptGC1
    str r0,[r1]                @ stockage adresse contexte graphique
                               @ tout est ok
    mov r0,r8                  @ retour gc standard
    b 99f
1:
    ldr r0,iAdrszMessErrPol    @ affichage message d'erreur
    bl affichageMess  
    mov r0,#0
    b 99f
2:
    ldr r0,iAdrszMessErrGc     @ affichage message d'erreur
    bl affichageMess     
    mov r0,#0
    b 99f
99:    
    pop {fp,lr}
    bx lr

iGC1mask:             .int GCFont|GCForeground
iAdrptPolice:         .int ptPolice
iAdrstXGCValues:      .int stXGCValues
iAdrptGC:             .int ptGC
iAdrptGC1:            .int ptGC1
iAdrfontname:         .int fontname
iAdrszMessErrPol:     .int szMessErrPol
iAdrszMessErrGc:      .int szMessErrGc

/******************************************************************/
/*     Affichage des lignes d'entête               */ 
/******************************************************************/
afficheentete1:
    push {r0-r2,lr}        @ save des registres
    ldr r0,iAdrszLibTouche @ ligne 1
    mov r1,#0
    mov r2,#POSYLIGNE1
    bl ecrituretexteStd
    ldr r0,iAdriNiveau     @ niveau
    ldr r0,[r0]
    ldr r1,iAdrsNiveau
    bl conversion10
    ldr r0,iAdrszLibNiveau
    mov r1,#0
    mov r2,#40
    bl ecrituretexteStd
    ldr r0,iAdriDensite    @ densité
    ldr r0,[r0]
    ldr r1,iAdrsDensite
    bl conversion10
    ldr r0,iAdrszLibDensite
    mov r1,#150
    mov r2,#40
    bl ecrituretexteStd
    ldr r0,iAdriEnergie    @ energie
    ldr r0,[r0]
    ldr r1,iAdrsEnergie
    bl conversion10
    ldr r0,iAdrszLibEnergie
    mov r1,#345
    mov r2,#40
    bl ecrituretexteStd
    ldr r1,iAdriDirection   @ direction
    ldr r1,[r1]
    cmp r1,#1
    ldreq r0,iAdrszLibDirNord
    cmp r1,#2
    ldreq r0,iAdrszLibDirEst
    cmp r1,#3
    ldreq r0,iAdrszLibDirSud
    cmp r1,#4
    ldreq r0,iAdrszLibDirOuest
    mov r1,#0
    mov r2,#60
    bl ecrituretexteStd
    ldr r0,iAdriPosXJoueur    @ position du joueur
    ldr r0,[r0]
    ldr r1,iAdrsPosXJoueur
    bl conversion10
    ldr r0,iAdriPosYJoueur
    ldr r0,[r0]
    ldr r1,iAdrsPosYJoueur
    bl conversion10
    ldr r0,iAdrszLibPosition
    mov r1,#150
    mov r2,#60
    bl ecrituretexteStd
100:
    pop {r0-r2,lr}
    bx lr  
iAdrszLibTouche:     .int szLibTouche
iAdriNiveau:         .int iNiveau
iAdrsNiveau:         .int sNiveau
iAdrszLibNiveau:     .int szLibNiveau
iAdrszLibDensite:    .int szLibDensite
iAdriDensite:        .int iDensite
iAdrsDensite:        .int sDensite
iAdrszLibEnergie:    .int szLibEnergie
iAdriEnergie:        .int iEnergie
iAdrsEnergie:        .int sEnergie
iAdrszLibDirNord:    .int szLibDirNord
iAdrszLibDirSud:     .int szLibDirSud
iAdrszLibDirEst:     .int szLibDirEst
iAdrszLibDirOuest:   .int szLibDirOuest
iAdrszLibPosition:   .int szLibPosition
iAdrsPosXJoueur:     .int sPosXJoueur
iAdrsPosYJoueur:     .int sPosYJoueur
/******************************************************************/
/*     Création du terrain pour un niveau                         */ 
/******************************************************************/
/* r0 niveau               */
creationTerrain:
    push {r0-r12,lr}         @ save des registres
    bl prepGraineNiveau      @ génération d'une nouvelle graine en fonction du niveau
    ldr r1,iAdriGraine1
    ldr r1,[r1] 
    vidregtit nouvellegraine 
    ldr r7,iAdriDensite
    ldr r7,[r7]
    ldr r8,iAdritTerrain
    add r12,r0,#79
    mov r4,#0            @ N
    mov r9,r0            @ I
1:
    mov r0,#0xFF00
    add r0,#0x7D00
    bl  genereraleasNiv
    mov r5,r0            @ save Alea
    mov r11,#0           @ D
    mov r6,#0            @ G
2:
    mov r0,r5
    mov r1,#10
    bl division
    mov r5,r2
    cmp r6,#0
    moveq r6,#1
    moveq r3,#9
    add r4,#1           @ N
    cmp r3,r7
    movge r10,#0
    movlt r10,#1
    str r10,[r8,r4,lsl #2]
    mov r0,r4
    mov r1,#20
    bl division
    mov r1,#COLONNESCASES
    mul r1,r2,r1
    add r1,r3
    ldr r2,iAdritValeur
    //vidregtit valeur
    str r10,[r2,r1,lsl #2]    @ A[X,Y]
    add r11,#1
    cmp r11,#5
    blt 2b
    add r9,#1
    cmp r9,r12
    blt 1b

                                @   mise en place limites
    ldr r2,iAdritValeur
    mov r5,#COLONNESCASES
    mov r3,#LIGNESCASES - 1     @ 19
    mov r4,#1
    mov r0,#0                   @ X
3:
    str r4,[r2,r0,lsl #2]       @ 1-> A[X,0]
    mul r1,r3,r5
    add r1,r0
    str r4,[r2,r1,lsl #2]       @ 1 ->A[X,19]
    add r0,#1
    cmp r0,#COLONNESCASES
    ble 3b
    mov r0,#0                   @Y
4:
    mul r1,r0,r5
    str r4,[r2,r1,lsl #2]       @ 1-> A[0,Y]
    add r1,#COLONNESCASES - 1
    str r4,[r2,r1,lsl #2]       @ 1 ->A[19,Y]
    add r0,#1
    cmp r0,#LIGNESCASES
    ble 4b
    pop {r0-r12,lr}
    bx lr  
iAdritTerrain:        .int itTerrain
iAdritValeur:         .int itValeur
iAdriGraine1:         .int iGraine
/******************************************************************/
/*     Ecriture texte avec le contexte standard               */ 
/******************************************************************/
/* r0 adresse du texte
/* r1 position X */
/* r2 position Y */
/* r10 r9 r8 gc standard */
/* Remarque : sauvegarde des registres d'appel puis récupération de leurs données
   sur la pile en utilisant le registre de frame fp (r11) */
ecrituretexteStd:
    push {r0-r4,fp,lr}         @ save des registres
    mov fp,sp                  @ fp <- adresse début
    mov r4,#0
1:
    ldrb r3,[r0,r4]
    cmp r3,#0
    addne r4,#1
    bne 1b
    mov r0,r10           @ adresse du display
    mov r1,r9            @ adresse de la fenetre
    ldr r2,iAdrptGC1     @ adresse du contexte graphique
    ldr r2,[r2]
    ldr r3,[fp,#4]       @ recup pos X
    push {r4}            @ pour alignement pile
    push {r4}            @ en parametre sur la pile
    ldr r4,[fp]          @ recup adresse du texte a afficher
    push {r4}
    ldr r4,[fp,#8]       @ recup pos Y
    push {r4}
    bl XDrawString
    add sp,sp,#16        @ pour les 4 push
    pop {r0-r4,fp,lr}
    bx lr  

/********************************************************************/
/*   Dessin rectangle pour un mur                                 ***/
/********************************************************************/
/* r0 position X */
/* r1 position Y */
dessinMur:
    push {r1-r5,lr}       @ save des registres
    mov r3,r0             @ position X
    mov r5,r1             @ position Y
    mov r0,r10            @ adresse du display
    mov r1,r9             @ adresse de la fenetre
    mov r2,r8             @ adresse du contexte graphique
    sub sp,sp,#4          @ remplace 1 push pour l'alignement pile
    mov r4,#TAILLECASE    @ hauteur en pixel
    push {r4}             @ passée par la pile
    mov r4,#TAILLECASE    @ largeur en pixel
    push {r4}             @ passée par la pile
    push {r5}             @ position y passée par la pile
    bl XFillRectangle
    add sp,sp,#16         @ réalignement pile
    pop {r1-r5,lr}
    bx lr
/******************************************************************/
/*     Dessin d'une croix pour représenter le joueur              */ 
/******************************************************************/
/* r10 r9 r8 gc standard */
dessinjoueur:
    push {r1-r6,lr}         @ save des registres
    ldr r5,iAdriPosXJoueur
    ldr r5,[r5]             @ position X
    mov r4,#TAILLECASE
    mul r5,r4,r5
    ldr r6,iAdriPosYJoueur  @ position Y
    ldr r6,[r6]
    mul r6,r4,r6
    add r6,#POSYCARTE       @ ajout position début carte
    @ effacement zone
    mov r0,r10              @ adresse du display
    mov r1,r9               @ adresse de la fenetre
    mov r2,r5               @ X
    mov r3,r6               @ Y
    sub sp,sp,#4            @ Alignement pile
    mov r4,#0               @ non exposition
    push {r4}
    mov r4,#TAILLECASE
    push {r4}
    mov r4,#TAILLECASE
    push {r4}
    bl XClearArea
    add sp,sp,#16           @ pour le réalignement pile

    mov r0,r10              @ adresse du display
    mov r1,r9               @ adresse de la fenetre
    mov r2,r8               @ adresse du contexte graphique
    mov r3,r5               @ position x sur la carte
    sub sp,sp,#4            @ alignement pile
    add r4,r6,#TAILLECASE   @ position y1
    push {r4}               @ passée sur la pile
    add r4,r5,#TAILLECASE   @ position x1
    push {r4}               @ passée sur la pile
    push {r6}               @ position y passée sur la pile
    bl XDrawLine
    add sp,sp,#16           @ réalignement pile
    mov r0,r10              @ adresse du display
    mov r1,r9               @ adresse de la fenetre
    mov r2,r8               @ adresse du contexte graphique
    add r3,r5,#TAILLECASE   @ position x
    sub sp,sp,#4            @ Alignement pile
    add r4,r6,#TAILLECASE   @ position y1
    push {r4}               @ sur la pile
    push {r5}               @ position x1
    push {r6}               @ position y
    bl XDrawLine
    add sp,sp,#16           @ réalignement pile
    pop {r1-r6,lr}
    bx lr
iAdriPosXJoueur:     .int iPosXJoueur
iAdriPosYJoueur:     .int iPosYJoueur
/********************************************************************/
/*   Affiche la carte du terrain                                  ***/
/********************************************************************/
afficheTerrain:
    push {r0-r6,lr}       @ save des registres
    ldr r2,iAdritValeur
    mov r6,#0             @ x
1:                        @ debut de boucle
    mov r5,#0             @ y
2:
    mov r4,#COLONNESCASES
    mul r4,r5,r4          @ calcul déplacement y
    add r4,r6             @ + x
    ldr r3,[r2,r4,lsl #2] @ charge valeur de la case [x,y]
    cmp r3,#1
    bne 4f
3:                        @ si egal à 1, dessin d'un mur
    mov r3,#TAILLECASE
    mul r0,r6,r3
    mul r1,r5,r3
    add r1,#POSYCARTE
    bl dessinMur
4:
    add r5,#1             @ increment y
    cmp r5,#LIGNESCASES
    blt 2b
    add r6,#1             @ increment x
    cmp r6,#COLONNESCASES
    blt 1b
    bl dessinjoueur       @ affichage personnage
    pop {r0-r6,lr}
    bx lr
/********************************************************************/
/*   Traitement des actions si arrivée sur un mur                 ***/
/********************************************************************/
/* r0 code touche */
/* r1 code etat */
traitementMur:
    push {r1-r2,lr}        @ save des registres
    cmp r1,#1              @ reponse carte ?
    bne 1f
    cmp r0,#111      @ o
    beq reponseCarte
    cmp r0,#79      @ O
    beq reponseCarte
    bl effacerLigne1
    b 90f
1:
    cmp r1,#2              @ reponse changement ?
    bne 2f
    cmp r0,#115      @ s
    beq reponseSuppression
    cmp r0,#83      @ S
    beq reponseSuppression
    cmp r0,#97      @ a
    beq reponseAjout
    cmp r0,#65      @ A
    beq reponseAjout
    bl effacerEcran
    bl afficheentete1
    bl afficheTerrain
    b 90f
2:
    cmp r1,#3              @ reponse Descente
    bne 3f
    cmp r0,#111            @ o
    beq reponseDescente
    cmp r0,#79             @ O
    beq reponseDescente
    bl effacerEcran
    bl afficheentete1
    bl afficheTerrain 
    b 90f
3:
    cmp r1,#4              @ reponse montee
    bne 4f
    cmp r0,#111            @ o
    beq reponseMontee
    cmp r0,#79             @ O
    beq reponseMontee
    bl effacerEcran
    bl afficheentete1
    bl afficheTerrain 
    b 90f
4:
    b 90f
reponseCarte:               @ affichage carte
    bl effacerEcran
    bl afficheentete1
    bl afficheTerrain 
    b 90f
reponseSuppression:
    ldr r0,iAdriDensite     @ diminution de la densité
    ldr r1,[r0]             @ pour supprimer des murs
    sub r1,#1
    str r1,[r0]
    bl creationTerrain
    bl effacerEcran
    bl afficheentete1
    bl afficheTerrain 
    b 90f
reponseAjout:               @ augmentation de la densité 
    ldr r0,iAdriDensite     @ pour ajouter des murs
    ldr r1,[r0]
    add r1,#1
    str r1,[r0]
    bl creationTerrain
    bl effacerEcran
    bl afficheentete1
    bl afficheTerrain 
    b 90f
reponseMontee:              @ montee d'un niveau
    ldr r0,iAdriNiveau
    ldr r1,[r0]
    sub r1,#1
    str r1,[r0]
    bl creationTerrain
    bl effacerEcran
    bl afficheentete1
    bl afficheTerrain 
    b 90f
reponseDescente:            @ descente d'un niveau
    ldr r0,iAdriNiveau
    ldr r1,[r0]
    add r1,#1
    str r1,[r0]
    bl creationTerrain
    bl effacerEcran
    bl afficheentete1
    bl afficheTerrain 
    b 90f
90:
    ldr r2,iAdriEtatTouches
    mov r1,#0              @ pour saisie mouvement
    str r1,[r2]            @ raz etat 
100:
    pop {r1-r2,lr}
    bx lr
/********************************************************************/
/*   traitement des mouvements                                    ***/
/********************************************************************/
/* r0 code touche */
traitementTouche:
    push {r1-r8,lr}            @ save des registres
    ldr r1,iAdriEnergie        @ decrement energie de 1 à chaque action
    ldr r2,[r1]
    sub r2,#1
    cmp r2,#0
    movle r0,#-1               @ plus d'energie
    ble 100f                   @ fin
    str r2,[r1]                @ stocke nouvelle energie
    ldr r1,iAdriNiveau
    ldr r1,[r1]                @ charge niveau
    cmp r1,#0                  @ > zero ?
    bgt 1f
    ldr r1,iAdriPosXJoueur
    ldr r1,[r1]                @ pos X
    cmp r1,#10                 @ = 10 ?
    bne 1f
    ldr r1,iAdriPosYJoueur
    ldr r1,[r1]                @ pos Y
    cmp r1,#10                 @ = 10 ?
    bne 1f
    bl effacerLigne1           @ GAGNE
    ldr r0,iAdrszLibFinJeu     @ afficher le message de fin de jeu
    mov r1,#0
    mov r2,#POSYLIGNE1
    bl ecrituretexteStd
    b 100f
1:
    cmp r0,#97                 @ touche a
    beq avancer
    cmp r0,#65                 @ A
    beq avancer
    cmp r0,#108                @ l
    beq droite
    cmp r0,#76                 @ L
    beq droite
    cmp r0,#107                @ k
    beq gauche
    cmp r0,#77                 @ K
    beq gauche
    b 100f
droite:
    ldr r2,iAdriDirection
    ldr r1,[r2]
    add r1,#1                 @ ajout de 1 à la direction
    cmp r1,#4                 @ si > 4 on enléve 4
    subgt r1,#4
    str r1,[r2]
    ldr r0,iAdritValeur
    ldr r2,iAdriPosXJoueur
    ldr r2,[r2]               @ pos X
    ldr r3,iAdriPosYJoueur
    ldr r3,[r3]               @ pos Y
    bl dessin3D               @ dessin en 3D 
    b 100f
gauche:
    ldr r2,iAdriDirection
    ldr r1,[r2]
    sub r1,#1                 @ diminution de 1 de la direction
    cmp r1,#1                 @ si inférieur à un on ajoute 4
    addlt r1,#4
    str r1,[r2]
    ldr r0,iAdritValeur
    ldr r2,iAdriPosXJoueur
    ldr r2,[r2]               @ pos X
    ldr r3,iAdriPosYJoueur
    ldr r3,[r3]               @ pos Y
    bl dessin3D
    b 100f
avancer:
    ldr r1,iAdriDirection
    ldr r1,[r1]
    ldr r2,iAdriPosXJoueur
    ldr r5,[r2]
    ldr r3,iAdriPosYJoueur
    ldr r6,[r3]
    ldr r4,iAdritValeur
    cmp r1,#1               @ en fonction de la direction
    beq nord                @ action à faire
    cmp r1,#2
    beq est
    cmp r1,#3
    beq sud
    cmp r1,#4
    beq ouest
    b 100f 
nord:
    sub r0,r6,#1           @ y = y -1
    mov r7,#COLONNESCASES
    mul r0,r7,r0
    add r0,r5
    ldr r7,[r4,r0,lsl #2]  @ A[x,y] est un mur ?
    cmp r7,#0
    bne panDansLeMur       @ oui donc action mur
    mov r7,#2
    str r7,[r4,r0,lsl #2]  @ sinon mise à jour de la position du joueur
    mov r7,#COLONNESCASES
    mul r0,r7,r6
    add r0,r5
    mov r7,#0              @ et raz de son ancienne position
    str r7,[r4,r0,lsl #2]
    sub r0,r6,#1           @ pos Y
    str r0,[r3]            @ mise à jour de position y joueur
    mov r0,r4              @ table valeur   r1=direction
    mov r2,r5              @ pos X
    sub r3,r6,#1           @ pos Y
    bl dessin3D
    b 100f
est:
    mov r7,#COLONNESCASES
    mul r7,r6,r7
    add r0,r5,#1           @ x = x + 1
    add r0,r7
    ldr r7,[r4,r0,lsl #2]
    cmp r7,#0
    bne panDansLeMur
    mov r7,#2
    str r7,[r4,r0,lsl #2]
    mov r7,#COLONNESCASES
    mul r7,r6,r7
    add r0,r7,r5
    mov r7,#0
    str r7,[r4,r0,lsl #2]
    add r0,r5,#1           @ pos X
    str r0,[r2]
    mov r0,r4              @ table valeur   r1=direction
    add r2,r5,#1           @ pos X
    mov r3,r6              @ pos Y
    bl dessin3D
    b 100f
sud:
    add r0,r6,#1           @ y = y + 1
    mov r7,#COLONNESCASES
    mul r0,r7,r0
    add r0,r5
    ldr r7,[r4,r0,lsl #2]
    cmp r7,#0
    bne panDansLeMur
    mov r7,#2
    str r7,[r4,r0,lsl #2]
    mov r7,#COLONNESCASES
    mul r0,r7,r6
    add r0,r5
    mov r7,#0
    str r7,[r4,r0,lsl #2]
    add r0,r6,#1          @ pos Y
    str r0,[r3]
    mov r0,r4             @ table valeur   r1=direction
    mov r2,r5             @ pos X
    add r3,r6,#1          @ pos Y
    bl dessin3D
    b 100f
ouest:
    mov r7,#COLONNESCASES
    mul r7,r6,r7
    sub r0,r5,#1          @ x = x - 1
    add r0,r7
    ldr r7,[r4,r0,lsl #2]
    cmp r7,#0
    bne panDansLeMur
    mov r7,#2
    str r7,[r4,r0,lsl #2]
    mov r7,#COLONNESCASES
    mul r7,r6,r7
    add r0,r7,r5
    mov r7,#0
    str r7,[r4,r0,lsl #2]
    sub r0,r5,#1          @ pos X
    str r0,[r2]
    mov r0,r4             @ table valeur   r1=direction
    sub r2,r5,#1          @ pos X
    mov r3,r6             @ pos Y
    bl dessin3D
    b 100f
panDansLeMur:             @ actions quand le joueur cogne contre un mur
    mov r1,#1
    mov r2,#0
    ldr r3,iAdritCasesVues
analysecase:              @ début de boucle d'analyse des cases 
    ldr r0,[r3,r1,lsl #2]
    cmp r0,#1
    addeq r2,#1
    add r1,#1
    cmp r1,#9
    ble analysecase
    cmp r2,#1            @ en fonction du résultat 
    beq murVide          @ action à faire
    cmp r2,#2
    beq murVide
    cmp r2,#3
    beq murChange
    cmp r2,#4
    beq murCarte
    cmp r2,#5
    beq murCarte
    cmp r2,#6
    beq murDescente
    cmp r2,#7
    beq murDescente
    cmp r2,#8
    beq murMontee
    b 100f

murCarte:                   @ demande daffichage de la carte 
    bl effacerLigne1
    ldr r0,iAdrszLibCarte
    mov r1,#0
    mov r2,#POSYLIGNE1
    bl ecrituretexteStd
    ldr r2,iAdriEtatTouches
    mov r1,#1               @ pour saisie réponse carte
    str r1,[r2]
    b 100f
murChange:                  @ demande de changement des murs
    bl effacerLigne1
    ldr r0,iAdrszLibMurs
    mov r1,#0
    mov r2,#POSYLIGNE1
    bl ecrituretexteStd
    ldr r2,iAdriEtatTouches
    mov r1,#2               @ pour saisie réponse changement
    str r1,[r2]
    b 100f
murDescente:                @ demande de descente d'un niveau 
    ldr r0,iAdriNiveau
    ldr r1,[r0]
    cmp r1,#10              @ niveau 10 pas de descente
    bge murVide
    bl effacerLigne1
    ldr r0,iAdrszLibDescente
    mov r1,#0
    mov r2,#POSYLIGNE1
    bl ecrituretexteStd
    ldr r2,iAdriEtatTouches
    mov r1,#3               @ pour saisie réponse descente
    str r1,[r2]
    b 100f
murMontee:                  @ demande de montee d'un niveau
    ldr r0,iAdriNiveau
    ldr r1,[r0]
    cmp r1,#0              @ niveau 0 pas de montee
    ble murVide
    bl effacerLigne1
    ldr r0,iAdrszLibMontee
    mov r1,#0
    mov r2,#POSYLIGNE1
    bl ecrituretexteStd
    ldr r2,iAdriEtatTouches
    mov r1,#4               @ pour saisie réponse montee
    str r1,[r2]
    b 100f
murVide:                    @ pas d'action à faire
    bl effacerLigne1        @ affichage des !!!!!
    ldr r0,iAdrszLibMurA
    mov r1,#0
    mov r2,#POSYLIGNE1
    bl ecrituretexteStd
    b 100f
100:
    pop {r1-r8,lr}
    bx lr 
iAdriDirection:     .int iDirection
iAdrszLibMurA:      .int szLibMurA
iAdrszLibCarte:     .int szLibCarte
iAdrszLibMurs:      .int szLibMurs
iAdrszLibDescente:  .int szLibDescente
iAdrszLibMontee:    .int szLibMontee
iAdrszLibFinJeu:    .int szLibFinJeu
/********************************************************************/
/*   Dessin des murs en 3D                                        ***/
/********************************************************************/
/* r0 table valeur */
/* r1 direction */
/* r2 position X du personnage */
/* r3 position Y du personnage */
dessin3D:
    push {fp,lr}    /* save des  2 registres */
    @ effacer l'ecran
    bl effacerEcran
    bl afficheentete1
    @ afficher le libelle LIMITE si necessaire
    cmp r2,#1
    ble 1f
    cmp r2,#COLONNESCASES - 2
    bge 1f
    cmp r3,#1
    ble 1f
    cmp r3,#LIGNESCASES - 2
    bge 1f
    b 2f
1:
    bl afficheLimite
2:
    @ relever les 9 cases devant le joueur
    cmp r1,#1
    bleq casesNord
    cmp r1,#2
    bleq casesEst
    cmp r1,#3
    bleq casesSud
    cmp r1,#4
    bleq casesOuest
    @ dessin du cadre puis des murs
    mov r0,r10              @ adresse du display
    mov r1,r9               @ adresse de la fenetre
    mov r2,r8               @ adresse du contexte graphique std
    mov r3,#POSXDESSIN3D    @ X
    sub sp,sp,#4            @ Alignement pile
    mov r4,#TAILLEDESSIN3D  @ hauteur
    push {r4}
    mov r4,#TAILLEDESSIN3D  @ larteur
    push {r4}
    mov r4,#POSYDESSIN3D    @ Y
    push {r4}
    bl XDrawRectangle
    add sp,sp,#16           @ pour le réalignement pile
    ldr r0,iAdritCasesVues
    mov r1,#7               @ en fonction de l'occupation des cases
    ldr r2,[r0,r1,lsl #2]   @ dessin des murs
    cmp r2,#1               @  ordre des cases :   3  2  1
    bleq dessinCase7        @                      6  5  4
    mov r1,#9               @                      9  8  7
    ldr r2,[r0,r1,lsl #2]   @        le joueur est sur la case 8 et a les cases 5 et 2 devant lui
    cmp r2,#1
    bleq dessinCase9
    mov r1,#5
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bne 1f
    mov r1,#4
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bne 1f
    mov r1,#7
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#0
    bne 1f
    bl dessinLigne1         @ et dessin ligne de jontion
1:
    mov r1,#5
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bne 2f
    mov r1,#6
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bne 2f
    mov r1,#9
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#0
    bne 2f
    bl dessinLigne2
2:
    mov r1,#5
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bne 21f
    bl dessinCase5         @ si la case 5 est un mur
    b 10f                  @ on ne dessine rien d'autre
21:
    mov r1,#4
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bleq dessinCase4
    mov r1,#4
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bne 3f
    mov r1,#7
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#0
    bne 3f
    bl dessinLigne3
3:
    mov r1,#6
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bleq dessinCase6
    mov r1,#6
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bne 4f
    mov r1,#9
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#0
    bne 4f
    bl dessinLigne4
4:
    mov r1,#2
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#0
    bne 5f
    mov r1,#1
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#0
    bne 5f
    mov r1,#3
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#0
    bne 5f
    b 10f
5:
    mov r1,#2
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bne 51f
    bl dessinCase2
    b 52f
51:
    mov r1,#1
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bleq dessinCase1
    mov r1,#3
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bleq dessinCase3
52:
    mov r1,#4
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    beq 7f          @ 
    mov r1,#7
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bne 6f
    mov r1,#1
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bne 6f
    bl dessinLigne5
6:
    mov r1,#7
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#0
    bne 7f
    mov r1,#1
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bne 7f
    bl dessinLigne6
7:
    mov r1,#6
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    beq 10f
    mov r1,#9
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bne 8f
    mov r1,#3
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bne 8f
    bl dessinLigne7
8:
    mov r1,#9
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#0
    bne 9f
    mov r1,#3
    ldr r2,[r0,r1,lsl #2]
    cmp r2,#1
    bne 9f
    bl dessinLigne8
9:
10:
100:
    pop {fp,lr}
    bx lr
iAdrszLibLimite:         .int szLibLimite
/********************************************************************/
/*   afficher le libelle limite  quand le joueur est près des murs exterieurs ***/
/********************************************************************/
afficheLimite:
    push {r0-r2,lr}                 @ save des registres
    ldr r0,iAdrszLibLimite
    mov r1,#500
    mov r2,#60
    bl ecrituretexteStd
    pop {r0-r2,lr}
    bx lr        
/********************************************************************/
/*   relever les 9 cases situees dans la direction nord           ***/
/********************************************************************/
/* r0 table valeur */
/* r1 direction */
/* r2 position X du personnage */
/* r3 position Y du personnage */
casesNord:
    push {r1-r9,lr}            @ save des  registres
    ldr r8,iAdritCasesVues
    mov r7,#1                  @ indice cases vues
    mov r9,#COLONNESCASES
    sub r4,r3,#2               @ y = yp - 2
1:
    add r5,r2,#1               @ x =xp + 1
2:
    mul r1,r4,r9
    add r1,r5                  @ calcul deplacement table valeur
    ldr r6,[r0,r1,lsl #2]      @ valeur
    str r6,[r8,r7,lsl #2]      @ et stockage dans cases vues
    add r7,#1                  @ case vue suivante
    sub r5,#1                  @ pos x precedente
    sub r1,r2,#1
    cmp r5,r1                  @ fin des x ?
    bge 2b
    add r4,#1                  @ pos y suivante
    cmp r4,r3                  @ fin des y
    ble 1b          
100:
    pop {r1-r9,lr}
    bx lr
iAdritCasesVues:        .int itCasesVues
/********************************************************************/
/*   relever les 9 cases situees dans la direction Est           ***/
/********************************************************************/
/* r0 table valeur */
/* r1 direction */
/* r2 position X du personnage */
/* r3 position Y du personnage */
casesEst:
    push {r1-r9,lr}             @ save des registres
    ldr r8,iAdritCasesVues
    mov r7,#1                  @ indice cases vues
    mov r9,#COLONNESCASES
    add r5,r2,#2               @ x = xp + 2
1:
    add r4,r3,#1               @ y = yp + 1
2:
    mul r1,r4,r9
    add r1,r5                  @ calcul deplacement table valeur
    ldr r6,[r0,r1,lsl #2]      @ valeur
    str r6,[r8,r7,lsl #2]      @ et stockage dans cases vues
    add r7,#1                  @ case vue suivante
    sub r4,#1                  @ pos y precedente
    sub r1,r3,#1
    cmp r4,r1                  @ fin des y ?
    bge 2b          
    sub r5,#1                  @ pos x precedente
    cmp r5,r2                  @ fin des x ?
    bge 1b
100:
    pop {r1-r9,lr}
    bx lr
/********************************************************************/
/*   relever les 9 cases situees dans la direction sud           ***/
/********************************************************************/
/* r0 table valeur */
/* r1 direction */
/* r2 position X du personnage */
/* r3 position Y du personnage */
casesSud:
    push {r1-r9,lr}            @ save des  2 registres
    ldr r8,iAdritCasesVues
    mov r7,#1                  @ indice cases vues
    mov r9,#COLONNESCASES
    add r4,r3,#2               @ y = yp + 2
1:
    sub r5,r2,#1               @ x = xp - 1
2:
    mul r1,r4,r9
    add r1,r5                  @ calcul deplacement table valeur
    ldr r6,[r0,r1,lsl #2]      @ valeur
    str r6,[r8,r7,lsl #2]      @ et stockage dans cases vues
    add r7,#1                  @ case vue suivante
    add r5,#1                  @ pos x suivante
    add r1,r2,#1
    cmp r5,r1                  @ fin des x ?
    ble 2b
    sub r4,#1                  @ pos y precedente
    cmp r4,r3                  @ fin des y
    bge 1b          
100:
    pop {r1-r9,lr}
    bx lr
/********************************************************************/
/*   relever les 9 cases situees dans la direction Ouest           ***/
/********************************************************************/
/* r0 table valeur */
/* r1 direction */
/* r2 position X du personnage */
/* r3 position Y du personnage */
casesOuest:
    push {r1-r9,lr}            @ save des registres
    ldr r8,iAdritCasesVues
    mov r7,#1                  @ indice cases vues
    mov r9,#COLONNESCASES
    sub r5,r2,#2               @ x = xp - 2
1:
    sub r4,r3,#1               @ y = yp - 1
2:
    mul r1,r4,r9
    add r1,r5                  @ calcul deplacement table valeur
    ldr r6,[r0,r1,lsl #2]      @ valeur
    str r6,[r8,r7,lsl #2]      @ et stockage dans cases vues
    add r7,#1                  @ case vue suivante
    add r4,#1                  @ pos y suivante
    add r1,r3,#1
    cmp r4,r1                  @ fin des y
    ble 2b          
    add r5,#1                  @ pos x suivante
    cmp r5,r2                  @ fin des x ?
    ble 1b
100:
    pop {r1-r9,lr}
    bx lr
/********************************************************************/
/*   pour effacer la première ligne                               ***/
/********************************************************************/
effacerLigne1:
    push {r0-r4,lr}         @ save registres
    mov r0,r10              @ adresse du display
    mov r1,r9               @ adresse de la fenetre
    mov r2,#0               @ X
    mov r3,#0               @ Y
    sub sp,sp,#4            @ Alignement pile
    mov r4,#0               @ pas d'exposition
    push {r4}
    mov r4,#TAILLEPOLICE    @ hauteur = taille de la police
    push {r4}
    ldr r4,iAdrlargeur
    ldr r4,[r4]             @ largeur ecran
    push {r4}
    bl XClearArea
    add sp,sp,#16           @ pour le réalignement pile
100:
    pop {r0-r4,lr}
    bx lr
/********************************************************************/
/*   effacer la zone d'affichage de l'ecran          ***/
/********************************************************************/
effacerEcran:
    push {r0-r4,lr}        @ save des registres
    mov r0,r10             @ adresse du display
    mov r1,r9              @ adresse de la fenetre
    mov r2,#0              @ X
    mov r3,#0             @ Y
    sub sp,sp,#4           @ Alignement pile
    mov r4,#0              @ non exposition
    push {r4}
    ldr r4,iAdrhauteur
    ldr r4,[r4]            @ hauteur écran
    sub r4,#25             @  moins le bandeau
    push {r4}
    ldr r4,iAdrlargeur
    ldr r4,[r4]            @ largeur ecran
    push {r4}
    bl XClearArea
    add sp,sp,#16          @ pour le réalignement pile
100:
    pop {r0-r4,lr}
    bx lr
iAdrlargeur:    .int largeur
iAdrhauteur:    .int hauteur
/********************************************************************/
/*   dessin 3D vision case 1                                      ***/
/********************************************************************/
dessinCase1:
    push {r0-r4,lr}                            @ save des registres
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 100  @ position x */
    sub sp,sp,#4                               @ alignement pile
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -100   @ position y1
    push {r4}                                  @ sur la pile
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D - 100  @ position x1
    push {r4}
    mov r4,#POSYDESSIN3D    @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour le réalignement pile
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 100  @ position x
    sub sp,sp,#4
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 120  @ position y1
    push {r4}      /* en parametre */
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D -120   @ position x1
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 100  @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour les 4 push
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 120  @ position x
    sub sp,sp,#4
    mov r4,#POSYDESSIN3D                       @ position y1
    push {r4}                                  @ en parametre
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D -120   @ position x1
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -120   @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour les 4 push 
100:
    pop {r0-r4,lr}
    bx lr
/********************************************************************/
/*   dessin 3D vision case 2                                      ***/
/********************************************************************/
dessinCase2:
    push {r0-r4,lr}                            @ save des registres
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 100   @ position x */
    sub sp,sp,#4                               @ alignement pile
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -100                      @ position y1
    push {r4}                                  @ sur la pile
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D - 100   @ position x1
    push {r4}
    mov r4,#POSYDESSIN3D    @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour le réalignement pile
    mov r0,r10                                 @ adresse du display
    mov r1,r9          @ adresse de la fenetre
    mov r2,r8          @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 100          @ position x */
    sub sp,sp,#4
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 100      @ position y1
    push {r4}      /* en parametre */
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D -200      /* position x1 */
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 100         /* position y */
    push {r4}
    bl XDrawLine
    add sp,sp,#16   /* pour les 4 push */
    mov r0,r10                                 @ adresse du display
    mov r1,r9          @ adresse de la fenetre
    mov r2,r8          @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 200          @ position x */
    sub sp,sp,#4
    mov r4,#POSYDESSIN3D      @ position y1
    push {r4}      /* en parametre */
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D -200      /* position x1 */
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -100        /* position y */
    push {r4}
    bl XDrawLine
    add sp,sp,#16   /* pour les 4 push */
100:
    pop {r0-r4,lr}
    bx lr
/********************************************************************/
/*   dessin 3D vision case 2                                      ***/
/********************************************************************/
dessinCase3:
    push {r0-r4,lr}                            @ save des registres
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 180   @ position x */
    sub sp,sp,#4                               @ alignement pile
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -120                      @ position y1
    push {r4}                                  @ sur la pile
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D - 180   @ position x1
    push {r4}
    mov r4,#POSYDESSIN3D    @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour le réalignement pile
    mov r0,r10                                 @ adresse du display
    mov r1,r9          @ adresse de la fenetre
    mov r2,r8          @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 180          @ position x */
    sub sp,sp,#4
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 100      @ position y1
    push {r4}      /* en parametre */
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D -200      /* position x1 */
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 120         /* position y */
    push {r4}
    bl XDrawLine
    add sp,sp,#16   /* pour les 4 push */
    mov r0,r10                                 @ adresse du display
    mov r1,r9          @ adresse de la fenetre
    mov r2,r8          @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 200          @ position x */
    sub sp,sp,#4
    mov r4,#POSYDESSIN3D      @ position y1
    push {r4}      /* en parametre */
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D -200      /* position x1 */
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -100        /* position y */
    push {r4}
    bl XDrawLine
    add sp,sp,#16   /* pour les 4 push */
100:
    pop {r0-r4,lr}
    bx lr
/********************************************************************/
/*   dessin 3D vision case 4                                      ***/
/********************************************************************/
dessinCase4:
    push {r0-r4,lr}                            @ save des registres
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 40   @ position x */
    sub sp,sp,#4                               @ alignement pile
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -40                      @ position y1
    push {r4}                                  @ sur la pile
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D - 40   @ position x1
    push {r4}
    mov r4,#POSYDESSIN3D    @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour le réalignement pile
    mov r0,r10                                 @ adresse du display
    mov r1,r9          @ adresse de la fenetre
    mov r2,r8          @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 40          @ position x */
    sub sp,sp,#4
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 100      @ position y1
    push {r4}      /* en parametre */
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D -100      /* position x1 */
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 40         /* position y */
    push {r4}
    bl XDrawLine
    add sp,sp,#16   /* pour les 4 push */
    mov r0,r10                                 @ adresse du display
    mov r1,r9          @ adresse de la fenetre
    mov r2,r8          @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 100          @ position x */
    sub sp,sp,#4
    mov r4,#POSYDESSIN3D      @ position y1
    push {r4}      /* en parametre */
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D -100      /* position x1 */
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -100        /* position y */
    push {r4}
    bl XDrawLine
    add sp,sp,#16   /* pour les 4 push */
100:
    pop {r0-r4,lr}
    bx lr
/********************************************************************/
/*   dessin 3D vision case 5                                      ***/
/********************************************************************/
dessinCase5:
    push {r0-r4,lr}                            @ save des registres
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 40   @ position x */
    sub sp,sp,#4                               @ alignement pile
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -40                      @ position y1
    push {r4}                                  @ sur la pile
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D - 40   @ position x1
    push {r4}
    mov r4,#POSYDESSIN3D    @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour le réalignement pile
    mov r0,r10                                 @ adresse du display
    mov r1,r9          @ adresse de la fenetre
    mov r2,r8          @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 40          @ position x */
    sub sp,sp,#4
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 40      @ position y1
    push {r4}      /* en parametre */
    mov r4,#POSXDESSIN3D +40            /* position x1 */
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 40         /* position y */
    push {r4}
    bl XDrawLine
    add sp,sp,#16   /* pour les 4 push */
    mov r0,r10                                 @ adresse du display
    mov r1,r9          @ adresse de la fenetre
    mov r2,r8          @ adresse du contexte graphique
    mov r3,#POSXDESSIN3D +40          @ position x */
    sub sp,sp,#4
    mov r4,#POSYDESSIN3D      @ position y1
    push {r4}      /* en parametre */
    mov r4,#POSXDESSIN3D +40      /* position x1 */
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -40        /* position y */
    push {r4}
    bl XDrawLine
    add sp,sp,#16   /* pour les 4 push */
100:
    pop {r0-r4,lr}
    bx lr
/********************************************************************/
/*   dessin 3D vision case 6                                      ***/
/********************************************************************/
dessinCase6:
    push {r0-r4,lr}                            @ save des registres
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 200   @ position x */
    sub sp,sp,#4                               @ alignement pile
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -100                      @ position y1
    push {r4}                                  @ sur la pile
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D - 200   @ position x1
    push {r4}
    mov r4,#POSYDESSIN3D    @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour le réalignement pile
    mov r0,r10                                 @ adresse du display
    mov r1,r9          @ adresse de la fenetre
    mov r2,r8          @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 200          @ position x */
    sub sp,sp,#4
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 40      @ position y1
    push {r4}      /* en parametre */
    mov r4,#POSXDESSIN3D +40      /* position x1 */
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 100         /* position y */
    push {r4}
    bl XDrawLine
    add sp,sp,#16   /* pour les 4 push */
    mov r0,r10                                 @ adresse du display
    mov r1,r9          @ adresse de la fenetre
    mov r2,r8          @ adresse du contexte graphique
    mov r3,#POSXDESSIN3D +40         @ position x */
    sub sp,sp,#4
    mov r4,#POSYDESSIN3D      @ position y1
    push {r4}      /* en parametre */
    mov r4,#POSXDESSIN3D + 40      /* position x1 */
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -40        /* position y */
    push {r4}
    bl XDrawLine
    add sp,sp,#16   /* pour les 4 push */
100:
    pop {r0-r4,lr}
    bx lr
/********************************************************************/
/*   dessin 3D vision case 7                                      ***/
/********************************************************************/
dessinCase7:
    push {r0-r4,lr}                            @ save des registres
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 40   @ position x */
    sub sp,sp,#4                               @ alignement pile
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 40                @ position y1
    push {r4}                                  @ sur la pile
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D - 40   @ position x1
    push {r4}
    mov r4,#POSYDESSIN3D                       @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour le réalignement pile
    mov r0,r10                                 @ adresse du display
    mov r1,r9          @ adresse de la fenetre
    mov r2,r8          @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 40          @ position x */
    sub sp,sp,#4
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D       @ position y1
    push {r4}      /* en parametre */
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D       /* position x1 */
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 40         /* position y */
    push {r4}
    bl XDrawLine
    add sp,sp,#16   /* pour les 4 push */
100:
    pop {r0-r4,lr}
    bx lr
/********************************************************************/
/*   dessin 3D vision case 9                                      ***/
/********************************************************************/
dessinCase9:
    push {r0-r4,lr}                            @ save des registres
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#POSXDESSIN3D +40   @ position x */
    sub sp,sp,#4                               @ alignement pile
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 40                       @ position y1
    push {r4}                                  @ sur la pile
    mov r4,#POSXDESSIN3D + 40   @ position x1
    push {r4}
    mov r4,#POSYDESSIN3D                      @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour le réalignement pile
    mov r0,r10                                 @ adresse du display
    mov r1,r9          @ adresse de la fenetre
    mov r2,r8          @ adresse du contexte graphique
    mov r3,#POSXDESSIN3D  +40        @ position x */
    sub sp,sp,#4
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D       @ position y1
    push {r4}      /* en parametre */
    mov r4,#POSXDESSIN3D      /* position x1 */
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -40         /* position y */
    push {r4}
    bl XDrawLine
    add sp,sp,#16   /* pour les 4 push */
100:
    pop {r0-r4,lr}
    bx lr
/********************************************************************/
/*   dessin 3D vision ligne 1                                      ***/
/********************************************************************/
dessinLigne1:
    push {r0-r4,lr}                            @ save des registres
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 40   @ position x */
    sub sp,sp,#4                               @ alignement pile
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 40                      @ position y1
    push {r4}                                  @ sur la pile
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D        @ position x1
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -40    @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour le réalignement pile
100:
    pop {r0-r4,lr}
    bx lr
/********************************************************************/
/*   dessin 3D ligne 2                                      ***/
/********************************************************************/
dessinLigne2:
    push {r0-r4,lr}                            @ save des registres
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#POSXDESSIN3D + 40                  @ position x
    sub sp,sp,#4                               @ alignement pile
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 40   @ position y1
    push {r4}                                  @ sur la pile
    mov r4,#POSXDESSIN3D                       @ position x1
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -40    @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour le réalignement pile
100:
    pop {r0-r4,lr}
    bx lr
/********************************************************************/
/*   dessin 3D ligne 3                                      ***/
/********************************************************************/
dessinLigne3:
    push {r0-r4,lr}                            @ save des registres
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 40                  @ position x
    sub sp,sp,#4                               @ alignement pile
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 40   @ position y1
    push {r4}                                  @ sur la pile
    mov r4,#POSXDESSIN3D + TAILLEDESSIN3D      @ position x1
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -40    @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour le réalignement pile
100:
    pop {r0-r4,lr}
    bx lr
/********************************************************************/
/*   dessin 3D ligne 4                                      ***/
/********************************************************************/
dessinLigne4:
    push {r0-r4,lr}                            @ save des registres
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#POSXDESSIN3D + 40                  @ position x
    sub sp,sp,#4                               @ alignement pile
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 40   @ position y1
    push {r4}                                  @ sur la pile
    mov r4,#POSXDESSIN3D      @ position x1
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -40    @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour le réalignement pile
100:
    pop {r0-r4,lr}
    bx lr
/********************************************************************/
/*   dessin 3D ligne 5                                      ***/
/********************************************************************/
dessinLigne5:
    push {r0-r4,lr}                            @ save des registres
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 100                  @ position x
    sub sp,sp,#4                               @ alignement pile
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 100   @ position y1
    push {r4}                                  @ sur la pile
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D -40       @ position x1
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -100    @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour le réalignement pile
100:
    pop {r0-r4,lr}
    bx lr
/********************************************************************/
/*   dessin 3D ligne 6                                      ***/
/********************************************************************/
dessinLigne6:
    push {r0-r4,lr}                            @ save des registres
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 100                  @ position x
    sub sp,sp,#4                               @ alignement pile
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 100   @ position y1
    push {r4}                                  @ sur la pile
    mov r4,#TAILLEDESSIN3D+POSXDESSIN3D        @ position x1
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -100    @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour le réalignement pile
100:
    pop {r0-r4,lr}
    bx lr
/********************************************************************/
/*   dessin 3D ligne 7                                      ***/
/********************************************************************/
dessinLigne7:
    push {r0-r4,lr}                            @ save des registres
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 200                  @ position x
    sub sp,sp,#4                               @ alignement pile
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 100   @ position y1
    push {r4}                                  @ sur la pile
    mov r4,#POSXDESSIN3D  + 40      @ position x1
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -100    @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour le réalignement pile
100:
    pop {r0-r4,lr}
    bx lr
/********************************************************************/
/*   dessin 3D ligne 8                                      ***/
/********************************************************************/
dessinLigne8:
    push {r0-r4,lr}                            @ save des registres
    mov r0,r10                                 @ adresse du display
    mov r1,r9                                  @ adresse de la fenetre
    mov r2,r8                                  @ adresse du contexte graphique
    mov r3,#TAILLEDESSIN3D+POSXDESSIN3D - 200                  @ position x
    sub sp,sp,#4                               @ alignement pile
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D - 100   @ position y1
    push {r4}                                  @ sur la pile
    mov r4,#POSXDESSIN3D                       @ position x1
    push {r4}
    mov r4,#TAILLEDESSIN3D+POSYDESSIN3D -100    @ position y
    push {r4}
    bl XDrawLine
    add sp,sp,#16                              @ pour le réalignement pile
100:
    pop {r0-r4,lr}
    bx lr
/**************************************************/
/* Préparation de la graine en fonction du niveau */
/**************************************************/
prepGraineNiveau:
    push {r0,r1,lr}          @ save des registres
    ldr r0,iAdriNiveau1
    ldr r0,[r0]
    ldr r1,iAdrTabGraine
    ldr r1,[r1,r0,lsl #2]    @ chargement graine en fonction du niveau
    ldr r0,iAdriGraine
    str r1,[r0]              @ et stockage dans zone
    pop {r0,r1,lr}
    bx lr
iAdrTabGraine:   .int TabGraine
iAdriNiveau1:    .int iNiveau
/*******************************************/
/* Génération nombre aléatoire           */
/*******************************************/
/* r0 plage fin  */
genereraleasNiv:
    push {r1-r4,lr}        @ save des registres
    mov r4,r0              @ save plage
    ldr r0,iAdriGraine     @ chargement graine
    ldr r0,[r0]
    ldr r1,iNombre1
    mul r0,r1
    add r0,#1
    ldr r1,iAdriGraine
    str r0,[r1]
                           @ prise en compte nouvelle graine
    ldr r1,m               @ diviseur pour registre de 32 bits
    bl division
    mov r0,r3              @ division du reste
    ldr r1,m1              @ diviseur  10000
    bl division
    mul r0,r2,r4           @ on multiplie le quotient par la plage demandée
    mov r6,r0
    ldr r1,m1              @ puis on divise le resultat diviseur
    bl division            @ pour garder les chiffres à gauche significatif.
    mov r0,r2              @ retour du quotient
100:
    pop {r1-r4,lr}
    bx lr
/*******************CONSTANTES****************************************/
iAdriGraine:     .int iGraine
iNombre1:        .int 31415821
m1:              .int 10000
m:               .int 100000000 


