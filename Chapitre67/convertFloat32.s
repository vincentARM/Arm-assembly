/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* modèle B 512MO   */
/*  */
/* conversion Float algorithme grisu  pour 32 bits  */
/* voir le document pdf de Florian Loitsch  */
/* https://www.cs.tufts.edu/~nr/cs257/archive/florian-loitsch/printf.pdf */
/* premier programme pour vérifier le déroulement */
/* ne génére que des chiffres bruts sans mise en forme finale */
/* Attention : problème de précision car la table des puissances de 10
  est imprécise */
/* seuls 17 chiffres sont significatifs */

/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/
.equ BIAS,     1075                  // biais voir norme IEEE 754 pour nombre double précision
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"
/*******************************************/
/* Structures                               */
/********************************************/
/* structure diy_fp   */
    .struct  0
diy_fp_f:                         // significant
    .struct  diy_fp_f + 8         // c'est un double
diy_fp_e:                         // exposant
    .struct  diy_fp_e + 4         // c'est un entier
diy_fp_fin: 
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessDebutPgm:      .asciz "Début du programme. \n"
szMessErreur:        .asciz "Erreur rencontrée.\n"
szMessFinOK:         .asciz "Fin normale du programme. \n"
szRetourligne:       .asciz  "\n"

.align 4
//dfTest1:                 .double 0f8E-280
//dfTest1:                  .double 0f314159265358979323E-17
dfTest1:                    .double 0f123456789123456789
.include "TablePuis10Norm32.inc"
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
diyFP:      .skip diy_fp_fin
diyResult:  .skip diy_fp_fin
sBuffer:    .skip 500 

/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text            
.global main                    @ main point d entrée doit être  global 

