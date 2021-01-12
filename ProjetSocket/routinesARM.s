/* Routines pour assembleur arm raspberry */
/* version 2021 */
/* ajout gestion du tas plus adaptée */
/*******************************************/
/* CONSTANTES                              */
/*******************************************/
.include "constantesARM.inc"
.equ LGZONEADR,  60 
.equ NBCARLIBEL, 45
.equ CHARPOS,    '@'
.equ BRK,        0x2d 

/*******************************************/
/* FICHIER DES MACROS                      */
/*******************************************/ 
.include "ficmacros.s"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
.align 4
iGraine:       .int 1234567
                                 @ donnees pour vidage un registre
szVidregistre: .ascii "adresse : "
adresse:       .ascii "           "
suite:         .ascii "valeur du registre : "
registre:      .fill 35, 1, ' '
szFin:         .asciz "\n"
                                 @ donnees pour vidage tout registres */          
szVidregistreReg: .ascii "Vidage registres : "
adresseLib:       .fill LGZONEADR, 1, ' '
suiteReg:         .ascii "\n r0  : "
reg0: .fill 9, 1, ' '
s1: .ascii " r1  : "
reg1: .fill 9, 1, ' '
s2: .ascii " r2  : "
reg2: .fill 9, 1, ' '
s3: .ascii " r3  : "
reg3: .fill 9, 1, ' '
/*ligne2 */
s4: .ascii "\n r4  : "
reg4: .fill 9, 1, ' '
s5: .ascii " r5  : "
reg5: .fill 9, 1, ' '
s6: .ascii " r6  : "
reg6: .fill 9, 1, ' '
s7: .ascii " r7  : "
reg7: .fill 9, 1, ' '
/*ligne 3 */
s8: .ascii "\n r8  : "
reg8: .fill 9, 1, ' '
s9: .ascii " r9  : "
reg9: .fill 9, 1, ' '
s10: .ascii " r10 : "
reg10: .fill 9, 1, ' '
s11: .ascii " fp  : "
reg11: .fill 9, 1, ' '
/*ligne4 */
s12: .ascii "\n r12 : "
reg12: .fill 9, 1, ' '
s13: .ascii " sp  : "
reg13: .fill 9, 1, ' '
s14: .ascii " lr  : inconnu  "
s15: .ascii " pc  : "
reg15: .fill 9, 1, ' '

fin: .asciz "\n"
                                        @ donnees pour vidage mémoire
szVidregistreMem: .ascii "Aff mémoire "
sadr1:            .ascii " adresse : "
adresseMem :      .ascii "          "
suiteMem:         .fill NBCARLIBEL,1,' '
                  .asciz "\n"
debmem: .fill 9, 1, ' '
s1mem: .ascii " "
zone1: .fill 48, 1, ' '
s2mem: .ascii " "
zone2: .fill 16, 1, ' '
s3mem: .asciz "\n"
/* pour affichage du registre d'état   */
szLigneEtat: .asciz "Etats :  Z=   N=   C=   V=       \n"
/*************************************************/
szMessErr: .ascii    "Code erreur hexa : "
sHexa: .space 9,' '
         .ascii "  décimal :  "
sDeci: .space 15,' '
         .asciz "\n"
.equ LGMESSERR, . -  szMessErr /* calcul de la longueur de la zone precedente */
szMessTemps: .ascii "Durée calculée : "
sSecondes: .fill 10,1,' '
             .ascii " s "
sMicroS:   .fill 10,1,' '
             .asciz " µs\n"    
szLibAncien: .asciz " ancien "
sMessAffBin: .ascii "Affichage base 2 r0 "
adresseLibBin:  .fill LGZONEADR, 1, ' '
                 @  .ascii "\n"
                 .ascii "    "
sZoneBin:        .space 36,' '
                   .asciz "\n"
/***********************************************/
/* Données non initialisées                    */
/***********************************************/
.bss
.align 4
dwDebut:           .skip 8
dwFin:             .skip 8
buffer_conversion: .skip 40

/*******************************************/
/*  CODE PROGRAMME                         */
/*******************************************/  
.text
.global affichage,affichage1,longchai,vidregistre,retourligne,conversion,vidtousregistres
.global affmemoireTit,conversiondeb,division,afficheerreur,affichageMess,conversion10,conversion10S
.global conversionAtoD,debutChrono,stopChrono,racinecarreeDP,divisionDP,affichetat
.global genereraleas,concatChaine,divisionS,comparaison,affregistres,allocPlace
.global razLibel,strInsert,affichageReg2,strInsertAtChar
/*******************************************/
/*  FONCTION AFFICHAGE V3                  */
/*******************************************/  
/* adresse de la chaine passée par la pile */
/* longueur passée par la pile ou -1 si calcul longueur à faire */
/* sauve tous les registres r0 r1 r2 r7 */
affichage:                   @ INFO: affichage
    push {fp,lr}            /* save des  2 registres */
    add fp,sp,#8            /* fp <- adresse début */
                            /*ici save autres registres */
    push {r0,r1,r2,r7}
    mov r0,fp               /* récuperation adresse chaine */
    ldr r0, [r0]            /* dans le registre r0 */
    add r2,fp,#4            /* récuperation longueur chaine */
    ldr r2, [r2]            /* dans le registre r2 */
    cmp r2,#-1              /* si -1 il faut calculer la longueur */ 
    bne 1f 
                            /* calcul longueur chaine */
                            /*l'adresse est dans le registre r0 */
    bl longchai
    mov r2,r0
1:                          /* r2 contient la longueur */
    mov r1,fp               /* r1 on remet l'adresse de la chaine */            
    ldr r1,[r1]
    mov r0, #1              /* r0 ← 1 */
    mov r7, #4              /* select system call 'write' */
    swi #0                  /* perform the system call */
                            /* retour de la fonction */
                            /*pop des autres registres */
    pop {r0,r1,r2,r7}
                            /*pop des registres frame et retour */
    pop {fp,lr}
    add sp, sp, #8          /* sp ← sp + 8. pour les 2 parametres passés à la fonction */
    bx lr                   /* return from main using lr */
/*******************************************/
/*  FONCTION AFFICHAGE retour ligne                  */
/*******************************************/  
/* adresse de la chaine passée par la pile */
retourligne:                    @ INFO: retourligne
    push {r0,r1,r2,r7}
    ldr r1,adresse_retourligne
    mov r2,#1                   /*longueur */
    mov r0, #1                  /* r0 ← 1 */
    mov r7, #4                  /* select system call 'write' */
    swi #0                      /* perform the system call */
    pop {r0,r1,r2,r7}
    bx lr
