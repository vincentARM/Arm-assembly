/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* modèle B 512MO   */
/*  */
/* variable environnement  */
/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/
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
szVarRech:           .asciz  "USER="
                     .equ LGVARRECH,  . - szVarRech  - 1 @ car zero final
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
    mov fp,sp                   @ recup adresse pile
    ldr r0,iAdrszMessDebutPgm   @ r0 ← adresse message debut 
    bl affichageMess            @ affichage message dans console 
    ldr r0,[fp]                 @ nombre param
    ldr r1,[fp,#4]              @ param 1 = nom du programme
    ldr r2,[fp,#8]              @ adresse retour = 0
    ldr r3,[fp,#12]             @ adresse de la première variable envronnement
    ldr r4,[fp,#16]             @ adresse 2ieme 
    ldr r5,[fp,#-4]             @ contient l'adresse de retour de affichageMess précédent
    vidregtit contenu_pile
    ldr r0,[fp,#4]              @ affiche le nom du programme
    bl affichageMess
    ldr r0,iAdrszRetourligne
    bl affichageMess
    mov r1,#3
1:                              @ boucle d'affichage des variables
    ldr r0,[fp,r1,lsl #2]
    cmp r0,#0
    beq 2f
    bl affichageMess  
    ldr r0,iAdrszRetourligne
    bl affichageMess 
    add r1,#1
    b 1b
2:
    add r2,r1,#1                 @ autre chose ?
    ldr r3,[fp,r2,lsl #2]
    add r2,r2,#1
    ldr r4,[fp,r2,lsl #2]
    add r2,r2,#1
    ldr r5,[fp,r2,lsl #2]
    vidregtit fin_variables
    ldr r4,=.text
    ldr r1,=.data
    ldr r2,=.bss
    ldr r3,=__bss_end__
    vidregtit section
                                @ recherche variable
    ldr r2,[fp]                 @ nombre param
    add r2,r2,#2
    ldr r1,iAdrszVarRech
3:
    ldr r0,[fp,r2,lsl #2]
    cmp r0,#0
    beq 4f
    mov r4,r0
    bl searchSubString
    cmp r0,#-1
    addeq r2,#1
    beq 3b
    add r0,r4,#LGVARRECH
    bl affichageMess            @ affichage message dans console 
    ldr r0,iAdrszRetourligne
    bl affichageMess 
    
4:
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
    svc 0 
/************************************/
iAdrszMessDebutPgm:     .int szMessDebutPgm
iAdrszMessErreur:       .int szMessErreur
iAdrszMessFinOK:        .int szMessFinOK
iAdrZoneBlanc:          .int iAdrZoneBlanc
iAdrszRetourligne:      .int szRetourligne
iAdrszVarRech:          .int szVarRech
/******************************************************************/
/*   search a substring in the string                            */ 
/******************************************************************/
/* r0 contains the address of the input string */
/* r1 contains the address of substring */
/* r0 returns index of substring in string or -1 if not found */
searchSubString:
    push {r1-r6,lr}                       @ save registers 
    mov r2,#0                             @ counter byte input string
    mov r3,#0                             @ counter byte string 
    mov r6,#-1                            @ index found
    ldrb r4,[r1,r3]
1:
    ldrb r5,[r0,r2]                       @ load byte string 
    cmp r5,#0                             @ zero final ?
    moveq r0,#-1                          @ yes returns error
    beq 100f
    cmp r5,r4                             @ compare character 
    beq 2f
    mov r6,#-1                            @ no equals - > raz index 
    mov r3,#0                             @ and raz counter byte
    add r2,#1                             @ and increment counter byte
    b 1b                                  @ and loop
2:                                        @ characters equals
    cmp r6,#-1                            @ first characters equals ?
    moveq r6,r2                           @ yes -> index begin in r6
    add r3,#1                             @ increment counter substring
    ldrb r4,[r1,r3]                       @ and load next byte
    cmp r4,#0                             @ zero final ?
    beq 3f                                @ yes -> end search
    add r2,#1                             @ else increment counter string
    b 1b                                  @ and loop
3:
    mov r0,r6
100:
    pop {r1-r6,lr}                        @ restaur registers
    bx lr   
/********************************************************************/
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
