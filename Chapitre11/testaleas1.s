/* generation nombres pseudo aleatoires : vérification validité  */
/* assembleur ARM Raspberry : Vincent LeBoulou */
/* AVERTISSEMENT : le programmeur ne garantit le bon fonctionnement de ce programme  */
/* que dans les limites pour lesquelles il a été conçu. Il est déconseillé de l'utiliser */
/* dans des environnements dangereux (centrales nucléaires) ou soumis à des contraintes */
/* de sécurité importantes (Avions, voitures sans pilote humain, intelligence artificielles */
/*   */
/*********************************************/
/*constantes du programme                    */
/********************************************/
.equ MAXI, 1000      @ nombre de tirages
.equ PLAGE, 100      @ plage des tirages
.equ VIRGULENEG, 22  @ constantes pour la routine de conversion
.equ VIRGULEPOS, 52
.equ POSTOCKAGE, 31
.equ TAILLEZONE, 64
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne: .asciz  "\n"

szMessMoyenne:  .ascii  "Moyenne : "
moy:   .fill 11, 1, ' '   
       .asciz  "\n"
   
/* pour affichage nombre en C   */       
szFormat: .asciz "Ecart type = %.10f \n" 
szFormat1: .asciz "Moyenne = %.10f \n" 
szFormatKhi: .asciz "Khi = %f \n" 
/* pour affichage par la routine de conversion */
szMessMoyenne1:  .asciz  "Moyenne1 = "
szMessMoyenneKhi:  .asciz  "Khi = "    
szZoneFinal: .fill 100,1,' '
.align 4
iGraine:  .int 1
multipl: .int 1000000
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
iNombre:      .skip 8 
itabTirage:   .skip 4 * PLAGE
izoneFin1:    .skip TAILLEZONE
izoneDivi:    .skip TAILLEZONE
izoneUN:      .skip TAILLEZONE
szZoneAscii:  .skip 100 

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main            /* 'main' point d'entrée doit être  global */

main:                   /* programme principal */
    push {fp,lr}        /* save des  2 registres */
    add fp,sp,#8        /* fp <- adresse début */
                        /*  Test nombres aleatoires  */
    mov r4,#0           @ init des registres
    mov r5,#0
    mov r0,#0       
    vmov s3, r0         /* copie de R0 dans s3 pour l'ecart type*/
    vcvt.f32.s32 s3, s3 /* conversion en flottant simple précision */
    vmov s4, r0         /* copie de R0 dans s3 pour la moyenne */
    vcvt.f32.s32 s4, s4 /* conversion en flottant simple précision */
    mov r3,#MAXI
    vmov s2,r3          /* préparation du diviseur */
    vcvt.f32.s32 s2, s2 /* conversion en flottant simple précision */
    mov r0,#0           /* raz de la table des tirages */
    mov r1,#0
    ldr r2,=itabTirage
