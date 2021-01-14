/* ARM assembleur Android termux ou raspberry pi 32 bits */
/*  program verifTas32.s   */
/* test avec objet routinesARM2021 */

.equ TAILLETAS,   0x1000
.global TAILLETAS
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"

/**************************************/
/* Données initialisées               */
/**************************************/
.data
szMessage:      .asciz "Pgm1 : Bonjour le monde. \n"       @ message

ptZoneTas:          .int heap_begin
/**************************************/
/* Code du programme                  */
/**************************************/
.text
.global main 
main:
    ldr r0,iAdrszMessage         @ adresse du message 
    bl affichageMess             @ appel fonction d'affichage
    
    ldr r1,iAdrptZoneTas
    ldr r0,[r1]
    vidregtit debut
    mov r1,#0xFF
    str r1,[r0]
    vidmemtit debut1 r0 4
    mov r0,#8
    bl allocPlace
    vidregtit retourTas
    vidmemtit debut1 r0 4
    mov r0,#1024
    lsl r0,#4
    bl reserverPlaceInt
    vidregtit retourTas2
    
    mov r0,#1024
    bl reserverPlace
    vidregtit retourTas3
    mov r3,r0
    bl libererPlace
    mov r0,#100
    bl reserverPlace
    vidregtit retourTas4
    
                                 @ fin du programme
    mov r0, #0                   @ code retour OK
    mov r7, #1                   @ code fin LINUX 
    svc 0                        @ appel système LINUX

iAdrszMessage: .int szMessage

/***************************************************/
/*   reserver place sur le tas                              */
/***************************************************/
// r0 contient la place à réserver 
// r0 retourne l'adresse de début de la place réservée
reserverPlaceInt:           @ INFO: reserverPlace
    push {r1,r2,r3,lr}      @ save des registres
    mov r1,r0
    tst r1,#0b11          @ la place est un multiple de 4
    beq 1f               @ oui
    and r1,#0xFFFFFFFC    @ sinon ajustement à un multiple de 4 superieur
    add r1,#4
1:
    ldr r2,iAdrptZoneTas
    ldr r0,[r2]
    add r1,r1,r0         @ attention pas de vérification de dépassement
    ldr r3,iAdrFinTas
    cmp r1,r3
    blt 2f
    adr r0,szMessErrTas
    bl affichageMess
    mov r0,#-1
    b 100f
2:
    str r1,[r2]
   // vidregtit tas
100:                      @ fin standard de la fonction
    pop {r1,r2,r3,lr}        @ restaur des registres
    bx lr                 @ retour de la fonction en utilisant lr
iAdrptZoneTas:       .int ptZoneTas
iAdrFinTas:          .int heap_end
szMessErrTas:        .asciz "Erreur : tas trop petit !!!\n"
.align 4
