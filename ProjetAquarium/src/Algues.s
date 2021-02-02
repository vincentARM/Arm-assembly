/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* modèle B 512MO   */
/*  */
/* Algues  */
/*********************************************/
/*           CONSTANTES                      */
/********************************************/
.include "./src/constAqua.inc"

/*******************************************/
/* Structures                               */
/********************************************/
.include "./src/structAqua.inc"

/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessErreurSaisie:     .asciz "Erreur de saisie !!!.\n"
szMessAgeAlgue:         .asciz "Age de l'algue ?  saisir un chiffre de 0 à 19 : \n"
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
.global saisirAlgue,ajouterAlgue,vieAlgues,reproduireAlgue
/***************************************************/
/*   ajouter une algue                             */
/***************************************************/
// r0 contient l'adresse de la structure aquarium
saisirAlgue:                    @ INFO: saisirAlgue
    push {r1-r7,lr}             @ save des registres
    mov r4,r0
    ldr r0,iAdrszMessAgeAlgue   @ saisie age
    bl affichageMess
    mov r0,#STDIN               @ code pour la console d'entrée standard
    ldr r1,iAdrsBuffer          @ adresse du buffer de saisie
    mov r2,#TAILLEBUF           @ taille buffer
    mov r7,#READ                @ appel système pour lecture saisie
    svc #0 
    cmp r0,#0                   @ erreur ?
    blt 99f
    ldr r0,iAdrsBuffer          @ adresse du buffer de saisie
    bl conversionAtoD
    mov r1,r0                   @ paramétre 1 
    mov r0,r4                   @ fin saisie
    mov r2,#PVDEPART
    bl ajouterAlgue
    b 100f
99:
    ldr r0,iAdrszMessErreurSaisie
    bl affichageMess
    bkpt
100:                            @ fin standard de la fonction
    pop {r1-r7,lr}              @ restaur des registres
    bx lr                       @ retour de la fonction en utilisant lr
iAdrszMessAgeAlgue:       .int szMessAgeAlgue
iAdrszMessErreurSaisie:   .int szMessErreurSaisie
iAdrsBuffer:              .int sBuffer
/***************************************************/
/*   ajouter une algue                             */
/***************************************************/
// r0 contient l'adresse de la structure aquarium
// r1 contient l'age de l'algue
// r2 contient les points de vie
ajouterAlgue:                   @ INFO: ajouterAlgue
    push {r1-r3,lr}             @ save des registres
    mov r3,r0
    mov r0,r1
    mov r1,r2
    bl creerAlgue               @ creer l'algue sur le tas
    mov r1,r0
    add r0,r3,#aqua_listeAlgues @ l'ajouter à la liste
    bl ajouterListe
    
    ldr r0,[r3,#aqua_nbAlgues]  @ mettre à jour le compteur
    add r0,r0,#1
    str r0,[r3,#aqua_nbAlgues] 
100:                            @ fin standard de la fonction
    pop {r1-r3,lr}              @ restaur des registres
    bx lr                       @ retour de la fonction en utilisant lr
/***************************************************/
/*   creer une algue                             */
/***************************************************/
// r0 contient l'age de l'algue
// r1 contient les PV
// r0 retourne l'adresse de la structure algue sur le tas
creerAlgue:                @ INFO: creerAlgue
    push {r1,r2,lr}        @ save des registres
    mov r2,r0
    mov r0,#algue_Fin      @ reserver la place sur le tas
    bl reserverPlace
    str r1,[r0,#algue_PV]  @ mettre à jour les PV
    str r2,[r0,#algue_Age] @ mettre à jour l'age

100:                       @ fin standard de la fonction
    pop {r1,r2,lr}         @ restaur des registres
    bx lr                  @ retour de la fonction en utilisant lr
/***************************************************/
/*   vie des algues                                */
/***************************************************/
// r0 contient l'adresse de la structure aquarium
vieAlgues:                @ INFO: vieAlgues
    push {r1-r4,lr}        @ save des registres
    ldr r1,[r0,#aqua_listeAlgues] @  balayer la liste des algues
    cmp r1,#0                     @ liste vide ?
    beq 100f
    mov r3,#0
1:
    ldr r2,[r1,#liste_pointeur]
    ldr r4,[r2,#algue_PV]         @ algue morte ?
    cmp r4,#0
    ble 2f
    add r4,#PVALGUETOUR
    str r4,[r2,#algue_PV]          @ algue croit 
    ldr r4,[r2,#algue_Age]         @ son age augmente
    add r4,r4,#1
    str r4,[r2,#algue_Age]         @ son age augmente
    cmp r4,#AGEMAXI
    ble 2f
    mov r4,#0
    str r4,[r2,#algue_PV]         @ algue meurt
    ldr r4,[r0,#aqua_nbAlgues]
    sub r4,#1
    str r4,[r0,#aqua_nbAlgues]    @ mise à jour du compteur
2:
    ldr r1,[r1,#liste_suivant]
    cmp r1,#0
    bne 1b
100:                       @ fin standard de la fonction
    pop {r1-r4,lr}         @ restaur des registres
    bx lr                  @ retour de la fonction en utilisant lr
/***************************************************/
/*   reproduction des algues                       */
/***************************************************/
// r0 contient l'adresse de la structure aquarium
reproduireAlgue:                  @ INFO: reproduireAlgue
    push {r1-r5,lr}               @ save des registres
    mov r4,r0
    ldr r5,[r0,#aqua_listeAlgues] @  balayer la liste des algues
    cmp r5,#0                     @ liste vide ?
    beq 100f
1:
    ldr r2,[r5,#liste_pointeur]
    ldr r3,[r2,#algue_PV]         @ algue morte ?
    cmp r3,#0
    ble 2f
    cmp r3,#AGEREPRODUCTION
    blt 2f
    lsr r3,#1                 @ points de vie divisée par 2
    str r3,[r2,#algue_PV] 
                             @ il faut creer le bebe algue
    mov r0,r4                @ adresse structure aquarium
    mov r2,r3
    mov r1,#0                @ age = 0
    bl ajouterAlgue
2:
    ldr r5,[r5,#liste_suivant]
    cmp r5,#0
    bne 1b
100:                       @ fin standard de la fonction
    pop {r1-r5,lr}         @ restaur des registres
    bx lr                  @ retour de la fonction en utilisant    lr

