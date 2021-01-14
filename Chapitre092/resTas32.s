/* ARM assembleur   32 bits */
/*  program restas32.s   */

/* gestion d'un tas dans chaine bss */
/*******************************************/
/* Constantes                       */
/********************************************/

.equ TAILLETAS,         10000

/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"

/**************************************/
/* Donn�es initialis�es               */
/**************************************/
.data
szMessage:      .asciz "D�but du programme. \n"       @ message

ptZoneTas:          .int ZoneTas
ptZoneFinBss:       .int __bss_end__
/**************************************/
/* Donn�es non initialis�es           */
/**************************************/
.bss
.align 4
ZoneTas:          .skip TAILLETAS
FinZoneTas:
/**************************************/
/* Code du programme                  */
/**************************************/
.text
.global main 
main:
    ldr r0,iAdrszMessage         @ adresse du message 
    bl affichageMess             @ appel fonction d'affichage
    
    ldr r0,iAdrptZoneFinBss
    ldr r0,[r0]
    mov r1,#0xFF
    str r1,[r0]
    vidmemtit finBss r0 4

    mov r0,#8
    bl allocPlace               @ ancienne allocation 
    vidregtit retourTas
    mov r0,#1024
    bl reserverPlace
    vidregtit retourTas2
    
    mov r0,#100
    bl reserverPlace
    vidregtit retourTas3

    
                                 @ fin du programme
    mov r0, #0                   @ code retour OK
    mov r7, #1                   @ code fin LINUX 
    svc 0                        @ appel syst�me LINUX

iAdrszMessage:      .int szMessage
iAdrptZoneFinBss:   .int ptZoneFinBss
/***************************************************/
/*   reserver place sur le tas                              */
/***************************************************/
// r0 contient la place � r�server 
// r0 retourne l'adresse de d�but de la place r�serv�e
reserverPlace:              @ INFO: reserverPlace
    push {r1,r2,r3,lr}      @ save des registres
    mov r1,r0
    tst r1,#0b11          @ la place est un multiple de 4
    beq 1f                @ oui
    and r1,#0xFFFFFFFC    @ sinon ajustement � un multiple de 4 superieur
    add r1,#4
1:
    ldr r2,iAdrptZoneTas
    ldr r0,[r2]
    add r1,r1,r0         @  v�rification de d�passement
    ldr r3,iAdrFinZoneTas
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
    pop {r1,r2,r3,lr}     @ restaur des registres
    bx lr                 @ retour de la fonction en utilisant lr
iAdrptZoneTas:       .int ptZoneTas
iAdrFinZoneTas:      .int FinZoneTas
szMessErrTas:        .asciz "Erreur : tas trop petit !!!\n"
.align 4