adresse_retourligne : .word szFin

/*******************************************/
/*  Calcul longueur chaine V1                  */
/*******************************************/  
/* adresse de la chaine passée par la pile */    
/* r0 contient l'adresse de la chaine */
/* r0 retourne la longueur */    
/* utilise r1 r2   */
longchai:              @ fonction
    push {r1,r2}
    mov r2,r0         /* adresse chaine dans r2 */
    mov r0,#0          /* raz de r0 */
1:    
    ldrb r1, [r2]                /* r1 ← *{byte}r2 */
    cmp r1,#0         /* fin de chaine ? */
    beq 1f         /* si egal fini */
    add r0,#1        /* +1 dans compteur */ 
    add r2,#1         /* +1 dans pointeur adresse */ 
    b 1b
1:          
    pop {r1,r2}
    bx lr     
 
/**************************************************/
/*       vidage d'un registre                     */
/**************************************************/
/* parametre 1 contient la valeur à afficher */
/* parametre 2 contient la base d'affichage 2 binaire ou 10 ou 16 (hexa) */
/* tous les registres sont sauvés */
vidregistre:              @ fonction
     push {fp,lr}    /* save des  2 registres */
    add fp,sp,#8    /* fp <- adresse début */
    /*ici save autres registres */
    push {r0,r1,r2,r3}
    sub r1,lr,#4    /* adresse instruction */
    ldr r0,adresse_adresse /*adresse de stockage du resultat */
    mov r2,#16    /* conversion en base 16 */
    push {r0,r1,r2}     /* parametre de conversion */
    bl conversion
    mov r0,fp  /* récuperation valeur a afficher */
    ldr r1, [r0]   /* dans le registre r1 */
    add r0,#4  /* récuperation facteur conversion */
    ldr r2, [r0]  /* dans le registre r2 */
    ldr r0,adresse_registre
    push {r0,r1,r2}    
    bl conversion
    /* affichage resultats */
    ldr r0, adresse_chaine   /* r0 ← adresse chaine */
    mov r1,#-1  //test calcul longueur
    push {r0,r1}
    bl affichage  /*appel procedure  */
    /* effacement zone registre */
    ldr r0,adresse_registre   
    mov r1,#32   /* caractère espace */
    mov r2,#0    /* compteur */
1:
    strb r1,[r0,+r2]   /* byte r1 -> adresse r0+r2 */ 
    add r2,r2,#1       /* incremente compteur */
    cmp r2,#34         /* blanc sur 35 caractères */
    ble 1b    
    
    /* retour de la fonction */
   /*pop des autres registres */
       pop {r0,r1,r2,r3}
     /*pop des registres frame et retour */
    pop {fp,lr}
    add sp, sp, #8  /* sp ← sp + 2. pour les 2 parametres passés à la fonction */
    bx lr                            /* return from main using lr */
adresse_chaine : .word szVidregistre
adresse_adresse: .word adresse 
adresse_registre: .word registre 

