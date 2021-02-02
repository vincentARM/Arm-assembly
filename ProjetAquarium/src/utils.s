/* Programme assembleur ARM Raspberry 32 bits ou Raspberry 32 bits*/
/* modèle B 512MO   */
/*  */
/* Utilitaires  */
/*********************************************/
/*           CONSTANTES                      */
/********************************************/
.include "./src/constAqua.inc"

.equ CHARPOS,    '@'

/*******************************************/
/* Structures                               */
/********************************************/
.include "./src/structAqua.inc"

/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
iGraine:            .int 1234567
ptZoneTas:          .int heap_begin
ptZoneDebutTas:     .int heap_begin
/*************************************************/
szMessErr: .ascii    "Code erreur hexa : "
sHexa:     .space 9,' '
           .ascii "  décimal :  "
sDeci:     .space 15,' '
           .asciz "\n"
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
sBuffer:     .skip TAILLEBUF
/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text
.global ajouterListe,affichageMess,conversion10,insererChaineCar,reserverPlace,libererPlace,conversionAtoD,comparerChaines
.global afficherErreur,genererAleas
/******************************************************************/
/*     affichage des messages   avec calcul longueur                           */ 
/******************************************************************/
/* r0 contient l'adresse du message */
affichageMess:                 @ INFO: affichageMess
    push {r0,r1,r2,r7,lr}      @ save des  registres
    mov r2,#0                  @ compteur longueur
1:                             @ boucle de calcul de la longueur
    ldrb r1,[r0,r2]            @ recup octet position debut + indice
    cmp r1,#0                  @ si 0 c'est fini
    beq 1f
    add r2,r2,#1               @ sinon ajout de 1
    b 1b
1:                             @ donc ici r2 contient la longueur du message
    mov r1,r0                  @ adresse du message en r1
    mov r0,#STDOUT             @ code pour écrire sur la sortie standard Linux
    mov r7,#WRITE              @ code de l'appel systeme 'write'
    svc #0                     @ appel systeme
    pop {r0,r1,r2,r7,lr}       @ restaur des  2 registres
    bx lr                      @ retour procedure
