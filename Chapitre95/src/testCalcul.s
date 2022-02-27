/* Programme assembleur ARM Raspberry ou android avec termux*/
/* exemples de test des routines de calcul multiprecision   */

/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/
.equ LGBUFFER, 100
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
szMessDebutPgm:      .asciz "Début du programme. \n"
szMessErreur:        .asciz "\033[31mErreur rencontrée.\033[0m\n"
szMessFinOK:         .asciz "Fin normale du programme. \n"
szRetourLigne:       .asciz "\n"
szChaine1:           .asciz "-123456789456789456789456789123456789"

.align 4
nombreFictif:       .int 1
                    .int -1
                    .int 20
                    .zero 4 * NBCHUNKMAXI

nombreFictif1:      .int 1
                    .int 0
                    .int 12
                    .zero 4 * NBCHUNKMAXI
nombreFictif2:      .int 1
                    .int 0
                    .int -1
                    .zero 4 * NBCHUNKMAXI
nombreFictif3:     .int 2
                    .int -1
                    .int 0xFFFFFF8
                    .int 0xFFFF
                    .zero 4 * NBCHUNKMAXI
nombreFictif4:      .int 2
                    .int 0
                    .int 101
                    .int 10
                    .zero 4 * NBCHUNKMAXI
nombreFictif5:      .int 2
                    .int 0
                    .int 0
                    .int 2
                    .zero 4 * NBCHUNKMAXI
        
// Nombres pour le controle des opérations
nombreFictifC1 :    .int 4
                    .int -1
                    .int 0x76795F15
                    .int 0x64F583AB
                    .int 0xC146B280
                    .int 0x0017C6E3
                    .zero 4 * NBCHUNKMAXI
                    
nombreFictifC2:     .int 1
                    .int 0
                    .int 24
                    .zero 4 * NBCHUNKMAXI
nombreFictifC3:     .int 2
                    .int 0
                    .int 11
                    .int 1
                    .zero 4 * NBCHUNKMAXI
nombreFictifC4:     .int 3
                    .int -1
                    .int 0xF0000008
                    .int 0x0FFEFFF8
                    .int 0xFFFF
                    .zero 4 * NBCHUNKMAXI

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
multiEntier1:  .skip multi_fin
multiEntier2:  .skip multi_fin
multiEntier3:  .skip multi_fin
sBuffer:       .skip LGBUFFER

/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text            
.global main                    @ INFO: main

main:                           @ programme principal 
    ldr r0,iAdrszMessDebutPgm   @ 
    bl affichageMess            @  
    
    afficherLib "CreationEntier à 0"
    ldr  r0,iAdrmultiEntier1    @ adresse zone réservée
    mov r1,#5                   @ nombre de chunks à initialiser
    bl initMultiEntier
    cmp r0,#-1                  @ erreur ?
    beq 99f
    mov r4,r0
    vidmemtit creation r0 4     @ affiche la zone mémoire
    bl afficherMultiEntier      @ affiche le nombre  
    mov r0,r4
    bl testerMultiEntierZero    @ verifie si le nombre est bien = à zéro
    cmp r0,#1
    beq 1f                      @ oui 
    afficherLib "\033[31mErreur Création Nombre !!\033[0m \n"
    mov r0,#-1
    b 100f 
1:
    afficherLib CreationEntierPositif
    ldr r0,iAdrmultiEntier2      @ adresse zone réservée
    mov r1,#12                   @ valeur à creer
    bl creerMultiDepuisEntier
    cmp r0,#-1                   @ erreur ?
    beq 99f
    bl afficherMultiEntier       @ affichage du nombre
    
    
    afficherLib "CreationEntierNegatif"
    ldr r0,iAdrmultiEntier3
    mov r1,#-20                  @ valeur négative
    bl creerMultiDepuisEntier
    cmp r0,#-1
    beq 99f
    mov r5,r0
    vidmemtit creationnegatif r0 4
    bl afficherMultiEntier       @ affichage du nombre crée
    mov r0,r5
    ldr r1,iAdrnombreFictif      @ valeur à comparer
    bl comparerMultiEntier
    cmp r0,#0
    beq 2f
    afficherLib "\033[31mErreur Création Nombre négatif!!\033[0m \n"
    mov r0,#-1
    b 100f
2:
    afficherLib "Conversion chaine en multiEntier"
    ldr r0,iAdrszChaine1             @ adresse de la chaine
    ldr r1,iAdrmultiEntier3          @ sert de zone résultat
    bl convertirChaineEnMultiEntier
    mov r4,r0
    bl afficherMultiEntier
    mov r0,r4
    ldr r1,iAdrnombreFictifC1
    bl comparerMultiEntier
    cmp r0,#0
    beq 3f
    afficherLib "\033[31mErreur conversion chaine en multientier!!\033[0m \n"
    mov r0,#-1
    b 100f
3:

    afficherLib additionpetitpositif
    ldr r0,iAdrnombreFictif1
    mov r1,r0
    ldr r2,iAdrmultiEntier3          @ sert de zone résultat
    bl ajouterMultiEntier
    mov r4,r0
    vidmemtit ajoutpetitpos r0 3
    bl afficherMultiEntier
    mov r0,r4
    ldr r1,iAdrnombreFictifC2
    bl comparerMultiEntier
    cmp r0,#0
    beq 4f
    afficherLib "\033[31mErreur ajout petit nombre!!\033[0m \n"
    mov r0,#-1
    b 100f
    
