/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* création fenetre X11 pour affichage image jpeg  */

/*********************************************/
/*constantes                                 */
/********************************************/
@ le ficher des constantes générales est en fin du programme
.equ LARGEUR,           600   @ largeur de la fenêtre
.equ HAUTEUR,           400   @ hauteur de la fenêtre
.equ LGBUFFER,          1000  @ longueur du buffer 
.equ JPEG_LIB_VERSION,  62
.equ JPOOL_PERMANENT,   0     @ lasts until master record is destroyed
.equ JPOOL_IMAGE,       1     @ lasts until done with image/datastream
.equ JPOOL_NUMPOOLS,    2

/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"
/***********************************/
/* description des structures */
/***********************************/
.include "../descStruct.inc"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szNomFenetre:            .asciz "Fenetre Raspberry"
szRetourligne:           .asciz  "\n"
szMessDebutPgm:          .asciz "Debut du programme. \n"
szMessFinPgm:            .asciz "Fin normale du programme. \n" 
szMessErrComm:           .asciz "Nom du fichier absent de la ligne de commande. \n"
szMessErreur:            .asciz "Serveur X non trouvé.\n"
szMessErrfen:            .asciz "Création fenetre impossible.\n"
szMessErreurX11:         .asciz "Erreur fonction X11. \n"
szMessErrGc:             .asciz "Création contexte graphique impossible.\n"
szMessErrGcBT:           .asciz "Création contexte graphique Bouton impossible.\n"
szMessErrbt:             .asciz "Création bouton impossible.\n"
szMessErrGPolice:        .asciz "Chargement police impossible.\n"

szTitreFenRed:           .asciz "Pi"   
szTitreFenRedS:          .asciz "PiS"  
szRouge:                 .asciz "red"
szBlack:                 .asciz "black"
szWhite:                 .asciz "white"
//szNomFichier:          .asciz "img2"
/* libellé special pour correction pb fermeture */
szLibDW:                 .asciz "WM_DELETE_WINDOW"

szNomRepDepart:          .asciz "."

szModeOpen:              .asciz "rb"

/* polices de caracteres */
szNomPolice:             .asciz  "-*-helvetica-bold-*-normal-*-14-*"
szNomPolice1:            .asciz  "-*-fixed-bold-*-normal-*-14-*"
.align 4
hauteur:                 .int HAUTEUR
largeur:                 .int LARGEUR


/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
iAdrFicName:            .skip 4     @ addresse du nom de fichier dans ligne de commande
ptDisplay:              .skip 4     @ pointeur display
ptEcran:                .skip 4     @ pointeur ecran standard
ptGC:                   .skip 4     @ pointeur contexte graphique
ptGC1:                  .skip 4     @ pointeur contexte graphique 1
ptGC2:                  .skip 4     @ pointeur contexte graphique 2
ptPolice:               .skip 4     @ pointeur police de caractères
ptPolice1:              .skip 4     @ pointeur police de caractères 1
ptCurseur:              .skip 4     @ pointeur curseur
ptImg1:                 .skip 4     @ pointeur image
ptImg2:                 .skip 4
ptIcone:                .skip 4
ptIcone2:               .skip 4
iLargeurIcone:          .skip 4
iHauteurIcone:          .skip 4
x_hot:                  .skip 4
y_hot:                  .skip 4
iBufferTas:             .skip 4
/* structure de décompression : contient toutes les données */
/* pour plus de détail voir jpeglib.h */
cinfo:                  .skip jpeg_decompress_fin  @ TODO taille à revoir

.align 4
my_error_mgr:           .skip jpeg_error_fin
//errorexist:             .skip 4
//msg_code:               .skip 4
//msg_parm:               .skip 80
//trace_level:            .skip 4
//num_warnings:           .skip 4
//jpeg_message_table: .skip 4
//last_jpeg_message:  .skip 4
//addon_message_table: .skip 4
//first_addon_message: .skip 4
//last_addon_message:  .skip 4
@
//setjmp_buffer:       .skip 4

wmDeleteMessage:        .skip 8   @ identification message de fermeture


event:                  .skip 400          @ TODO revoir cette taille 
sBuffer:                .skip LGBUFFER 

/* Structures des données */  
.align 4
stAttributs:           .skip Att_fin       @ reservation place structure Attibuts 
.align 4
stXGCValues:           .skip XGC_fin       @ reservation place structure XGCValues
.align 4
stFenetreAtt:          .skip Win_fin       @ reservation place attributs fenêtre
.align 4  
stFenetreChge:         .skip XWCH_fin      @ reservation place   XWindowChanges
.align 4
stWmHints:             .skip  Hints_fin    @ reservation place pour structure XWMHints 
.align 4
stAttrSize:            .skip XSize_fin     @ reservation place structure XSizeHints
.align 4
stImageBMP1:           .skip BMP_fin
.align 4
stImageJPEG:           .skip JPEG_fin
.align 4
Closest:               .skip XColor_fin    @ reservation place structure XColor
Exact:                 .skip XColor_fin
Front:                 .skip XColor_fin
Backing:               .skip XColor_fin
TableFenetres:
stFenetrePrinc:        .skip  Win_fin      @ reservation place structure fenêtre
stFenetreSec1:         .skip  Win_fin      @ reservation place structure fenêtre
stFenetreFin:          .skip   Win_fin     @ structure de la fin de la table des fenetre

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text           
.global main                            @ 'main' point d'entrée doit être  global 