/**************************************************/
/*     vidage de tous les registres               */
/**************************************************/
/* aucun argument  */
vidtousregistres:                @ fonction
    push {fp,lr}    /* save des  2 registres */
    //add fp,sp,#8    /* fp <- adresse début */
    push {r12}
    ldr r12,iAdrszLibAncien
    push {r12}
    ldr r12,[sp,#4]
    bl affregistres 
    pop {r12}

    pop {fp,lr}   /* restaur des  2 registres */
    bx lr                            /* return from main using lr */
iAdrszLibAncien: .int szLibAncien

/*******************************************/    
/* affichage zone memoire                  */
/*******************************************/    
/*  new   r0  adresse memoire  r1 nombre de bloc r2 titre */
affmemoireTit:                 @ fonction
    push {fp,lr}
    add fp,sp,#8    /* fp <- adresse début pile */
    push {r0-r8} /* save des registres utilisés */ 
    mov r4,r0
    ldr r3,adresse_adresseMem /*adresse de stockage du resultat */
    mov r5,#16    /* conversion en base 16 */
    push {r3,r4,r5}    
    bl conversion
/* recup libelle dans r2 */
    mov r4,#0
    ldr r5,adresse_suiteMem /*adresse de stockage du resultat */
    //bl vidtousregistres
1: @ boucle copie
    ldrb r3,[r2,r4]
    cmp r3,#0
    strneb r3,[r5,r4]
    addne r4,#1
    bne 1b        
    mov r3,#' '
2:
    cmp r4,#NBCARLIBEL
    strltb r3,[r5,r4]
    addlt r4,#1
    blt 2b
    
    mov r6,r1 /* récuperation nombre de blocs dans r6*/
    mov r2,r0 /* récuperation debut memoire a afficher */
    /* affichage entete */
    ldr r0, adresse_chaineMem   /* r0 ← adresse chaine */
    mov r1,#-1  /*pour calcul longueur */
    push {r0,r1}
    bl affichage  /*appel procedure  */

    /*calculer debut du bloc de 16 octets*/
    mov r1, r2, ASR #4      /* r1 ← (r2/16) */
    mov r1, r1, LSL #4      /* r1 ← (r2*16) */
    /* mettre une étoile à la position de l'adresse demandée*/
    mov r8,#3            /* 3 caractères pour chaque octet affichée */
    sub r0,r2,r1         /* calcul du deplacement dans le bloc de 16 octets */
    mul r5,r0,r8         /* deplacement * par le nombre de caractères */
    ldr r0,adresse_zone1  /*adresse de stockage   */
    add r7,r0,r5          /* calcul de la position */
    sub r7,r7,#1          /* on enleve 1 pour se mettre avant le caractère */
    mov r0,#'*'           
    strb r0,[r7]         /* stockage de l'étoile */
3:
    /*afficher le debut  soit r1  */
    ldr r0,adresse_debmem /*adresse de stockage du resultat */
    mov r2,#16    /* conversion en base 16 */
    push {r0,r1,r2}    
    bl conversion
    /*balayer 16 octets de la memoire  */
    mov r8,#3
    mov r2,#0
4:  /* debut de boucle de vidage par bloc de 16 octets */
    ldrb r4,[r1,+r2]    /* recuperation du byte à l'adresse début + le compteur */
    /* conversion byte pour affichage */
    ldr r0,adresse_zone1 /*adresse de stockage du resultat */
    mul r5,r2,r8   /* calcul position r5 <- r2 * 3 */
    add r0,r5
    mov r3, r4, ASR #4      /* r3 ← (r4/16) */
    cmp r3,#9    /* inferieur a 10 ? */
    addle r5,r3,#48  /*oui  */
    addgt r5,r3,#55  /* c'est une lettre en hexa */
    strb r5,[r0]    /* on le stocke au premier caractères de la position */ 
    add r0,#1        /* 2ième caractere */
    mov r5,r3,LSL #4  /* r5 <- (r4*16)  */
    sub r3,r4,r5     /* pour calculer le reste de la division par 16 */
    cmp r3,#9    /* inferieur a 10 ? */
    addle r5,r3,#48
    addgt r5,r3,#55
    strb r5,[r0]  /* stockage du deuxieme caracteres */
    add r2,r2,#1   /* +1 dans le compteur */
    cmp r2,#16     /* fin du bloc de 16 caractères ? */
    blt 4b
    /* vidage en caractères */
    mov r2,#0   /* compteur */
5:  /* debut de boucle */
    ldrb r4,[r1,+r2]  /* recuperation du byte à l'adresse début + le compteur */
    cmp r4,#31       /* compris dans la zone des caractères imprimables ? */
    ble 6f   /* non */
    cmp r4,#125
    bgt 6f
    b 7f
6:
    mov r4,#46  /* on force le caractere . */
7:
    ldr r0,adresse_zone2 /*adresse de stockage du resultat */
    add r0,r2
    strb r4,[r0]
    add r2,r2,#1
    cmp r2,#16    /* fin de bloc ? */
    blt 5b    

    /* affichage resultats */
    ldr r0, adresse_debmem   /* r0 ← adresse chaine */
    mov r2,#-1  //pour calcul longueur
    push {r0,r2}
    bl affichage  /*appel procedure  */
    mov r0,#' '
    strb r0,[r7]   /* on enleve l'étoile pour les autres lignes */
    add r1,r1,#16   /* adresse du bloc suivant de 16 caractères */
    subs r6,#1    /* moins 1 au compteur de blocs */
    bgt 3b   /* boucle si reste des bloc à afficher */
    
    /* fin de la fonction */
    pop {r0-r8}
    pop {fp,lr}   /* restaur des  2 registres */
    bx lr
adresse_chaineMem : .word szVidregistreMem
adresse_adresseMem: .word adresseMem
//adresse_adresseInst: .word adresseInst 
adresse_debmem: .word debmem
adresse_suiteMem: .int suiteMem
adresse_zone1: .word zone1
adresse_zone2: .word zone2
/***********************************************/
/* conversion avec deplacement en début de zone*/
/***********************************************/
conversiondeb:               @ fonction
    push {fp,lr}    /* save des  2 registres */
    add fp,sp,#8    /* fp <- adresse début */
    /*ici save autres registres */
    push {r0-r5}
    mov r0,fp  /* récuperation adresse zone stockage */
    ldr r5, [r0]   /* dans le registre r5 */
    add r0,#4  /* récuperation valeur du registre */
    ldr r1, [r0]  /* dans le registre r1 */
    add r0,#4    /* récuperation facteur de conversion */
    ldr r2, [r0]  /* dans le registre r2 */
    
    ldr r0,=buffer_conversion /*adresse de stockage du resultat */
    //bl vidtousregistres
    push {r0,r1,r2}    
    bl conversion
    /* recopie des caractères */
    ldr r0,=buffer_conversion
    mov r1,#0 //compteur buffer
    mov r2,#0 // compteur zone de reception
    //bl vidtousregistres
1:  ldrb r3,[r0,+r1]
     cmp r3,#0
     beq 2f
     cmp r3,#0x20
     beq 2f
    strb r3,[r5,+r2]
     add r2,#1
    b 3f
2: cmp r2,#0
    bne 4f
3: add r1,#1
    b 1b    
4:
   /* retour de la fonction */
   /*pop des autres registres */
       pop {r0-r5}
     /*pop des registres frame et retour */
    pop {fp,lr}
    add sp, sp, #12  /* sp ← sp + 12. pour les 3 parametres passés à la fonction */
    bx lr                            /* return from main using lr */
/**************************************************/
/*       conversion registre en caractères ascii  */
/**************************************************/
/* arguments passés par la pile */
/* gestion des nombres negatifs si base 10 */
conversion:                @ fonction
     push {fp,lr}    /* save des  2 registres */
    add fp,sp,#8    /* fp <- adresse début */
    /*ici save autres registres */
        push {r0,r1,r2,r3,r4,r5,r6,r7}
    mov r0,fp  /* récuperation adresse zone stockage */
    ldr r5, [r0]   /* dans le registre r5 */
    add r0,#4  /* récuperation valeur du registre */
    ldr r2, [r0]  /* dans le registre r2 */
    add r0,#4    /* récuperation facteur de conversion */
    ldr r1, [r0]  /* dans le registre r1 */
    cmp r1,#2    /*   conversion en binaire */ 
    bne 1f
    mov r4,#32
    b 3f
1:    
    cmp r1,#10    /*   conversion en base 10 */ 
    bne 2f
    mov r4,#10
    @ test si nombre negatif
    cmp r2,#0
    bge 3f   @ non negatif
    mov  r3,#-1   @ negatif on le multiplie par -1 
    mov r6,r2
    mul r2,r6,r3
    mov r3,#'-'  @ et on affiche le signe moins
    strb r3,[r5]
    add r5,r5,#1
    sub r4,r4,#1
    b 3f
2:    
    mov r4,#8  /* et conversion autres */ 
3:    
    mov r0,#0   /* compteur de boucle */
    mov r3,#32  /*  espace */ 
4:    /* raz de la zone de reception */
   strb r3,[r5,+r0]     
    add r0,#1
    cmp r0,r4
    blt 4b
    add r5,r5,r4  /* on ajoute la longueur de la zone pour commencer par la fin */
5:    /* debut de boucle de conversion */
    mov r0,r2    /* division par le facteur de conversion */
    bl division
    cmp r3,#9    /* inferieur a 10 ? */
    ble 6f
    add r3,#55   /* c'est une lettre au dela de 9 : A B C D E F*/
    b 7f
6:    
    add r3,#48   /* c'est un chiffre */
7:    
    strb r3,[r5]
    sub r5,r5,#1   /* position précedente */
    cmp r2,#0      /* arret si quotient est égale à zero */
    bne 5b    
    
    
    /* retour de la fonction */
   /*pop des autres registres */
       pop {r0,r1,r2,r3,r4,r5,r6,r7}
     /*pop des registres frame et retour */
    pop {fp,lr}
    add sp, sp, #12  /* sp ← sp + 12. pour les 3 parametres passés à la fonction */
    bx lr                            /* return from main using lr */
    
/*=============================================*/
/* division entiere non signée                */
/*============================================*/
division:                     @ fonction
    /* r0 contains N */
    /* r1 contains D */
    /* r2 contains Q */
    /* r3 contains R */
    push {r4, lr}
    mov r2, #0                 /* r2 ← 0 */
    mov r3, #0                 /* r3 ← 0 */
    mov r4, #32                /* r4 ← 32 */
    b 2f
1:
    movs r0, r0, LSL #1    /* r0 ← r0 << 1 updating cpsr (sets C if 31st bit of r0 was 1) */
    adc r3, r3, r3         /* r3 ← r3 + r3 + C. This is equivalent to r3 ← (r3 << 1) + C */
 
    cmp r3, r1             /* compute r3 - r1 and update cpsr */
    subhs r3, r3, r1       /* if r3 >= r1 (C=1) then r3 ← r3 - r1 */
    adc r2, r2, r2         /* r2 ← r2 + r2 + C. This is equivalent to r2 ← (r2 << 1) + C */
2:
    subs r4, r4, #1        /* r4 ← r4 - 1 */
    bpl 1b            /* if r4 >= 0 (N=0) then branch to .Lloop1 */
 
    pop {r4, lr}
    bx lr    
/*=============================================*/
/* division entiere signée                    */
/*============================================*/
divisionS:                 @ fonction
    /* r0 contains N */
    /* r1 contains D */
    /* r2 contains Q */
    /* r3 contains R */
    push {r4, lr}    
    cmp r0,#0      
    rsblt r0,r0,#0       @ inversion si dividende negatif
    movlt r4,#1
    movge r4,#0
    cmp r1,#0
    rsblt r1,r1,#0       @ inversion si diviseur negatif
    eorlt r4,#1
    bl division       @ appel division non signée
    cmp r4,#0          @ test  negatif
    rsbne r2,r2,#0       @ si negatif on inverse le quotient
    pop {r4, lr}
    bx lr    
/**************************************************/
/**************************************************/
/************NOUVELLES FONCTIONS *****************/
/**************************************************/

/***************************************************/
/*   conversion registre en décimal   signé  */
/***************************************************/
/* r0 contient le registre   */
/* r1 contient l'adresse de la zone de conversion */
conversion10S:                 @ fonction
    push {fp,lr}    /* save des  2 registres frame et retour */
    push {r0,r1,r2,r3,r4,r5,r6,r7}   /* save autres registres  */
    mov r5,r1       /* debut zone stockage */
    mov r6,#'+'     /* par defaut le signe est + */
    cmp r0,#0       /* nombre négatif ? */
    bge 0f
    mov r6,#'-'     /* oui le signe est - */
    mov r4,#-1
    mov r2,r0       /* et on multiplie le nombre par -1 */
    mul r0,r2,r4
0:    
    mov r4,#10   /* longueur de la zone */
    mov r2,r0    /* nombre de départ des divisions successives */
    mov r1,#10   /* conversion decimale */
1:    /* debut de boucle de conversion */
    mov r0,r2    /* copie nombre départ ou quotients successifs */
    bl division /* division par le facteur de conversion */
    add r3,#48   /* car c'est un chiffre */    
    strb r3,[r5,r4]  /* stockage du byte en début de zone r5 + la position r4 */
    sub r4,r4,#1   /* position précedente */
    cmp r2,#0      /* arret si quotient est égale à zero */
    bne 1b    
    /* stockage du signe à la position courante */
    strb r6,[r5,r4] 
    subs r4,r4,#1   /* position précedente */
    blt  100f         /* si r4 < 0  fin  */
    /* sinon il faut completer le debut de la zone avec des blancs */
    mov r3,#' '   /* caractere espace */    
2:    
    strb r3,[r5,r4]  /* stockage du byte  */
    subs r4,r4,#1   /* position précedente */
    bge 2b        /* boucle si r4 plus grand ou egal a zero */
100:  /* fin standard de la fonction  */
       pop {r0,r1,r2,r3,r4,r5,r6,r7}   /*restaur des autres registres */
       pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr  
/******************************************************************/
/*     Conversion d'une chaine en nombre stocké dans un registre  */ 
/******************************************************************/
/* r0 contient l'adresse de la zone terminée par 0 ou 0A */
conversionAtoD:             @ fonction
    push {fp,lr}    /* save des  2 registres */ 
    push {r1-r7}    /* save des autres registres */
    mov r1,#0
    mov r2,#10   /* facteur */
    mov r3,#0  /* compteur */
    mov r4,r0  /* save de l'adresse dans r4 */
    mov r6,#0   /* signe positif par defaut */
    mov r0,#0  /* initialisation à 0 */ 
1:     /* boucle d'élimination des blancs du debut */
    ldrb r5,[r4,r3]  /* chargement dans r5 de l'octet situé au debut + la position */
    cmp r5,#0       /* fin de chaine -> fin routine */
    beq 100f
    cmp r5,#0x0A       /* fin de chaine -> fin routine */
    beq 100f
    cmp r5,#' '        /* blanc au début */
    bne 1f           /* non on continue */
    add r3,r3,#1      /* oui on boucle en avançant d'un octet */
    b 1b
1:
    cmp r5,#'-'       /* premier caracteres est -    */
    moveq r6,#1     /* maj du registre r6 avec 1 */
    beq 3f          /* puis on avance à la position suivante */
2:   /* debut de boucle de traitement des chiffres */
    cmp r5,#'0' /* caractere n'est pas un chiffre */
    blt 3f
    cmp r5,#'9' /* caractere n'est pas un chiffre */
    bgt 3f
    /* caractère est un chiffre */
    sub r5,#48
    ldr r1,iMaxi  /*verifier le dépassement du registre  */  
    cmp r0,r1
    bgt 99f
    mul r0,r2,r0    /* multiplier par facteur */
    add r0,r5    /* ajout à r0 */
3:
    add r3,r3,#1   /* avance à la position suivante */
    ldrb r5,[r4,r3]  /* chargement de l'octet */
    cmp r5,#0        /* fin de chaine -> fin routine */
    beq 4f
    cmp r5,#10    /* fin de chaine -> fin routine */
    beq 4f
    b 2b   /* boucler */ 
4:
    cmp r6,#1  /* test du registre r6 pour le signe */
    bne 100f
    mov r1,#-1
    mul r0,r1,r0  /* si negatif, on multiplie par -1 */
    b 100f
99:  /* erreur de dépassement */
    ldr r1,=szMessErrDep
    bl   afficheerreur 
    mov r0,#0   /* en cas d'erreur on retourne toujours zero */
100:    
    pop {r1-r7}     /* restaur des autres registres */
    pop {fp,lr}    /* restaur des  2 registres */ 
    bx lr            /* retour procedure */    
/* constante programme */    
.align 4    
iMaxi: .int 1073741824    
szMessErrDep:  .asciz  "Nombre trop grand : dépassement de capacite de 32 bits. :\n"
/******************************************************************/
/*     affichage des messages   avec calcul longueur                           */ 
/******************************************************************/
/* r0 contient l'adresse du message */
affichageMess:                 @ fonction
    push {fp,lr}    /* save des  2 registres */ 
    push {r0,r1,r2,r7}    /* save des autres registres */
    mov r2,#0   /* compteur longueur */
1:          /*calcul de la longueur */
    ldrb r1,[r0,r2]  /* recup octet position debut + indice */
    cmp r1,#0       /* si 0 c'est fini */
    beq 1f
    add r2,r2,#1   /* sinon on ajoute 1 */
    b 1b
1:    /* donc ici r2 contient la longueur du message */
    mov r1,r0        /* adresse du message en r1 */
    mov r0,#STDOUT      /* code pour écrire sur la sortie standard Linux */
    mov r7, #WRITE                  /* code de l'appel systeme 'write' */
    swi #0                      /* appel systeme */
    pop {r0,r1,r2,r7}     /* restaur des autres registres */
    pop {fp,lr}    /* restaur des  2 registres */ 
    bx lr            /* retour procedure */
    
/***************************************************/
/*   affichage message d'erreur                   */
/***************************************************/
/* r0 contient le code erreur  r1, l'adresse du message */
afficheerreur:                  @ INFO: afficheerreur
   push {fp,lr}                 @ save des  2 registres frame et retour
   push {r1,r2,r3,r4}           @ save autres registres
   mov r4,r0                    @ save du code erreur
   mov r0,r1
   bl affichageMess
   
                                @ conversion hexa du code retour
    ldr r0,=sHexa               @ adresse de stockage du resultat */
    mov r1,r4
    mov r2,#16                  @ conversion en base 16
    push {r0,r1,r2}             @ parametre de conversion
    bl conversion
                                @ conversion decimale
    ldr r0,=sDeci               @ adresse de stockage du resultat */
    mov r1,r4
    mov r2,#10                  @ conversion en base 10
    push {r0,r1,r2}             @ parametre de conversion
    bl conversion
                                @ affichage du message
    ldr r0,=szMessErr
    bl affichageMess
  
    mov r0,r4                   @ retour du code erreur

100:                            @ fin standard de la fonction
    pop {r1,r2,r3,r4}           @ restaur des autres registres
    pop {fp,lr}                 @ restaur des  2 registres frame et retour
    bx lr                       @ retour de la fonction en utilisant lr
/******************************************************************/
/*     Conversion d'un registre en décimal                                 */ 
/******************************************************************/
/* r0 contient la valeur et r1 l' adresse de la zone de stockage   */
conversion10:                @ fonction
    push {fp,lr}    /* save des  2 registres */ 
    push {r1,r2,r3,r4,r5,r6}  /* save des registres */
    mov r5,r1
    mov r4,#10
    mov r2,r0
    mov r1,#10   /* conversion decimale */
1:    /* debut de boucle de conversion */
    mov r0,r2    /* copie nombre départ ou quotients successifs */
    bl division /* division par le facteur de conversion */
    add r3,#48   /* car c'est un chiffre */    
    strb r3,[r5,r4]  /* stockage du byte au debut zone (r5) + la position (r4) */
    sub r4,r4,#1   /* position précedente */
    cmp r2,#0      /* arret si quotient est égale à zero */
    bne 1b    
    /* mais il faut completer le debut de la zone avec des blancs */
    mov r3,#' '   /* caractere espace */    
2:    
    strb r3,[r5,r4]  /* stockage du byte  */
    subs r4,r4,#1   /* position précedente */
    bge 2b        /* boucle si r4 plus grand ou egal a zero */
    
100:    
    pop {r1,r2,r3,r4,r5,r6}    /* restaur des autres registres */
    pop {fp,lr}    /* restaur des  2 registres */ 
    bx lr            /* retour procedure */        
/********************************************************/
/* Lancement du chrono                                  */
/********************************************************/
debutChrono:                @ fonction
    push {fp,lr}    /* save des  2 registres frame et retour */
    push {r0,r1,r7,r8}
      ldr r0,=dwDebut   @ zone de reception du temps début
    mov r1,#0
    mov r7, #0x4e  @ test appel systeme gettimeofday
    swi #0 
    cmp r0,#0        @ verification si l'appel est OK
    bge 100f
   /* affichage erreur */
    ldr r1,=szMessErreurCH   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */        
100:   
   /* fin standard  de la fonction  */
    pop {r0,r1,r7,r8}
    pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */     
szMessErreurCH: .asciz "Erreur debut Chrono rencontrée.\n"
.align 4     
/********************************************************/
/* r0 rouge r1 vert  r2 bleu */
/* r0 retourne le code RGB  */
stopChrono:                   @ fonction
    push {fp,lr}    /* save des  2 registres frame et retour */
    push {r0-r7}
    ldr r0,=dwFin   @ zone de reception du temps fin
    mov r1,#0
    mov r7, #0x4e @ test appel systeme gettimeofday
    swi #0 
    cmp r0,#0
    blt 99f     @ verification si l'appel est OK
    /* calcul du temps */
    ldr r0,=dwDebut @ zones avant tri
    ldr r2,[r0]        @ secondes
    ldr r3,[r0,#4]       @ micro secondes
    ldr r0,=dwFin      @ zones après tri
    ldr r4,[r0]             @ secondes
    ldr r5,[r0,#4]         @ micro secondes
    sub r2,r4,r2         @ nombre de secondes ecoulées
    subs r3,r5,r3       @ nombre de microsecondes écoulées
    sublt r2,#1        @ si negatif on enleve 1 seconde aux secondes
    ldr r4,iSecMicro
    addlt r3,r4        @ et on ajoute 1000000 pour avoir un nb de microsecondes exact
    mov r0,r2            @ conversion des secondes en base 10 pour l'affichage
    ldr r1,=sSecondes
    bl conversion10
    mov r0,r3            @ conversion des microsecondes en base 10 pour l'affichage
    ldr r1,=sMicroS
    bl conversion10
    ldr r0,=szMessTemps   /* r0 ← adresse du message */
    bl affichageMess  /* affichage message dans console   */
    b 100f
99:    /* erreur rencontree */
    ldr r1,=szMessErreurCHS   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */    
100:   
   /* fin standard  de la fonction  */
    pop {r0-r7}
    pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */     
/* variables */    
iSecMicro:  .int 1000000    
szMessErreurCHS: .asciz "Erreur stop Chrono rencontrée.\n"
.align 4             
/********************************************************/
/* racine carree double precision           */
/* r0 nombre  */
/* ro retourne le résultat */
racinecarreeDP:               @ fonction
    push {fp,lr}    /* save des  2 registres frame et retour */    
    vmov s1, r0          /* copie de R0 dans s1*/
    vcvt.f64.s32 d1, s1 /* conversion en flottant double précision dans le registre d1 */
    vsqrt.f64 d3,d1     /* racine carree */
    vcvt.s32.f64 s0, d3 /* conversion du resultat en simple précision */
    vmov r0,s0            /* recup résultat  dans r0*/
    pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */     
/********************************************************/
/* division double precision           */
/* r0 dividende  */
/* r1 diviseur  */
/* ro retourne le quotient */
/* r1 retourne le reste  */
divisionDP:                 @ fonction
    push {r2,lr}    /* save des  2 registres r2 et retour */    
    vmov s1, r0          /* copie de r0 dans s1*/
    vcvt.f64.u32 d1, s1 /* conversion en flottant double précision */
    vmov s4, r1         /* copie de r1 dans s2  */
    vcvt.f64.u32 d3, s4 /* conversion en flottant double précision */
    vdiv.f64 d4,d1,d3   /* division */
    vcvt.s32.f64 s0, d4 /* conversion résultat en simple précision */
    vmov r2,s0            /* recup résultat */
    mul r1,r2,r1            /* calcul du reste car instruction vlms non admise */
    sub r1,r0,r1
    mov r0,r2
   pop {r2,lr}   /* restaur des  2 registres r2 et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */         
/***************************************************/
/*   affichage des drapeaux du registre d'état     */
/***************************************************/
affichetat:                 @ fonction
    push {fp,lr}    /* save des  2 registres frame et retour */
    push {r0,r1,r2}   /* save autres registres */
    mrs r2,cpsr  /* save du registre d'état  dans r2 */
    ldr r1,=szLigneEtat
    beq 1f       @ flag zero à 1
    mov r0,#48
    strb r0,[r1,#11]
    b 2f
1:    
    mov r0,#49       @ Zero à 1
    strb r0,[r1,#11]
2:    
    bmi 3f          @ Flag negatif a 1
    mov r0,#48
    strb r0,[r1,#16]
    b 4f
3:    
    mov r0,#49
    strb r0,[r1,#16]
4:        
    bvs 5f         @ flag overflow à 1 ?
    mov r0,#48
    strb r0,[r1,#26]
    b 6f
5:                  @ overflow = 1
    mov r0,#49
    strb r0,[r1,#26]
6:        
    bcs 7f         @ flag carry à 1 ?
    mov r0,#48
    strb r0,[r1,#21]
    b 8f
7:                  @ carry = 1
    mov r0,#49
    strb r0,[r1,#21]
8:        
    ldr r0,=szLigneEtat  @ affiche le résultat
    bl affichageMess 
 
100:   
   /* fin standard de la fonction  */
    msr cpsr,r2    /*restaur registre d'état */
       pop {r0,r1,r2}   /*restaur des autres registres */
       pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */
/***************************************************/
/*   Génération nombre aleatoire                  */
/***************************************************/
/* r0 plage fin  */
genereraleas:              @ fonction
   push {fp,lr}    /* save des  2 registres frame et retour */
   //add fp,sp,#8    /* fp <- adresse début */
   push {r1,r2,r3,r4}   /* save autres registres en nombre pair */
   mov r4,r0  @ save plage
   ldr r0,=iGraine
   ldr r0,[r0]
   ldr r1,iNombre1
   mul r0,r1
   add r0,#1
   ldr r1,=iGraine
   str r0,[r1]
   //bl vidtousregistres
   @ prise en compte nouvelle graine
   ldr r1,m   @ diviseur pour registre de 32 bits
   bl division
   mov r0,r3   @ division du reste
   ldr r1,m1   @ diviseur  10000
   bl division
   mul r0,r2,r4   @ on multiplie le quotient par la plage demandéé
   //mov r6,r0
   ldr r1,m1   @ puis on divise le resultat diviseur
   bl division  @ pour garder les chiffres à gauche significatif.
   mov r0,r2    @ retour du quotient
  
100:   
   /* fin standard de la fonction  */
       pop {r1,r2,r3,r4}   /*restaur des autres registres */
       pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */    
/*******************CONSTANTES****************************************/
iNombre1: .int 31415821
m1:  .int 10000
m:   .int 100000000 

.align 4     /* alignement car l'étiquette de la routine suivante doit être alignée */    
/***************************************************/
/*   Concatenation de 2 chaines                    */
/***************************************************/
/* r0 chaine 1 */
/* r1 chaine 2 */
/* r2 buffer de reception */
/* retourne la longueur sans le 0 final dans r0 */
concatChaine:               @ fonction
   push {r1,r2,r3,r4,r5}   /* save autres registres en nombre pair */
       mov r3,#0
    mov r5,#0
    /* boucle de copie des caractères */
1:                      /* label local */
    ldrb r4,[r0,r3]
    cmp r4,#0
    beq 2f         /* saut au label 2 forward */ 
    strb r4,[r2,r3]
    add r3,#1
    b 1b         /* saut au label 1 backward */

2:
    ldrb r4,[r1,r5]
    strb r4,[r2,r3]
    cmp r4,#0
    moveq r0,r3     @ retourne la longueur sans le 0 final
    beq 100f
    add r3,#1
    add r5,#1
    b 2b         /* saut au label 1 backward */

100:   
   /* fin standard de la fonction  */
       pop {r1,r2,r3,r4,r5}   /*restaur des autres registres */
    bx lr                   /* retour de la fonction en utilisant lr  */
/************************************/       
/* comparaison de chaines           */
/************************************/      
/* r0 et r1 contiennent les adresses des chaines */
/* retour 0 dans r0 si egalite */
/* retour -1 si chaine r0 < chaine r1 */
/* retour 1  si chaine r0> chaine r1 */
comparaison:              @ fonction
    //push {fp,lr}    /* save des  2 registres */
    push {r1-r4}  /* save des registres */
    mov r2,#0   /* indice */
1:    
    ldrb r3,[r0,r2]   /* octet chaine 1 */
    ldrb r4,[r1,r2]   /* octet chaine 2 */
    cmp r3,r4
    movlt r0,#-1     /* plus petite */     
    movgt r0,#1     /* plus grande */     
    bne 100f     /* pas egaux */
    cmp r3,#0   /* 0 final */
    moveq r0,#0    /* egalite */     
    beq 100f     /* c'est la fin */
    add r2,r2,#1 /* sinon plus 1 dans indice */
    b 1b         /* et boucle */
100:
    pop {r1-r4}
    //pop {fp,lr}   /* fin procedure */
    bx lr       
/********************************************************/
/**************************************************/
/*     vidage de tous les registres               */
/**************************************************/
/* argument pile : adresse du libelle a afficher */
affregistres:               @ fonction
    push {fp,lr}    /* save des  2 registres */
    add fp,sp,#8    /* fp <- adresse début */
    push {r0,r1,r2,r3} /* save des registres pour restaur finale en fin */ 
    push {r0,r1,r2,r3} /* save des registres avant leur vidage */ 
    ldr r1,[fp]
    mov r2,#0
    ldr r0,adresse_adresseLib /*adresse de stockage du resultat */
1: @ boucle copie
    ldrb r3,[r1,r2]
    cmp r3,#0
    strneb r3,[r0,r2]
    addne r2,#1
    bne 1b
    mov r3,#' '
2:
    strb r3,[r0,r2]
    add r2,#1
    cmp r2,#LGZONEADR
    blt 2b
    /* contenu registre */
    ldr r0,adresse_reg0 /*adresse de stockage du resultat */
    pop {r1}
    mov r2,#16
    push {r0,r1,r2}    
    bl conversion
    ldr r0,adresse_reg1 /*adresse de stockage du resultat */
    pop {r1}
    mov r2,#16
    push {r0,r1,r2}    
    bl conversion
    ldr r0,adresse_reg2 /*adresse de stockage du resultat */
    pop {r1}
    mov r2,#16
    push {r0,r1,r2}    
    bl conversion
    ldr r0,adresse_reg3 /*adresse de stockage du resultat */
    pop {r1}
    mov r2,#16
    push {r0,r1,r2}    
    bl conversion
    ldr r0,adresse_reg4 /*adresse de stockage du resultat */
    mov r1,r4
    mov r2,#16
    push {r0,r1,r2}    
    bl conversion
    ldr r0,adresse_reg5 /*adresse de stockage du resultat */
    mov r1,r5
    mov r2,#16
    push {r0,r1,r2}    
    bl conversion
    ldr r0,adresse_reg6 /*adresse de stockage du resultat */
    mov r1,r6
    mov r2,#16
    push {r0,r1,r2}    
    bl conversion
    ldr r0,adresse_reg7 /*adresse de stockage du resultat */
    mov r1,r7
    mov r2,#16
    push {r0,r1,r2}    
    bl conversion
    ldr r0,adresse_reg8 /*adresse de stockage du resultat */
    mov r1,r8
    mov r2,#16
    push {r0,r1,r2}    
    bl conversion
    ldr r0,adresse_reg9 /*adresse de stockage du resultat */
    mov r1,r9
    mov r2,#16
    push {r0,r1,r2}    
    bl conversion
    ldr r0,adresse_reg10 /*adresse de stockage du resultat */
    mov r1,r10
    mov r2,#16
    push {r0,r1,r2}    
    bl conversion
    /* r11 = fr  frame register sauvegarde en debut de fonction */
    ldr r0,adresse_reg11 /*adresse de stockage du resultat */
    sub r1,fp,#8
    ldr r1,[r1]
    mov r2,#16
    push {r0,r1,r2}    
    bl conversion
    ldr r0,adresse_reg12 /*adresse de stockage du resultat */
    mov r1,r12
    mov r2,#16
    push {r0,r1,r2}    
    bl conversion
    /* r13 = sp   et est egale au fp actuel  */
    ldr r0,adresse_reg13 /*adresse de stockage du resultat */
    //pop {r1}
    mov r1,fp
    mov r2,#16
    push {r0,r1,r2}    
    bl conversion
    /* r14 = lr   adresse du retour  sauvegardé au début */
    /* mais c'est l'adresse de retour du programme appelant  */
    /* et donc qui est ecrase par l'appel de cette procedure */
    /* pour connaitre la valeur exacte il faur utiliser vidregistre */
    /* en vidant le contenu de lr */

    /* r15 = pc  donc contenu = adresse de retour (lr) - 4 */
    ldr r0,adresse_reg15 /*adresse de stockage du resultat */
    sub r1,fp,#4
    ldr r1,[r1]
    sub r1,#4
    mov r2,#16
    push {r0,r1,r2}    
    bl conversion
    /* affichage resultats */
    ldr r0, adresse_chaineReg   /* r0 ← adresse chaine */
    mov r1,#-1  /*pour calcul longueur */
    push {r0,r1}
    bl affichage  /*appel procedure  */

    /* fin fonction */
    pop {r0,r1,r2,r3}
    pop {fp,lr}   /* restaur des  2 registres */
    add sp,#4     /* pour liberer la pile du push 1 argument */
    bx lr                            /* return from main using lr */

adresse_chaineReg : .word szVidregistreReg
adresse_adresseLib: .word adresseLib 
adresse_reg0: .word reg0
adresse_reg1: .word reg1
adresse_reg2: .word reg2
adresse_reg3: .word reg3
adresse_reg4: .word reg4
adresse_reg5: .word reg5
adresse_reg6: .word reg6
adresse_reg7: .word reg7
adresse_reg8: .word reg8
adresse_reg9: .word reg9
adresse_reg10: .word reg10
adresse_reg11: .word reg11
adresse_reg12: .word reg12
adresse_reg13: .word reg13
//adresse_reg14: .word reg14
adresse_reg15: .word reg15

/************************************/       
/* allocation de place sur le tas           */
/************************************/      
/* r0 contient la taille en octets à allouer  */
/* retour adresse debut dans r0 si ok */
/* retour -1 si erreur d'allocation */
allocPlace:      @ fonction
    push {r1,lr}    /* save des  2 registres */
    push {r2,r7}  /* save des registres */
    mov r2,r0
    mov r0,#0      /* recuperation de l'adresse du tas */
    mov r7, #0x2D                  /* code de l'appel systeme 'brk' */
    swi #0                      /* appel systeme */
    mov r1,r0       @ save du début
    add r0,r2                  @ reservation place demandé
    mov r7, #0x2D                  /* code de l'appel systeme 'brk' */
    swi #0                      /* appel systeme */
    cmp r0,#-1       @ erreur allocation
    beq 100f
    mov r0,r1    @ retour adresse début 
100:
    pop {r2,r7}
    pop {r1,lr}   /* fin procedure */
    bx lr   
/******************************************************************/
/*     insertion d'une sous-chaine dans une chaine en position souhaitée*/ 
/******************************************************************/
/* r0 contains the address of string 1 */
/* r1 contains the address of string to insert */
/* r2 contains the position of insertion : 
      0 start string 
      if r2 > lenght string 1 insert at end of string*/
/* r0 return the address of new string  on the heap */
strInsert:     @ fonction
    push {r1-r7,lr}                          @ save  registres
    mov r3,#0                                @ length counter 
1:                                           @ compute length of string 1
    ldrb r4,[r0,r3]
    cmp r4,#0
    addne r3,#1
    bne 1b
    mov r5,#0                                @ length counter 
2:
    ldrb r4,[r1,r5]
    cmp r4,#0
    addne r5,#1
    bne 2b
    cmp r5,#0
    moveq r0,#-1
    beq 100f
    add r3,r5                                @ add 2 length
    add r3,#1                                @ +1 for final zero
    mov r6,r0                                @ save address string 1
    mov r0,#0                                @ allocation place heap
    mov r7,#0x2D                             @ call system 'brk'
    svc #0
    mov r5,r0                                @ save address heap for output string
    add r0,r3                                @ reservation place r3 length
    mov r7,#0x2D                             @ call system 'brk'
    svc #0
    cmp r0,#-1                               @ allocation error
    beq 100f
    @
    mov r7,#0                                @ index load characters string 1
    cmp r2,#0                                @ index insertion = 0
    beq 5f                                   @ insertion at string 1 begin
3:                                           @ loop copy characters string 1
    ldrb r0,[r6,r7]                          @ load character
    cmp r0,#0                                @ end string ?
    beq 5f                                   @ insertion at end
    strb r0,[r5,r7]                          @ store character in output string
    add r7,#1                                @ increment index
    cmp r7,r2                                @ < insertion index ?
    blt 3b                                   @ yes -> loop
5:
    mov r4,r7                                @ init index character output string
    mov r3,#0                                @ index load characters insertion string
6:
    ldrb r0,[r1,r3]                          @ load characters insertion string
    cmp r0,#0                                @ end string ?
    beq 7f
    strb r0,[r5,r4]                          @ store in output string
    add r3,#1                                @ increment index
    add r4,#1                                @ increment output index
    b 6b                                     @ and loop
7:
    ldrb r0,[r6,r7]                          @ load other character string 1
    strb r0,[r5,r4]                          @ store in output string
    cmp r0,#0                                @ end string 1 ?
    beq 8f                                   @ yes -> end
    add r4,#1                                @ increment output index
    add r7,#1                                @ increment index
    b 7b                                     @ and loop
8:
    mov r0,r5                                @ return output string address 
100:
    pop {r1-r7,lr}                           @ restaur des registres */ 
    bx lr                                    @ return  
/************************************/       
/* raz d'un libellé (voir macros)   */
/************************************/      
/* r0 contient l'adresse  */
razLibel:       @ fonction
    push {r1,r2,lr}    /* save des  2 registres */
    //bl vidtousregistres
    mov r1,#0
1:
    strb r1,[r0],#1
    ldrb r2,[r0]
    cmp r2,#0
    bne 1b
    //bl vidtousregistres
100:
    pop {r1,r2,lr}   /* fin procedure */
    bx lr   
/******************************************************************/
/*     register display in binary                              */ 
/******************************************************************/
/* r0 contains the register */
/* sur la pile le libelle à afficher */
affichageReg2:                   @ INFO: affichageReg2
    push {fp,lr}                 @ save  registers
    add fp,sp,#8                 @ fp <- adresse début
    push {r0-r4}                 @ save others registers
    ldr r1,[fp]                  @ load label address
    mov r4,r0                    @ save register
    mov r2,#0
    ldr r0,iAdradresseLibBin     @ adresse de stockage du resultat
1: @ boucle copie
    ldrb r3,[r1,r2]
    cmp r3,#0
    strneb r3,[r0,r2]
    addne r2,#1
    bne 1b
    mov r3,#' '
2:
    strb r3,[r0,r2]
    add r2,#1
    cmp r2,#LGZONEADR
    blt 2b
    ldr r1,iAdrsZoneBin
    mov r0,r4               @ restaur register
    mov r2,#0               @ read bit position counter
    mov r3,#0               @ position counter of the written character
3:                         @ loop 
    lsls r0,#1            @ left shift  with flags
    movcc r4,#48          @ flag carry off   character '0'
    movcs r4,#49          @ flag carry on    character '1'
    strb r4,[r1,r3]       @ character ->   display zone
    add r2,r2,#1           @ + 1 read bit position counter
    add r3,r3,#1           @ + 1 position counter of the written character
    cmp r2,#8              @ 8 bits read
    addeq r3,r3,#1        @ + 1 position counter of the written character
    cmp r2,#16             @ etc
    addeq r3,r3,#1
    cmp r2,#24
    addeq r3,r3,#1
    cmp r2,#31            @ 32 bits shifted ?
    ble 3b               @  no -> loop

    ldr r0,iAdrsZoneMessBin   @ address of message result
    bl affichageMess           @ display result
   // ldr r0,iAdrsZoneMessBin  
   // vidmemtit binaire r0 4
100:
    pop {r0-r4}                  @ restaur others registers
    pop {fp,lr}
    add sp,#4                 @ pour liberer la pile du push 1 argument
    bx lr    
iAdrsZoneBin:           .int sZoneBin       
iAdrsZoneMessBin:      .int sMessAffBin
iAdradresseLibBin:     .int adresseLibBin
/******************************************************************/
/*   insert string at character insertion                         */ 
/******************************************************************/
/* r0 contains the address of string 1 */
/* r1 contains the address of insertion string   */
/* r0 return the address of new string  on the heap */
/* or -1 if error   */
strInsertAtChar:
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
    mov r0,#0                                // allocation place heap
    mov r7,#BRK                               // call system 'brk' 
    svc #0
    mov r5,r0                                // save address heap for output string
    add r0,r0,r3                             // reservation place r3 length
    mov r7,#BRK                               // call system 'brk'
    svc #0
    cmp r0,#-1                               // allocation error
    beq 99f
 
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
    bx lr                                   @ return  
    