/* programme : saisie au clavier dans console  */
/* Assembleur ARM Raspberry  */
/*********************************************/
/*constantes */
/********************************************/
.include "src/constantesARM.inc"
.equ TAILLEBUF,  100
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "src/ficmacros.inc"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szSaisie:       .asciz "Veuillez saisir un texte :\n"
szRetourligne:  .asciz "\n"
szMessErrAppel: .asciz "Erreur appel systeme. \n"
/*************************************************/
szMessErr:      .ascii    "Code erreur hexa : "
sHexa:          .space 9,' '
                .ascii "  décimal :  "
sDeci:          .fill 14,1,' '
                .asciz "\n"
.equ LGMESSERR, . -  szMessErr  @ calcul de la longueur de la zone precedente
/*******************************************/
/* DONNEES  NON INITIALISEES               */
/*******************************************/ 
.bss
sBuffer:  .skip TAILLEBUF

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main                @ 'main' point d'entrée doit être  global

main:                       @ programme principal
    push {fp,lr}            @ save des  2 registres
    add fp,sp,#8            @ fp <- adresse début
    vidregtit debut
    ldr r0, adresse_saisie  @ r0 ← adresse chaine
    bl affichageMess        @ affichage message dans console
    mov r0,#0
    ldr r1,adresse_buffer   @ adresse du buffer de saisie
    mov r2,#TAILLEBUF       @ taille buffer
    //mov r2,#10
    mov r7, #READ           @ Appel system pour lecture saisie clavier
    swi #0 
    cmp r0,#0
    ble 99f
    vidregtit saisie     @ pour vérification
    ldr r0,adresse_buffer
    vidmemtit saisie r0 5
    mov r0,#0               @ code retour ok
    b 100f
99:                         @ edition des erreurs
   ldr r1,=szMessErrAppel
   bl   afficheerreur
   mov r0,#1                @ code retour erreur

100:                        @ fin de programme standard
    pop {fp,lr}             @ restaur des  2 registres
    mov r7, #EXIT           @ request to exit program
    swi 0 
/************************************/
adresse_saisie : .word szSaisie
adresse_buffer : .word sBuffer

/***************************************************/
/*   affichage message d'erreur                    */
/***************************************************/
/* r0 contient le code erreur  r1, l'adresse du message */
afficheerreur:
    push {fp,lr}                   @ save des  2 registres frame et retour
    add fp,sp,#8                   @ fp <- adresse début
    push {r1,r2,r3,r4}             @ save autres registres en nombre pair
    mov r4,r0                      @ save du code erreur
    mov r0,r1
    bl affichageMess
                                   @ conversion hexa du code erreur
    ldr r0,=sHexa                  @adresse de stockage du resultat
    mov r1,r4
    mov r2,#16                     @ conversion en base 16
    push {r0,r1,r2}                @ parametre de conversion
    bl conversion
                                   @ conversion decimale
    ldr r0,=sDeci                  @ adresse de stockage du resultat
    mov r1,r4
    mov r2,#10                     @ conversion en base 10
    push {r0,r1,r2}                @ parametres de conversion passés par la pile
    bl conversion

    ldr r0,=szMessErr              @affichage du message
    bl affichageMess
  
    mov r0,r4                      @ retour du code erreur

100:                               @ fin standard de la fonction
       pop {r1,r2,r3,r4}           @ restaur des autres registres
       pop {fp,lr}                 @ restaur des  2 registres frame et retour
    bx lr                          @ retour de la fonction en utilisant lr