main:                                   @ programme principal
    push {fp,lr}                        @ save des  2 registres 
    add fp,sp,#8                        @ fp <- adresse début 
    ldr r0,iAdrszMessDebutPgm           @ adresse message debut 
    bl affichageMess                    @ affichage message dans console
    ldr r4,[fp]                         @ nombre de paramètres ligne de commande
    cmp r4,#1                           @ TODO voir avec 2 !!
    movle r0,#-1
    ble erreurCommande                  @ erreur
    add r5,fp,#8                        @ adresse du 2ième paramètre
    ldr r5,[r5]                         @ recup adresse nom du fichier image
    ldr r0,iAdriAdrFicName              @ et stockage adresse dans zone mémoire
    str r5,[r0]
    /* attention r6  pointeur display*/
    /* attention r7  pointeur ecran   */
    /* attention r12 est utilisé par les fonctions X11 */
    bl ConnexionServeur                 @ ouverture du serveur X
    cmp r0,#0
    beq erreurServeur
    ldr r2,iAdrptDisplay
    str r0,[r2]                         @ stockage adresse du DISPLAY 
    mov r6,r0                           @ mais aussi dans le registre r6
    ldr r2,iAdrptEcran
    str r1,[r2]                         @stockage  pointeur ecran
    mov r7,r1                           @ mais aussi dans le registre r7

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
    mov r9,r0                           @ adresse fenêtre dans r9

    /*  creation des contextes graphiques */
    mov r0,r6
    mov r1,r9
    mov r2,r7
    bl creationGC
    cmp r0,#0
    beq erreurGC


    ldr r0,iAdriAdrFicName
    ldr r0,[r0]
    bl chargeImageJpeg

    
    /* création de l'image X11   */
    mov r0,r6
    mov r1,r7
    ldr r2,iAdrstImageJPEG                @ pointeur structure image
    bl creationImageX11JPEG
    
    /* création fenetre avec dimension de l'image JPEG et affichage image */
    mov r0,r6
    mov r1,r9
    mov r2,r7
    ldr r3,iAdrstFenetreSec1
    bl creationFenetreSec1
    
    
    /* boucle des evenements */     
boucleevt:
    bl gestionEvenements
    cmp r0,#0                             @ si zero on boucle sinon on termine 
    beq  boucleevt
                                          @ fin des évenements liberation des ressources
    mov r0,r6                             @ adresse du display 
    ldr r1,iAdrptGC
    ldr r1,[r1]                           @ adresse du contexte 
    bl XFreeGC
    cmp r0,#0
    blt erreurX11
    mov r0,r6                             @ adresse du display 
    ldr r1,iAdrptGC1
    ldr r1,[r1]                           @ adresse du contexte 
    bl XFreeGC
    cmp r0,#0
    blt erreurX11
    mov r0,r6                             @ adresse du display 
    mov r1,r9                             @ adresse de la fenetre 
    bl XDestroyWindow
    cmp r0,#0
    blt erreurX11
    mov r0,r6
    bl XCloseDisplay
    cmp r0,#0
    blt erreurX11
    ldr r0,iAdrszMessFinPgm               @ fin programme OK
    bl affichageMess                      @ affichage message dans console   
    mov r0,#0                             @ code retour OK  
    b 100f
erreurCommande:
    ldr r1,iAdrszMessErrComm
    bl   afficheerreur   
    mov r0,#1                             @ code erreur
    b 100f
erreurF:                                  @ erreur creation fenêtre mais ne sert peut être à  rien car erreur directe X11  */
    ldr r1,iAdrszMessErrfen   
    bl   afficheerreur   
    mov r0,#1                             @ code erreur
    b 100f
erreurGC:                                 @ erreur creation contexte graphique
    ldr r1,iAdrszMessErrGc  
    bl   afficheerreur  
    mov r0,#1                             @ code erreur
    b 100f
erreurX11:                                @ erreur X11
    ldr r1,iAdrszMessErreurX11   
    bl   afficheerreur   
    mov r0,#1                             @ retour erreur
    b 100f
erreurServeur:                            @ erreur car pas de serveur X   (voir doc putty et serveur Xming )*/
    ldr r1,iAdrszMessErreur  
    bl   afficheerreur   
    mov r0,#1                             @ retour erreur
    b 100f

100:                                      @ fin de programme standard
    pop {fp,lr}                           @ restaur des  2 registres
    mov r7, #EXIT                         @ appel fonction systeme pour terminer
    swi 0 

