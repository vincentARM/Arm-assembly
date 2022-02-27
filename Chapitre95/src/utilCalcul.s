/* Programme assembleur ARM Raspberry 32 bits */
/* ou smartphone android avec Termux */
/*  */
/* calculs multiprécisions   */
/* nouvelles optimisations et nouvelles routines 21 février 2022 */ 
/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "src/ficmacros.inc"
/*******************************************/
/* Fichier des structures                   */
/********************************************/
.include "src/descStruct.inc"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne:       .asciz  "\n"
szMessErrInit:        .asciz "\033[31mNombre de chunk trop petit ou trop grand !!\033[0m \n"

.align 4

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text            
.global initMultiEntier,creerMultiDepuisEntier,convertirMultiVersChaine,multiplierEntierMultiEntier
.global multiplierMultiEntier,deplacerGaucheMultiEntier,deplacerDroiteMultiEntier
.global diviserMultiEntier,comparerMultiEntier,soustraireMultiEntier
.global convertirChaineEnMultiEntier,ajouterMultiEntier,copierMultiEntier
.global convertirMultiEntierEnEntier,testerMultiEntierZero,calculerModuloMultiEntier
.global testerMultiEntierPair,deplacerGaucheUnBitMultiEntier,creerAleaMultiEntier
.global incrementerMultiEntier,decrementerMultiEntier,deplacerDroiteBitsMultiEntier
.global ajouterMultiEntierPositif,multiplierMultiEntierNonOpt,soustraireMultiEntierPositif
.global diviserMultiEntierNOPT
// temporaire pour tests
.global etendreMultiEntier,reduireMultiEntier,inverserMultiEntier
.global deplacerGaucheChunkMultiEntier,deplacerDroiteChunkMultiEntier
/***************************************************/
/*   init multiEntier             */
/***************************************************/
// r0 contient l'adresse de la zone réservée 
// r1 contient le nombre de chunk à créer 
// donc minimum 1
// r0 retourne l'adresse ou -1 si problème
initMultiEntier:             @ INFO: initMultiEntier
    push {r1-r4,lr}        @ save des registres
    cmp r0,#0
    beq 99f
    cmp r1,#1              @ mini 1 chunk
    blt 99f
    cmp r1,#NBCHUNKMAXI    @ maxi ?
    bgt 99f
    //vidregtit reserve1
    str r1,[r0,#multi_taille]
    mov r2,#0
    str r2,[r0,#multi_signe]
    add r2,r0,#multi_fin
    //vidregtit reserve2
    add r2,r0,#multi_chunk    @ adresse premier chunk
    
    mov r4,#0
    mov r3,#0
1:
    str r4,[r2,r3,lsl #2]   @ raz chunk
    add r3,r3,#1
    cmp r3,r1
    blt 1b
    b 100f
99:
    ldr r0,iAdrszMessErrInit
    bl affichageMess
    mov r0,#-1
100:                       @ fin standard de la fonction  
    pop {r1-r4,pc}         @ restaur des registres 
iAdrszMessErrInit:        .int szMessErrInit

/***************************************************/
/*   création multiEntier depuis un entier            */
/***************************************************/
// r0 contient l'adresse de la zone réservée
// r1 contient entier
// r0 retourne l'adresse 
creerMultiDepuisEntier:      @ INFO: creerMultiDepuisEntier
    push {r1-r2,lr}          @ save des registres
    mov r2,r1
    mov r1,#1
    bl initMultiEntier
    cmp r0,#-1
    beq 100f
    cmp r2,#0              @ test signe
    blt 1f
    str r2,[r0,#multi_chunk] @ entier positif
    mov r2,#0
    str r2,[r0,#multi_signe] @ stocke le signe
    b 100f
1:                         @ entier négatif
    mvn r2,r2
    add r2,r2,#1
    str r2,[r0,#multi_chunk]
    mov r2,#-1             @ signe
    str r2,[r0,#multi_signe]

100:                       @ fin standard de la fonction  
    pop {r1-r2,pc}         @ restaur des registres
/***************************************************/
/*   conversion multientier en un entier  de 32 bits     */
/***************************************************/
// r0 contient adresse multiEntier
// r0 retourne l'entier (attention au -1 si erreur)
convertirMultiEntierEnEntier:  @ INFO: convertirMultiEntierEnEntier
    push {r1,lr}          @ save des registres
    bl reduireMultiEntier
    ldr r1,[r0,#multi_taille]
    cmp r1,#1                @ taille > 1 -> erreur
    bgt 99f
    add r1,r0,#multi_chunk
    ldr r0,[r1]              @ charge le chunk
    b 100f 
99:
    adr r0,szMessErrEntier
    bl affichageMess
    mov r0,#-1
100:                         @ fin standard de la fonction  
    pop {r1,pc}           @ restaur des registres
szMessErrEntier:        .asciz "\033[31mMultiEntier trop grand pour conversion vers entier !!\033[0m \n"
    .align 4
/***************************************************/
/*   conversion multiEntier vers chaine            */
/***************************************************/
// r0 contient adresse multientier
// r1 contient adresse buffer
// r2 contient longueur buffer
convertirMultiVersChaine:   @ INFO: convertirMultiVersChaine
    push {r1-r9,fp,lr}        @ save des registres
    //vidregtit conversion
    sub sp,sp,#multi_fin
    mov fp,sp
    mov r6,r0
    mov r8,r1
    mov r1,fp
    bl copierMultiEntier
    cmp r0,#-1
    beq 100f
    //vidregtit retourcopie
    ldr r6,[fp,#multi_taille]
    ldr r9,[fp,#multi_signe]   @ recup du signe
    add r4,fp,#multi_chunk
1:
    mov r0,fp
    //vidmemtit avantapl r0 3
    bl testerMultiEntierZero
    cmp r0,#0
    beq 2f
    mov r1,#0x00000030
    str r1,[r8]
    mov r0,r8
    b 100f
2:
    mov r4,#10            // nombre de caractère par chunk
    mul r4,r6,r4
    cmp r4,r2             // verif taille du buffer
    bge 99f
    mov r0,#0
    strb r0,[r8,r4]       // stockage 0 final
    sub r4,r4,#1          // fin stockage chiffres
3:
    mov r0,fp
    mov r1,#10
    //vidregtit avantapl2
    bl calculerModuloMultiEntier
    add r0,r0,#0x30
    strb r0,[r8,r4]
    sub r4,r4,#1
    //vidregtit retourmodulo
    mov r0,fp
    bl testerMultiEntierZero
    cmp r0,#0
    beq 3b
    
4:                          @ si négatif, on ajoute le signe
    cmp r9,#-1
    bne 5f
    mov r0,#'-'
    strb r0,[r8,r4]
    sub r4,r4,#1
5:

    add r0,r8,r4            @ retourne début des chiffres
    add r0,r0,#1
    b 100f
99:
    adr r0,szMessErrBuffer
    bl affichageMess
    mov r0,#-1
100:                    @ fin standard de la fonction  
    add sp,sp,#multi_fin
    pop {r1-r9,fp,pc}         @ restaur des registres
szMessErrBuffer:        .asciz "\033[31mBuffer de conversion trop petit !!\033[0m \n"
.align 4
/***************************************************/
/*   copie multiEntier vers multiEntier           */
/***************************************************/
// r0 contient adresse multientier
// r1 contient adresse multientier copie
// r0 retourne adresse copie
copierMultiEntier:           @ INFO: copierMultiEntier
    push {r2-r3,lr}        @ save des registres    
    ldr r3,[r0,#multi_taille]
    add r3,r3,#1           @ indice dernier chunk + Taille et signe 
1:
    ldr r2,[r0,r3,lsl #2]
    str r2,[r1,r3,lsl #2]
    subs r3,r3,#1
    bge 1b
    mov r0,r1
100:
    pop {r2-r3,pc}
/***************************************************/
/* incremente multiEntier directement                 */
/* Attention ajoute le nombre à la valeur absolue  */
/* exemple 10 + 1 = 11  et -10 + 1 = -11 (et pas -9) */
/***************************************************/
// r0 contient adresse multientier
// r1 contient le nombre non signé 
incrementerMultiEntier:           @ INFO: incrementeMultiEntier
    push {r1-r5,lr}        @ save des registres    
    ldr r3,[r0,#multi_taille]
    add r4,r0,#multi_chunk
    ldr r2,[r4]    @ 1er chunk
    adds r2,r2,r1 
    str r2,[r4]  
    bcc  100f     @ pas de retenue -> fin
    mov r1,#1    @ retenue
    mov r5,#1    @ indice deuxième chunk
    vidregtit incrementer
1:
    cmp r5,r3    @ fin ?
    bge 2f
    ldr r2,[r4,r5,lsl #2]
    adds r2,r2,r1
    movcs r1,#1
    movcc r1,#0
    str r2,[r4,r5,lsl #2]
    cmp r1,#0
    beq 100f          @ plus de retenue
    add r5,r5,#1
    b 1b
2:
    cmp r1,#0          @ retenue finale
    beq 100f
    str r1,[r4,r5,lsl #2]  @ et il faut ajouter un chunk 
    add r5,r5,#1
    str r5,[r0,#multi_taille]
 
100:
    pop {r1-r5,pc}
 
 /***************************************************/
/* decremente multiEntier directement                 */
/* Attention ajoute le nombre à la valeur absolue  */
/* exemple 10 - 1 = 10  et -10 - 1 = -9 (et pas -11) */
/***************************************************/
// r0 contient adresse multientier
// r1 contient le nombre non signé 
decrementerMultiEntier:      @ INFO: decrementeMultiEntier
    push {r1-r5,lr}          @ save des registres    
    ldr r3,[r0,#multi_taille]
    add r4,r0,#multi_chunk
    ldr r2,[r4]              @ 1er chunk
    subs r2,r2,r1 
    str r2,[r4]  
    bcs  100f                @ pas de retenue -> fin
    mov r1,#1                @ retenue
    mov r5,#1                @ indice deuxième chunk
1:
    cmp r5,r3                @ fin ?
    bge 2f
    ldr r2,[r4,r5,lsl #2]
    subs r2,r2,r1
    movcc r1,#1
    movcs r1,#0
    str r2,[r4,r5,lsl #2]
    cmp r1,#0
    beq 100f                 @ plus de retenue
    add r5,r5,#1
    b 1b
2:
    cmp r1,#0                @ retenue finale
    beq 100f
    str r1,[r4,r5,lsl #2]    @ et il faut ajouter un chunk 
    add r5,r5,#1
    str r5,[r0,#multi_taille]
 
100:
    pop {r1-r5,pc}
    
/***************************************************/
/*   test si  multiEntier = zéro                  */
/***************************************************/
// r0 contient adresse multientier
// r0 retourne 1 si égal sinon 0
testerMultiEntierZero:   @ INFO: testerMultiEntierZero
    push {r1-r2,lr}        @ save des registres 
    ldr r1,[r0,#multi_taille]
    sub r1,r1,#1
    add r2,r0,#multi_chunk
1:
    ldr r0,[r2,r1,lsl #2]
    cmp r0,#0
    movne r0,#0
    bne 100f
    subs r1,r1,#1
    bge 1b
    mov r0,#1
    
100:                    @ fin standard de la fonction  
    pop {r1-r2,pc}         @ restaur des registres
/***************************************************/
/*   test si  multiEntier est pair            */
/***************************************************/
// r0 contient adresse multientier
// r0 retourne 1 si pair sinon 0
testerMultiEntierPair:   @ INFO: testerMultiEntierZero
    push {r1,lr}        @ save des registres 
    add r1,r0,#multi_chunk
1:
    ldr r0,[r1]
    tst r0,#1
    movne r0,#0
    moveq r0,#1

100:                    @ fin standard de la fonction  
    pop {r1,pc}         @ restaur des registres
/***************************************************/
/*   calcul du modulo                              */
/***************************************************/
// r0 contient adresse multientier
// r1 contient le diviseur (positif)
// r0 retourne le modulo
// ATTENTION : le multientier origine est modifié et contient le quotient
calculerModuloMultiEntier:   @ INFO: calculerModuloMultiEntier
    push {r1-r5,lr}        @ save des registres 
    cmp r1,#0
    ble 99f
    mov r4,r1              @ save nombre
    ldr r3,[r0,#multi_taille]
    sub r3,r3,#1           @ indice dernier chunk
    add r5,r0,#multi_chunk   @ adresse des chunks
    ldr r0,[r5,r3,lsl #2]  @ TODO: revoir le cas du signe si nombre négatif
    mov r1,#0
1:
    cmp r3,#0
    ble 2f
    mov r2,r4
    bl division32R
    str r0,[r5,r3,lsl #2]
    sub r3,r3,#1
    ldr r0,[r5,r3,lsl #2]
    mov r1,r2
    b 1b
2:
    mov r2,r4
    bl division32R
    str r0,[r5]            @ stockage dans le 1er chunk
    mov r0,r2              @ retourne le reste
    b 100f
99:
    adr r0,szMessNegatif
    bl affichageMess
    mov r0,#-1
100:                       @ fin standard de la fonction  
    pop {r1-r5,pc}         @ restaur des registres
szMessNegatif:      .asciz "\033[31mLe diviseur doit être positif !\033[0m\n"
.align 4
/***************************************************/
/*   inversion  multiEntier                          */
/***************************************************/
// r0 contient adresse multientier
// r1 contient adresse inverse
// r0 retourne adresse de l inverse
inverserMultiEntier:       @ INFO: inverserMultiEntier
    push {r1-r6,lr}        @ save des registres 
    mov r4,r0
    mov r0,r1
    ldr r1,[r4,#multi_taille]
    add r2,r4,#multi_chunk    @ adresse des chunks origine
    add r3,r0,#multi_chunk    @ adresse des chunks destination
    mov r4,#1               @ pour ajout du 1
    mov r5,#0               @ indice
1:
    ldr r6,[r2,r5,lsl #2]   @ charge un chunk
    mvn r6,r6               @ complement
    adds r6,r6,r4           @ ajout du 1 ou du carry
    movcs r4,#1             @ nouveau carry
    movcc r4,#0
    str r6,[r3,r5,lsl #2]   @ stocke le résultat
    add r5,r5,#1
    cmp r5,r1               @ fin ?
    blt 1b                  @ sinon boucle
    //vidregtit inversion
    cmp r4,#1               @ reste une retenue
    bne 2f
    add r5,r5,#1            @ ajoute un chunk 
    cmp r5,#NBCHUNKMAXI
    bge 99f
    str r4,[r3,r5,lsl #2]   @ et stockage de la retenue
2:
    mov r6,#0               @ signe positif
    str r6,[r0,#multi_signe]
    //vidregtit inversion1
    str r5,[r0,#multi_taille] @ stocke nouvelle taille
    b 100f
99:
    ldr r0,iAdrszMessErrInit
    bl affichageMess
    mov r0,#-1
100:
    pop {r1-r6,pc}         @ restaur des registres
/***************************************************/
/*   inversion  multiEntier en place                         */
/***************************************************/
// r0 contient adresse multientier
// r0 retourne adresse de l inverse
inverserMultiEntierOpt:       @ INFO: inverserMultiEntierOpt
    push {r1-r6,lr}         @ save des registres 
    ldr r1,[r0,#multi_taille]
    add r2,r0,#multi_chunk    @ adresse des chunks origine
    mov r4,#1               @ pour ajout du 1
    mov r5,#0               @ indice
1:
    ldr r6,[r2,r5,lsl #2]   @ charge un chunk
    mvn r6,r6               @ complement
    adds r6,r6,r4           @ ajout du 1 ou du carry
    movcs r4,#1             @ nouveau carry
    movcc r4,#0
    str r6,[r2,r5,lsl #2]   @ stocke le résultat
    add r5,r5,#1
    cmp r5,r1               @ fin ?
    blt 1b                  @ sinon boucle
    //vidregtit inversion
    cmp r4,#1               @ reste une retenue
    bne 2f
    add r5,r5,#1            @ ajoute un chunk 
    cmp r5,#NBCHUNKMAXI
    bge 99f
    str r4,[r2,r5,lsl #2]   @ et stockage de la retenue
2:
    mov r6,#0               @ signe positif
    str r6,[r0,#multi_signe]
    //vidregtit inversion1
    str r5,[r0,#multi_taille] @ stocke nouvelle taille
    b 100f
99:
    ldr r0,iAdrszMessErrInit
    bl affichageMess
    mov r0,#-1
100:
    pop {r1-r6,pc}         @ restaur des registres
/***************************************************/
/*   addition  multiEntier             */
/***************************************************/
// r0 contient adresse multientier 1
// r1 contient adresse multientier 2
// r2 contient adresse résultat
// r0 retourne adresse du résultat
ajouterMultiEntier:              @ INFO: ajouterMultiEntier
    push {r1-r12,lr}           @ save des registres 
    sub sp,sp,#multi_fin * 2     @ reserve 2 zones de travail
    mov fp,sp
    mov r6,r0
    mov r5,r1
    ldr r3,[r0,#multi_taille]
    ldr r4,[r1,#multi_taille]
    cmp r3,r4
    bgt 1f
    mov r3,r4                  @ alignement operande 1 sur la taille la plus grande
    mov r1,r3                  @ nouveau nombre de chunks
    bl etendreMultiEntier
    mov r6,r0
    b 2f
1:                             @ alignement operande 2
    mov r0,r5
    mov r1,r3
    bl etendreMultiEntier
    mov r5,r0
2:
    mov r7,#0                  @ indicateur positif negatif
    ldr r4,[r6,#multi_signe]     @ signe operande 1
    cmp r4,#-1
    moveq r7,#1                @ negatif
    
    ldr r4,[r5,#multi_signe]     @ signe operande 2
    cmp r4,#-1
    addeq r7,r7,#2
    cmp r7,#0                  @ 2 opérandes positifs
    moveq r8,#0                @ le résultat sera positif
    streq r8,[r2,#multi_signe]
    beq 4f
    cmp r7,#0b11               @ 2 opérandes négatifs
    moveq r8,#-1               @ le résultat sera négatif
    streq r8,[r2,#multi_signe]
    beq 4f
    
    tst r7,#1                  @ premier négatif ?
    beq 3f
    mov r0,r6                  @ operande 1 negatif
    mov r1,fp
    bl inverserMultiEntier       @ resultat dans fp 
    //vidmemtit inversion1 r0 3
    mov r7,#1
    mov r6,fp
    b 4f
3:
    mov r0,r5                  @ operande 2 négatif
    add r1,fp,#multi_fin
    bl inverserMultiEntier
    //vidmemtit inversion2 r0 3
    mov r5,r0                 @ ou fp+#multifin
4:
    mov r0,r2                @ zone somme retour
    add r2,r5,#multi_chunk     @ debut des chunks operateur 1
    add r1,r6,#multi_chunk     @ debut des chunks operateur 2
    add r12,r0,#multi_chunk    @ debut des chunks somme
    mov r10,#0               @ indice
    mov r6,#0                @ carry a zero
5:                           @ boucle addition
    mov r9,#0
    ldr r4,[r2,r10,lsl #2]
    ldr r5,[r1,r10,lsl #2]
    adds r8,r4,r5
    adc r9,r9,#0
    adds r8,r8,r6    @ ajout carry
    adc r6,r9,#0    @ nouveau carry
    //vidregtit addition
    str r8,[r12,r10,lsl #2]
    add r10,r10,#1
    cmp r10,r3
    blt 5b
                                 @ analyse finale
    cmp r6,#0                    @ il y a une retenue ?
    beq 7f
    cmp r7,#0                    @ oui et les 2 operandes sont positifs ?
    beq 6f
    cmp r7,#0b11                 @ oui et les 2 operandes sont negatifs ?
    beq 6f
    mov r8,#0                    @ operandes differents et le résultat est positif
    str r8,[r0,#multi_signe]
    str r3,[r0,#multi_taille]
    b 8f
 
6:
    str r6,[r12,r10,lsl #2]       @ ajout d'un chunk
    add r10,r10,#1
    cmp r10,#NBCHUNKMAXI
    bge 98f
    str r10,[r0,#multi_taille]
    b 8f

7:
    str r3,[r0,#multi_taille]
    cmp r7,#0            @ les 2 positifs  RAF
    beq 8f
    cmp r7,#0b11         @ les 2 negatifs RAF
    beq 8f    
    //vidregtit invresultat
    mov r2,r0            @ save adresse zone retour
    mov r1,fp            @ sinon il faut inverser le résultat
    bl inverserMultiEntier
    //vidmemtit inverserA1 r0 3
    mov r8,#-1              @  et le signe est négatif
    str r8,[r0,#multi_signe]
    mov r1,r2               @ recopie inverse dans zone retour
    bl copierMultiEntier
8:
    b 100f
98:
    adr r0,szMessErrNbchunk
    bl affichageMess
100:                        @ fin standard de la fonction 
    add sp,sp,#multi_fin * 2
    pop {r1-r12,pc}         @ restaur des registres
szMessErrNbchunk:        .asciz "\033[31mAddition : nombre de chnuk trop petit !!\033[0m \n"
.align 4
/***************************************************/
/*   addition  2 multiEntier positifs              */
/* attention le resultat est à l'adresse de r1 dont 
            la valeur initiale est perdue        */ 
/***************************************************/
// r0 contient adresse multientier 1
// r1 contient adresse multientier 2
// r0 retourne adresse du résultat
ajouterMultiEntierPositif:      @ INFO: ajouterMultiEntierPositif
    push {r1-r9,lr}             @ save des registres 
    mov r6,r0
    mov r2,r1
    ldr r3,[r6,#multi_taille]
    ldr r4,[r2,#multi_taille]
    cmp r3,r4
    bgt 1f
    mov r3,r4                  @ alignement operande 1 sur la taille la plus grande
    mov r0,r6
    mov r1,r3                  @ nouveau nombre de chunks
    bl etendreMultiEntier
    mov r6,r0
    b 2f
1:                             @ alignement operande 2
    mov r0,r2
    mov r1,r3
    bl etendreMultiEntier
2:
    mov r0,r2
    add r2,r0,#multi_chunk     @ debut des chunks operateur 2
    add r1,r6,#multi_chunk     @ debut des chunks operateur 1
    mov r7,#0                  @ indice
    mov r6,#0                  @ carry a zero
    //vidregtit debutsomme
5:                             @ boucle addition
    mov r9,#0
    ldr r4,[r2,r7,lsl #2]
    ldr r5,[r1,r7,lsl #2]
    adds r8,r4,r5
    adc r9,r9,#0
    adds r8,r8,r6              @ ajout carry
    adc r6,r9,#0               @ nouveau carry
    str r8,[r2,r7,lsl #2]
    add r7,r7,#1
    cmp r7,r3
    blt 5b
                                 @ analyse finale
    cmp r6,#0                    @ il y a une retenue ?
    streq r3,[r0,#multi_taille]    @ non stocke la taille actuelle et fin
    beq 100f

    str r6,[r2,r7,lsl #2]       @ oui ajout d'un chunk avec la retenue
    add r7,r7,#1
    cmp r7,#NBCHUNKMAXI         @ maxi ?
    strlt r7,[r0,#multi_taille]
    blt 100f

98:
    adr r0,szMessErrNbchunk
    bl affichageMess
100:                        @ fin standard de la fonction 
    pop {r1-r9,pc}         @ restaur des registres
/***************************************************/
/*   soustraction  multiEntier             */
/***************************************************/
// r0 contient adresse multientier 1
// r1 contient adresse multientier 2
// r2 contient adresse du résultat
// r0 retourne adresse du résultat
soustraireMultiEntier:          @ INFO: soustraireMultiEntier
    push {r1-r3,fp,lr}        @ save des registres 
    sub sp,sp,#multi_fin
    mov fp,sp
    mov r3,r0
    mov r0,r1
    mov r1,fp
    bl copierMultiEntier
    ldr r1,[r0,#multi_signe]
    cmp r1,#0
    moveq r1,#-1
    movne r1,#0
    str r1,[r0,#multi_signe]     @ change le signe
    mov r1,r0
    mov r0,r3
    //vidmemtit souscpl2 r0 3
    bl ajouterMultiEntier
100:                    @ fin standard de la fonction  
    add sp,sp,#multi_fin
    pop {r1-r3,fp,pc}         @ restaur des registres
/***************************************************/
/*   soustraction  2 multiEntier positifs              */
/* attention le resultat est à l'adresse de r0 dont 
            la valeur initiale est perdue        */ 
/***************************************************/
// r0 contient adresse multientier 1
// r1 contient adresse multientier 2
// r0 retourne adresse du résultat
soustraireMultiEntierPositif:              @ INFO: soustraireMultiEntierPositif
    push {r1-r9,lr}           @ save des registres 
    //mov r2,r0
    mov r6,r1
    ldr r4,[r0,#multi_taille]
    ldr r3,[r1,#multi_taille]
    add r1,r0,#multi_chunk       @ debut des chunks operateur 1
    add r2,r6,#multi_chunk        @ debut des chunks operateur 2
    cmp r4,r3
    bgt 2f
    //mov r0,r6   @ r3 est superieur à r4
    mov r5,r4                  @ indice
    mov r7,#0                  @ valeur
1:
    str r7,[r1,r5,lsl #2]
    add r5,r5,#1
    cmp r5,r3
    blt 1b
    b 4f
2:                             @ alignement operande 1 en stockant des 0 dans les nouveaux chunks
    mov r5,r3 
    mov r7,#0
3:
    str r7,[r2,r5,lsl #2]
    add r5,r5,#1
    cmp r5,r4
    blt 3b
    mov r3,r4                  @ alignement operande 1 sur la taille la plus grande
    
4:
    mov r7,#0               @ indice
    mov r6,#0                @ carry a zero
    //vidregtit debutsous
5:                           @ boucle soustraction
    mov r9,#0
    ldr r4,[r2,r7,lsl #2]
    ldr r5,[r1,r7,lsl #2]
    subs r8,r5,r4
    rsc r9,r9,#0
    subs r8,r8,r6    @ ajout carry
    rsc r6,r9,#0     @ nouveau carry
    str r8,[r1,r7,lsl #2]
    add r7,r7,#1
    cmp r7,r3
    blt 5b
    
    str r3,[r0,#multi_taille]      @ non stocke la taille actuelle
                                 @ analyse finale
    cmp r6,#0                    @ il y a une retenue ?
    streq r6,[r0,#multi_signe]
    beq 100f

    bl inverserMultiEntierOpt      @ inversion du résultat
    mov r6,#-1                   @ car le résultat est négatif
    str r6,[r0,#multi_signe]
    
    blt 100f

98:
    adr r0,szMessErrNbchunk
    bl affichageMess
100:                        @ fin standard de la fonction 
    pop {r1-r9,pc}         @ restaur des registres
/***************************************************/
/*   augmentation des chunks  multiEntier             */
/***************************************************/
// r0 contient adresse multientier
// r1 nouveau nombre de chunks
// r0 retourne adresse identique
etendreMultiEntier:          @ INFO: etendreMultiEntier
    push {r1-r4,lr}        @ save des registres 
    ldr r2,[r0,#multi_taille]
    cmp r1,r2
    ble 100f               @ si plus petit ou égal Raf
    cmp r1,#NBCHUNKMAXI
    bge 99f
    str r1,[r0,#multi_taille]
    add r3,r0,#multi_chunk
    mov r4,#0
1:
    cmp r2,r1
    bge 100f
    str r4,[r3,r2,lsl #2]   @  stocke 0
    add r2,r2,#1            @ incremente indice
    b 1b
99:
    ldr r0,iAdrszMessErrInit
    bl affichageMess
    mov r0,#-1
100:                       @ fin standard de la fonction  
    pop {r1-r4,pc}         @ restaur des registres
/***************************************************/
/*   reduction des chunks  multiEntier             */
/***************************************************/
// r0 contient adresse multientier
// r0 retourne la même adresse du multiEntier reduit
reduireMultiEntier:          @ INFO: reduireMultiEntier
    push {r1-r3,lr}        @ save des registres 
    //vidmemtit reduire r0,3
    ldr r2,[r0,#multi_taille]
    add r3,r0,#multi_chunk
    sub r2,r2,#1           @ indice dernier chunk
    cmp r2, #0             @ 1 seul chunk 
    beq 100f
    ldr r1,[r3,r2,lsl #2]  @ charge dernier chunk
    cmp r1,#0
    bne 100f
1:
    ldr r1,[r3,r2,lsl #2]  @ charge chunk
    cmp r1,#0              @ égal à zéro ?
    bne  2f
    subs r2,r2,#1          @ decremente indice
    bgt 1b                 @ et boucle
2:
    add r2,r2,#1
    str r2,[r0,#multi_taille]

100:                    @ fin standard de la fonction  
    pop {r1-r3,pc}         @ restaur des registres
/***************************************************/
/*   deplacement vers la gauche d'un nombre de bits   multiEntier  */
/***************************************************/
// r0 contient adresse multientier
// r1 contient le nombre de bits
// r2 contient adresse de la zone receptrice
// r0 retourne adresse du nouveau multiEntier
deplacerGaucheMultiEntier:           @ INFO: deplacerGaucheMultiEntier
    push {r1-r7,lr}               @ save des registres 
    //mov r5,r0
    mov r4,r1
    lsr r1,r1,#5                   @ division par 32 pour calculer le nombre de chunk
    lsl r3,r1,#5
    sub r4,r4,r3                   @ calcul reste pour avoir le nombre de bits restants
    bl deplacerGaucheChunkMultiEntier
    //vidmemtit deplgauchechunk r0 3
    cmp r4,#0
    beq 2f
    ldr r3,[r0,#multi_taille]
    add r5,r0,#multi_chunk
    mov r6,#0
    
1:
    ldr r7,[r5,r6,lsl #2]
    lsr r7,r7,r4
    add r1,r6,#1
    ldr r2,[r5,r1,lsl #2]
    rsb r1,r4,#32
    lsl r2,r2,r1          @ modif 23
    orr r7,r7,r2
    str r7,[r5,r6,lsl #2]
    add r6,r6,#1
    cmp r6,r3
    blt 1b

2:
    bl reduireMultiEntier
    
100:                    @ fin standard de la fonction  
    pop {r1-r7,pc}         @ restaur des registres
/***************************************************/
/*   deplacement vers la gauche des chunks  multiEntier  */
/***************************************************/
// r0 contient adresse multientier
// r1 contient le nombre de chunk
// r2 contient l'adresse de la zone receptrice
// r0 retourne adresse du nouveau multiEntier
deplacerGaucheChunkMultiEntier:     @ INFO: deplacerGaucheChunkMultiEntier
    push {r1-r8,lr}               @ save des registres 
    mov r4,r0
    mov r8,r1
    ldr r3,[r4,#multi_taille]
    mov r0,r2
    sub r1,r3,r1                  @ modif 28 janvier
    bl initMultiEntier
    add r5,r4,#multi_chunk          @ adresse chunk origine
    add r4,r0,#multi_chunk          @ adresse chunk  destination
    mov r2,#0                     @ indice
    //vidregtit deplgauche
1:
    add r6,r2,r8                  @ indice chunk origine
    cmp r6,r3                     @ test si < nombre
    blt 2f
    mov r7,#0                     @ si >  on met 0 dans le chnuk
    str r7,[r4,r2,lsl #2]
    b 3f
2:                                @ sinon on met la valeur du chunk situé à distance r1 
    ldr r7,[r5,r6,lsl #2]
    str r7,[r4,r2,lsl #2]
    //vidregtit transfert
3:
    add r2,r2,#1                  @ incremente indice
    cmp r2,r3                     @ test si fin
    blt 1b
    
100:                    @ fin standard de la fonction  
    pop {r1-r8,pc}         @ restaur des registres
/***************************************************/
/*   deplacement vers la gauche d'un bit  */
/***************************************************/
// r0 contient adresse multientier
// r1 contient adresse de la zone receptrice
// r0 retourne le bit extrait
// r1 retourne l'adresse du nouveau multiEntier
deplacerGaucheUnBitMultiEntier:           @ INFO: deplacerGaucheUnBitMultiEntier
    push {r1-r8,lr}               @ save des registres 
    //mov r5,r0
    mov r4,r1
    //lsr r1,r1,#5                   @ division par 32 pour calculer le nombre de chunk
    //lsl r3,r1,#5
    //sub r4,r4,r3                   @ calcul reste pour avoir le nombre de bits restants
    mov r1,#0
    mov r2,r4
    bl deplacerGaucheChunkMultiEntier
    //vidmemtit deplgauchechunk r0 3

    ldr r3,[r0,#multi_taille]
    add r5,r0,#multi_chunk
    mov r6,#0
    ldr r7,[r5]   @ charge le 1er chunk
    tst r7,#1
    movne r8,#1
    moveq r8,#0
1:
    ldr r7,[r5,r6,lsl #2]
    lsr r7,r7,#1
    add r1,r6,#1
    //vidregtit depl1
    cmp r1,r3
    bge 2f
    ldr r2,[r5,r1,lsl #2]
    mov r1,#31
    lsl r2,r2,r1          @ modif 23
    orr r7,r7,r2
2:
    str r7,[r5,r6,lsl #2]
    add r6,r6,#1
    cmp r6,r3
    blt 1b

3:
    bl reduireMultiEntier
    mov r0,r8
    mov r1,r4
100:                    @ fin standard de la fonction  
    pop {r1-r8,pc}         @ restaur des registres
/***************************************************/
/*   deplacement vers la droite   multiEntier  */
/***************************************************/
// r0 contient adresse multientier
// r1 contient le nombre de bits
// r2 contient l'adresse de la zone reservée
// r0 retourne adresse du nouveau multiEntier
deplacerDroiteMultiEntier:          @ INFO: deplacerDroiteMultiEntier
    push {r1-r7,fp,lr}               @ save des registres
    mov r4,r1
    ldr r1,[r0,#multi_taille]
    add r1,r1,#1
    bl etendreMultiEntier
    mov r1,r4
    lsr r1,r1,#5                  @ division par 32
    lsl r3,r1,#5
    sub r4,r4,r3                  @ calcul reste
    bl deplacerDroiteChunkMultiEntier @ génére aussi la zone de sortie
    cmp r4,#0
    beq 2f
    ldr r6,[r0,#multi_taille]
    sub r6,r6,#1
    add r5,r0,#multi_chunk
    //vidregtit deplacerD1
1:
    ldr r7,[r5,r6,lsl #2]
    lsl r7,r7,r4
    //vidregtit deplacerD2
    sub r1,r6,#1
    ldr r2,[r5,r1,lsl #2]
    rsb r1,r4,#32
    lsr r2,r2,r1
    //vidregtit deplacerD3
    orr r7,r7,r2
    str r7,[r5,r6,lsl #2]
    subs r6,r6,#1
    bgt 1b
    ldr r7,[r5]
    lsl r7,r7,r4
    str r7,[r5]
2:
    bl reduireMultiEntier
100:
    pop {r1-r7,fp,pc}
 
 /***************************************************/
/*   deplacement vers la droite d'un nombre de bits   */
/* Attention : modifie le multientier
/***************************************************/
// r0 contient adresse multientier
// r1 contient le nombre de bits (maxi 31)
// r0 retourne adresse du nouveau multiEntier
deplacerDroiteBitsMultiEntier:          @ INFO: deplacerDroiteBitsMultiEntier
    push {r1-r8,lr}               @ save des registres
    cmp r1,#31
    bgt 99f
    mov r4,r1
    ldr r3,[r0,#multi_taille]
    add r5,r0,#multi_chunk
    mov r2,#0
    mov r6,#0
1:
    ldr r7,[r5,r2,lsl #2]  @ charge un chunk
    rsb r1,r4,#32
    lsr r8,r7,r1           @ recupere les r4 bits poids forts
    lsls r7,r7,r4          @ deplace les bits de r4 vers la gauche
    orr r7,r7,r6           @ met en place les bits du chunk precedent
    str r7,[r5,r2,lsl #2]  @ stocke le chunk
    mov r6,r8              @ met les bits deplacés pour le suivant
    add r2,r2,#1
    cmp r2,r3
    blt 1b
    cmp r6,#0              @ reste des bits à la fin
    beq 100f
    str r6,[r5,r2,lsl #2]  @ oui alors on les stocke
    add r2,r2,#1           @ et on ajoute un chunk 
    str r2,[r0,#multi_taille]
    b 100f
99:
    afficherLib "\033[31mNombre de bits> 31 \033[0m \n"
    mov r0,#-1
100:                    @ fin standard de la fonction 
    pop {r1-r8,pc}         @ restaur des registres
/***************************************************/
/*   deplacement vers la droite des chunks  multiEntier  */
/***************************************************/
// r0 contient adresse multientier
// r1 contient le nombre de chunk
// r2 contient l'adresse du nouveau multientier
// r0 retourne adresse du nouveau multiEntier
deplacerDroiteChunkMultiEntier:     @ INFO: deplacerDroiteChunkMultiEntier
    push {r1-r7,lr}               @ save des registres 
    mov r4,r0
    mov r7,r1
    ldr r3,[r4,#multi_taille]
    mov r0,r2
    add r1,r3,r1
    bl initMultiEntier
    add r5,r4,#multi_chunk        @ adresse chunk
    add r4,r0,#multi_chunk
    sub r2,r3,#1                  @ indice
    add r2,r2,r7
    mov r1,r7
1:
    sub r6,r2,r1                  @ indice chunk origine
    cmp r2,r1                     @ test si < nombre
    bge 2f
    mov r7,#0                     @ si < on met 0 dans le chunk
    str r7,[r4,r2,lsl #2]
    b 3f
2:                                @ sinon on met la valeur dans le chunk situé à distance r1 
    ldr r7,[r5,r6,lsl #2]
    str r7,[r4,r2,lsl #2]
3:
    subs r2,r2,#1                  @ decremente indice
    bge 1b

100:                    @ fin standard de la fonction  
    pop {r1-r7,pc}         @ restaur des registres
/***************************************************/
/*  multiplication multiEntier  par entier non signé   */
/***************************************************/
// r0 contient adresse multientier
// r1 contient l'entier non signé
// r2 contient l'adresse de la zone receptrice
// r0 retourne adresse de la zone receptrice
multiplierEntierMultiEntier:          @ INFO: multiplierEntierMultiEntier
    push {r1-r11,lr}               @ save des registres 
    sub sp,sp,#multi_fin * 2
    sub sp,sp,#multi_fin
    mov fp,sp
    mov r4,r0
    mov r7,r1
    ldr r3,[r4,#multi_taille]
    mov r0,r2
    mov r1,r3
    bl initMultiEntier
    mov r5,r0                    @ somme
    //vidregtit mult0
    ldr r0,[r4,#multi_signe]         @ signe
    mov r10,#0                    @ indicateur positif/negatif
    cmp r0,#0
    beq 1f
    mov r10,#1                    @ négatif -> inversion
    mov r0,r4
    mov r1,fp                     @ utilise la première zone de fp
    bl copierMultiEntier
    mov r4,#0
    str r4,[r0,#multi_signe]      @ raz signe
    mov r4,r0
    //vidmemtit inverse r0 3
1:
    add r0,fp,#multi_fin           @ zone reception utilise la 2ième zone de fp
    mov r1,#3
    bl initMultiEntier
    mov r8,r0
    add r9,r8,#multi_chunk         @ zone des chunks
    add r6,r4,#multi_chunk
    sub r2,r3,#1                 @ indice dernier chunk
2:
   ldr r1,[r6,r2,lsl #2]         @ charge un chunk
   mov r0,r6
   //vidmemtit mulboucle00 r0 3
   umull r3,r4,r1,r7
  // vidregtit multboucle0
   str r3,[r9]                   @ stocke partie basse
   str r4,[r9,#4]                 @ stocke partie haute
   mov r4,#0
   str r4,[r9,#8]                 @ stocke zéro
   mov r0,r8
  // vidmemtit mulboucle0 r0 3
   mov r3,r2                     @ save registre r2
   mov r1,r2
   add r2,fp,#multi_fin * 2      @ utilise la 3ième zone de fp
   //vidregtit avantdeplace
   bl deplacerDroiteChunkMultiEntier
   mov r1,r5                      @ resultat précédent
   bl ajouterMultiEntierPositif
   subs r2,r3,#1                  @ recalcule indice
   bge 2b                         @ fin ?
   
   mov r0,r5                      @ retourne le dernier résultat
   cmp r10,#1                     @ si négatif
   bne 3f
   mov r4,#-1
   str r4,[r0,#multi_signe]
3:
    
100:
    add sp,sp,#multi_fin * 2
    add sp,sp,#multi_fin
    pop {r1-r11,pc}
/***************************************************/
/*  multiplication multiEntier  par multiEntier   */
/***************************************************/
// r0 contient adresse multientier 1
// r1 contient adresse multientier 2
// r2 contient adresse zone reception
// r0 retourne adresse du nouveau multiEntier
multiplierMultiEntierNonOpt:             @ INFO: multiplierMultiEntierNonOpt
    push {r1-r12,lr}               @ save des registres 
    sub sp,sp,#multi_fin * 2
    sub sp,sp,#multi_fin * 2
    mov fp,sp
    mov r4,r0
    //mov r9,r2
    mov r10,r1
    ldr r3,[r1,#multi_taille]
    mov r0,r2
    mov r1,r3
    bl initMultiEntier
    mov r9,r0                     @ somme

    ldr r7,[r10,#multi_signe]         @ signe 
    mov r12,#0                    @ indicateur positif/negatif
    cmp r7,#0
    beq 1f
    mov r12,#1                    @ négatif -> inversion
    mov r0,r10
    mov r1,fp
    bl copierMultiEntier
    //vidregtit inversion
    mov r7,#0
    str r7,[r0,#multi_signe]         @ raz signe
    mov r10,r0
1:
    mov r1,r10
    sub r7,r3,#1
    add r8,r1,#multi_chunk        @ zone des chunks
2:
    mov r0,r4
    ldr r1,[r8,r7,lsl #2]
    add r2,fp,#multi_fin
    bl multiplierEntierMultiEntier
   // vidmemtit multboucle r0 3
    mov r1,r7
    //vidregtit depl
    add r2,fp,#multi_fin * 2
    bl deplacerDroiteChunkMultiEntier
    mov r1,r9                  @ somme précédente
    bl ajouterMultiEntierPositif
    subs r7,r7,#1
    bge 2b
    
    mov r0,r9
    cmp r12,#1
    bne 3f
    ldr r4,[r0,#multi_signe]
    cmp r4,#0
    moveq r4,#-1
    movne r4,#0
    str r4,[r0,#multi_signe]
3:
    bl reduireMultiEntier
100:                    @ fin standard de la fonction  
    add sp,sp,#multi_fin  * 2
    add sp,sp,#multi_fin * 2
    pop {r1-r12,pc}         @ restaur des registres
/***************************************************/
/*  multiplication multiEntier  par multiEntier  Optimisation */
/***************************************************/
// r0 contient adresse multientier 1
// r1 contient adresse multientier 2
// r2 contient adresse zone reception
// r0 retourne adresse du nouveau multiEntier
multiplierMultiEntier:             @ INFO: multiplierMultiEntier
    push {r1-r12,lr}               @ save des registres 

    add r9,r0,#multi_chunk         @ zone des chunks oper 1
    add r10,r1,#multi_chunk        @ zone des chunks oper 2
    add r12,r2,#multi_chunk        @ zone des chunks oper 3
    //vidregtit debutbouc
    ldr r7,[r1,#multi_taille]      @ taille oper 2
    ldr r11,[r0,#multi_taille]     @ taille oper 1
    add r6,r7,r11                @ indice taille resultat
    mov r5,#0
    //vidregtit debut
1:
    str r5,[r12,r6,lsl #2]        @ init des chunks résultats
    subs r6,r6,#1
    bge 1b
    mov r5,#0                    @ indice boucle 1
2:                               @ boucle elements oper 2
    //vidregtit boucle1
    ldr r0,[r9,r5,lsl #2]        @ charge un chunk
    mov r4,#0
    mov r8,#0
3:                               @ boucle element oper 1
    add r6,r4,r5                 @ calcul indice résultat 
    ldr r1,[r10,r4,lsl #2]       @ charge un chunk
    umull r2,r3,r1,r0            @ multiplication 32 bits 
    //vidregtit mult1
    ldr r1,[r12,r6,lsl #2]       @ charge le chunk précedent du résultat
    //vidregtit mult2
    adds r1,r1,r2                @ ajoute la partie basse de la multiplication
    movcc r2,#0
    movcs r2,#1
    adds  r1,r1,r8               @ ajout partie haute précédente
    adcs  r8,r3,r2               @ nouvelle partie haute
    //mov r2,#0
    //adc  r2,r2,#0
    //vidregtit mult3
    str r1,[r12,r6,lsl #2]       @ stocke la somme 
   
    add r4,r4,#1
    cmp r4,r7
    blt 3b                       @ et boucle 2
    cmp r8,#0                  @ reste une retenue ou une partie haute
    beq 4f
    add r6,r6,#1               @ ajout chunk
    //ldr r1,[r12,r6,lsl #2]
    //add r8,r1
    str r8,[r12,r6,lsl #2]     @ stockage partie haute finale
4:
    add r5,r5,#1 
    cmp r5,r11
    blt 2b                     @ et boucle 1
    
    add r6,r6,#1               @ taille
    //vidregtit finmult
    sub r0,r12,#multi_chunk    @ calcul adresse multientier à partir adresse des chunk
    str r6,[r0,#multi_taille]    @ maj zone taille
    ldr r4,[r9,#-4]            @ chargement du signe oper 1
    ldr r5,[r10,#-4]           @ chargement signe oper 2
    cmp r4,r5                  @ test des signes
    moveq r6,#0                @ si egaux le résultat est positif
    movne r6,#-1
    str r6,[r0,#multi_signe]
   
    //vidmemtit finmult r0 3

100:                        @ fin standard de la fonction  
    pop {r1-r12,pc}         @ restaur des registres
/***************************************************/
/*  division multiEntier  par multiEntier              */
/***************************************************/
// r0 contient adresse multientier 1  dividende
// r1 contient adresse multientier 2  diviseur
// r2 contient adresse du quotient
// r3 contient adresse du reste
// r0 retourne adresse du nouveau multiEntier quotient
// r1 retourne adresse du nouveau multiEntier reste
diviserMultiEntierNOPT:                @ INFO: diviserMultiEntierNOPT
    push {r2-r12,lr}             @ save des registres 
    sub sp,sp,#multi_fin * 2       @ reserve 4 zones de travail
    sub sp,sp,#multi_fin * 2
    sub sp,sp,#multi_fin
    mov fp,sp
    mov r5,r1                    @ save du diviseur
    bl reduireMultiEntier          @ reduction du dividende 
    //vidmemtit divdebut r0 3
    mov r1,r3                    @ le reste est initialisé avec le dividende
    bl copierMultiEntier
    mov r4,r0                    @ dividende = reste départ
    //vidmemtit dividendedeb r0 3
    mov r0,r5                    @ reduction du diviseur
    bl reduireMultiEntier
    add r1,fp,#multi_fin * 2
    add r1,r1,#multi_fin * 2
    bl copierMultiEntier
    mov r5,r0                    @ copie du diviseur
    
    //vidmemtit diviseurdeb r0 3
    ldr r6,[r4,#multi_taille]      @ taille dividende
    mov r0,r2                    @ zone du quotient
    mov r1,r6
    bl initMultiEntier
    mov r9,r0                     @ init quotient à zéro
    ldr r2,[r5,#multi_taille]       @ taille diviseur
    //vidregtit divdebut
    cmp r6,r2                     @ si dividende < diviseur
    bge 1f
    mov r1,r4                     @ reste = dividende
    mov r0,r9                     @ quotient = 0
    b  100f
1:
    mov r0,r5
    bl testerMultiEntierZero        @ division par zero -> erreur
    cmp r0,#1
    moveq r0,#-1
    beq 100f
    //vidregtit div0
    add r8,r4,#multi_chunk          @ adresse chunk dividende
    sub r1,r6,#1
    ldr r7,[r4,#multi_signe]        @ signe
    mov r12,#0                    @ indicateur positif/negatif
    cmp r7,#0                     @ dividende négatif ?
    beq 1f
    mov r12,#1                    @ négatif -> inversion
    mov r7,#0
    str r7,[r4,#multi_signe]        @ init signe

1:
    add r8,r5,#multi_chunk          @ adresse chunk diviseur
    sub r1,r2,#1
    ldr r7,[r5,#multi_signe]        @ signe
    cmp r7,#0                     @ diviseur négatif ?
    beq 2f
    eor r12,r12,#1                @ négatif -> inversion
    mov r7,#0
    str r7,[r5,#multi_signe]        @ init signe
2:
    sub r1,r6,r2                  @ 
    mov r7,r1
    cmp r1,#0
    ble 3f
    mov r0,r5
    //vidregtit depl
    //vidmemtit depl r0 3
    mov r2,fp
    bl deplacerDroiteChunkMultiEntier
    mov r5,r0
3:
    mov r6,#0
    mov r0,r4
    //vidmemtit etiq3Dividende r0 3
4:
    cmp r6,#31
    bge 5f
    mov r0,r5              @ diviseur
    //vidmemtit Diviseur r0 3
    mov r1,r4              @ dividende
    bl comparerMultiEntier
    //vidregtit retourcompar
    cmp r0,#0
    bge 5f
    add r6,r6,#1
    mov r0,r5
    mov r1,#1
    //vidregtit depl1
    //vidmemtit depl1 r0 3
    add r2,fp,#multi_fin
    bl deplacerDroiteMultiEntier
    //mov r1,r0
    //vidmemtit depl1_2 r0 3
    mov r1,r5
    bl copierMultiEntier
    mov r5,r0
    b 4b
5:
    mov r0,r5
    //vidmemtit etiq5 r0 3
    lsl r7,r7,#5        @ multiplier par 32
    add r6,r6,r7        @ taille totale en bits
    //vidregtit etiq5
6:
    cmp r6,#0
    blt 10f
    mov r0,r9           @ quotient
    mov r1,#1
    add r2,fp,#multi_fin * 2
    bl deplacerDroiteMultiEntier
    mov r1,r9
    bl copierMultiEntier
    //vidmemtit quotient r0 3
    mov r0,r5          @ diviseur
    //vidmemtit diviseur r0 3
    mov r1,r4          @ dividende
    //vidmemtit dividende r1 3
    bl comparerMultiEntier
    cmp r0,#0
    bgt 7f
    //vidregtit avantstoust
    mov r0,r4          @ le dividende est > au diviseur donc soustraction
    mov r1,r5          @ diviseur
    //vidmemtit diviseur r1 3
    add r2,fp,#multi_fin * 2
    add r2,r2,#multi_fin
    bl soustraireMultiEntier
    mov r1,r4          @ nouveau dividende
    bl copierMultiEntier
    add r0,r9,#multi_chunk
    ldr r2,[r0]        @ positionnement à 1 du premier bit du quotient
    orr r2,#1
    str r2,[r0]
7:
    mov r0,r5           @ diviseur
    mov r1,#1
    add r2,fp,#multi_fin  @ reception dans 2ième zone de la pile
    bl deplacerGaucheMultiEntier
    //vidmemtit depldiviseur r0 3
    mov r1,r5           @ puis recopie dans diviseur
    bl copierMultiEntier
    sub r6,r6,#1
    b 6b
10: 
    mov r0,r4           @ reste
    bl reduireMultiEntier
    mov r1,r0           @ retour du reste
    mov r0,r9           @ quotient
    //vidmemtit finreste r1 3
    cmp r12,#1
    bne 11f
    mov r4,#-1
    str r4,[r0,#multi_signe]
11:
   bl reduireMultiEntier

100:                       @ fin standard de la fonction  
    add sp,sp,#multi_fin
    add sp,sp,#multi_fin * 2
    add sp,sp,#multi_fin * 2
    pop {r2-r12,pc}         @ restaur des registres
/***************************************************/
/*  division multiEntier  par multiEntier              */
/***************************************************/
// r0 contient adresse multientier 1  dividende
// r1 contient adresse multientier 2  diviseur
// r2 contient adresse du quotient
// r3 contient adresse du reste
// r0 retourne adresse du nouveau multiEntier quotient
// r1 retourne adresse du nouveau multiEntier reste
diviserMultiEntier:                @ INFO: diviserMultiEntier
    push {r2-r12,lr}             @ save des registres 
    sub sp,sp,#multi_fin * 2     @ reserve 2 zones de travail sur la pile
    mov fp,sp
    mov r5,r1                    @ save du diviseur
    mov r7,#1
    str r7,[r2,#multi_taille]
    mov r7,#0
    str r7,[r2,#multi_signe]
    add r6,r2,#multi_chunk         @ adresse chunk du quotient
    str r7,[r6]                  @ init à 0 du 1er chunk du quotient
    
    add r8,r0,#multi_chunk         @ adresse chunk du dividende
    //vidmemtit dividende r0 3
    add r7,r3,#multi_chunk         @ adresse chunk du reste
    ldr r6,[r0,#multi_signe]
    cmp r6,#0
    moveq r12,#0
    movne r12,#1
    mov r6,#0
    str r6,[r3,#multi_signe]
    ldr r6,[r0,#multi_taille]
    str r6,[r3,#multi_taille]
    subs r4,r6,#1                 @ indice
    beq 2f
1:                                @ reduction du dividende
    ldr r9,[r8,r4,lsl #2]
    cmp r9,#0
    bne 2f
    sub r6,r6,#1
    subs r4,r4,#1
    bne 1b
    add r6,r6,#1
2:                               @ et copie dans le reste
    ldr r9,[r8,r4,lsl #2]
    str r9,[r7,r4,lsl #2]
    subs r4,r4,#1
    bge 2b
    str r6,[r3,#multi_taille]
    mov r4,r3                    @ dividende = reste départ
    
    mov r0,r5                    @ reduction du diviseur
    add r7,r0,#multi_chunk         @ adresse chunk du diviseur
    add r5,fp,#multi_fin
    //add r5,r5,#multi_fin * 2       @ adresse copie du diviseur
    add r10,r5,#multi_chunk         @ adresse chunk de la copie du diviseur
    ldr r6,[r0,#multi_signe]
    cmp r6,#0
    eorne r12,r12,#1
    mov r6,#0
    str r6,[r5,#multi_signe]
    ldr r6,[r0,#multi_taille]
    str r6,[r5,#multi_taille]
    subs r8,r6,#1                 @ indice
    beq 4f
3:                                @ reduction
    ldr r9,[r7,r8,lsl #2]
    cmp r9,#0
    bne 4f
    sub r6,r6,#1                 @ diminue le nombre total de chunk
    subs r8,r8,#1
    bne 3b
    add r6,r6,#1                 @ ajout car un sub de trop dans la boucle ci dessus
    ldr r9,[r7,r8,lsl #2]        @ valeur du 1er chunk
    cmp r9,#0                    @ division par 0 erreur
    moveq r0,#-1
    beq 100f
4:                               @ et copie 
    ldr r9,[r7,r8,lsl #2]
    str r9,[r10,r8,lsl #2]
    subs r8,r8,#1
    bge 4b
   //add r6,r6,#1
    str r6,[r5,#multi_taille]
         // ici r5 contient l'adresse de la copie du diviseur
    
    mov r9,r2                     @ save adresse quotient
    ldr r2,[r5,#multi_taille]       @ taille diviseur
    ldr r6,[r3,#multi_taille]       @ taille dividende
    //vidregtit divdebut
    cmp r6,r2                     @ si dividende < diviseur
    bge 5f
    mov r1,r4                     @ reste = dividende
    cmp r12,#1                    @ si resultat doit être négatif
    moveq r12,#-1
    streq r12,[r1,#multi_signe]
    mov r0,r9                     @ quotient = 0
    b  100f
5:
    sub r1,r6,r2                  @ calcul du nombre différent de chunk 
    mov r7,r1
    cmp r1,#0                     @ si aucun
    ble 6f
    mov r0,r5                     @ sinon déplacement des chunks
    mov r2,fp
    bl deplacerDroiteChunkMultiEntier
    mov r5,r0
6:
    mov r6,#0
    mov r0,r4

7:                                 @ boucle de déplacement d'un bit sur la droite
    cmp r6,#31   
    bge 10f
    mov r0,r5                      @ diviseur
    //vidmemtit Diviseurdiv r0 3
    mov r1,r4                      @ dividende
    //vidmemtit Dividendediv r1 3
    bl comparerMultiEntier         @ arret si le diviseur déplacé sur la droite 
    cmp r0,#0                      @ est plus grand que le dividende
    bge 10f
    add r6,r6,#1
    add r0,r5,#multi_chunk
    ldr r1,[r5,#multi_taille]
    sub r2,r1,#1
    ldr r10,[r0,r2,lsl #2]         @ charge le dernier chunk
    tst r10,#1<<31                 @ teste le dernier bit
    beq 8f                        @ si 0 raf
    mov r2,#0                      @ sinon on ajoute un chunk à 0
    str r2,[r0,r1,lsl #2]
    add r1,r1,#1
    str r1,[r5,#multi_taille]
8:
    mov r2,#0
    mov r8,#0
9:                             @ boucle de déplacement à droite d'un bit du diviseur
    ldr r10,[r0,r2,lsl #2]
    lsls r10,r10,#1
    orr r10,r10,r8
    movcc r8,#0
    movcs r8,#1
    str r10,[r0,r2,lsl #2]
    add r2,r2,#1
    cmp r2,r1
    blt 9b
    
    b 7b                       @ boucle générale
10:  
    // TODO:  le dernier chunk du diviseur doit être à zéro
    //mov r0,r5
    lsl r7,r7,#5        @ multiplier par 32 les chunks déplacés 
    add r6,r6,r7        @ + nombre de bits déplacés = taille totale en bits
    //vidregtit etiq10
11:
    cmp r6,#0
    blt 17f                  @ fin de la boucle des soustractions
    add r0,r9,#multi_chunk    @ deplacement à droite d'un bit du quotient
    ldr r1,[r9,#multi_taille]
    sub r2,r1,#1
    ldr r10,[r0,r2,lsl #2]    @ charge le dernier chunk
    tst r10,#1<<31            @ teste le dernier bit
    beq 12f                   @ si 0 raf
    mov r2,#0                 @ sinon on ajoute un chunk à 0
    str r2,[r0,r1,lsl #2]
    add r1,r1,#1
    str r1,[r9,#multi_taille]
12:
    mov r2,#0
    mov r8,#0
13:                           @ boucle de deplacement d'un bit à droite 
    ldr r10,[r0,r2,lsl #2]
    lsls r10,r10,#1
    orr r10,r10,r8
    movcc r8,#0
    movcs r8,#1
    str r10,[r0,r2,lsl #2]
    add r2,r2,#1
    cmp r2,r1
    blt 13b
    
    //vidmemtit quotient r0 3
    mov r0,r5          @ diviseur
    //vidmemtit diviseur r0 3
    mov r1,r4          @ dividende
    //vidmemtit dividende r1 3
    bl comparerMultiEntier
    cmp r0,#0
    bgt 14f
    //vidregtit avantstoust
    mov r0,r4                       @ le dividende est > au diviseur donc soustraction
    mov r1,r5                       @ diviseur
    bl soustraireMultiEntierPositif @ donne le nouveau dividende
    add r0,r9,#multi_chunk
    ldr r2,[r0]                     @ positionnement à 1 du premier bit du quotient
    orr r2,#1
    str r2,[r0]
14:
    add r0,r5,#multi_chunk          @ adresse chunk diviseur
    ldr r1,[r5,#multi_taille]
    mov r2,#0
    mov r8,#0
15:                                 @ boucle de déplacement d'un bit à gauche
    ldr r10,[r0,r2,lsl #2]         @ charge un chunk
    lsr r10,r10,#1                 @ deplacement droite
    add r7,r2,#1                   @ chunk suivant 
    cmp r7,r1
    bge 16f
    ldr r3,[r0,r7,lsl #2]          @ charge le chunk suivant
    mov r7,#31                     
    lsl r3,r3,r7                   @ extrait le bit 31 du chunk suivant
    orr r10,r10,r3                 @ et le combine avec le chunk courant
16:
    str r10,[r0,r2,lsl #2]         @ stocke le chunk courant
    add r2,r2,#1
    cmp r2,r1
    blt 15b                         @ et boucle 
    sub r2,r2,#1                   @ si le dernier chunk est à zero, on le supprime
    ldr r10,[r0,r2,lsl #2]
    cmp r10,#0
    streq r2,[r5,#multi_taille]
    
    sub r6,r6,#1                 @ et boucle générale 
    b 11b
17: 
    mov r0,r4                    @ reste
    bl reduireMultiEntier
    mov r1,r0                    @ retour du reste
    mov r0,r9                    @ quotient
    //vidmemtit finreste r1 3
    cmp r12,#1
    bne 18f
    mov r4,#-1
    str r4,[r0,#multi_signe]
18:
   bl reduireMultiEntier

100:
    add sp,sp,#multi_fin * 2
    //add sp,sp,#multi_fin * 2
    //add sp,sp,#multi_fin * 2
    pop {r2-r12,pc}
/***************************************************/
/*  conversion chaine vers MultiEntier            */
/***************************************************/
// r0 contient adresse chaine
// r1 contient adresse zone réservée 
// r0 retourne adresse du multiEntier
convertirChaineEnMultiEntier:  @ INFO: convertirChaineEnMultiEntier
    push {r1-r11,lr}             @ save des registres 
    sub sp,sp,#multi_fin * 2
    sub sp,sp,#multi_fin
    mov fp,sp
    mov r4,r0                @ save adresse chaine
    mov r7,r1
    mov r0,fp
    mov r1,#10               @ valeur 10
    bl creerMultiDepuisEntier
    cmp r0,#-1
    beq 99f
    mov r5,r0                @ ou fp
    mov r0,r7                @ resultat
    mov r1,#1                @ 1 chunk
    bl initMultiEntier         @ init résultat à 0
    cmp r0,#-1
    beq 99f
    //vidregtit debut
    mov r12,#0
    mov r6,#0
    ldrb r1,[r4,r6]       @ charge 1er caractère pour vérifier le signe
    cmp r1,#'-'
    moveq r10,#1          @ négatif
    addeq r6,r6,#1        @ avance un caractère
1:                        @ boucle de lecture des caractères de la chaine
    ldrb r1,[r4,r6]      
    cmp r1,#0             @ fin ?
    beq 2f
    cmp r1,#0x30          @ < à zéro ?
    blt 99f
    cmp r1,#0x39          @ > à 9
    bgt 99f
    add r0,fp,#multi_fin
    sub r1,r1,#0x30       @ calcul valeur
    bl creerMultiDepuisEntier @ et conversion en multiEntier
    cmp r0,#-1
    beq 99f
    mov r9,r0              @ adresse résultat
    mov r0,r7              @ resultat prec
    //vidmemtit avantmult r0 3
    mov r1,r5              @ * 10
    add r2,fp,#multi_fin * 2
    bl multiplierMultiEntier
    //vidmemtit apresmult r0 3
    mov r8,r0
    mov r1,r9
    mov r2,r7
    bl ajouterMultiEntier    @ addition des 2
    //mov r7,r0

    //vidregtit finboucle
    add r6,r6,#1           @ et boucle
    b 1b
    
2:
    mov r0,r7
    bl reduireMultiEntier
    
    cmp r10,#1             @ si négatif
    bne 3f
    mov r4,#-1             @ mise en place du signe 
    str r4,[r0,#multi_signe]
3:
    b 100f
99:
    adr r0,szMessErreur1
    bl affichageMess
    mov r0,#-1
100:                    @ fin standard de la fonction  
    add sp,sp,#multi_fin
    add sp,sp,#multi_fin * 2
    pop {r1-r11,pc}         @ restaur des registres
szMessErreur1:      .asciz "\033[31mErreur création MultiEntier !\033[0m\n"
.align 4
/***************************************************/
/*  comparer 2 multiEntier                           */
/***************************************************/
// r0 contient adresse multientier 1
// r1 contient adresse multientier 2
// r0 retourne resultat comparaison non signée
comparerMultiEntier:           @ INFO: comparerMultiEntier
    push {r1-r8,lr}          @ save des registres 
    ldr r2,[r0,#multi_taille]  @ taille 1
    sub r2,r2,#1
    ldr r3,[r1,#multi_taille]  @ taille 2
    sub r3,r3,#1
    add r4,r0,#multi_chunk     @ adresse chunk
    add r6,r1,#multi_chunk     @ adresse chunk
                                 @ comparaison du signe
    ldr r7,[r0,#multi_signe]
    ldr r8,[r1,#multi_signe]
    cmp r7,r8
    beq 1f                   @ signes egaux
    movlt r0,#-1             @ sinon si premier est negatif
    movgt r0,#1              @ sinon si premier est positif
    b 100f

1:
    cmp r2,r3
    ble 2f
    ldr r5,[r4,r2,lsl #2]
    cmp r5,#0
    movne r0,#1
    bne 5f
    sub r2,r2,#1
    b 1b
2:
    cmp r3,r2
    ble 3f
    ldr r5,[r6,r3,lsl #2]
    cmp r5,#0
    movne r0,#-1
    bne 5f
    sub r3,r3,#1
    b 2b
3:
    cmp r2,#0
    blt 4f
    ldr r5,[r4,r2,lsl #2]
    ldr r7,[r6,r2,lsl #2]
    //vidregtit compar
    cmp r5,r7
    movlo r0,#-1
    blo 5f
    movhi r0,#1
    bhi 5f
    sub r2,r2,#1
    b 3b
4:
    mov r0,#0               @ egaux
    b 100f
5:
    cmp r8,#-1              @ signes négatifs ?
    bne 100f
    cmp r0,#-1              @ si oui inversion des résultats
    moveq r0,#1
    movne r0,#-1
100:                        @ fin standard de la fonction  
    pop {r1-r8,pc}         @ restaur des registres
/***************************************************/
/*   copie multiEntier vers multiEntier           */
/***************************************************/
// r0 contient adresse multientier limite haute (positive)
// r1 contient adresse zone résultat réservée 
// r0 retourne adresse multientier aléatoire (positif
creerAleaMultiEntier:           @ INFO: creerAleaMultiEntier
    push {r2-r4,lr}        @ save des registres    
    ldr r3,[r0,#multi_taille]
    str r3,[r1,#multi_taille]
    mov r2,#0
    str r2,[r1,#multi_signe] @ signe +
    sub r3,r3,#1           @ indice dernier chunk 
    add r2,r0,#multi_chunk
    add r4,r1,#multi_chunk
    ldr r0,[r2,r3,lsl #2]  @ charge valeur dernier chunk
    bl genereraleas        @ genere valeur aléatoire inférieure
    str r0,[r4,r3,lsl #2]  @ et la stocke en sortie
1:
    subs r3,r3,#1          @ chunk précédent
    blt 2f                 @ c'est fini
    mov r0,#-1             @ sinon valeur maxi 
    bl genereraleas        @ genére valeur aléatoire
    str r0,[r4,r3,lsl #2]  @ et la stocke
    b 1b                   @ et boucle 
2:
    mov r0,r1              @ retour zone résultat
100:
    pop {r2-r4,pc}
/***************************************************/
/*   division nombre de 64 bits 2 registres par un nombre de 32 bits */
/***************************************************/
/* r0 contient la partie basse dividende   */
/* r1 contient la partie haute dividende   */
/* r2 contient le diviseur   */
/* r0 retourne le partie basse quotient    */
/* r1 retourne la partie haute quotient    */
/* r2 contient le reste                    */
division32R:           @ INFO: division32R
    push {r3-r9,lr}    @ save des registres
    mov r6,#0          @ init reste partie haute haute !!
    mov r7,r1          @ partie haute dans le reste r7,r8
    mov r8,r0          @ partie basse
    mov r9,#0          @ quotient partie haute
    mov r4,#0          @ quotient partie basse
    mov r5,#32
1:    
    lsl r6,#1
    lsls r7,#1
    orrcs r6,#1
    lsls r8,#1        @ on déplace le reste d'un bit à gauche
    orrcs r7,#1
    lsls r4,#1        @ deplacement du quotient d'un bit à gauche
    lsl r9,#1
    orrcs r9,#1
                      @ soustraction du diviseur du reste partie haute
    subs r7,r2
    sbcs  r6,#0
    bmi 2f            @ est il négatif
    
                      @ positif ou egal
    orr r4,#1         @ on met le bit de droite du quotient  à 1
    b 3f
2:                    @ negatif
    orr r4,#0         @ on met le bit de droite à 0
    adds r7,r2        @ et on restaure le reste à sa valeur
    adc  r6,#0 
3:
    subs r5,#1
    bgt 1b
    mov r0,r4         @ quotient partie basse
    mov r1,r9         @ quotient partie haute
    mov r2,r7         @ reste 
100:                  @ fin standard de la fonction
    pop {r3-r9,lr}    @ restaur des  2 registres frame et retour  */
    bx lr  
/********************************************************************/
/*********************************************/
/*constantes */
/********************************************/
.include "src/constantesARM.inc"