/***************************************************/
/*   ajouter un noeud dans une liste                */
/***************************************************/
// r0 contient l'adresse du début de liste
// r1 contient l'adresse de l'objet à inserer
ajouterListe:                    @ INFO: ajouterListe
    push {r1,r2,lr}              @ save des registres
    mov r2,r0
    mov r0,#liste_Fin            @ reserver la place sur le tas pour le noeud
    bl reserverPlace
    str r1,[r0,#liste_pointeur]  @ mettre à jour le pointeur vers l'objet
    mov r1,#0                    @ et zero vers le noeud suivant
    str r1,[r0,#liste_suivant]
    
    ldr r1,[r2]                  @ charge l'adresse de début de liste
    cmp r1,#0                    @ la liste est vide ?
    bne 1f
    str r0,[r2]                  @ oui stocke l'adresse du noeud 
    b 100f
1:                               @ debut boucle balayage de la liste
    ldr r2,[r1,#liste_suivant]
    cmp r2,#0
    movne r1,r2
    bne 1b
    str r0,[r1,#liste_suivant]
    
100:                             @ fin standard de la fonction
    pop {r1,r2,lr}               @ restaur des registres
    bx lr                        @ retour de la fonction en utilisant lr
/******************************************************************/
/*     Conversion d'un registre en décimal                                 */ 
/******************************************************************/
/* r0 contient la valeur et r1 l' adresse de la zone de stockage   */
conversion10:                 @ INFO: conversion10
    push {r1-r6,lr}           @  save registres
    mov r5,r1                 @ save zone stockage
    mov r4,#10                @ nombre maxi de caractères
    mov r2,r0
    mov r1,#10                @ conversion decimale
1:                            @ debut de boucle de conversion
    mov r0,r2                 @ copie nombre départ ou quotients successifs
    udiv r2,r0,r1             @ division par 10
    mls r3,r2,r1,r0           @ calcul reste
    //bl division /* division par le facteur de conversion */
    add r3,#48                @ car c'est un chiffre
    strb r3,[r5,r4]           @ stockage du byte au debut zone (r5) + la position (r4)
    sub r4,r4,#1              @ position précedente
    cmp r2,#0                 @ arret si quotient est égale à zero
    bne 1b    
                              @ mais il faut completer le debut de la zone avec des blancs
    mov r3,#' '               @ caractere espace
2:    
    strb r3,[r5,r4]           @ stockage du byte
    subs r4,r4,#1             @ position précedente
    bge 2b                    @ boucle si r4 plus grand ou egal à zero
    
100:    
    pop {r1-r6,lr}            @ restaur des registres
    bx lr                     @ retour procedure
/***************************************************/
/*   reserver place sur le tas                     */
/***************************************************/
// r0 contient la place à réserver 
// r0 retourne l'adresse de début de la place réservée
reserverPlace:            @ INFO: reserverPlace
    push {r1,r2,r3,lr}    @ save des registres
    mov r1,r0
    tst r1,#0b11          @ la place est un multiple de 4
    beq 1f                @ oui
    and r1,#0xFFFFFFFC    @ sinon ajustement à un multiple de 4 superieur
    add r1,#4
1:
    ldr r2,iAdrptZoneTas
    ldr r0,[r2]
    add r1,r1,r0          @ vérification de dépassement
    ldr r3,iAdrFinTas
    cmp r1,r3
    blt 2f
    adr r0,szMessErrTas
    bl affichageMess
    mov r0,#-1
    b 100f
2:
    str r1,[r2]
100:                      @ fin standard de la fonction
    pop {r1,r2,r3,lr}     @ restaur des registres
    bx lr                 @ retour de la fonction en utilisant lr
iAdrptZoneTas:       .int ptZoneTas
iAdrFinTas:          .int heap_end
szMessErrTas:        .asciz "Erreur : tas trop petit !!!\n"
.align 4
/***************************************************/
/*   liberer place sur le tas                     */
/***************************************************/
// r0 contient l'adresse de début de la place réservée
libererPlace:               @ INFO: libererPlace
    push {r1,lr}            @ save des registres
    ldr r1,iAdrDebutTas
    cmp r0,r1
    blt 99f
    ldr r1,iAdrFinTas
    cmp r0,r1
    bge 99f
    ldr r1,iAdrptZoneTas
    str r0,[r1]
    b 100f
99:
    adr r0,szMessErrTas1
    bl affichageMess
    mov r0,#-1
100:
    pop {r1,lr}             @ restaur registers 
    bx lr
iAdrDebutTas:     .int heap_begin
szMessErrTas1:    .asciz "Erreur : adresse plus petite ou plus grande que le tas !!!\n"
.align 4
/******************************************************************/
/*   insert string at character insertion                         */ 
/******************************************************************/
/* r0 contains the address of string 1 */
/* r1 contains the address of insertion string   */
/* r0 return the address of new string  on the heap */
/* or -1 if error   */
insererChaineCar:
    push {r1-r7,lr}                         @ save  registres
    mov r3,#0                                // length counter 
1:                                           // compute length of string 1
    ldrb r4,[r0,r3]
    cmp r4,#0
    addne r3,r3,#1                           // increment to one if not equal
    bne 1b                                   // loop if not equal
    mov r5,#0                                // length counter insertion string
2:                                           // compute length to insertion string
    ldrb r4,[r1,r5]
    cmp r4,#0
    addne r5,r5,#1                           // increment to one if not equal
    bne 2b                                   // and loop
    cmp r5,#0
    beq 99f                                  // string empty -> error
    add r3,r3,r5                             // add 2 length
    add r3,r3,#1                             // +1 for final zero
    mov r6,r0                                // save address string 1
    mov r0,r3
    bl reserverPlace
    cmp r0,#-1
    beq 99f
    mov r5,r0                                // save address heap for output string
 
    mov r2,#0
    mov r4,#0
3:                                           // loop copy string begin 
        ldrb r3,[r6,r2]
        cmp r3,#0
        beq 99f
        cmp r3,#CHARPOS                           // insertion character ?
        beq 5f                                   // yes
        strb r3,[r5,r4]                          // no store character in output string
        add r2,r2,#1
        add r4,r4,#1
        b 3b                                     // and loop
5:                                           // r4 contains position insertion
    add r7,r4,#1                              // init index character output string
                                             // at position insertion + one
    mov r3,#0                                // index load characters insertion string
6:
        ldrb r0,[r1,r3]                          // load characters insertion string
        cmp r0,#0                                // end string ?
        beq 7f                                   // yes 
        strb r0,[r5,r4]                          // store in output string
        add r3,r3,#1                             // increment index
        add r4,r4,#1                             // increment output index
        b 6b                                     // and loop
7:                                           // loop copy end string 
    ldrb r0,[r6,r7]                          // load other character string 1
    strb r0,[r5,r4]                          // store in output string
    cmp r0,#0                                // end string 1 ?
    beq 8f                                   // yes -> end
    add r4,r4,#1                             // increment output index
    add r7,r7,#1                             // increment index
    b 7b                                     // and loop
8:
    mov r0,r5                                // return output string address 
    b 100f
99:                                          // error
    mov r0,#-1
100:
    pop {r1-r7,lr}                          @ restaur registers 
    bx lr
/******************************************************************/
/*     Conversion d'une chaine en nombre stocké dans un registre  */ 
/******************************************************************/
/* r0 contient l'adresse de la zone terminée par 0 ou 0A */
conversionAtoD:             @ INFO: conversionAtoD
    push {r1-r7,lr}         @ save des  2 registres
    mov r1,#0
    mov r2,#10              @ facteur
    mov r3,#0               @ compteur
    mov r4,r0               @ save de l'adresse dans r4
    mov r6,#0               @ signe positif par defaut
    mov r0,#0               @ initialisation à 0
1:                          @ boucle d'élimination des blancs du debut
    ldrb r5,[r4,r3]         @ chargement dans r5 de l'octet situé au debut + la position
    cmp r5,#0               @ fin de chaine -> fin routine
    beq 100f
    cmp r5,#0x0A            @ fin de chaine -> fin routine
    beq 100f
    cmp r5,#' '             @ blanc au début
    bne 1f                  @ non on continue
    add r3,r3,#1            @ oui on boucle en avançant d'un octet
    b 1b
1:
    cmp r5,#'-'             @ premier caracteres est -
    moveq r6,#1             @ maj du registre r6 avec 1
    beq 3f                  @ puis on avance à la position suivante
2:                          @ debut de boucle de traitement des chiffres
    cmp r5,#'0'             @ caractere n'est pas un chiffre ?
    blt 3f
    cmp r5,#'9'             @ caractere n'est pas un chiffre ?
    bgt 3f
                            @ caractère est un chiffre
    sub r5,#48
    ldr r1,iMaxi            @ verifier le dépassement du registre
    cmp r0,r1
    bgt 99f
    mul r0,r2,r0            @ multiplier par facteur
    add r0,r5               @ ajout à r0
3:
    add r3,r3,#1            @ avance à la position suivante
    ldrb r5,[r4,r3]         @ chargement de l'octet
    cmp r5,#0               @ fin de chaine -> fin routine
    beq 4f
    cmp r5,#10              @ fin de chaine -> fin routine
    beq 4f
    b 2b                    @ boucler
4:
    cmp r6,#1               @ test du registre r6 pour le signe
    bne 100f
    neg r0,r0
    b 100f
99:                         @ erreur de dépassement
    adr r1,szMessErrDep
    bl   afficherErreur 
    mov r0,#0               @ en cas d'erreur on retourne toujours zero
100:
    pop {r1-r7,lr}          @ restaur des registres
    bx lr                   @ retour procedure
iMaxi:         .int 1073741824    
szMessErrDep:  .asciz  "Nombre trop grand : dépassement de capacite de 32 bits. :\n"
.align 4
/************************************/       
/* comparaison de chaines           */
/************************************/      
/* r0 et r1 contiennent les adresses des chaines */
/* retour 0 dans r0 si egalite */
/* retour -1 si chaine r0 < chaine r1 */
/* retour 1  si chaine r0> chaine r1 */
comparerChaines:          @ INFO: comparerChaines
    push {r1-r4}          @ save des registres
    mov r2,#0             @ indice
1:    
    ldrb r3,[r0,r2]       @ octet chaine 1
    ldrb r4,[r1,r2]       @ octet chaine 2
    cmp r3,r4
    movlt r0,#-1          @ plus petite
    movgt r0,#1           @ plus grande
    bne 100f              @ pas egaux 
    cmp r3,#0             @ 0 final
    moveq r0,#0           @ egalite
    beq 100f              @ c'est la fin
    add r2,r2,#1          @ sinon plus 1 dans indice
    b 1b                  @ et boucle
100:
    pop {r1-r4}
    bx lr
/***************************************************/
/*   Génération nombre aleatoire                  */
/***************************************************/
/* r0 plage fin  */
genererAleas:              @ INFO: genereraleas
    push {r1-r4,lr}         @ save  registres
    mov r4,r0               @ save plage
    ldr r0,iAdriGraine
    ldr r0,[r0]
    ldr r1,iNombre1
    mul r0,r1
    add r0,#1
    ldr r1,iAdriGraine
    str r0,[r1]
                            @ prise en compte nouvelle graine
    ldr r1,m                @ diviseur pour registre de 32 bits
    udiv r2,r0,r1
    mls r3,r2,r1,r0
    mov r0,r3               @ division du reste
    ldr r1,m1               @ diviseur  10000
    udiv r2,r0,r1
    mul r0,r2,r4            @ on multiplie le quotient par la plage demandéé
    ldr r1,m1               @ puis on divise le resultat diviseur
    udiv r2,r0,r1
    mov r0,r2               @ retour du quotient
  
100:                        @ fin standard de la fonction
    pop {r1-r4,lr}          @ restaur registres
    bx lr                   @ retour de la fonction en utilisant lr  
/*******************CONSTANTES****************************************/
iNombre1:     .int 31415821
m1:           .int 10000
m:            .int 100000000
iAdriGraine:  .int iGraine
/***************************************************/
/*   affichage message d'erreur                   */
/***************************************************/
/* r0 contient le code erreur  r1, l'adresse du message */
afficherErreur:                 @ INFO: afficherErreur
   push {r1-r4,lr}              @ save des registres
   mov r4,r0                    @ save du code erreur
   mov r0,r1
   bl affichageMess
   
                                @ conversion hexa du code retour
    ldr r0,iAdrsHexa            @ adresse de stockage du resultat
    mov r1,r4
    bl conversion16
                                @ conversion decimale
    ldr r0,iAdrsDeci            @ adresse de stockage du resultat
    mov r1,r4
    bl conversion10
                                @ affichage du message
    ldr r0,iAdrszMessErr
    bl affichageMess
  
    mov r0,r4                   @ retour du code erreur

100:                            @ fin standard de la fonction
    pop {r1-r4,lr}                 @ restaur des  2 registres frame et retour
    bx lr                       @ retour de la fonction en utilisant lr
iAdrszMessErr:         .int szMessErr
iAdrsDeci:             .int sDeci
iAdrsHexa:             .int sHexa
/******************************************************************/
/*     Converting a register to hexadecimal                      */ 
/******************************************************************/
/* r0 contains value and r1 address area   */
conversion16:
    push {r1-r4,lr}                                    @ save registers
    mov r2,#28                                         @ start bit position
    mov r4,#0xF0000000                                 @ mask
    mov r3,r0                                          @ save entry value
1:                                                     @ start loop
    and r0,r3,r4                                       @ value register and mask
    lsr r0,r2                                          @ move right 
    cmp r0,#10                                         @ compare value
    addlt r0,#48                                       @ <10  ->digit	
    addge r0,#55                                       @ >10  ->letter A-F
    strb r0,[r1],#1                                    @ store digit on area and + 1 in area address
    lsr r4,#4                                          @ shift mask 4 positions
    subs r2,#4                                         @  counter bits - 4 <= zero  ?
    bge 1b                                             @  no -> loop
    mov r0,#8
100:
    pop {r1-r4,lr}                                     @ restaur registers 
    bx lr                                              @return

