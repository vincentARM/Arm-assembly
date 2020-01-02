/* programme saisie nombre au clavier dans console  */
/* Assembleur ARM Raspberry  */
/* conversion chaine en nombre  */
/********************************************/
/*constantes                                */
/********************************************/
.include "../constantesARM.inc"
.equ TAILLEBUF,  100  
.equ STDIN, 0
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szSaisie:       .asciz "Veuillez saisir un nombre :\n"
szRetourligne:  .asciz "\n"
szMessErr:      .asciz "Nombre trop grand : dépassement de capacite de 32 bits. :\n"
szMessErrAppel: .asciz "Erreur appel systeme. \n"
/*******************************************/
/* DONNEES NON INITIALISEES                */
/*******************************************/
.bss
.align 4                  @ Pour  alignement données
iValeur: .skip 4          @ reserve 4 octets pour stocker un nombre sur 32 bits
sBuffer: .skip TAILLEBUF  @ reserve des octets pour stocker chaine saisie

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main                @'main' point d'entrée doit être  global

main:                       @ programme principal
    push {fp,lr}            @ save des  2 registres
    add fp,sp,#8            @ fp <- adresse début

    ldr r0, adresse_saisie  @ r0 ← adresse chaine
    bl affichageMess        @ affichage message dans console
    mov r0,#STDIN           @ code pour la console d'entrée standard
    ldr r1,adresse_buffer   @ adresse du buffer de saisie
    mov r2,#TAILLEBUF       @ taille buffer
    mov r7, #READ           @ appel système pour lecture saisie
    swi #0 
    cmp r0,#0
    blt 99f
    bl vidtousregistres     @ pour vérification
    ldr r0,adresse_buffer   @ affichage des zones mémoire pour vérification
    vidmemtit verification2 r0 2

    ldr r0,adresse_buffer   @ adresse de la chaine à convertir
    bl conversionAtoD       @ conversion de la chaine saisie en nombre stocké dans r0
    bl vidtousregistres     @ pour vérification
    ldr r1,adresse_valeur   
    str r0,[r1]
    ldr r0,adresse_valeur   @ affichage des zones mémoire pour vérification
    vidmemtit verification2 r0 2

    mov r0,#0               @ code retour OK
    b 100f
99:                         @ erreur lors de l'appel systeme
    ldr r1,=szMessErrAppel  @ adresse du message
    bl   afficheerreur 
    mov r0,#1               @ code retour erreur
 100:                       @ fin de programme standard
    pop {fp,lr}             @ restaur des  2 registres
    mov r7, #EXIT           @ appel systeme pour terminer
    swi #0 
/************************************/       
adresse_saisie : .word szSaisie
adresse_buffer : .word sBuffer
adresse_valeur : .word iValeur

/******************************************************************/
/*     Conversion d'une chaine en nombre stocké dans un registre  */ 
/******************************************************************/
/* r0 contient l'adresse de la zone terminée par 0 ou 0A */
conversionAtoD:
    push {fp,lr}           @ save des  2 registres
    push {r1-r7}           @ save des autres registres
    mov r1,#0
    mov r2,#10             @ facteur
    mov r3,#0              @ compteur
    mov r4,r0              @ save de l'adresse dans r4
    mov r6,#0              @ signe positif par defaut
    mov r0,#0              @ initialisation à 0
1:                         @ boucle d'élimination des blancs du debut
    ldrb r5,[r4,r3]        @ chargement dans r5 de l'octet situé au debut + la position
    cmp r5,#0              @ fin de chaine -> fin routine
    beq 100f
    cmp r5,#0x0A           @ fin de chaine -> fin routine
    beq 100f
    cmp r5,#' '            @ blanc au début
    bne 1f                 @ non on continue
    add r3,r3,#1           @ oui on boucle en avvançant d'un octet
    b 1b
1:
    cmp r5,#'-'            @ premier caracteres est -
    moveq r6,#1            @ maj du registre r6 avec 1
    beq 3f                 @ puis on avance à la position suivante
2:                         @ debut de boucle de traitement des chiffres
    cmp r5,#'0'            @ caractere n'est pas un chiffre
    blt 3f
    cmp r5,#'9'            @ caractere n'est pas un chiffre
    bgt 3f
                           @ caractère est un chiffre
    sub r5,#48
    ldr r1,iMaxi           @ verifier le dépassement du registre
    cmp r0,r1
    bgt 99f
    mul r0,r2,r0           @ multiplier par facteur
    add r0,r5              @ ajout à r0
3:
    add r3,r3,#1           @ avance à la position suivante
    ldrb r5,[r4,r3]        @ chargement de l'octet
    cmp r5,#0              @ fin de chaine -> fin routine
    beq 4f
    cmp r5,#10             @ fin de chaine -> fin routine
    beq 4f
    b 2b                   @ boucler
4:
    cmp r6,#1              @ test du registre r6 pour le signe
    bne 100f
    mov r1,#-1
    mul r0,r1,r0           @ si negatif, on multiplie par -1
    b 100f
99:                        @ erreur de dépassement
    ldr r1,=szMessErr
    bl   afficheerreur 
    mov r0,#0              @ en cas d'erreur on retourne toujours zero
100:    
    pop {r1-r7}            @ restaur des autres registres
    pop {fp,lr}            @ restaur des  2 registres
    bx lr                  @ retour procedure
.align 4    
iMaxi: .int 1073741824     @ valeur limite programme origine