iAdrszMessDebutPgm:     .int szMessDebutPgm
iAdrszMessFinPgm:       .int szMessFinPgm
iAdrszMessErreur:       .int szMessErreur
iAdrszMessErrComm:      .int szMessErrComm
iAdrptDisplay:          .int ptDisplay
iAdrptEcran:            .int ptEcran
iAdrstFenetrePrinc:     .int stFenetrePrinc
iAdrstFenetreSec1:      .int stFenetreSec1
iAdrstImageJPEG:        .int stImageJPEG
iAdriAdrFicName:        .int iAdrFicName
/********************************************************************/
/*   Connexion serveur X et recupération informations du display  ***/
/********************************************************************/    
@ retourne dans r0 le pointeur vers le Display
@ retourne dans r1 le pointeur vers l'écran 
ConnexionServeur:
    push {fp,lr}                     @ save des  2 registres
    mov r0,#0
    bl XOpenDisplay                  @ ouverture du serveur X
    cmp r0,#0
    beq 100f                         @ serveur non actif 
    ldr r2,[r0,#Disp_default_screen] @ recup ecran par defaut
    ldr r1,[r0,#Disp_screens]        @ pointeur de la liste des écrans
    add r1,r2,lsl #2                 @ récup du pointeur de l'écran par defaut
100:
    pop {fp,lr}                      @ restaur des registres frame et retour
    bx lr
/********************************************************************/
/*   Chargement des polices utilisées                             ***/
/********************************************************************/    
@ r0 pointeur vers le Display
@ sauvegarde des registres
chargementPolices:
    push {r6,lr}                     @ save des registres
    mov r6,r0                        @ save Display
    ldr r1,iAdrszNomPolice           @ nom de la police 
    bl XLoadQueryFont
    cmp r0,#0
    beq 99f                          @ police non trouvée  
    ldr r1,iAdrptPolice
    str r0,[r1]
    mov r0,r6                        @ Display
    ldr r1,iAdrszNomPolice1          @ nom de la police 
    bl XLoadQueryFont
    cmp r0,#0
    beq 99f                          @ police non trouvée  
    ldr r1,iAdrptPolice1
    str r0,[r1]
    b 100f

99:                                  @ police non trouvée 
    ldr r1,iAdrszMessErrGPolice  
    bl   afficheerreur   
    mov r0,#0
100:
    pop {r6,lr}                      @ restaur des registres
    bx lr                            @ retour procedure
iAdrszNomPolice:      .int szNomPolice
iAdrszNomPolice1:     .int szNomPolice1
iAdrptPolice:         .int ptPolice
iAdrptPolice1:        .int ptPolice1
iAdrszMessErrGPolice: .int szMessErrGPolice
/********************************************************************/
/*   Chargement des polices utilisées                             ***/
/********************************************************************/    
@ r0 pointeur vers le Display
@ r1 pointeur vers l'écran
@ sauvegarde des registres
chargementCouleurs:
    push {r6-r8,lr}                @ save des registres
    mov r6,r0                      @ save Display
    mov r7,r1                      @ save ecran
    /* chargement couleurs */
    mov r0,r6
    mov r1,#0
    bl XDefaultColormap
    cmp r0,#0
    beq 2f
    mov r8,r0                      @ save colormap
    mov r1,r0                      @ pointeur colormap
    mov r0,r6                      @ display
    ldr r2,iAdrszRouge
    ldr r3,iAdrExact
    mov r4,#0
    push {r4}
    ldr r4,iAdrClosest
    push {r4}
    bl XAllocNamedColor
    add sp,#8                      @ remise à  niveau pile car 2 push
    cmp r0,#0
    beq 2f
    ldr r0,iAdrClosest
    ldr r0,[r0,#XColor_pixel]
    mov r1,r8                      @ pointeur colormap
    mov r0,r6                      @ display
    ldr r2,iAdrszBlack             @ couleur noir
    ldr r3,iAdrExact
    mov r4,#0
    push {r4}
    ldr r4,iAdrFront
    push {r4}
    bl XAllocNamedColor
    add sp,#8                      @ remise à  niveau pile car 2 push
    cmp r0,#0
    beq 2f
    mov r1,r8                      @ pointeur colormap
    mov r0,r6                      @ display
    ldr r2,iAdrszWhite             @ couleur blanc
    ldr r3,iAdrExact
    mov r4,#0
    push {r4}
    ldr r4,iAdrBacking
    push {r4}
    bl XAllocNamedColor
    add sp,#8                      @ remise à  niveau pile car 2 push
    cmp r0,#0
    beq 2f

    b 100f
2:                                 @ pb couleur 
    ldr r1,iAdrszMessErreurX11 
    bl   afficheerreur   
    mov r0,#0                      @ code erreur
100:
    pop {r6-r8,lr}                 @ restaur des registres
    bx lr                          @ retour procedure
iAdrszRouge:  .int  szRouge
iAdrszBlack:  .int szBlack
iAdrszWhite:  .int szWhite
iAdrClosest:  .int Closest
iAdrExact:    .int Exact
iAdrBacking:  .int Backing
iAdrFront:    .int Front
/********************************************************************/
/*   Creation de la fenêtre  principale                                   ***/
/********************************************************************/
/* r0 contient le Display */
/* r1 le pointeur écran */
/* r2 le poniteur structure fenêtre */
/* sauvegarde des registres   */
creationFenetrePrincipale:
    push {r4-r9,lr}                       @ save des registres
    mov r6,r0                             @ save du Display
    mov r7,r1                             @ save de l'écran
    mov r5,r2                             @ save de la structure
                                          @ calcul de la position X pour centrer la fenetre
    ldr r2,[r7,#Screen_width]             @ récupération de la largeur de l'écran racine
    sub r2,#LARGEUR                       @ soustraction de la largeur de notre fenêtre
    lsr r2,#1                             @ division par 2 et résultat pour le parametre 3
    ldr r3,[r7,#Screen_height]            @ récupération de la hauteur de l'écran racine
    sub r3,#HAUTEUR                       @ soustraction de la hauteur de notre fenêtre
    lsr r3,#1                             @ division par 2 et résultat pour le parametre 4
    
    /* CREATION DE LA FENETRE */
    mov r0,r6                             @ display
    ldr r1,[r7,#Screen_root]              @ identification écran racine
                                          @ r2 et r3 ont été calculés plus haut
    mov r4,#0                             @ alignement pile
    push {r4}
    ldr r4,iAdrClosest
    ldr r4,[r4,#XColor_pixel]
    //ldr r4,iGris1                       @ couleur du fond
    push {r4}
    ldr r4,[r7,#Screen_black_pixel]       @ couleur bordure
    push {r4}
    mov r4,#3                             @ bordure
    push {r4}
    mov r4,#HAUTEUR                       @ hauteur
    push {r4}
    mov r4,#LARGEUR                       @ largeur 
    push {r4}   
    bl XCreateSimpleWindow
    add sp,#24                            @ remise à  niveau pile car 6 push
    cmp r0,#0
    beq 98f
    mov r9,r0                             @ stockage adresse fenetre dans le registre r9 pour usage ci dessous
    str r0,[r5,#Win_id]                   @ et dans la structure

    /* ajout directives pour le serveur */
    mov r0,r6                             @ display
    mov r1,r9                             @ adresse fenêtre
    ldr r2,iAdrstAttrSize                 @ structure des attributs 
    ldr r3,atribmask                      @ masque des attributs
    str r3,[r2,#XSize_flags]
    bl XSetWMNormalHints
    /* ajout directives pour etat de la fenêtre */
    ldr r2,iAdrstWmHints                  @ structure des attributs 
    mov r3,#NormalState                   @ etat normal pour la fenêtre
    str r3,[r2,#Hints_initial_state]
    mov r3,#StateHint                     @ etat initial
    str r3,[r2,#Hints_flags]
    mov r0,r6                             @ adresse du display 
    mov r1,r9                             @ adresse fenetre 
    bl XSetWMHints
    
        /* ajout de proprietes de la fenêtre */
    mov r0,r6                             @ adresse du display 
    mov r1,r9                             @ adresse fenetre 
    ldr r2,iAdrszNomFenetre               @ titre de la fenêtre 
    ldr r3,iAdrszTitreFenRed              @ titre de la fenêtre reduite 
    mov r4,#0
    push {r4}                             @ pointeur vers XSizeHints éventuellement
    push {r4}                             @ nombre d'aguments ligne de commande 
    push {r4}                             @ adresse arguments de la ligne de commande
    push {r4}
    bl XSetStandardProperties
    add sp,sp,#16                         @ pour les 4 push

    /* Correction erreur fermeture fenetre */
    mov r0,r6                             @ adresse du display
    ldr r1,iAdrszLibDW                    @ adresse nom de l'atome
    mov r2,#1                             @ False  création de l'atome s'il n'existe pas
    bl XInternAtom
    cmp r0,#0
    ble 99f
    ldr r1,iAdrwmDeleteMessage            @ adresse de reception
    str r0,[r1]
    mov r2,r1                             @ adresse zone retour precedente
    mov r0,r6                             @ adresse du display
    mov r1,r9                             @ adresse fenetre
    mov r3,#1                             @ nombre de protocoles 
    bl XSetWMProtocols
    cmp r0,#0
    ble 99f
    
    /* affichage de la fenetre */
    mov r0,r6                             @ adresse du display
    mov r1,r9                             @ adresse fenetre
    bl XMapWindow
    
    /* autorisation des saisies */
    mov r0,r6                             @ adresse du display
    mov r1,r9                             @ adresse de la fenetre
    ldr r2,iFenetreMask                   @ masque pour autoriser saisies
    bl XSelectInput
    cmp r0,#0
    ble 99f
    /* chargement des donnees dans la structure */
    mov r0,r6                             @ adresse du display
    mov r1,r9                             @ adresse de la fenetre
    mov r2,r5
    bl XGetWindowAttributes
    cmp r0,#0
    ble 99f
    @ pas d'erreur

    ldr r0,iAdrevtFenetrePrincipale
    str r0,[r5,#Win_procedure]
    mov r0,r9                              @ retourne l'identification de la fenetre
    b 100f
    
98:  @ erreur fenetre 
    ldr r1,iAdrszMessErrfen   
    bl   afficheerreur  
    mov r0,#0                              @ code erreur 
    b 100f
99:    @ erreur X11
    ldr r1,iAdrszMessErreurX11  
    bl   afficheerreur  
    mov r0,#0                              @ code erreur 
    b 100f

100:
    pop {r4-r9,lr}                         @ restaur des registres
    bx lr                                  @ retour procedure
iFenetreMask:             .int  KeyPressMask|ButtonPressMask|StructureNotifyMask|ExposureMask|EnterWindowMask
iGris1:                   .int 0xFFA0A0A0
iAdrhauteur:              .int hauteur
iAdrlargeur:              .int largeur
iAdrszNomFenetre:         .int  szNomFenetre
iAdrszTitreFenRed:        .int szTitreFenRed
iAdrszMessErreurX11:      .int szMessErreurX11
iAdrszMessErrfen:         .int szMessErrfen
iAdrszLibDW:              .int szLibDW
iAdrwmDeleteMessage:      .int wmDeleteMessage
iAdrstAttrSize:           .int stAttrSize
atribmask:                .int USPosition | USSize
iAdrstWmHints :           .int stWmHints 
iAdrevtFenetrePrincipale: .int evtFenetrePrincipale

/********************************************************************/
/*   Création contexte graphique                                  ***/
/********************************************************************/    
/* r0 contient le display, r1 la fenêtre r2 l 'ecran*/
creationGC:
    push {r4-r7,lr}          @ save des registres
    /* creation contexte graphique simple */
    mov r6,r0                @ save adresse du display
    mov r5,r1                @ adresse fenetre
    mov r7,r2
    mov r2,#0
    mov r3,#0
    bl XCreateGC
    cmp r0,#0
    beq 99f    
    ldr r1,iAdrptGC
    str r0,[r1]              @ stockage adresse contexte graphique   
    mov r8,r0                @ et stockage dans r8
    mov r0,r6                @ adresse du display 
    mov r1,r8                @ adresse GC 
    ldr r2,[r7,#Screen_white_pixel]
    bl XSetForeground
    cmp r0,#0
    beq 99f    
    mov r0,r6                @ adresse du display 
    mov r1,r8                @ adresse GC 
    ldr r2,[r7,#Screen_black_pixel]
    bl XSetBackground
    cmp r0,#0
    beq 99f    

    /* création contexte graphique avec autre couleur de fond */
    mov r0,r6                 @ adresse du display 
    mov r1,r5                 @ adresse fenetre 
    mov r2,#0
    mov r3,#0
    bl XCreateGC
    cmp r0,#0
    beq 99f
    ldr r1,iAdrptGC1
    str r0,[r1]                 @ stockage adresse contexte graphique dans zone gc2 
    mov r1,r0                   @ adresse du nouveau GC
    mov r0,r6                   @ adresse du display 
    ldr r2,iAdrClosest
    ldr r2,[r2,#XColor_pixel]   @ fond rouge identique à la fenêtre principale
    bl XSetBackground
    cmp r0,#0
    beq 99f    
    mov r0,r6                   @ adresse du display 
    ldr r1,iAdrptGC1
    ldr r1,[r1]                 @ stockage adresse contexte graphique dans zone gc2 
    ldr r2,[r7,#Screen_white_pixel]
    bl XSetForeground
    cmp r0,#0
    beq 99f    
    
    /* creation contexte graphique simple BIS */
    mov r0,r6                   @ adresse du display
    mov r1,r5                   @ adresse fenetre
    mov r2,#0
    mov r3,#0
    bl XCreateGC
    cmp r0,#0
    beq 99f    
    ldr r1,iAdrptGC2
    str r0,[r1]                 @ stockage adresse contexte graphique  
    b 100f

99:                             @ erreur creation contexte graphique
    ldr r1,iAdrszMessErrGc  
    bl   afficheerreur  
    mov r0,#0                   @code erreur
    b 100f
100:
    pop {r4-r7,lr}
    bx lr
iRouge:             .int 0xFFFF0000
iAdrptGC:           .int ptGC
iAdrptGC1:          .int ptGC1
iAdrptGC2:          .int ptGC2
iAdrszMessErrGc:    .int szMessErrGc
iGC1mask:           .int GCFont
iGCmask:            .int GCFont
iAdrstXGCValues:    .int stXGCValues


/********************************************************************/
/*   Creation d 'une fenêtre secondaire                         ***/
/********************************************************************/
/* r0 contient le Display */
/* r1 la fenetre mère */
/* r2 l'ecran */
/* r3 la structure de la fenêtre */
creationFenetreSec1:
    push {r4-r9,lr}                   @ save des registres
    mov r6,r0                         @ save du Display
    mov r7,r2                         @ save de l'écran
    mov r5,r3                         @ save de la structure

    /* CREATION DE LA FENETRE */
    mov r0,r6                         @ display
                                      @ r1 contient l'identification fenêtre mère
    mov r2,#10                        @ position X
    mov r3,#10                        @ position Y 
    mov r4,#0                         @ alignement pile 
    push {r4}
    ldr r4,[r7,#Screen_black_pixel]   @ couleur du fond
    push {r4}
    ldr r4,[r7,#Screen_white_pixel]   @ couleur bordure
    push {r4}
    mov r4,#1                         @ bordure
    push {r4}
    ldr r4,iAdrstImageJPEG
    ldr r4,[r4,#BMP_hauteur]
    push {r4}
    ldr r4,iAdrstImageJPEG
    ldr r4,[r4,#BMP_largeur]
    push {r4}   
    bl XCreateSimpleWindow
    add sp,#24                        @ remise à  niveau pile car 6 push
    cmp r0,#0
    beq 98f
    mov r9,r0                         @ stockage adresse fenetre dans le registre r9 pour usage ci dessous
    str r0,[r5,#Win_id]               @ et dans la structure

    /* affichage de la fenetre */
    mov r0,r6                         @ adresse du display
     mov r1,r9                        @ adresse fenetre locale
    bl XMapWindow

    /* autorisation des saisies */
    mov r0,r6                         @ adresse du display
    mov r1,r9                         @ adresse de la fenetre
    ldr r2,iFenetreMaskS4             @ masque pour autoriser saisies
    bl XSelectInput
    cmp r0,#0
    ble 99f
    /* chargement des donnees dans la structure */
    mov r0,r6                         @ adresse du display
    mov r1,r9                         @ adresse de la fenetre
    mov r2,r5
    bl XGetWindowAttributes
    cmp r0,#0
    ble 99f
1:                                    @ pas d'erreur
    ldr r0,iAdrevtFenetreSec1
    str r0,[r5,#Win_procedure] 

    mov r0,r6
    mov r1,r9                         @ adresse de la fenetre
    ldr r2,iAdrstImageJPEG
    bl affichageImageJPEG

    mov r0,r9                         @ retourne l'identification de la fenetre
   b 100f
98:                                   @ erreur fenetre 
    ldr r1,iAdrszMessErrfen   
    bl   afficheerreur  
    mov r0,#0                         @ code erreur 
    b 100f
99:                                   @ erreur X11
    ldr r1,iAdrszMessErreurX11  
    bl   afficheerreur  
    mov r0,#0                         @ code erreur 
    b 100f

100:
    pop {r4-r9,lr}                    @ restaur des registres
    bx lr                             @ retour procedure
iFenetreMaskS4:      .int  StructureNotifyMask|ExposureMask
iAdrevtFenetreSec1:  .int evtFenetreSec1
/********************************************************************/
/*   Gestion des évenements                                       ***/
/********************************************************************/
@ pas de sauvegarde des registres
gestionEvenements:
    push {fp,lr}                @ save des  2 registres 
    mov r0,r6                   @ adresse du display
    ldr r1,iAdrevent            @ adresse evenements
    bl XNextEvent
    ldr r0,iAdrevent
                                @ Quelle fenêtre est concernée ?
    ldr r0,[r0,#XAny_window]
    ldr r3,iAdrTableFenetres    @ tables des structures des fenêtres
    mov r2,#0                   @ indice de boucle
1:                              @ debut de boucle de recherche de la fenêtre
    mov r4,#Win_fin             @ longueur de chaque structure
    mul r4,r2,r4                @ multiplié par l'indice de boucle
    add r4,r3                   @ et ajouté au début de table 
    ldr r1,[r4,#Win_id]         @ recup ident fenêtre dans table des structures
    cmp r1,#0                   @ fin de la table ?
    moveq r0,#0                 @ on termine la recherche
    beq 100f
    cmp r0,r1                   @ fenetre table = fenetre évenement ?
    addne r2,#1                 @ non
    bne 1b                      @ on boucle
    ldr r2,[r4,#Win_procedure]  @ fenetre trouvée, chargement de la procèdure à executer
    ldr r0,iAdrevent            @ adresse de l'évenement
    cmp r2,#0                   @ vérification si procédure est renseigne avant l'appel
    moveq r0,#0                 @ on termine la recherche
    beq 100f
    blx r2                      @ appel de la procèdure à executer pour la fenêtre
                                @ le code retour dans r0 est positionné dans la routine

100:
    pop {fp,lr}   /*restaur des registres frame et retour */
    bx lr         /* retour procedure */
iAdrevent:         .int event
iAdrTableFenetres: .int TableFenetres
/********************************************************************/
/*   Evenements de la fenêtre principale                          ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ sauvegarde des registres
evtFenetrePrincipale:
    push {fp,lr}                @ save des  2 registres
    ldr r0,[r0,#XAny_type]
    cmp r0,#ClientMessage       @ cas pour fermeture fenetre sans erreur 
    beq fermeture
    cmp r0,#ButtonPress         @ cas d'un bouton souris
    beq evtboutonsouris
    cmp r0,#Expose              @ cas d'une modification de la fenetre ou son masquage
    beq evtexpose
    cmp r0,#ConfigureNotify     @ cas pour modification de la fenetre 
    beq evtconfigure
    cmp r0,#EnterNotify         @ la souris passe sur une fenêtre
    beq evtEnterNotify
    mov r0,#0
    b 100f
/***************************************/    
fermeture:                      @ clic sur menu systeme */
    vidregtit fermeture
    ldr r0,iAdrevent            @ evenement de type XClientMessageEvent
    ldr r1,[r0,#XClient_data]   @ position code message
    ldr r2,iAdrwmDeleteMessage
    ldr r2,[r2]
    cmp r1,r2
    moveq r0,#1
    movne r0,#0
    b 100f
/***************************************/    
evtexpose:                       @ masquage ou modification fenetre
    mov r0,r6                    @ adresse du display

    @ il faut redessiner l'image JPEG

    mov r0,#0
    b 100f
evtconfigure:
    ldr r0,iAdrevent
    ldr r1,[r0,#+XConfigureEvent_width]
    ldr r2,iAdrlargeur
    ldr r3,[r2]
    cmp r1,r3                    @ modification de la largeur ?
    beq evtConfigure1
    str r1,[r2]                  @ maj nouvelle largeur
evtConfigure1:
    mov r0,#0
    b 100f
evtEnterNotify:
    mov r0,r6                    @ adresse du display 

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
/*   Evenements de la fenêtre secondaire                          ***/
/********************************************************************/
@ r0 doit contenir le pointeur sur l'evenement
@ r1 doit contenir l'identification de la fenêtre
@ sauvegarde des registres
evtFenetreSec1:
    push {fp,lr}            @ save des  2 registres 
    ldr r0,iAdrevent
    ldr r0,[r0,#XAny_type]
    cmp r0,#Expose          @ cas d'une modification de la fenetre ou son masquage
    bne 2f
    mov r0,r6
    ldr r2,iAdrstImageJPEG
    bl affichageImageJPEG
2:
    mov r0,#0
100:
    pop {fp,lr}
    bx lr

/******************************************************************/
/*     Chargement d'une image JPEG                                */ 
/******************************************************************/
/* r0 contient l'addresse du nom du fichier à charger             */
chargeImageJpeg:
    push {r1-r10,fp,lr}                         @ save  registres
    vidmemtit debut r0 2
    @ ouverture fichier en utilisant fonction fopen
    ldr r1,iAdrszModeOpen                       @ mode
    bl fopen
    cmp r0,#0
    ble 99f
    mov r8,r0                                   @ File Descriptor
    ldr r0,iAdrmy_error_exit                    @ adresse de la routine d'erreur
    ldr r1,iAdrmy_error_mgr                     @ adresse structure erreur 
    str r0,[r1,#jpeg_error_error_exit]
    ldr r0,iAdrmy_error_mgr
    bl jpeg_std_error                           @ création structure erreur
    ldr r1,iAdrcinfo
    str r0,[r1]
    //str r0,[r1,#12]                           @ inutile à verifier

    ldr r0,iAdrcinfo
    mov r1,#JPEG_LIB_VERSION
    mov r2,#jpeg_decompress_fin                 @ taille de la structure de décompression
    bl jpeg_CreateDecompress                    @ init décompression
    ldr r0,iAdrcinfo
    mov r1,r8
    bl jpeg_stdio_src                           @ indique le fichier source

    ldr r0,iAdrcinfo
    mov r1,#1                                   @ TRUE
    bl jpeg_read_header                         @ lecture de l'entête du fichier image 
    ldr r0,iAdrcinfo
    ldr r10,[r0,#jpeg_decompress_image_width]   @ largeur
    ldr r6,[r0,#jpeg_decompress_image_height]   @ hauteur
    ldr r3,[r0,#jpeg_decompress_num_components] @ nombre d'octets par pixel
    cmp r3,#3                                   @ codage image sur 24 bits ?
    bne 99f                                     @ sinon erreur
    ldr r5,iAdrstImageJPEG
    str r10,[r5,#JPEG_largeur]
    str r6,[r5,#JPEG_hauteur]
    @ allocation de la place pour le buffer image: L * H * 4 octets
    mul r0,r10,r6
    lsl r0,#2
    bl allocPlace                               @ demande allocation sur le tas
    cmp r0,#-1
    beq 99f
    ldr r1,iAdrBufferTas                        @ ok stockage adresse debut buffer
    str r0,[r1]
    mul r7,r10,r3                               @ calcul de la taille d'une ligne du buffer lecture
    ldr r0,iAdrcinfo
    bl jpeg_start_decompress                    @ debut de la decompression Jpeg
    ldr r0,iAdrcinfo
    vidmemtit affcinfo r0 20
    @ creation buffer pour la reception de chaque ligne de l'image
    ldr r0,iAdrcinfo
    ldr r5,[r0,#jpeg_decompress_mem]            @ recup de l'adresse de la structure mem
    ldr r4,[r5,#8]                              @ recup de l'adresse de la fonction alloc_sarray 
    ldr r0,iAdrcinfo
    mov r1,#JPOOL_IMAGE
    mov r2,r7                                   @ taille de la ligne calculée plus haut
    mov r3,#1
    blx r4                                      @ demande de création du buffer 
    mov r9,r0                                   @ stockage de l'adresse qui contiendra l'adresse buffer dans r9
2:                                              @ debut de boucle de récuperation de chaque ligne
    ldr r0,iAdrcinfo
    mov r1,r9
    mov r2,#1
    bl jpeg_read_scanlines                      @ lecture d'une ligne de l'image

    ldr r0,iAdrcinfo 
    ldr r2,[r0,#140]                            @ récupération du compteur de lignes
    ldr r0,[r9]                                 @ récupération adresse buffer ligne
    mov r1,r10                                  @ r1 contient la largeur en pixel
    bl traitementLigneJpeg                      @ conversion ligne en code RGB 32 bits
    cmp r2,r6                                   @ nombre de lignes >= hauteur de l'image ? 
    blt 2b                                      @ non -> boucle autre ligne

    ldr r0,iAdrcinfo
    bl jpeg_finish_decompress                   @ fin de la decompression
    vidregtit fin
    ldr r0,iAdrcinfo
    bl jpeg_destroy_decompress                  @ libération ressources 
    ldr r0,iAdrstImageJPEG
    ldr r2,iAdrBufferTas                        @ alimentation structure JPEG
    ldr r2,[r2]                                 @ avec l'adresse début image
    str r2,[r0,#JPEG_debut_pixel]

    mov r0,r8
    bl fclose                                   @ @ fermeture du fichier image Jpeg
    mov r0,#0                                   @ tout est OK
    b 100f
99:                                             @ error
    ldr r1,iAdrszMessErreur                     @ error message
    bl   afficheerreur
    mov r0,#-1
100:
    pop {r1-r10,fp,lr}                          @ restaur registers 
    bx lr                                       @return

iAdrszModeOpen:                 .int szModeOpen
iAdrcinfo:                      .int cinfo
iAdrmy_error_exit:              .int my_error_exit
iAdrmy_error_mgr:               .int my_error_mgr
iAdrBufferTas:                  .int iBufferTas
/****************************************/
/* TODO gestion des erreurs             */
/****************************************/
my_error_exit:
    vidregtit erreur_exit
    bkpt
/********************************************************/
/*   création de l'image complète à partir des lignes   */
/*   les lignes lues comportent 3 octets par pixel      */
/*   et les lignes de l'image à afficher 4 octets       */ 
/********************************************************/
/* r0 pointeur vers buffer ligne */
/* r2 compteur ligne             */
/* r1 largeur ligne en pixel     */
traitementLigneJpeg:
    push {r1-r7,lr}           @ save des  2 registres fp et retour 
    ldr r4,iAdrBufferTas
    ldr r4,[r4]
    sub r2,#1                 @ le compteur est en avance de 1 
    mul r3,r1,r2
    lsl r3,#2
    add r2,r4,r3              @ debut nouvelle ligne
    mov r4,#0
    mov r6,#0
    mov r7,#0
    //vidregtit trtligne
1:
    add r4,#2
    ldrb r5,[r0,r4]          @ lecture d'un octet dans le buffer de lecture   vert
    strb r5,[r2,r6]          @ stockage de l'octet dans le buffer image
    sub r4,#1                @ maj des compteurs 
    add r6,#1
    ldrb r5,[r0,r4]          @ stockage du 2ième octet   bleu
    strb r5,[r2,r6]
    sub r4,#1
    add r6,#1
    ldrb r5,[r0,r4]          @ stockage du 3ième octet  rouge
    strb r5,[r2,r6]
    add r4,#3
    add r6,#1
    mov r5,#0
    strb r5,[r2,r6]          @ et on stocke 0 pour completer l'affichage en 32 bits
    add r6,#1
    add r7,#1
    cmp r7,r1                @ Nombre de pixel d'une ligne image atteint ?
    blt 1b                   @ non on boucle

100:                         @ fin standard de la fonction
       pop {r1-r7,lr}           @ restaur des registres
    bx lr                    @ retour de la fonction en utilisant lr
/***************************************************/
/*   Création de de XImage à partir buffer image JPEG  */
/***************************************************/
/* r0 pointeur vers display */
/* r1 pointeur ecran  */
/* r2 pointeur vers structure image */
/* r0 retourne le pointeur vers l'image crée */
creationImageX11JPEG:
    push {r4-r7,lr}                   @ save des registres
    mov r7,r1                         @ save ecran
    mov r6,r2                         @ save structure
    ldr r1,[r7,#Screen_root_visual]   @ visual defaut
    ldr r2,[r7,#Screen_root_depth]    @ Nombre de bits par pixel
    mov r3,#ZPixmap
    mov r4,#0                         @ nombre de bytes par lines 
    push {r4}
    mov r4,#8                         @ nombre de bit de décalage !!!!!!!! à revoir
    push {r4}
    ldr r4,[r6,#JPEG_hauteur]
    push {r4}
    ldr r4,[r6,#JPEG_largeur]
    push {r4} 
    ldr r4,[r6,#JPEG_debut_pixel]
    push {r4}                        @ adresse image BMP
    mov r4,#0                        @ offset debut image
    push {r4}
    bl XCreateImage
    add sp,#24                       @ remise à  niveau pile car 6 push
    str r0,[r6,#JPEG_imageX11]       @ maj adresse image X11 dans structure
100:
    pop {r4-r7,lr}                   @ restaur des registres
    bx lr                            @ retour de la fonction en utilisant lr
/***************************************************/
/*   Affichage de XImage dans fenetre        */
/***************************************************/
/* r0 pointeur vers display */
/* r1 pointeur fenêtre  */
/* r2 pointeur vers structure image */
affichageImageJPEG:
    push {r4-r5,lr}                @ save des registres 
    mov r5,r2                      @ save structure
    ldr r2,iAdrptGC                @ contexte graphique 
    ldr r2,[r2]
    ldr r3,[r5,#JPEG_imageX11]     @ adresse de l'image
    ldr r4,[r5,#JPEG_hauteur]
    push {r4}
    ldr r4,[r5,#JPEG_largeur]
    push {r4} 
    mov r4,#0                      @ position Y de l'image dans la destination
    push {r4}
    mov r4,#0                      @ position X de l'image dans la destination
    push {r4}
    mov r4,#0                      @ position Y de l'image dans la source
    push {r4}
    mov r4,#0                      @ position X de l'image dans la source
    push {r4}
    bl XPutImage
    add sp,sp,#24                  @ pour les 6 push 

100:                               @ fin standard de la fonction
    pop {r4-r5,lr}                 @ restaur des registres
    bx lr                          @ retour de la fonction en utilisant lr
/*********************************************************************/
/* constantes Générales              */
.include "../../asm/constantesARM.inc"
