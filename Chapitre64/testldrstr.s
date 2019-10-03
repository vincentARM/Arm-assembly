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
szMessDebutPgm: 	.asciz "Début du programme. \n"
szMessErreur: 		.asciz "Erreur rencontrée.\n"
szMessFinOK: 		.asciz "Fin normale du programme. \n"
sMessResult:        .ascii " "
sMessValeur:        .fill 11, 1, ' '            @ taille => 11
szRetourligne: 		.asciz  "\n"
szChaineOrigine: .asciz "12345678"
szChaineOrigine2: .asciz "Bonjour le monde."

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
sBuffer:    .skip 500 
decalage:   .skip 1
sBuffer2:   .skip 500
/**********************************************/
/* SECTION CODE                               */
/**********************************************/
.text            
.global main                    @ 'main' point d'entrée doit être  global 
main:                           @ programme principal 
    push {fp,lr}                @ save des  registres 
    ldr r0,iAdrszMessDebutPgm   @ r0 ← adresse message debut 
    bl affichageMess            @ affichage message dans console
    /*******************************/
    /*  pseudo instruction ca      */
    /*******************************/
    ldr r0,iAdrsBuffer          @ pseudo instruction 1
    mov r1,#1
    str r1,[r0]                 @ stockage le plus simple
    vidmemtit cas1 r0 2         @ et verification
    /*******************************/
    /* cas 2                       */
    /*******************************/
    ldr r0,=sBuffer             @ pseudo instruction  2
    mov r1,#0xFFFFFFFF
    str r1,[r0]                 @ stockage le plus simple
    vidmemtit cas2 r0 2         @ et verification
    /*******************************/
    /* chargement d'une constante  */
    /*******************************/
    ldr r1,iConstante1          @ chargement constante 
    str r1,[r0]                 @ stockage le plus simple
    vidmemtit constante1 r0 2   @ et verification
    ldr r0,iAdrsBuffer
    /*******************************/
    /* inversion des octets avant stockage      */
    /*******************************/
    rev r1,r1                   @ inversion des octets
    str r1,[r0]                 @ stockage 
    vidmemtit constante1 r0 2   @ et verification
    ldr r2,[r0]
    vidregtit recup1
    rev r2,r2                   @ nouvelle inversion 
    vidregtit inversion1
    /****************************************************/
    /* verification si buffer non aligné sur un mot     */
    /****************************************************/
    ldr r0,iAdrsBuffer2         @ buffer non aligné
    ldr r1,iConstante1          @ chargement constante 
    str r1,[r0]                 @ stockage 
    vidmemtit buffer2 r0 2      @ et verification
    ldr r0,iAdrsBuffer2
    ldr r1,[r0]                 @ extraction
    vidregtit avecdecalage      @ et verification
    /***************************************************/
    /* Ajout d'un déplacement immédiat à l'adresse de base      */
    /***************************************************/
    ldr r0,iAdrsBuffer 
    mov r2,#0x35
    str  r2,[r0,#4]   @    peut aussi être négatif
    vidregtit stravecdeplacement
    vidmemtit verif5 r0 2
   /***************************************************/
    /* Ajout d'un déplacement registre à l'adresse de base      */
    /***************************************************/
    ldr r0,iAdrsBuffer 
    mov r1,#8
    mov r2,#0x36
    str  r2,[r0,r1]   @ peut aussi être [r0,-r1]
    vidregtit stravecdeplacementRegistre
    vidmemtit verif6 r0 2
   /***************************************************/
    /* Ajout d'un déplacement dans registre avec opération*/
    /***************************************************/
    ldr r0,iAdrsBuffer 
    mov r1,#3
    mov r2,#0x37
    str  r2,[r0,r1, lsl #2]   @  avec deplacement sans increment
    vidregtit stravecdeplRegistreLsl
    vidmemtit verif7 r0 2
   /***********************************************************************/
    /* Ajout d'un déplacement avec post incrémentation de l'adresse de base      */
    /*********************************************************************/
    ldr r0,iAdrsBuffer 
    mov r1,#1
    mov r2,#0x38
    str  r2,[r0],r1, lsl #2    @ post + increment r0
    vidregtit verifincrement
    mov r2,#0x39
    str  r2,[r0],r1, lsl #2    @ r2 est bien stocké à la position suivante
    vidregtit verifincrementSuite
    ldr r0,iAdrsBuffer         @ mais r0 a évolué 
    vidmemtit verifincrementPost r0 2
    mov r2,#0xA
    str  r2,[r0],#4            @ post + increment r0
    vidregtit verifincrementnumpost
    ldr r0,iAdrsBuffer
    vidmemtit verifincrementnumpost r0 2
    ldr r0,iAdrsBuffer
   /***************************************************/
    /* Ajout d'un déplacement avec pré incrementation de l'adresse de base      */
    /***************************************************/
    ldr r0,iAdrsBuffer
    mov r2,#8
    str r2,[r0,#+4]!         @ stocke r2 à r0 + 4 puis increment r0 de +4
    vidregtit verifincrementpre
    mov r2,#9
    mov r1,#1
    str r2,[r0,r1,lsl #2]!  @ idem
    vidregtit verifincrementpre1
    mov r2,#10
    str r2,[r0,r1,lsl #2]!  @ idem
    vidregtit verifincrementpre2
    ldr r0,iAdrsBuffer             @ r0 à evolué
    vidmemtit finincrement r0 2
    /*******************************/
    /* recherche d'une valeur      */
    /*******************************/
    ldr r0,iAdrsBuffer  
    mov r1,#0              @ indice de boucle
    mov r2,#9              @ valeur à chercher
1:
    ldr r3,[r0,r1,lsl #2]  @ chargement du mot à l'adresse r0 +(r1 *4)
    cmp r3,r2              @ egal à la valeur cherchée ?
    beq 2f                 @ oui -> fin
    add r1,#1              @ non -> poste suivant
    cmp r1,#4              @ fin de table limite à 5 mots de 32 bits
    ble 1b                 @ et boucle si non
    vidregtit nontrouve
    b 3f
2:                  @ r1 contient le N° de poste trouvé
    vidregtit trouve
3:
    /*************************/
    /* stockage un octet     */
    /*************************/
    ldr r0,iAdrsBuffer
    mov r1,#'A'
    strb r1,[r0]
    vidmemtit verifoctet r0 2
    /*************************/
    /* recopie d'une chaine  */
    /*************************/
    ldr r1,iAdrszChaineOrigine
    ldr r0,iAdrsBuffer
4:
    ldrb r2,[r1],#1            @ chargement d'un caractère et increment r1
    strb r2,[r0],#1            @ stockage du caractère et increment r0
    cmp r2,#0                  @ fin de chaine ?
    bne 4b                     @ non -> boucle
    ldr r0,iAdrsBuffer         @ car r0 et r1 ont avancé
    vidmemtit suitecopie r0 2
    @ mais si on veut avoir le nombre de caractères 
    @ et conserver les pointeurs des chaines
    mov r3,#0                  @ indice caractères
    ldr r1,iAdrszChaineOrigine2
    ldr r0,iAdrsBuffer
5:                             @ boucle de copie
    ldrb r2,[r1,r3]
    strb r2,[r0,r3]
    cmp r2,#0
    addne r3,#1
    bne 5b
    vidmemtit suitecopie2 r0  2 @ car r0 et r1 n'ont pas bougé
    /*************************/
    /* recopie d'une chaine avec pré incrémentation */
    /*************************/
    ldr r1,iAdrszChaineOrigine
    ldr r0,iAdrsBuffer
3:                             @ boucle de copie
    ldrb r2,[r1,#1]!           @ incrementation de 1 octet puis chargement
    strb r2,[r0,#1]!           @ incrementation de 1 octet puis stockage
    cmp r2,#0
    bne 3b
    ldr r0,iAdrsBuffer
    vidmemtit suitecopie3 r0  2 @ car r0 et r1 ont bougé
    @ et remarquez l'état du premier caractère !!!
   /**************************************/
    /* stockage d'un demimot (16 bits)   */
    /*************************************/
    ldr r0,iAdrsBuffer
    mov r1,#0x3132
    strh r1,[r0,#18]
    vidmemtit verifdemimot r0 2 @ il est stocké à l'envers (little endian)
                                @ ou petitboutiste ou petitetete
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
iAdrsBuffer2:            .int sBuffer2
iAdrszChaineOrigine:    .int szChaineOrigine
iAdrszChaineOrigine2:    .int szChaineOrigine2
iConstante1:            .int 0x31323334
/********************************************************************/
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
