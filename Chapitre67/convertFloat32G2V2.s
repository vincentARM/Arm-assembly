/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* modèle B 512MO   */
/*  */
/* conversion Float grisu 2   32 bits  */
/* avec table reconstituée */ 
/* et formatage du résultat */
/* voir le document pdf de Florian Loitsch  */
/* https://www.cs.tufts.edu/~nr/cs257/archive/florian-loitsch/printf.pdf */
/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/
.equ BIAS,     1075
.equ NBPOSTESTABLE, 87
.equ EXP10MINI,  -348
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
    .struct  diy_fp_f + 8
diy_fp_e:                         // exposant
    .struct  diy_fp_e + 4
diy_fp_fin: 
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessDebutPgm:      .asciz "Début du programme. \n"
szMessErreur:        .asciz "Erreur rencontrée.\n"
szMessFinOK:         .asciz "Fin normale du programme. \n"
szMessErrSous:       .asciz "Erreur lors de la soustraction.\n"
.equ LGMESSERRSOUS,          . - szMessErrSous
szMessErrGener:      .asciz "Erreur lors de la génération des chiffres. \n"
szRetourligne:       .asciz  "\n"


.align 4
//dfTest1:                      .double 0f314159265358979323E-17
dfTest2:                      .double 0f7E-324     // valeur minimum 
dfTest1:                   .double 0F12345678912345678
//dfTest1:                   .double 0F-0.3
dfTest3:                   .double 0F1.7976E308    // valeur maximun
.include "table10Reorg.inc"
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
//diyFP:      .skip diy_fp_fin
//diyResult:  .skip diy_fp_fin
sBuffer:    .skip 500 

/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text            
.global main                    @ main point d entrée doit être  global 

main:                           @ programme principal 
    push {fp,lr}                @ save des  registres 
    ldr r0,iAdrszMessDebutPgm   @ r0 ← adresse message debut 
    bl affichageMess            @ affichage message dans console   

    ldr r0,iAdrdfTest1
    vidmemtit debut r0 2
    vldr d0,[r0]
    ldr r0,iAdrsBuffer
    bl convertirFloat
    ldr r0,iAdrsBuffer
    bl affichageMess      
    ldr r0,iAdrszRetourligne
    bl affichageMess
                              // test valeur mini
    ldr r0,iAdrdfTest2
    vidmemtit debut r0 2
    vldr d0,[r0]
    ldr r0,iAdrsBuffer
    bl convertirFloat
    ldr r0,iAdrsBuffer
    bl affichageMess      
    ldr r0,iAdrszRetourligne
    bl affichageMess
                             // test valeur maxi
    ldr r0,iAdrdfTest3
    vidmemtit debut r0 2
    vldr d0,[r0]
    ldr r0,iAdrsBuffer
    bl convertirFloat
    ldr r0,iAdrsBuffer
    bl affichageMess      
    ldr r0,iAdrszRetourligne
    bl affichageMess
    // test zero
    mov r0,#0
    vmov s0,r0
    vmov s1,r0
    ldr r0,iAdrsBuffer
    bl convertirFloat
    ldr r0,iAdrsBuffer
    bl affichageMess      
    ldr r0,iAdrszRetourligne
    bl affichageMess
                                  // test infini
    mov r0,#0
    vmov s0,r0
    ldr r1,iMaskExposant
    vmov s1,r1
    ldr r0,iAdrsBuffer
    bl convertirFloat
    ldr r0,iAdrsBuffer
    bl affichageMess      
    ldr r0,iAdrszRetourligne
    bl affichageMess
                                   // test NAN
    mov r0,#0
    vmov s0,r0
    ldr r1,iConstNAN
    vmov s1,r1
    ldr r0,iAdrsBuffer
    bl convertirFloat
    ldr r0,iAdrsBuffer
    bl affichageMess      
    ldr r0,iAdrszRetourligne
    bl affichageMess

