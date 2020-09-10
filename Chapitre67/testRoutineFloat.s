/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* modèle B 512MO   */
/*  */
/* verification affichage tous registres  */
/* commentaire */ 
/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/
.equ N, 10   
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessDebutPgm:      .asciz "Début du programme. \n"
szMessErreur:        .asciz "Erreur rencontrée.\n"
szMessFinOK:         .asciz "Fin normale du programme. \n"
sMessResult:         .ascii " "
sMessValeur:         .fill 11, 1, ' '            @ taille => 11
szRetourligne:       .asciz  "\n"
szTestZoneMemoire:   .asciz "12345678"
.equ longueur, . - szTestZoneMemoire   @ calcul de la longueur de la zone precedente 

szMessChaine:        .asciz  "Test affichage d'une chaine \n"
.equ LGMESSCHAINE, . -  szMessChaine /* calcul de la longueur de la zone precedente */

.align 4
qfValeur1:          .double 0F123456

.include "TableOriginePuis10.inc"
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4

sBuffer:    .skip 500 

/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text            
.global main                    @ 'main' point d'entrée doit être  global 

main:                           @ programme principal 
    push {fp,lr}                @ save des  registres 
    ldr r0,iAdrszMessDebutPgm   @ r0 ← adresse message debut 
    bl affichageMess            @ affichage message dans console   
    /*  Exemple d'affichage memoire  */
    //ldr r0,iAdrZoneBlanc
    //vidmemtit zonedatas r0 2
    mov r4,#0
    ldr r5,iAdrTableOrigine
    ldr r1,iAdrqfValeur1
1:
    add  r3,r5,r4,lsl#3
    vldr d0,[r3]
    vldr d1,[r1]
    vadd.f64 d0,d0,d1
    ldr r0,iAdrsBuffer
    bl convertirFloat
    ldr r0,iAdrsBuffer
    bl affichageMess 
    ldr r0,iAdrszRetourligne
    bl affichageMess 
    add r4,#1
    mov r3,#616
    add r3,#1
    cmp r4,r3
    blt 1b
    
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
    pop {fp,lr}                 @ restaur des  registres 
    mov r7, #EXIT               @ appel fonction systeme pour terminer 
    svc 0 
    
/************************************/

iAdrszMessDebutPgm:     .int szMessDebutPgm
iAdrszMessErreur:       .int szMessErreur
iAdrszMessFinOK:        .int szMessFinOK
iAdrsBuffer:            .int sBuffer
iAdrszRetourligne:       .int szRetourligne
iAdrqfValeur1:           .int qfValeur1
iAdrTableOrigine:        .int TableOriginePuis10
/********************************************************************/
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
