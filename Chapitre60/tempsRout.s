/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* modèle B 512MO   */
/*  */
/* Chonometrage de sous routines à l'aide du timer  */
/* Utilisation du driver bcm2708_usec    */

/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/
.equ  TAILLECPT,     4     @ taille en octet du compteur du TIMER
.equ  NBBOUCLES,      1000000
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessDebutPgm:     .asciz "Début du programme. \n"
szMessErreur:       .asciz "Erreur rencontrée.\n"
szMessFinOK:        .asciz "Fin normale du programme. \n"
szMessTemps:        .ascii "Valeur Timer : "
sMessValeur:        .fill  11,1,' '
szRetourligne: 	    .asciz  "\n"

szNomDriver:        .asciz "/dev/bcm2708_usec"

.align 4

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
iTemps1:         .skip TAILLECPT
iTemps2:         .skip TAILLECPT


/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text            
.global main                       @ 'main' point d'entrée doit être  global 

main:                              @ programme principal 
    ldr r0,iAdrszMessDebutPgm      @ r0 ← adresse message debut 
    bl affichageMess               @ affichage message dans console   
    /* ouverture du driver */
    ldr r0,iAdrszNomDriver         @
    mov r1,#O_RDONLY               @ flag
    mov r2,#0                      @ mode
    mov r7,#OPEN                   @ appel fonction systeme pour ouvrir 
    swi #0 
    cmp r0,#0                      @ erreur ?
    ble 99f
    mov r8,r0                      @ save du Fd
    @ test d'une routine vide
    affichelib vide
    adr r1,vide
    bl chrono

    @ test manip registre
    affichelib registres
    mov r0,r8
    adr r1,move
    bl chrono

    @ test load
    affichelib load
    mov r0,r8
    adr r1,charge
    bl chrono

    @ test d'une routine vide
    affichelib vide
    mov r0,r8
    adr r1,vide
    bl chrono

    mov r0,r8
    mov r7,#CLOSE               @ fermeture driver
    svc 0 
    cmp r0,#0                   @ erreur ?
    blt 99f

    ldr r0,iAdrszMessFinOK      @ r0 ← adresse chaine 
    bl affichageMess            @ affichage message dans console 
    mov r0,#0                   @ code retour OK 
    b 100f
99:                             @ affichage erreur 
    ldr r1,iAdrszMessErreur     @ r0 <- code erreur, r1 <- adresse chaine 
    bl   afficheerreur          @ appel affichage message
    mov r0,#1                   @ code erreur 
    b 100f
100:                            @ fin de programme standard  
    mov r7, #EXIT               @ appel fonction systeme pour terminer 
    swi 0 
/************************************/
iAdrszMessDebutPgm:     .int szMessDebutPgm
iAdrszMessErreur:       .int szMessErreur
iAdrszMessFinOK:        .int szMessFinOK
iAdrszNomDriver:        .int szNomDriver

/*********************************************/
/*   mesure du temps                       */
/********************************************/
/* r0 contient le FD                           */
/* r1 contient l'adresse de la routine à tester */
chrono:
    push {r1-r9,lr}
    mov r3,r0
    mov r4,r1
    mov r8,#0                      @ compteur de mesure
    mov r9,#0                      @ total pour calcul moyenne
    ldr r6,iNbBoucles
1:                                 @ debut d'une mesure
    mov r5,#0                      @ raz compteur de boucles
    mov r0,r3
    ldr r1,iAdriTemps1
    mov r2,#TAILLECPT
    mov r7,#READ                   @ lecture compteur timer
    svc 0 
//    cmp r0,#0                      @ erreur lecture
//    ble 99f

2:
    blx r4
    add r5,#1
    cmp r5,r6
    blt 2b
    @ fin
    mov r0,r3
    ldr r1,iAdriTemps2
    mov r2,#TAILLECPT
    mov r7,#READ                 @ lecture compteur timer
    svc 0 
    cmp r0,#0                    @ erreur
    ble 99f
/* calcul du nombre de micro secondes du Timer */
    ldr r0,iAdriTemps2
    ldr r0,[r0]
    ldr r1,iAdriTemps1
    ldr r1,[r1]
    cmp r1,r0
    subls r0,r1                 @ si T1>T1 calcul de T2 - T1
    mvnhi r0,r0                 @ sinon calcul de T2 + (2 ^32 - T1)
    addhi r0,r1
    add r9,r0                   @ ajout au total
    ldr r1,iAdrsMessValeur
    bl conversion10
    ldr r0,iAdrszMessTemps
    bl affichageMess
    add r8,#1
    cmp r8,#8
    blt 1b
    lsr r0,r9,#3                @ division par 8
    affichelib Moyenne:
    ldr r1,iAdrsMessValeur      @ affichage de la myenne des 8 essais
    bl conversion10
    ldr r0,iAdrszMessTemps
    bl affichageMess
    mov r0,#0                   @ ok
    b 100f
99:                             @ affichage erreur 
    ldr r1,iAdrszMessErreur     @ r0 <- code erreur, r1 <- adresse chaine 
    bl   afficheerreur          @ appel affichage message
    mov r0,#1                   @ code erreur 
    b 100f
100:
    pop {r1-r9,lr}
    bx lr
iAdriTemps1:                .int iTemps1
iAdriTemps2:                .int iTemps2
iNbBoucles:                 .int NBBOUCLES
iAdrsMessValeur:            .int sMessValeur
iAdrszMessTemps:            .int szMessTemps

/*********************************************/
/*  test procedure vide                      */
/********************************************/
vide:
    bx lr

/*********************************************/
/*  test procedure mov registres                    */
/********************************************/
move:

    mov r0,#0
    mov r1,r0
    bx lr

/*********************************************/
/*  test procedure load registres                    */
/********************************************/
charge:
    //push {lr}
    ldr r0,iAdriTemps1
    ldr r1,[r0]
    mov r0,r1
    //pop {lr}
    bx lr
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