98:
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
iAdrszRetourligne:      .int szRetourligne
//iAdrdiyFP:              .int diyFP
iAdrdfTest1:            .int dfTest1
iAdrdfTest2:            .int dfTest2
iAdrdfTest3:            .int dfTest3
iAdrsBuffer:            .int sBuffer
iAdrTablePuis10Norm32:  .int TablePuis10Norm32P8
//iAdrdiyResult:          .int diyResult
iConstNAN:              .int 0xFFF80000
/***************************************************/
/*   conversionFloat                               */
/***************************************************/
/* d0 contient la valeur à afficher */
/* r0 contient l'adresse du buffer de reception 30 caractères mini*/
convertirFloat:          @ INFO: convertirFloat
    push {fp,lr}        @ save des registres
    mov r12,r0          @ save adresse buffer
    vmov r0,s0
    vmov r1,s1
    mov r10,#0          @ signe +
    tst r1,#1<<31
    beq 1f
    mov r10,#1          @ signe -
    mov r2,#'-'
    strb r2,[r12]
1:
    lsl r2,r1,#1          @ elimine le signe
    cmp r2,#0
    bne 2f
    cmp r0,#0
    bne 2f
    mov r2,#'0'         @ cas du zéro  (- ou +)
    str r2,[r12,r10]
    add r0,r10,#1
    b  100f
2:
    ldr r2,iMaskExposant
    tst r1,r2           // exposant à zéro ?
    beq 3f
    cmp r10,#0
    beq 3f
    tst r1,#1<<19
    beq 3f
    ldr r2,iAffNan
    str r2,[r12,r10]
    add r0,r10,#3
    b  100f
3:
    ldr r2,iMaskExposant
    and r2,r1        // infini ?
    lsr r2,r2,#20
    ldr r3,iMaskExpDr
    cmp r2,r3
    bne 4f
    ldr r2,iAffInf             // affichage infini + ou -
    str r2,[r12,r10]
    add r0,r10,#3
    b  100f