4:
    afficherLib additiongrandpositif
    ldr r0,iAdrnombreFictif1
    ldr r1,iAdrnombreFictif2
    ldr r2,iAdrmultiEntier3          @ sert de zone résultat
    bl ajouterMultiEntier
    mov r4,r0
    vidmemtit ajoutgrandpos r0 3
    bl afficherMultiEntier
    mov r0,r4
    ldr r1,iAdrnombreFictifC3
    bl comparerMultiEntier
    cmp r0,#0
    beq 5f
    afficherLib "\033[31mErreur ajout grand nombre!!\033[0m \n"
    mov r0,#-1
    b 100f
5:
    afficherLib multiplicationpositifnegatifOPTI
    ldr r4,iAdrnombreFictif2
    mov r0,r4
    bl afficherMultiEntier
    ldr r5,iAdrnombreFictif3
    mov r0,r5
    bl afficherMultiEntier
    mov r0,r4
    mov r1,r5
    ldr r2,iAdrmultiEntier3          @ sert de zone résultat
    bl multiplierMultiEntier
    mov r4,r0
    vidmemtit multentier r0 3
    bl afficherMultiEntier
    mov r0,r4
    ldr r1,iAdrnombreFictifC4
    bl comparerMultiEntier
    cmp r0,#0
    beq 6f
    afficherLib "\033[31mErreur multiplication positif negatif!!\033[0m \n"
    mov r0,#-1
    b 100f

6:
    afficherLib Division
    ldr r0,iAdrnombreFictif4       @ dividende
    ldr r1,iAdrnombreFictif5       @ diviseur
    ldr r2,iAdrmultiEntier3          @ quotient
    ldr r3,iAdrmultiEntier1          @ reste 
    bl diviserMultiEntier
    mov r4,r0
    bl afficherMultiEntier      @ doit afficher le quotient
    mov r0,r1
    bl afficherMultiEntier      @ doit afficher le reste

    mov r0,r4
    bl convertirMultiEntierEnEntier
    cmp r0,#5
    beq 7f
    afficherLib "\033[31mErreur quotient division nombre !!\033[0m \n"
    mov r0,#-1
    b 100f
7:
    mov r0,r1
    bl convertirMultiEntierEnEntier
    cmp r0,#101
    beq 8f
    afficherLib "\033[31mErreur reste division nombre !!\033[0m \n"
    mov r0,#-1
    b 100f
8:
    
    afficherLib multiplicationetdivision
    ldr r4,iAdrnombreFictif2
    mov r0,r4
    bl afficherMultiEntier
    ldr r5,iAdrnombreFictif3
    mov r0,r5
    bl afficherMultiEntier
    mov r0,r4
    mov r1,r5
    ldr r2,iAdrmultiEntier3 
    bl multiplierMultiEntier
    mov r4,r0
    vidmemtit multentier r0 3
    bl afficherMultiEntier
    
    afficherLib VerifNombre
    ldr r0,iAdrnombreFictif3
    bl afficherMultiEntier
    
    afficherLib Division
    mov r0,r4
    ldr r1,iAdrnombreFictif3
    ldr r2,iAdrmultiEntier1          @ quotient
    ldr r3,iAdrmultiEntier2          @ reste
    bl diviserMultiEntier
    bl afficherMultiEntier
    mov r0,r1            @ reste
    vidmemtit restefinal r0 3
    bl afficherMultiEntier
    mov r0,r1
    bl testerMultiEntierZero
    cmp r0,#1
    beq 9f
    afficherLib "\033[31mErreur reste division non à zéro !!\033[0m \n"
    mov r0,#-1
    b 100f
    
9:
    
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
iAdrszRetourLigne:      .int szRetourLigne
iAdrmultiEntier1:       .int multiEntier1
iAdrmultiEntier2:       .int multiEntier2
iAdrmultiEntier3:       .int multiEntier3

iAdrsBuffer:            .int sBuffer
iAdrnombreFictif:       .int nombreFictif
iAdrnombreFictif1:       .int nombreFictif1
iAdrnombreFictif2:      .int nombreFictif2
iAdrnombreFictif3:      .int nombreFictif3
iAdrnombreFictif4:      .int nombreFictif4
iAdrnombreFictif5:      .int nombreFictif5
iAdrszChaine1:          .int szChaine1
iAdrnombreFictifC1:     .int nombreFictifC1
iAdrnombreFictifC2:     .int nombreFictifC2
iAdrnombreFictifC3:     .int nombreFictifC3
iAdrnombreFictifC4:     .int nombreFictifC4

/***************************************************/
/*   affichage multi entier               */
/***************************************************/
// r0 adresse du multi entier
afficherMultiEntier:         @ INFO: afficherMultiEntier
    push {r1,r2,lr}          @ save des registres
    ldr r1,iAdrsBuffer1
    mov r2,#LGBUFFER
    bl convertirMultiVersChaine
    cmp r0,#-1
    beq 99f
    bl affichageMess
    
    ldr r0,iAdrszRetourLigne1
    bl affichageMess
    b 100f
99:
    adr r0,szMessErrAff
    bl affichageMess
    mov r0,#-1
100:                       @ fin standard de la fonction
    pop {r1,r2,pc}         @ restaur des registres
iAdrsBuffer1:        .int sBuffer
iAdrszRetourLigne1:  .int szRetourLigne
szMessErrAff:        .asciz "\033[31mErreur conversion !!\033[0m \n"
.align 4
/********************************************************************/
/*********************************************/
/*constantes */
/********************************************/
.include "src/constantesARM.inc"