main:                           @ programme principal 
    ldr r0,iAdrszMessDebutPgm   @ r0 ← adresse message debut 
    bl affichageMess            @ affichage message dans console   

    ldr r0,iAdrdfTest1
    vidmemtit debut r0 2
    vldr d0,[r0]               @ chargement du Float dans d0
    ldr r0,iAdrdiyFP           @ convertir le nombre dans la structure adéquate
    bl convertirDiy_fp
    ldr r0,iAdrdiyFP
    vidmemtit conversion r0 2
    bl normaliserDiy_fp        @ normalise le nombre
    ldr r0,iAdrdiyFP
    vidmemtit normaliser r0 2
    ldr r0,[r0,#diy_fp_e]      @ exposant
    add r0,#64
    mov r1,#0                  @ alpha
    bl calculerK               @ calcul du K
    vidregtit retourK
                               @ Calcul adresse poste table
    mov r4,r0                  @ save coefficient
    add r0,r0,#255             @ calcul adresse poste kieme des puissance de 10
    add r0,#54                 @ addition de 54 pour avoir 255+54 = 304   1er puissance de la table
    mov r2,#diy_fp_fin
    
    mul r0,r2,r0               @ calcul du déplacement
    ldr r2,iAdrTablePuis10Norm32
    add r1,r2,r0               @ contient l adresse de la puissance de 10
    vidmemtit table r1 2
    ldr r0,iAdrdiyFP           @ multiplication du nombre
    ldr r2,iAdrdiyResult
    bl multiplier
    ldr r0,iAdrdiyResult
    vidmemtit mult r0 2
    ldr r0,iAdrdiyResult       @ résultat 
    ldr r1,iAdrsBuffer
    mov r2,r4                  @ exposant
    bl couperResultat          @ découpage du résultat
    ldr r0,iAdrsBuffer         @ affichage du buffer
    bl affichageMess      
    ldr r0,iAdrszRetourligne
    bl affichageMess
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
iAdrszRetourligne:      .int szRetourligne
iAdrdiyFP:              .int diyFP
iAdrdfTest1:            .int dfTest1
iAdrsBuffer:            .int sBuffer
iAdrTablePuis10Norm32:  .int TablePuis10Norm32
iAdrdiyResult:          .int diyResult

/***************************************************/
/*   conversion float               */
/***************************************************/
/* d0 contient le float double précision */
/* r0 contient l'adresse de la structure de reception */
convertirDiy_fp:             @ INFO: convertirDiy_fp
    push {r1-r5,lr}          @ save des registres
    vmov r1,r2,d0            @ r1 ← Lower32BitsOf(d0) r2 ← Higher32BitsOf(d0)
    ldr r5,iMaskMantisse
    and r3,r2,r5
    ldr r5,iMaskExposant
    and r4,r2,r5             @ exposant
    ldr r5,iBias
    lsrs r4,#20
    bne 1f
    mov r4,#1
    ldr r5,iBias
    sub r4,r4,r5
    b 2f
1:
    sub r4,r4,r5  
    orr r3,#1<<20
2:
    str r4,[r0,#diy_fp_e]
    stm r0,{r1,r3}           @ stocke la mantisse (8 octets) à l adresse r0

100:                         @ fin standard de la fonction
    pop {r1-r5,lr}           @ restaur des registres
    bx lr                    @ retour de la fonction en utilisant lr
iBias:             .int BIAS
iMaskMantisse:     .int 0xFFFFF
iMaskExposant:     .int 0x7FF<<20
/***************************************************/
/*   normaliser structure float                    */
/***************************************************/
/* r0 contient l'adresse de la structure diy_fp */
normaliserDiy_fp:           @ INFO: normaliserDiy_fp
    push {r1-r5,lr}         @ save des registres
    ldm r0,{r1,r2}          @ charge la mantisse dans r1 r2
    ldr r3,[r0,#diy_fp_e]
1:
    tst r2,#1<<21
    beq 2f
    lsl r2,#1
    lsls r1,#1
    orrcs r2,#1
    sub r3,#1
    b 1b
2:
    lsl r2,#11
    mov r4,r1
    ldr r5,iMask20
    and r4,r5
    lsr r4,#21
    orr r2,r4
    lsl r1,#11
    sub r3,#11
    str r3,[r0,#diy_fp_e]  @ stocke l exposant
    stm r0,{r1,r2}         @ stocke le significand
100:                       @ fin standard de la fonction
    pop {r1-r5,lr}         @ restaur des registres
    bx lr                  @ retour de la fonction en utilisant lr
iMask11:     .int 0xFFFFF000
iMask20:     .int 0xFFE<<20
/***************************************************/
/*   calculer l indice pour acces table                    */
/***************************************************/
/* r0 contient l'exposant    */
/* r1 contient le parametre alpha */
calculerK:                  @ INFO: calculerK
    push {r1,lr}            @ save des registres
    vpush {d0,d1}           @ save des registres
    sub r0,r1,r0
    add r0,r0,#63
    vidregtit calculK
    vmov s0,r0
    vcvt.f64.s32 d0, s0 
    vldr d1,D_1
    vmul.f64 d0,d0,d1
    vcvt.s32.f64 s0, d0
    vmov r0,s0
    
100:                       @ fin standard de la fonction
    vpop {d0,d1}           @ save des registres
    pop {r1,lr}            @ restaur des registres
    bx lr                  @ retour de la fonction en utilisant lr
D_1:               .double 0.30102999566398114
/***************************************************/
/*   multiplier 2 nombres                    */
/***************************************************/
/* r0 contient l adresse de la structure premier nombre */
/* r1 contient l adresse de la structure deuxieme nombre */
/* r2 contient l adresse de la structure du résultat  */
multiplier:                  @ INFO: multiplier
    push {r1-r12,lr}         @ save des registres
    ldm r0,{r3,r4}           @ charge la mantisse nombre 1 dans r3 r4
    ldm r1,{r5,r6}           @ charge la mantisse nombre 1 dans r5 r6
    umull r7,r8,r3,r5        @ db     pour ab * cd
    umull r9,r10,r4,r5       @ da
    umull r11,r12,r3,r6      @ cb
    adds  r7,r8, r11         @ ajout partie basse
    movcs r11,#1             @ première retenue
    movcc r11,#0
    adds  r7,r7,r9           @ ajout partie basse
    adc  r11,#0              @ 2ième retenue
    adds  r9,r10,r11         @ ajout des retenues à partie haute
    movcs r7,#1              @ 1ere retenue
    movcc r7,#0
    adds r9,r12              @ ajout 2ieme partie haute
    adc r7,#0                @ 2 ieme retenue
    umull r11,r12,r4,r6      @ ca
    adds r9,r9,r11           @ ajout partie haute
    adc r7,#0                @ retenue
    add r12,r7               @ et ajout retenue partie trés haute
    stm r2,{r9,r12}
    ldr r3,[r0,#diy_fp_e]
    ldr r4,[r1,#diy_fp_e]
    add r3,r4
    add r3,#64
    str r3,[r2,#diy_fp_e]
100:                        @ fin standard de la fonction
    pop {r1-r12,lr}         @ restaur des registres
    bx lr                   @ retour de la fonction en utilisant lr
/***************************************************/
/*   couper et extraire le resultat                */
/***************************************************/
/* r0 contient l adresse de la structure resultat */
/* r1 contient l adresse du buffer            */
/* r2 contient l exposant */
couperResultat:             @ INFO: couperResultat
    push {r1-r9,lr}         @ save des registres
    mov r5,r0
    mov r6,r1
    mov r4,r2
    ldm r5,{r0,r1}          @ charge la mantisse dans r0 r1
    ldr r7,[r5,#diy_fp_e]   @ charge l'exposant
    ldr r8,qDix7
    lsr r2,r8,r7            @ diviseur
    bl divisionReg64U
    vidregtit couper1
    lsl r9,r3,r7            @ deplacement à gauche du reste
    mov r2,r8
    bl divisionReg64U
    mov r1,r6               @ conversion du quotient en début du buffer
    bl conversion10 
    mov r0,r3               @ puis conversion du reste en position 10 du buffer
    add r1,r6,#10
    bl conversion10SP7
    mov r0,r9               @ puis conversion du premier reste en position 17
    add r1,r6,#17
    bl conversion10SP7
    mov r0,#'E'
    strb r0,[r6,#25]
    mvn r0,r4               @ inversion exposant
    //add r0,#1
    add r1,r6,#26           @ conversion exposant en fin des 3 zones précédentes
    bl conversion10S 
100:                        @ fin standard de la fonction
    pop {r1-r9,lr}          @ restaur des registres
    bx lr                   @ retour de la fonction en utilisant lr
qDix7:               .int 10000000
/***************************************************/
/*   division d un nombre de 64 bits par un nombre de 32 bits */
/***************************************************/
/* r0 contient partie basse dividende */
/* r1 contient partie haute dividente */
/* r2 contient le diviseur */
/* r0 retourne partie basse quotient */
/* r1 retourne partie haute quotient */
/* r3 retourne le reste */
divisionReg64U:        @ INFO: divisionReg64U
    push {r4,r5,lr}    @ save des registres
    mov r5,#0          @ raz du reste R
    mov r3,#64         @ compteur de boucle
    mov r4,#0          @ dernier bit
1:    
    lsl r5,#1          @ on decale le reste de 1
    lsls r1,#1         @ on decale la partie haute du quotient de 1
    orrcs r5,#1        @ et on le pousse dans le reste R
    lsls r0,#1         @ puis on decale la partie basse 
    orrcs r1,#1        @ et on pousse le bit de gauche dans la partie haute
    orr r0,r4          @ position du dernier bit du quotient
    mov r4,#0          @ raz du bit
    cmp r5,r2
    subge r5,r2        @ on enleve le diviseur du reste
    movge r4,#1        @ dernier bit à 1
    @ et boucle
    subs r3,#1
    bgt 1b    
    lsl r1,#1          @ on decale le quotient de 1
    lsls r0,#1         @ puis on decale la partie basse 
    orrcs r1,#1
    orr r0,r4          @ position du dernier bit du quotient
    mov r3,r5
100:                   @ fin standard de la fonction
    pop {r4,r5,lr}     @ restaur des  2 registres frame et retour
    bx lr              @ retour de la fonction en utilisant lr
/******************************************************************/
/*     Conversion de 7 caractère d un registre en décimal         */ 
/******************************************************************/
/* r0 contient la valeur et r1 l' adresse de la zone de stockage   */
conversion10SP7:                @ INFO: conversion10SP7
    push {r1-r6,fp,lr}          @ save des registres
    mov r5,r1
    mov r4,#7
    mov r2,r0
    mov r1,#10                  @ conversion decimale
1:                              @ debut de boucle de conversion
    mov r0,r2                   @ copie nombre départ ou quotients successifs
    bl division                 @ division par le facteur de conversion
    add r3,#48                  @ car c'est un chiffre
    strb r3,[r5,r4]             @ stockage du byte au debut zone (r5) + la position (r4)
    sub r4,r4,#1                @ position précedente
    cmp r4,#0                   @ arret si nombre de chiffre atteint
    bne 1b    
100:    
    pop {r1-r6,fp,lr}           @ restaur des registres
    bx lr                       @ retour procedure
    /***************************************************/
/*   conversion registre en décimal   signé  */
/***************************************************/
/* r0 contient la valeur à convertir   */
/* r1 contient l'adresse de la zone de conversion */
conversion10S:         @ INFO: conversion10S
    push {fp,lr}       @ save des  2 registres frame et retour
    push {r1-r7}       @ save autres registres
    mov r5,r1          @ debut zone stockage
    mov r6,#'+'        @ par defaut le signe est +
    cmp r0,#0          @ nombre négatif ?
    bge 0f
    mov r6,#'-'        @ oui le signe est -
    mvn r0,r0          @ et inversion du signe
    add r0,#1

0:    
    mov r4,#10         @ longueur de la zone
    mov r2,r0          @ nombre de départ des divisions successives
    mov r1,#10         @ conversion decimale
1:                     @ debut de boucle de conversion
    mov r0,r2          @ copie nombre départ ou quotients successifs
    bl division        @ division par le facteur de conversion
    add r3,#48         @ car c'est un chiffre
    strb r3,[r5,r4]    @ stockage du byte en début de zone r5 + la position r4
    sub r4,r4,#1       @ position précedente
    cmp r2,#0          @ arret si quotient est égale à zero
    bne 1b    
    strb r6,[r5,r4]    @ stockage du signe à la position courante
    subs r4,r4,#1      @ position précedente
    blt  100f          @ si r4 < 0  fin
    add r4,#1          @sinon il faut deplacer le résultat au debut de la zone
    mov r2,#0
2:    
    ldrb r3,[r5,r4]    @ lecture octet
    strb r3,[r5,r2]    @ stockage octet
    add r4,r4,#1       @ position suivante
    add r2,r2,#1
    cmp r4,#10         @ longueur zone ?
    ble 2b             @ boucle si r4 plus petit
    mov r0,r2
100:                   @ fin standard de la fonction
    pop {r1-r7}        @restaur des autres registres
    pop {fp,lr}        @ restaur des  2 registres frame et retour
    bx lr  
/********************************************************************/
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