4:
    sub sp,#128              // reserve zones sur la pile
    mov fp,sp                @ zones fp
    .equ MINI,          diy_fp_fin
    .equ MAXI,          diy_fp_fin * 2
    .equ DELTA,         diy_fp_fin * 3
    .equ BUFFER,        diy_fp_fin * 4
    mov r0,#0               // init des zones
    str r0,[fp,#BUFFER]
    str r0,[fp,#BUFFER+4]
    str r0,[fp,#BUFFER+8]
    str r0,[fp,#BUFFER+12]
    str r0,[fp,#BUFFER+16]
    mov r0,fp               // convertit le float dans la structure adéquate
    bl convertirDiy_fp
    mov r0,fp
    //vidmemtit conversion r0 2
    mov r0,fp
    add r1,fp,#MINI
    add r2,fp,#MAXI
    bl calculerLimites
    mov r0,fp
    bl normaliserDiy_fp     // normalisation du nombre
    mov r0,fp
    //vidmemtit normaliser r0 4
    add r2,fp,#MAXI
    ldr r6,[r2,#diy_fp_e]      @ charge l exposant MAXI
    mov r0,r6
    mov r1,#0                  @ alpha
    bl calculerK
    //vidregtit retourK
    ldr r5,iExpoMini
    sub r4,r0,r5                 // calcul index
    asr r4,r4,#3                 // division par pas de 8
    mov r2,#diy_fp_fin
    ldr r3,iAdrTablePuis10Norm32
5:                              // boucle de recherche de la puissance de 10 normalisée
    mul r0,r4,r2                // calcul déplacement dans table
    add r1,r3,r0                // contient l adresse de la puissance de 10
    //vidregtit bouclerecherche 
    ldr r5,[r1,#diy_fp_e]       // chargement de l'exposant trouvé
    add r5,r5,r6                // + exposant maxi
    add r5,r5,#64
    cmp r5,#-60                 // recherche de l exposant dans la fourchette -59 -32
    bgt 6f
    add r4,r4,#1
    b 5b                        // sinon boucle
6:
    cmp r5,#-32
    ble 7f
    sub r4,r4,#1
    b 5b                        //  sinon boucle
7:
    lsl r0,r4,#3                // mul index par le pas de  8
    ldr r5,iExpoMini
    add r9,r0,r5                // ajout première puissance pour coefficient
                                // ici r1 contient l'adresse de la puissance de 10 dans la table
    //vidmemtit table r1 2
                               // multiplication FP
    mov r0,fp
    mov r2,fp
    bl multiplier
    //mov r0,fp
    //vidmemtit multiplier r0 4
                                   // multiplication mini
    add r0,fp,#MINI
    add r2,fp,#MINI
    bl multiplier
    ldm r2,{r3,r4}             @ charge le significant dans r1 r2
    adds r3,#1                 // mini + 1
    adc r4,#0
    stm r2,{r3,r4} 
    //mov r0,r2
    //vidmemtit multMINI r0 4
    
    add r0,fp,#MAXI
    add r2,fp,#MAXI
    bl multiplier
    ldm r2,{r3,r4}          @ charge le significant dans r1 r2
    subs r3,#1              // maxi - 1
    sbc r4,#0
    stm r2,{r3,r4} 
    //mov r0,r2
    //vidmemtit multMAXI r0 4
    add r0,fp,#MAXI
    add r1,fp,#MINI
    add r2,fp,#DELTA
    bl calculerDelta
    //add r0,fp,#DELTA
    //vidmemtit DELTA r0 2
    add r0,fp,#MAXI
    add r1,fp,#DELTA
    add r2,fp,#BUFFER
    mvn r3,r9               // inversion K
    add r3,#1
    bl genererChiffres
    //vidregtit retourGenerer
    mov r3,r0                 @ exposant retourné
    add r0,fp,#BUFFER         @ adresse zone chiffre 
    //vidmemtit retourGener r0 3
    mov r2,r12                @ adresse buffer
    mov r4,r10                @ signe
    bl formaterChiffres
90:
    add sp,#128               @ alignement pile
100:                          @ fin standard de la fonction
    pop {fp,lr}               @ restaur des registres 
    bx lr                     @ retour de la fonction en utilisant lr
iExpoMini:      .int EXP10MINI
iAffNan:        .int 0x006E614E
iAffInf:        .int 0x00666E49
iMaskExpDr:     .int 0x7FF
/***************************************************/
/*   conversion float               */
/***************************************************/
/* d0 contient le float double précision */
/* r0 contient l'adresse de la structure de reception */
convertirDiy_fp:             @ INFO: convertirDiy_fp
    push {r1-r5,lr}          @ save des registres
    vmov r1,r2,d0            @ r1 ← Lower32BitsOf(d0) r2 ← Higher32BitsOf(d0)
    ldr r5,iMaskMantisse
    and r3,r2,r5             @ extraction de la mantisse
    ldr r5,iMaskExposant     @ 
    and r4,r2,r5             @ extraction de l exposant
    ldr r5,iBias
    lsrs r4,#20
    bne 1f
    mov r4,#1
    sub r4,r4,r5             @ exposant =1 moins le biais
    b 2f
1:
    sub r4,r4,r5             @ sinon exposant = exposant moins le biais
    orr r3,#1<<20            @ et remise à 1 du bit supprimé (cf norme IEEE754)
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
/*   calcul limite mini maxi               */
/***************************************************/
/* r0 contient l'adresse de la structure du nombre */
/* r1 contient l'adresse de la structure limite MINI */
/* r2 contient l'adresse de la structure limite MAXI */
calculerLimites:             @ INFO: calculerLimites
    push {r3-r11,lr}         @ save des registres
    ldm r0,{r3,r4}           @ charge le significant dans r1 r2
    lsl r6,r4,#1
    lsls r5,r3,#1
    orrcs r6,#1              @ significant MAXI partie haute
    add r5,r5,#1             @ significant MAXI partie basse
    ldr r7,[r0,#diy_fp_e]
    sub r7,r7,#1             @ exposant MAXI
1:                           @ normalisation MAXI
    tst r6,#1<<23
    beq 2f
    lsl r6,#1
    lsls r5,#1
    orrcs r6,#1
    sub r7,#1
    b 1b
2:
    lsl r6,#10
    ldr r8,iMaskDeb
    and r9,r5,r8
    lsr r9,#22
    orr r6,r9                @ significant MAXI partie haute
    
    lsl r5,#10               @ significant MAXI partie basse
    sub r7,#10               @ exposant MAXI
    stm r2,{r5,r6}           @ stocke significant maxi
    str r7,[r2,#diy_fp_e]    @ stocke exposant maxi
    
    tst r4,#1<<22            @ tst du bit 22 partie haute du nombre
    bne 3f
    lsl r10,r4,#1            @ déplacement à gauche de 1
    lsls r9,r3,#1            @ significant MINI partie basse
    orrcs r10,#1             @ significant MINI partie haute
    subs r9,#1
    sbc  r10,#0
    ldr r11,[r0,#diy_fp_e]
    sub r11,r11,#1           @ exposant MINI - 1
    b 4f
3:
    lsl r10,r4,#1            @ deplacement à gauche de 2
    lsls r9,r3,#1            @ significant MINI partie basse
    orrcs r10,#1             @ significant MINI partie haute
    lsl r10,r10,#1
    lsls r9,r9,#1            @ significant MINI partie basse
    orrcs r10,#1             @ significant MINI partie haute
    subs r9,#1
    sbc  r10,#0
    ldr r11,[r0,#diy_fp_e]
    sub r11,r11,#2           @ exposant MINI - 2
4:    
    sub r11,r11,r7
5:
    lsl r10,#1               @ significant MINI partie haute
    lsls r9,#1               @ significant MINI partie basse
    orrcs r10,#1             @ significant MINI partie haute
    subs r11,#1
    bgt 5b
    //vidregtit MINI2
    stm r1,{r9,r10}          @ stocke significant MINI 
    str r7,[r1,#diy_fp_e]    @ stocke exposant mini = maxi
100:                         @ fin standard de la fonction
    pop {r3-r11,lr}          @ restaur des registres
    bx lr                    @ retour de la fonction en utilisant lr 
iMaskDeb:     .int 0xFFC<<20
/***************************************************/
/*   normaliser structure float                    */
/***************************************************/
/* r0 contient l'adresse de la structure diy_fp */
normaliserDiy_fp:           @ INFO: normaliserDiy_fp
    push {r1-r5,lr}         @ save des registres
    ldm r0,{r1,r2}          @ charge le significant dans r1 r2
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
    str r3,[r0,#diy_fp_e]
    stm r0,{r1,r2}
100:                       @ fin standard de la fonction
    pop {r1-r5,lr}         @ restaur des registres
    bx lr                  @ retour de la fonction en utilisant lr
//iMask11:     .int 0xFFFFF000
iMask20:     .int 0xFFE<<20
/***************************************************/
/*   calculer l indice pour acces table                    */
/***************************************************/
/* r0 contient l'exposant    */
/* r1 contient le parametre alpha */
calculerK:                  @ INFO: calculerK
    push {r1,lr}            @ save des registres
    vpush {d0,d1}           @ save des registres
    add r0,r0,#NBPOSTESTABLE
    sub r0,r1,r0
    vmov s0,r0
    vcvt.f64.s32 d0, s0 
    vldr d1,D_1
    vmul.f64 d0,d0,d1
    vcvt.s32.f64 s0, d0
    vmov r0,s0
    
100:                       @ fin standard de la fonction
    vpop {d0,d1}           @ restaur des registres float
    pop {r1,lr}            @ restaur des registres
    bx lr                  @ retour de la fonction en utilisant lr
D_1:               .double 0.30102999566398114
/***************************************************/
/*   multiplier 2 nombres                    */
/***************************************************/
/* r0 contient l adresse de la structure premier nombre */
/* r1 contient l adresse de la structure deuxieme nombre */
/* r2 contient l adresse de la structure du résultat  */
multiplier:             @ INFO: multiplier
    push {r1-r12,lr}         @ save des registres
    ldm r0,{r3,r4}          @ charge la mantisse nombre 1 dans r3 r4
    ldm r1,{r5,r6}          @ charge la mantisse nombre 1 dans r5 r6
    umull r7,r8,r3,r5     // db
    umull r9,r10,r4,r5    // da
    umull r11,r12,r3,r6   // cb
    adds  r7,r8, r11          // partie basse
    movcs r11,#1
    movcc r11,#0
    adcs  r7,r7,r9            // partie basse
    adc r11,#0
    adcs  r9,r10,r11
    movcs r7,#1
    movcc r7,#0
    adds r9,r12
    adc r7,#0
    umull r11,r12,r4,r6
    adds r9,r9,r11
    adc r7,#0
    add r12,r7
    stm r2,{r9,r12}
    ldr r3,[r0,#diy_fp_e]
    ldr r4,[r1,#diy_fp_e]
    add r3,r4
    add r3,#64
    str r3,[r2,#diy_fp_e]
100:                    @ fin standard de la fonction
    pop {r1-r12,lr}         @ restaur des registres
    bx lr               @ retour de la fonction en utilisant lr
/******************************************************************/
/*     calcul du delta par soustraction maxi - mini               */ 
/******************************************************************/
/* x0 contient l'adresse de la structure du  premier nombre   */
/* x1 contient l'adresse de la structure du  deuxieme nombre  */
/* x2 contient l'adresse de la structure résultat   */
/* le premier nombre doit être superieur au second */
/* les exposants doivent être egaux */
calculerDelta:
    push {r1-r6,lr}         @ save des registres
    ldr r3,[r0,#diy_fp_e]
    ldr r4,[r1,#diy_fp_e]
    cmp r3,r4               @ les exposants doivent être égaux
    bne 99f
    str r4,[r2,#diy_fp_e]
    ldm r0,{r3,r4}
    ldm r1,{r5,r6}
    cmp r4,r6
    blt 99f                 @ le significant 1er chiffre doit être > au second
    bgt 1f
    cmp r3,r5
    blt 99f   
1:    
    subs r3,r3,r5
    sbc r4,r4,r6
    stm r2,{r3,r4}
    mov r0,r2              // retourne adresse du résultat
    b 100f
99:
    ldr r0,iAdrszMessErrSous     // message erreur
    bl affichageMess
    mov r0,#-1
100:
    pop {r1-r6,lr}         @ restaur des registres
    bx lr                  @ retour de la fonction en utilisant lr

iAdrszMessErrSous:    .int szMessErrSous
/***************************************************/
/*   extraire les chiffres du résultat                   */
/***************************************************/
/* r0 contient l adresse de la structure resultat */
/* r1 contient le delta   */
/* r2 contient l adresse du buffer            */
/* r3 contient le coefficient */
/* r0 retourne K */
/* r1 retourne le nombre de chiffres écrits dans le buffer */
genererChiffres:             @ INFO: genererChiffres
    push {r2-r12,lr}         @ save des registres
    vpush {d0,d1}            @ save des registres
    // r4 = d r5= kappa r6 r7 one frac r8 one exposant
    ldr r8,[r0,#diy_fp_e]     // one exposant
    mvn r9,r8                 // inversion signe
    add r9,#1                 // - one exposant
    cmp r9,#0                 // vérif si coefficient négatif
    bge 1f
    vidregtit CoefNegatif
    b 100f
1:
    cmp r9,#63                // vérification coefficient > 63
    ble 2f
    vidregtit CoefSUPP63
    b 100f
2:
    cmp r9,#31            @ coef > 31
    bgt 3f
    mov r6,#1             @ 1<<r9 partie basse
    lsl r6,r9
    b 4f
3:                        @ calcul one frac
    sub r10,r9,#32
    mov r6,#0
    mov r7,#1
    lsl r7,r10            @ 1<< (r9-31) partie haute
4:
    ldm r0,{r10,r11}      @ charge significant
    mov r5,r9
    mov r4,r11
    mov r12,r10
5:                        // boucle de déplacement à droite 
    lsr r12,#1            // partie 1
    lsrs r4,#1            // ne sert plus ensuite
    orrcs r12,#1<<31
    subs r5,#1
    bgt 5b
                          // ici r12 contient la partie 1
    //vidregtit partie1 
    subs r8,r6,#1             
    sbc  r9,r7,#0         @ frac one - 1
    //vidregtit fracone
    vmov s0,r8           // pour utilisation partie 2
    vmov s1,r9           // sauvegarde des registres dans les registres float
    and r8,r10
    and r9,r11                // partie 2
    //vidregtit partie1et2
    mov r7,#0                @ nb de caractères
    mov r5,#10               @ kappa
    ldr r6,qDix9             @ one frac plus utilisée

6:                           @ debut boucle extraction partie 1
    udiv r4,r12,r6           @ division partie1
    cmp r4,#0
    bne 7f
    cmp r7,#0
    bne 7f
    b 8f
7:                           @ conversion ascii du chiffre
    add r10,r4,#'0'
    strb r10,[r2,r7]
    add r7,r7,#1
8:
    mls r12,r4,r6,r12        @ nouvelle partie 1 = modulo
    sub r5,#1                @ decrement kappa
    mov r10,#10
    udiv r6,r6,r10           @ nouveau diviseur
    mov r4,#0                @ partie haute p1
    vmov s2,r2               @ pas assez de registres on garde r2 et r3  
    vmov s3,r3               @ dans les registres float
    mov r3,r12               @ partie basse p1
    ldr r2,[r0,#diy_fp_e]     // one exposant
    mvn r2,r2
    add r2,#1                // inversion signe exposant
9:                           // boucle deplacement gauche de partie 1
    lsl r4,#1
    lsls r3,#1
    orrcs r4,#1
    subs r2,#1
    bgt 9b
    adds r3,r8               // ajout partie 2
    adc  r4,r9
    ldm r1,{r10,r11}          @ delta
    //vidregtit avantcomp
    cmp r4,r11              // comparaison partie haute
    bhi 11f
    blo 10f
    cmp r3,r10               // partie basse
    bhi 11f
10:
    vmov r2,s2              // remise en place des registres
    vmov r3,s3
    add r0,r3,r5            // retourne K
    mov r1,r7               // nombre de chiffres
    b 100f                  // et fin
11:
    vmov r2,s2              // remise en place des registres
    vmov r3,s3
    cmp r5,#0
    bgt 6b                  // boucle si kappa > 0
    
    // ************ 2ième partie
    mov r10,#10
12:                        // debut de boucle extraction partie 2
    umull r4,r6,r8,r10     // partie 2 * 10
    umull r11,r12,r9,r10
    mov r8,r4
    add r9,r6,r11
    ldr r11,[r0,#diy_fp_e]     // one exposant
    mvn r11,r11
    add r11,#1               // inversion signe exposant
    
    mov r4,r8               //P2 bas
    mov r6,r9               //P2 haut 
13:                         // boucle de calcul de d
    lsr r4,#1
    lsrs r6,#1
    orrcs r4,#1<<31
    subs r11,#1
    bgt 13b

    cmp r7,#0
    bne 14f
    cmp r4,#0
    beq 15f
14:                         // conversion ascii caractère
    add r4,#'0'
    strb r4,[r2,r7]
    add r7,r7,#1
15:
    vmov r4,s0             // utilisation de frac one - 1
    vmov r6,s1
    and r8,r4                @ nouvelle partie 2
    and r9,r6
    sub r5,#1                 @ decrement kappa
    ldm r1,{r4,r6}            @ delta
    umull r11,r12,r4,r10      @ multiplié par 10
    vmov s2,r2                @ pas assez de registres
    vmov s3,r3                @ on sauve r2 r3 dans les registres float
    umull r2,r3,r6,r10
    mov r4,r11
    add r6,r12,r2
    stm r1,{r4,r6}            @  nouveau delta
    vmov r2,s2                @ et on restaure les registres
    vmov r3,s3
    cmp r9,r6
    bhi 12b
    blo 16f
    cmp r8,r4
    bhi 12b
16:
    add r0,r3,r5              @ ajout de kappa à K
    //vidregtit finextract
    mov r1,r7                 @ nombre de chiffres 
100:                          @ fin standard de la fonction
    vpop {d0,d1}              @ restaur des registres Float
    pop {r2-r12,lr}           @ restaur des registres
    bx lr                     @ retour de la fonction en utilisant lr
qDix9:               .int 1000000000
/***************************************************/
/*   formater le résultat                          */
/***************************************************/
/* r0 contient l adresse de la zone chiffres */
/* r1 contient le nombre de chiffres            */
/* r2 contient l adresse du buffer de destination  Mini 30 caractères */
/* r3 contient l exposant */
/* r4 contient 0 si positif 1 si negatif */
/* Remarque si négatif le buffer contient - en premier position */
formaterChiffres:           @ INFO: formaterChiffres
    push {r1-r7,lr}         @ save des registres
    cmp r1,#0               @ erreur si nombre de chiffres = zéro
    ble 99f
    mov r6,#0
1:                          @ boucle copie caractères
    ldrb r7,[r0,r6]
    strb r7,[r2,r4]
    add r4,#1
    add r6,#1
    cmp r6,r1
    blt 1b
    cmp r3,#0              @ exposant = 0 ?
    bne 10f
    mov r7,#0
    strb r7,[r2,r4]
    mov r0,r4
    b 100f
10:                        @ affichage exposant
    mov r7,#'E'
    strb r7,[r2,r4]
    add r4,#1
    
    mov r0,r3
    add r1,r2,r4
    bl conversion10S
    add r4,r0
    mov r7,#0
    strb r7,[r2,r4]
    mov r0,r4
    b 100f
99: 
    ldr r0,iAdrszMessErrGener
    bl affichageMess
    mov r0,#-1
100:                       @ fin standard de la fonction
    pop {r1-r7,lr}         @ restaur des registres
    bx lr                  @ retour de la fonction en utilisant lr
iAdrszMessErrGener:   .int szMessErrGener
/***************************************************/
/*   conversion registre en décimal   signé  */
/***************************************************/
/* r0 contient la valeur à convertir   */
/* r1 contient l'adresse de la zone de conversion */
conversion10S:         // INFO: conversion10S
    push {fp,lr}       // save des  2 registres frame et retour
    push {r1-r7}       // save autres registres
    mov r5,r1          // debut zone stockage
    mov r6,#'+'        // par defaut le signe est +
    cmp r0,#0          // nombre négatif ?
    bge 0f
    mov r6,#'-'        // oui le signe est -
    mvn r0,r0          // et inversion du signe
    add r0,#1

0:    
    mov r4,#10         // longueur de la zone
    mov r2,r0          // nombre de départ des divisions successives
    mov r1,#10         // conversion decimale
1:                     // debut de boucle de conversion
    mov r0,r2          // copie nombre départ ou quotients successifs
    bl division        // division par le facteur de conversion
    add r3,#48         // car c'est un chiffre
    strb r3,[r5,r4]    // stockage du byte en début de zone r5 + la position r4
    sub r4,r4,#1       // position précedente
    cmp r2,#0          // arret si quotient est égale à zero
    bne 1b    
    strb r6,[r5,r4]    // stockage du signe à la position courante
    subs r4,r4,#1      // position précedente
    blt  100f          // si r4 < 0  fin
    add r4,#1          //sinon il faut deplacer le résultat au debut de la zone
    mov r2,#0
2:    
    ldrb r3,[r5,r4]    // lecture octet
    strb r3,[r5,r2]    // stockage octet
    add r4,r4,#1       // position suivante
    add r2,r2,#1
    cmp r4,#10         // longueur zone ?
    ble 2b             // boucle si r4 plus petit
    mov r0,r2
100:                   // fin standard de la fonction
    pop {r1-r7}        //restaur des autres registres
    pop {fp,lr}        // restaur des  2 registres frame et retour
    bx lr  
/********************************************************************/
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