1:                      /* debut de boucle de raz */
   str r0,[r2,r1,lsl #2]/* stockage de 0 tous les 4 octets */
   add r1,#1
   cmp r1,#PLAGE
   blt 1b
2:                        /* début de boucle de MAXI tirages */
    mov r0,#PLAGE
    bl genereraleas       /* fonction de génération d'un nombre pseudo aléatoire */
    ldr r1,[r2,r0,lsl #2] /* on compte le nombre de tirage pour un chiffre */
    add r1,#1
    str r1,[r2,r0,lsl #2]
    vmov s1, r0           /* récupération du nombre dans s1 */
    vcvt.f32.s32 s1, s1   /* conversion en flottant simple précision */
    vdiv.f32 s0,s1,s2     /* calcul de la moyenne */
    vadd.f32 s4,s4,s0     /* ajout dans la totalisation */
    vmul.f32 s1,s1        /* calcul de l'ecart type */
    vdiv.f32 s0,s1,s2   
    vadd.f32 s3,s0,s3     /* ajout dans la totalisation */
    add r5,r5,r0          /* ajout dans r5 */
    add r4,#1
    cmp r4,#MAXI
    blt 2b                /* boucle */
                          /* Calculs de fin de boucle */
    mov r0,r5
    mov r1,r4             /* calcul de la moyenne entière */
    bl division   
    mov r0,r2
    ldr r1,=moy
    bl conversion10
    ldr r0,=szMessMoyenne  /* message moyenne entière */
    bl affichageMess       /* affichage message dans console   */
                           /* calcul de l'écart type final */ 
    vmul.f32 s0,s4,s4      /* calcul du carre de la moyenne */ 
    vsub.f32 s1,s3,s0      /* après calcul du carre de la moyenne on le soustrait */
    vsqrt.f32 s3,s1        /* de la somme des ecarts type et on calcule la racine carrée */
    vcvt.f64.f32  d5, s3   /* convertion en  double */
    ldr r0,=szFormat       /* préparation pour l'affichage par la fonction du C */
    vmov r2,r3,d5          /* pour transferer une valeur en double précision */
    bl printf              /* affichage ecart type */
    vcvt.f64.f32  d5, s4   /* convertion en  double */
    ldr r0,=szFormat1      /* préparation pour l'affichage par la fonction du C */
    vmov r2,r3,d5
    bl printf              /* affichage moyenne */
    ldr r0,=szMessMoyenne1 /* r0 ← adresse chaine */
    bl affichageMess       /* affichage message dans console   */
    vmov r0,s4             /* transfer dans le registre r0 pour passer à la fonction suivante */
    bl conversionFloatSP
    bl affichageMess       /* affichage message dans console   */
    ldr r0,=szRetourligne
    bl affichageMess       /* affichage message dans console   */
    /**********************************************/
    /* calcul du KHI */
    /* le KHI doit être proche de la plage   */
    /* Pour une plage de 100, un khi acceptable */
    /* doit être compris entre 90 et 110       */
    mov r0,#0
    mov r1,#0
   ldr r2,=itabTirage
3:
   ldr r3,[r2,r1,lsl #2]   @ récupération de chaque compteur de tirage
   mov r4,r3
   mul r4,r3,r4            @ calcul du carré de chaque volume de tirage
   add r0,r4               @ ajout au total précedent
   add r1,#1
   cmp r1,#PLAGE
   blt 3b                  @ boucle
       
    /* calcul du KHI */
    vmov s1,r0             @ stockage du total dans s1
    vcvt.f32.s32 s1, s1    @ conversion en flottant simple précision
    mov r1,#MAXI          
    vmov s2,r1             @ puis le nombre de tirage dans s2
    vcvt.f32.s32 s2, s2    @ conversion en flottant simple précision
    mov r2,#PLAGE
    vmov s3,r2             @ puis la plage dans s3
    vcvt.f32.s32 s3, s3    @ conversion en flottant simple précision
    vdiv.f32 s4,s1,s2      @ division du total par le nombre de tirage
    vmul.f32 s1,s4,s3      @ multiplier par la plage
    vsub.f32 s4,s1,s2      @ et on enleve le nombre de tirage
    vcvt.f64.f32  d5, s4   @ convertion en  double 
    ldr r0,=szFormatKhi    @ pour l'impression par la fonction du C
    vmov r2,r3,d5
    bl printf              @ affichage Khi
    
    ldr r0,=szMessMoyenneKhi    /* r0 ← adresse chaine */
    bl affichageMess            /* affichage message dans console   */
    vmov r0,s4
    bl conversionFloatSP
    bl affichageMess            /* affichage du KHI  */
    ldr r0,=szRetourligne
    bl affichageMess            /* retour ligne   */
    
finnormale:    
    ldr r0,=szMessFinOK         /* r0 ← adresse chaine */
    bl affichageMess            /* affichage message dans console   */
    mov r0,#0                   /* code retour OK */
    b 100f
erreur:                         /* affichage erreur */
    ldr r1,=szMessErreur        /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur          /*appel affichage message  */        
    mov r0,#1                   /* code erreur */
    b 100f    

100:                            /* fin de programme standard  */
    pop {fp,lr}                 /* restaur des  2 registres */
    mov r7, #EXIT               /* appel fonction systeme pour terminer */
    swi 0 
/************************************/       
szMessErreur: .asciz "Erreur rencontrée.\n"
szMessFinOK:  .asciz "Fin normale du programme. \n"
.align 4     /* alignement car l'étiquette de la routine suivante doit être alignée */
/***************************************************/
/*   Génération nombre pseudo aleatoire            */
/***************************************************/
/* r0 plage fin  */
genereraleas:
   push {fp,lr}    @ save des  2 registres frame et retour
   push {r1-r4}    @ save autres registres en nombre pair
   ldr r4,=iGraine
   ldr r2,[r4]     @ chargement de la graine
   ldr r3,=iNbDep1
   ldr r3,[r3]     @ chargement nombre 1
   mul r2,r3,r2    @ multiplication de la graine
   ldr r3,=iNbDep2 
   ldr r3,[r3]     @ chargement nombre 2 
   add r2,r2,r3    @ ajout au résultat précédent
   str r2,[r4]     @ maj de la graine pour l'appel suivant 

   /* division par la plage désirée */
   mov r1,r0       @ diviseur
   mov r0,r2       @ nombre
   bl division
   mov r0,r3       @ on garde le reste comme résultat
  
100:                 @ fin standard de la fonction
       pop {r1-r4}   @ restaur des autres registres
       pop {fp,lr}   @ restaur des  2 registres frame et retour
    bx lr            @ retour de la fonction en utilisant lr
/********************************************************************/
adresse.igraine: .int iGraine    
iNbDep1: .int 0x343FD
iNbDep2: .int 0x269EC3 

/***********************************************/    
/* Conversion float simple précision en chaine */   
/**********************************************/     
/* r0 contient le nombre  */ 
/* r0 retournera un pointeur vers la chaine ou -1 si erreur */
conversionFloatSP:            
    push {fp,lr}            @ save des  2 registres
    push {r1-r12}
    mov r12,r0              @ save du nombre dans r12
     /* calculer l'exposant */
    ldr r3,iMaskExp
    and r0,r3
    lsr r0,#23
    mov r10,r0   /* save exposant dans r10 */
    /* extraire la mantisse */
    mov r0,r12
    ldr r3,iMaskMan
    and r0,r3
    mov r9,r0   /* save mantisse dans r9 */
    /* analyse exposant */
    cmp r10,#255   @ cas Nan
    beq 2f
    cmp r10,#0      @ cas spéciaux
    beq 3f
    cmp r10,#127
    bgt 1f       @ cas exposant positif
    
    /* cas de l'exposant negatif */
    mov r3,#127
    sub r10,r3,r10   @ calcul de l'exposant = 127 - exposant extrait 
    mov r0,r9       @ mantisse 
    mov r1,#1       @ pour ajouter 1 à la fraction
    bl calculZones @ calcul de la mantisse
    bl regulmulti  @ multiplication du resultat pour assurer 126 divisions par 2
    
    ldr r0,=izoneFin1   @ division du resultat par 2
    mov r1,r10            @ en fonction de l'exposant
    mov r2,#32
    bl divisionpar2
    mov r0,#VIRGULENEG  @ position de la virgule 
    bl conversion @ conversion du résultat en ascii pour affichage
    ldr r0,=szZoneAscii
    mov r1,#VIRGULENEG
    ldr r2,=szZoneFinal
    bl affichagefinal   @ préparation affichage final
    ldr r0,=szZoneFinal  @ r0 retourne l'adresse de la zone finale
    b 100f    
    
1: /* cas de l'exposant positif */
    sub r10,#127    @ calcul de l'exposant : exposant extrait - 127
    mov r0,r9       @ mantisse
    mov r1,#1       @ pour ajouter 1 à la fraction
    bl calculZones  @ calcul de la mantisse
    ldr r0,=izoneFin1 @ et multiplication par des puissances de 2 
    mov r1,r10          @ en fonction de l'exposant
    mov r2,#32          @ longueur de la zone
    bl multipar2
    
    mov r0,#VIRGULEPOS   @ place de la virgule 
    bl conversion @ conversion du résultat en ascii pour affichage
    ldr r0,=szZoneAscii
    mov r1,#VIRGULEPOS   @ place de la virgule 
    ldr r2,=szZoneFinal
    bl affichagefinal     @ préparation affichage final
    ldr r0,=szZoneFinal  @ r0 retourne l'adresse de la zone finale
    b 100f
2:     /* retour libelle spécial NAN  Not An Number */
    ldr r0,=szMessAffSpe  @ r0 retourne l'adresse de la zone finale
    b 100f
3:    /* cas speciaux */
    mov r0,r9    @ recup mantisse
    cmp r0,#0
    bne 4f
    /* le nombre est égal à zéro */
    ldr r0,=szZoneFinal
    ldr r1,sZero
    str r1,[r0]
    b 100f
  
4:      /* cas des petits nombres */
    mov r10,#126  @ dans ce cas l'exposant est toujours - 126
    mov r1,#0   @ pour ajouter 0 à la fraction
    bl calculZones
    bl regulmulti  @ multiplication du resultat pour assurer 126 divisions par 2
    ldr r0,=izoneFin1
    mov r1,r10
    mov r2,#32
    bl divisionpar2
    mov r0,#VIRGULENEG
    bl conversion @ conversion du résultat en ascii pour affichage
    ldr r0,=szZoneAscii
    mov r1,#VIRGULENEG
    ldr r2,=szZoneFinal
    bl affichagefinal
    ldr r0,=szZoneFinal
    b 100f    
    
100:   
   /* fin standard de la fonction  */
    pop {r1-r12}
       pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */
sZero: .int 0x48444800      /*  représente la chaine 0,0 */
iMaskExp: .int 0b01111111100000000000000000000000
iMaskMan: .int 0b00000000011111111111111111111111    
szMessAffSpe: .asciz "Attention : valeur Nan. \n"
.align 4     /* alignement car l'étiquette de la routine suivante doit être alignée */
/************************************/    
/*   Calcul à partir de la mantisse dans zone mémoire */   
/************************************/     
/* r0 contient la mantisse */ 
/* r1 contient un indicateur pour ajouter soit un soit 0 à la fraction */
/*  */
calculZones:            
    push {fp,lr}    /* save des  2 registres */
    mov r5,r0      @ save mantisse
    mov r6,r1     @ save indicateur
    /* raz zone résultats */
    mov r2,#0
    ldr r3,=izoneFin1    
    mov r4,#0
1:    /* raz zone résultat */
    strb r2,[r3,r4]
    add r4,#1
    cmp r4,#TAILLEZONE
    ble 1b
    /* init zone de départ des calculs */
    ldr r3,=izoneDivi    
    mov r4,#0
2:    /* raz zone résultat */
    strb r2,[r3,r4]
    add r4,#1
    cmp r4,#TAILLEZONE
    ble 2b
    mov r2,#5
    strb r2,[r3,#POSTOCKAGE]    @ revoir ce stockage  19
    ldr r0,=izoneDivi
    ldr r1,=izoneDivi
    ldr r2,=multipl
    ldr r2,[r2]
    mov r3,#32       @ longueur de la zone
    bl multiZones
    ldr r0,=izoneDivi
    ldr r1,=izoneDivi
    ldr r2,=multipl
    ldr r2,[r2]
    mov r3,#32       @ longueur de la zone
    bl multiZones

    lsl r5,#9   /* décalage de la mantisse de 9 bits à gauche pour extraire les autres bits */
    mov r3,#23    @ compteur : la mantisse fait 23 bits
3:    @debut boucle
    lsls r5,#1  @extraire byte de gauche
    bcc 4f
    /* le bit est a 1, il faut ajouter la valeur */
    ldr r0,=izoneFin1
    ldr r1,=izoneDivi
    mov r2,#32         @longueur
    bl additionZones

4:    
    /* division par 2 de la zone valeur */
    ldr r0,=izoneDivi
    mov r1,#1
    mov r2,#32
    bl divisionpar2
    subs r3,#1       @decrementer le compteur
    bge 3b      @ si >= à zero boucle
    
    cmp r6,#0
    beq 6f
    mov r2,#0
    ldr r3,=izoneUN
    mov r4,#0
5:    /* raz zone UN */
    strb r2,[r3,r4]
    add r4,#1
    cmp r4,#TAILLEZONE
    ble 5b
    /* calcul de un à la bonne position  */
    ldr r0,=izoneUN
    mov r2,#1
    strb r2,[r0,#POSTOCKAGE]    @ Stockage à la meme position que le 5 de la valeur de départ
    ldr r1,=izoneUN
    ldr r2,=multipl     @ on le multiplie par le même multiplicateur
    ldr r2,[r2]
    mov r3,#32       @ longueur de la zone
    bl multiZones
    ldr r1,=izoneUN
    ldr r2,=multipl     @ on le multiplie par le même multiplicateur
    ldr r2,[r2]
    mov r3,#32       @ longueur de la zone
    bl multiZones
    ldr r0,=izoneUN
    ldr r1,=izoneUN
    mov r2,#10        @ et on le remultiplie par 10 pour calculer 1,abcdefg
    mov r3,#32       @ longueur de la zone
    bl multiZones
    ldr r0,=izoneFin1  /* et il faut l'ajouter à la fraction calculé */
    ldr r1,=izoneUN
    mov r2,#32         @longueur
    bl additionZones
6:    
    
100:   
   /* fin standard de la fonction  */    
      pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */
/******************************************/    
/*  conversion du resultat exposant positif en ASCII   */   
/*****************************************/     
/* r0 contient la place de la virgule  */ 
regulmulti:             /* programme principal */
    push {fp,lr}    /* save des  2 registres */    
        ldr r0,=izoneFin1 @ multiplication du résultat 
    ldr r1,=izoneFin1 @ pour assurer un resultat correct lors des divisions 
    ldr r2,=multipl    @ facteur multiplicatif
    ldr r2,[r2]
    mov r3,#32       @ longueur de la zone en octet
    bl multiZones  @ routine de multiplication d'une zone en memoire
    ldr r0,=izoneFin1 @ 2 ieme multiplication identique
    ldr r1,=izoneFin1
    ldr r2,=multipl
    ldr r2,[r2]
    mov r3,#32       @ longueur de la zone
    bl multiZones
    ldr r0,=izoneFin1 @ 3 ieme multiplication identique
    ldr r1,=izoneFin1
    ldr r2,=multipl
    ldr r2,[r2]
    mov r3,#32       @ longueur de la zone
    bl multiZones
    ldr r0,=izoneFin1 @ 4 ieme multiplication identique
    ldr r1,=izoneFin1
    ldr r2,=multipl
    ldr r2,[r2]
    mov r3,#32       @ longueur de la zone
    bl multiZones
    ldr r0,=izoneFin1 @ 5 ieme multiplication identique
    ldr r1,=izoneFin1
    ldr r2,=multipl
    ldr r2,[r2]
    mov r3,#32       @ longueur de la zone
    bl multiZones
    
100:   
   /* fin standard de la fonction  */    
      pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */    

/******************************************/    
/*  conversion du resultat exposant positif en ASCII   */   
/*****************************************/     
/* r0 contient la place de la virgule  */ 
conversion:             /* programme principal */
    push {fp,lr}    /* save des  2 registres */    
    sub r6,r0,#1  @ place de la virgule - 1
    ldr r4,=izoneFin1
    ldr r7,=szZoneAscii
    mov r0,#32         @ caractères blanc
    mov r1,r6          @ place de la virgule -1 
1:
    strb r0,[r7,r1]   @ stockage de blancs jusquà la place de la virgule -1
    subs r1,#1
    bge 1b
    mov r0,#'0'         @ caractères zero
    mov r1,#TAILLEZONE
2:
    strb r0,[r7,r1]   @ et on stocke des zeros dans le reste de la zone
    sub r1,#1
    cmp r1,r6
    bge 2b

    mov r3,#0      @ reste de la division 
    mov r5,#TAILLEZONE  @ position de stockage de chaque chiffre en commençant par la fin
    mov r6,#0      @ compteur de boucle
    mov r8,#256    @ multiplicateur
3:              @ debut de boucle de recherche du 1er caractère non nul
    ldrb r0,[r4,r6]
    cmp r0,#0
    bne 4f    @ caractère trouvé
    add r6,#1   @ +1 dans compteur
    cmp r6,#POSTOCKAGE + 1 @  tous les octets sont traités ?
    bge 5f  @fin
    b 3b     @ sinon boucle
4:    @ debut de boucle des divisions par 10
    ldrb r0,[r4,r6]  @ recup d'un octet 
    mul r3,r8,r3      @ multiplication du reste précedent par 256    
    add  r0,r0,r3     @ addition du reste precedent
    mov r1,#10      @ division par 10
    bl division
    strb r2,[r4,r6] @ stockage du quotient dans même octet
    add r6,#1        @ +1 dans compteur
    cmp r6,#POSTOCKAGE + 1    @ tous les octets  sont traités ?
    blt 4b         @ boucle
    @ fin de la division complete
    add r3,#48   /* r3 contient le dernier reste et on le passe en ascii*/    
    strb r3,[r7,r5]  /* stockage du byte en début de zone r7 + la position r5 */    
    sub r5,#1         /* pour position précedente */
    mov r6,#0        /* raz des compteurs et reste pour recommencer */
    mov r3,#0
    b  3b   @boucle pour convertir un autre chiffre
    
5: @ c'est fini 

    
100:   
   /* fin standard de la fonction  */
       pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */        


/****************************************************/    
/*   preparation finale suppression des blancs      */  
/*   mise en place de la virgule et du sig         */ 
/***************************************************/     
/* r0 contient l'adresse de la zone de départ */ 
/*  r1 contient le rang de la virgule */
/* r2 contient la zone de reception */
affichagefinal:            
    push {fp,lr}    /* save des  2 registres */
    @ elimination des blancs 
    mov r3,#0
    mov r5,#0
1:    @ boucle d'élimination des blancs 
    ldrb r4,[r0,r3]   @ recup octet
    cmp r4,#' '        @ c'est un espace ?
    bne 2f         @ non
    add r3,#1
    cmp r3,#TAILLEZONE    @  fin de zone ?
    bge 100f       @ que des blancs ????
    b 1b       @ boucle
2:  /* traitement du signe */
    mov r6,r12    @ recup du nombre 
    lsls r6,#1   @ deplacement du bit de gauche dans la zone carry 
    movcs r6,#'-' @ negatif
    movcc r6,#'+'  @ positif
       strb r6,[r2,r5] @ mise en place
    add r5,#1
    
3:  /* debut de boucle de transfert des chiffres */
    cmp r3,r1     @ position de la virgule ?
    bne 4f
    mov r6,#','   @ oui, stockage de la virgule
    strb r6,[r2,r5]    
    add r5,#1
4:    
    strb r4,[r2,r5]    @ stockage du caractère dans la zone de reception
    add r5,#1
    add r3,#1          @ caractère suivant
    cmp r4,#0   @ 0 rencontré alors fin
    beq 100f
    ldrb r4,[r0,r3]
    cmp r4,#' '  @ blanc rencontré ?
    bne 3b       @ non boucle
    mov r6,#0     @ 0 final
    str r6,[r2,r5] @ pour fin de chaine
    
100:   
   /* fin standard de la fonction  */
       pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */    
/******************************************/    
/*  addition de 2 zones  memoire          */   
/*****************************************/    
/* r0 zone départ   */  
/* r1 valeur a additionner  */ 
/* r2 longueur         */  
additionZones:             /* programme principal */
    push {fp,lr}    /* save des  2 registres */    
    push {r2,r3,r4,r5}
    mov r3,#0
1:    
    ldrb r4,[r0,r2]   /* lecture un octet en commencant par la fin */
    ldrb r5,[r1,r2]       @ octet à additionner
    add  r4,r4,r5     @ addition des 2
    add  r4,r3      @ et de la retenue précedente
    mov r3,#0
    cmp r4,#256
    subgt r4,#256
    movgt r3,#1      @ retenue    
    strb r4,[r0,r2]  
    subs r2,#1
    bne 1b
    
100:   
   /* fin standard de la fonction  */
    pop {r2,r3,r4,r5}
       pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr   
/****************************************************/    
/*   multiplication zones par un multiple de 10  maxi 10 000 000 */   
/***************************************************/     
/* r0 contient zone memoire origine */ 
/* r1 contient zone memoire resultat */ 
/* r2 contient le multiplicateur  */
/* r3 contient la longueur des zones */
/* r0 retourne -1 si erreur */
multiZones:            
    push {fp,lr}    /* save des  2 registres */
    push {r3-r6}
    ldr r4,limite
    cmp r2,r4      @ verif multiplicateur
    movgt r0,#-1
    bgt 100f
    @ multiplication de cette zone
    mov r4,#256
    mov r5,#0
2:                @ debut de boucle
   ldrb r6,[r0,r3]
   mul r6,r2,r6    @ multiplication d'un octet
   add r6,r6,r5    @ ajout du quotient
   push {r0-r3}    @ save des registres utilises par la division
   mov r0,r6       @ dividende
   mov r1,r4       @ diviseur 
   bl division
   mov r5,r2       @ quotient 
   mov r6,r3       @ reste
   pop {r0-r3}     @ restaur des registres
   strb r6,[r1,r3]  @ stockage du reste
   sub r3,#1      @ - 1 sur la longueur
   cmp r3,#0      @ fin ?  
   bge 2b    
 100:   
   /* fin standard de la fonction  */
    pop {r3-r6}
       pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr     
limite: .int 10000000    
/****************************************************/    
/*   copie de zones      */   
/***************************************************/     
/* r0 contient la  zone origine */ 
/*  r1 contient la zone destinataire */
/*  r2 contient la longueur */
copieZone:            
    push {fp,lr}    /* save des  2 registres */
    push {r2,r3}
1:    
    ldrb r3,[r0,r2]
    strb r3,[r1,r2]
    subs  r2,#1
    bgt 1b

100:   
   /* fin standard de la fonction  */
    pop {r2,r3}
       pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */        
/******************************************/    
/*  division par 2 d'une zone  memoire     */   
/*****************************************/     
/* r0 contient l'adresse de la zone  */ 
/* r1 nombre de division  */
/* r2 la longueur de la zone en octets */
divisionpar2:             
    push {fp,lr}    /* save des  2 registres */    
    push {r2-r6}
    ldr r3,maskBitGau
    cmp r1,#0     /* nombre de multiplication egale à zero ? */
    beq 100f   
1:    
    mov r4,#0   @  compteur d'octets  
    mov r5,#0   @  bit de droite
2:    
    ldrb r6,[r0,r4]
    lsrs r6,#1   @ decalage d'un bit soit / 2
    orr r6,r5      @ on ajoute le bit issu de l'opération précedente 
    movcs r5,r3  @ conservation dans r3 du bit de droite
    movcc r5,#0 
    strb r6,[r0,r4]
    add r4,#1
    cmp r4,r2
    blt 2b    
    subs r1,#1
    bgt 1b
    
100:   
   /* fin standard de la fonction  */
    pop {r2-r6}
       pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */    
maskBitGau: .int 0b00000000000000000000000010000000    
/******************************************/    
/*  multiplication par 2 d'une zone  memoire     */   
/*****************************************/     
/* r0 contient l'adresse de la zone  */ 
/* r1 nombre de multiplication (exposant)  */
/* r2 la longueur de la zone en octets */
multipar2:             
    push {fp,lr}    /* save des  2 registres */    
    push {r2-r6}
    ldr r3,maskBitDroit
    cmp r1,#0     /* nombre de multiplication egale à zero ? */
    beq 100f   
1:    
    mov r4,r2   @  compteur d'octets  
    mov r5,#0   @  bit de droite
2:    
    ldrb r6,[r0,r4]
    rev r6,r6
    lsls r6,#1   @ decalage d'un bit soit * 2
    orr r6,r5      @ on ajoute le bit issu de l'opération précedente 
    movcs r5,r3  @ conservation dans r3 du bit de droite
    movcc r5,#0 
    rev r6,r6
    strb r6,[r0,r4]
    sub r4,#1
    cmp r4,#0
    bgt 2b    
    subs r1,#1
    bgt 1b
    
100:   
   /* fin standard de la fonction  */
    pop {r2-r6}
       pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */    
maskBitDroit: .int 0b00000001000000000000000000000000
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
