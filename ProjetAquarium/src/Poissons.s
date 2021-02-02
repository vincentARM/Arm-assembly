/* Programme assembleur ARM Raspberry 32 bits ou Android 32 bits*/
/* modèle B 512MO   */
/*  */
/* Poissons  */
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
szMessErreurSaisie:   .asciz "Erreur de saisie !!!.\n"
szMessErreurRepro:    .asciz "Erreur code reproducyion !!!.\n"
szMessNomPoisson:     .asciz "Nom du poisson ? :"
szMessSexePoisson:    .asciz "Sexe du poisson (M ou F) (par défaut : M) ? :"
szMessRacePoisson:    .asciz "Race du poisson ?  saisir le chiffre : \n"
szMessAgePoisson:     .asciz "Age du poisson ?  saisir un chiffre de 0 à 19 : \n"
szMessListeRace:      .asciz " @  : @ \n"

.global szMale,szFemelle
szMale:               .asciz "Male"
szFemelle:            .asciz "Femelle"
szNomPetit:           .asciz "Petit_@_@"

szNomRace1:           .asciz "Mérou"
szNomRace2:           .asciz "Thon"
szNomRace3:           .asciz "Poisson-clown"
szNomRace4:           .asciz "Sole"
szNomRace5:           .asciz "Bar"
szNomRace6:           .asciz "Carpe"

.global tabRace
tabRace:
tbMerou:             .int szNomRace1
                     .int mangerPoisson
                     .int 2
tbThon:              .int szNomRace2
                     .int mangerPoisson
                     .int 1
tbClown:             .int szNomRace3
                     .int mangerPoisson
                     .int 3
tbSole:              .int szNomRace4
                     .int mangerAlgue
                     .int 3
tbBar:               .int szNomRace5
                     .int mangerAlgue
                     .int 2
tbCarpe:             .int szNomRace6
                     .int mangerAlgue
                     .int 1
                   .equ NBPOSTERABRACE,  (. - tabRace) / race_Fin

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
sZoneConv:   .skip 24
sBuffer:     .skip TAILLEBUF
/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text
.global saisirPoisson,ajouterPoisson,reproduirePoisson,viePoissons,repasPoisson
/***************************************************/
/*   saisie des poissons                             */
/***************************************************/
// r0 contient l'adresse de la structure aquarium
saisirPoisson:                  @ INFO: saisirPoisson
    push {r1-r9,lr}             @ save des registres
    mov r9,r0
    ldr r0,iAdrszMessNomPoisson
    bl affichageMess
    mov r0,#STDIN               @ code pour la console d'entrée standard
    ldr r1,iAdrsBuffer          @ adresse du buffer de saisie
    mov r2,#TAILLEBUF           @ taille buffer
    mov r7,#READ                @ appel système pour lecture saisie
    svc #0 
    cmp r0,#0                   @ erreur ?
    blt 99f
                                @ copie nom sur le tas r0 contient la longueur
    bl reserverPlace
    ldr r1,iAdrsBuffer          @ adresse du buffer de saisie
    mov r3,#0
1:
    ldrb r2,[r1,r3]
    cmp r2,#0xA
    beq 2f
    strb r2,[r0,r3]
    add r3,r3,#1
    b 1b
2:
    mov r2,#0
    strb r2,[r0,r3]             @ 0 final
    mov r6,r0
    ldr r0,iAdrszMessSexePoisson
    bl affichageMess
    mov r0,#STDIN               @ code pour la console d'entrée standard
    ldr r1,iAdrsBuffer          @ adresse du buffer de saisie
    mov r2,#TAILLEBUF           @ taille buffer
    mov r7,#READ                @ appel système pour lecture saisie
    svc #0 
    cmp r0,#0                   @ erreur ?
    blt 99f
    ldr r1,iAdrsBuffer          @ adresse du buffer de saisie
    ldrb r0,[r1]
    cmp r0,#'F'
    beq 3f
    cmp r0,#'f'
    beq 3f
    ldr r5,iAdrszMale
    b 4f
3:
    ldr r5,iAdrszFemelle
4:                             @ saisie race
    ldr r0,iAdrszMessRacePoisson
    bl affichageMess
    ldr r3,iAdrtabRace
    mov r8,#race_Fin
    mov r4,#0
5:
    mla r7,r4,r8,r3
    ldr r2,[r7,#race_Nom]
    add r0,r4,#1
    ldr r1,iAdrsZoneConv
    bl conversion10
    ldr r0,iAdrszMessListeRace
    ldr r1,iAdrsZoneConv
    bl insererChaineCar
    mov r1,r2
    bl insererChaineCar
    bl affichageMess
    add r4,r4,#1
    cmp r4,#NBPOSTERABRACE
    blt 5b
    
    mov r0,#STDIN               @ code pour la console d'entrée standard
    ldr r1,iAdrsBuffer          @ adresse du buffer de saisie
    mov r2,#TAILLEBUF           @ taille buffer
    mov r7,#READ                @ appel système pour lecture saisie
    svc #0 
    cmp r0,#0                   @ erreur ?
    blt 99f
    ldr r0,iAdrsBuffer          @ adresse du buffer de saisie
    bl conversionAtoD
    sub r8,r0,#1

    // saisie age
    ldr r0,iAdrszMessAgePoisson
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
    mov r4,r0                   @ paramétre 4 age pour ajout poisson
    
                                @ fin saisie
    mov r0,r9
    mov r1,r6
    mov r2,r5
    mov r3,r8
    mov r5,#PVDEPART
    bl ajouterPoisson
    
    b 100f
99:
    ldr r0,iAdrszMessErreurSaisie
    bl affichageMess
    bkpt
100:                          @ fin standard de la fonction
    pop {r1-r9,lr}            @ restaur des registres
    bx lr                     @ retour de la fonction en utilisant lr
iAdrszMessNomPoisson:   .int szMessNomPoisson
iAdrszMessSexePoisson:  .int szMessSexePoisson
iAdrszMessRacePoisson:  .int szMessRacePoisson
iAdrszMessListeRace:    .int szMessListeRace
iAdrszMessAgePoisson:   .int szMessAgePoisson
iAdrtabRace:            .int tabRace
iAdrszMale:             .int szMale
iAdrszFemelle:          .int szFemelle
iAdrszMessErreurSaisie: .int szMessErreurSaisie
iAdrsBuffer:            .int sBuffer
iAdrsZoneConv:          .int sZoneConv
/***************************************************/
/*   ajouter un poisson                             */
/***************************************************/
// r0 contient l'adresse de la structure aquarium
// r1 contient l'adresse du nom du poisson
// r2 contient le sexe
// r3 contient la race
// r4 contient l'age
// r5 contient les PV
ajouterPoisson:                   @ INFO: ajouterPoisson
    push {r1-r8,lr}               @ save des registres
    mov r6,r0
                                  @ balayage de la liste pour trouver un poisson mort
    ldr r0,[r6,#aqua_listePoissons]
    cmp r0,#0                     @ liste vide
    beq 3f
1:
    ldr r7,[r0,#liste_pointeur]     @ recup structure poisson
    ldr r8,[r7,#poisson_PV]         @ poisson mort ?
    cmp r8,#0
    beq 4f                         @ réutilisation de sa place
    ldr r0,[r0,#liste_suivant]     @ sinon poste suivant
    cmp r0,#0
    bne 1b
3:                                @ pas de place vide création
    mov r0,r1
    mov r1,r2
    mov r2,r3
    mov r3,r4
    mov r4,r5
    bl creerPoisson               @ creer le poisson sur le tas
    mov r1,r0
    add r0,r6,#aqua_listePoissons @ l'ajouter à la liste
    bl ajouterListe
    b 5f
4:                                @ récup de la place d'un poisson mort
    str r1,[r7,#poisson_Nom]
    str r2,[r7,#poisson_Sexe]
    str r3,[r7,#poisson_Race]
    str r4,[r7,#poisson_Age]
    str r5,[r7,#poisson_PV]
5:
    ldr r0,[r6,#aqua_nbPoissons]  @ mettre à jour le compteur
    add r0,r0,#1
    str r0,[r6,#aqua_nbPoissons] 
100:                              @ fin standard de la fonction
    pop {r1-r8,lr}                @ restaur des registres
    bx lr                         @ retour de la fonction en utilisant lr
/***************************************************/
/*   creer un Poisson                             */
/***************************************************/
// r0 contient l'adresse du nom
// r1 contient le sexe
// r0 retourne l'adresse de la structure algue sur le tas
creerPoisson:                @ INFO: creerPoisson
    push {r1-r5,lr}             @ save des registres
    mov r5,r0
    mov r0,#poisson_Fin      @ reserver la place sur le tas
    bl reserverPlace
    str r5,[r0,#poisson_Nom]
    str r1,[r0,#poisson_Sexe]
    str r2,[r0,#poisson_Race]
    str r3,[r0,#poisson_Age]
    str r4,[r0,#poisson_PV]
100:                         @ fin standard de la fonction
    pop {r1-r5,lr}           @ restaur des registres
    bx lr                    @ retour de la fonction en utilisant lr
/***************************************************/
/*   vie des poissons                                */
/***************************************************/
// r0 contient l'adresse de la structure aquarium
viePoissons:                @ INFO: vieAlgues
    push {r1-r4,lr}        @ save des registres
                                    @ poissons ont faim
    ldr r1,[r0,#aqua_listePoissons] @  balayer la liste des poissons
    cmp r1,#0                       @ liste vide ?
    beq 100f
    mov r3,#0
1:
    ldr r2,[r1,#liste_pointeur]
    ldr r4,[r2,#poisson_PV]          @ poisson mort ?
    cmp r4,#0
    ble 2f
    sub r4,#PVPOISSONTOUR
    str r4,[r2,#poisson_PV]          @ poisson a de plus en plus faim
    ldr r4,[r2,#poisson_Age]         @ son age augmente
    add r4,#1
    str r4,[r2,#poisson_Age]         @ son age augmente
    cmp r4,#AGEMAXI
    ble 2f
    mov r4,#0
    str r4,[r2,#poisson_PV]         @ poisson meurt
    ldr r4,[r0,#aqua_nbPoissons]
    sub r4,r4,#1
    str r4,[r0,#aqua_nbPoissons]    @ mettre à jour le compteur
2:
    ldr r1,[r1,#liste_suivant]
    cmp r1,#0
    bne 1b
100:                         @ fin standard de la fonction
    pop {r1-r4,lr}           @ restaur des registres
    bx lr                    @ retour de la fonction en utilisant lr
/***************************************************/
/*   repas des Poissons                             */
/***************************************************/
// r0 contient la structure aquarium 
repasPoisson:                       @ INFO: repasPoisson
    push {r1-r7,lr}                 @ save des registres
    mov r7,r0
    ldr r2,[r0,#aqua_listePoissons] @ balayage poisson dans la liste
    cmp r2,#0                       @ liste vide ?
    beq 100f
    mov r3,#0
    ldr r4,iAdrtabRace
    mov r8,#race_Fin
1:
    ldr r6,[r2,#liste_pointeur]     @ recup structure poisson
    ldr r5,[r6,#poisson_PV]         @ poisson mort ?
    cmp r5,#0
    ble 2f
    cmp r5,#PVFAIMPOISSON           @ le poisson a-t-il faim ?
    bgt 2f
    ldr r5,[r6,#poisson_Race]       @ recup race
    mla r5,r8,r5,r4
    ldr r3,[r5,#race_Repas]         @ appel repas suivant race poissons
    mov r0,r7
    mov r1,r6
    blx r3
2:
    ldr r2,[r2,#liste_suivant]
    cmp r2,#0
    bne 1b
    
100:                       @ fin standard de la fonction
    pop {r1-r7,lr}         @ restaur des registres
    bx lr                  @ retour de la fonction en utilisant lr

/***************************************************/
/*   manger un Poisson                             */
/***************************************************/
// r0 contient le pointeur vers la structure aquarium
// r1 contient le pointeur vers la structure poisson
mangerPoisson:              @ INFO: mangerPoisson
    push {r1-r10,lr}        @ save des registres
    mov r8,r0               @ save structure aquarium
    mov r9,r1               @ save structure poisson
    ldr r10,[r0,#aqua_nbPoissons]
    cmp r10,#1                      @ nombre <= 1 impossible manger !!!
    ble 100f
    cmp r10,#2                      @ si deux poissons on commence au début
    moveq r2,#0
    beq 1f
    mov r0,r10                      @ tirage d'un rang dans la liste si plus d'un poisson
    bl genererAleas
    mov r2,r0
1:
    ldr r1,[r8,#aqua_listePoissons] @ chercher le nieme (r2) poisson dans la liste
    mov r3,#0
2:
    ldr r6,[r1,#liste_pointeur]     @ recup structure poisson
    ldr r5,[r6,#poisson_PV]         @ poisson mort ?
    cmp r5,#0
    ble 4f
    add r3,r3,#1
    cmp r3,r2
    blt 4f
    cmp r6,r9                       @ même poisson ?
    beq 4f
    ldr r7,[r6,#poisson_Race]       @ même race ?
    ldr r2,[r9,#poisson_Race]
    cmp r2,r7
    beq 4f
    mov r5,#0
    str r5,[r6,#poisson_PV] 
    ldr r5,[r8,#aqua_nbPoissons]
    sub r5,r5,#1
    str r5,[r8,#aqua_nbPoissons]    @ supprimer le poisson et mettre à jour le compteur
    ldr r5,[r9,#poisson_PV]         @ et le poisson mangeur reprend des forces 
    add r5,#PVREPASPOISSON
    str r5,[r9,#poisson_PV]
    b 100f
4:
    ldr r1,[r1,#liste_suivant]
    cmp r1,#0
    bne 2b
    cmp r3,r10                      @ le tour de la liste a été fait 
    bge 100f
    ldr r1,[r8,#aqua_listePoissons] @ si fin de liste on repart au debut
    b 2b                            @ sans remettre le compteur à zéro
100:                       @ fin standard de la fonction
    pop {r1-r10,lr}         @ restaur des registres
    bx lr                  @ retour de la fonction en utilisant lr

/***************************************************/
/*   manger une algue                             */
/***************************************************/
// r0 contient l'adresse de la structure aquarium
// r1 contient la structure poisson
mangerAlgue:                @ INFO: mangerAlgue
    push {r1-r9,lr}         @ save des registres
    //vidregtit debrepasAlgue
    mov r4,r0
    mov r7,r1
    ldr r8,[r0,#aqua_nbAlgues]
    cmp r8,#0               @ nombre > 0
    ble 100f
    cmp r8,#1               @ si une seule algue on commence au début
    moveq r2,#0
    beq 1f
    mov r0,r8
    bl genererAleas
    mov r9,r0
1:
    ldr r1,[r4,#aqua_listeAlgues] @ chercher la nieme (r2) algue dans la liste
    mov r3,#0
2:
    ldr r6,[r1,#liste_pointeur]
    ldr r5,[r6,#algue_PV]         @ algue morte ?
    cmp r5,#0
    ble 4f
    
    cmp r3,r9
    addlt r3,r3,#1
    blt 4f
    subs r5,r5,#NBPVALGUEMANGE
    bgt 3f
    mov r5,#0                     @ algue morte
    ldr  r2,[r4,#aqua_nbAlgues]
    sub r2,r2,#1
    str  r2,[r4,#aqua_nbAlgues]
3:
    str r5,[r6,#algue_PV] 
    ldr r5,[r7,#poisson_PV]
    add r5,#PVREPASALGUE
    str r5,[r7,#poisson_PV]
    b 100f
4:
    ldr r1,[r1,#liste_suivant]
    cmp r1,#0
    bne 2b
    cmp r3,r8                       @ tour complet ?
    bgt 100f 
    ldr r1,[r4,#aqua_listeAlgues]   @ si fin de liste on repart au debut
    b 2b                            @ sans remettre le compteur à zéro

100:                       @ fin standard de la fonction
    pop {r1-r9,lr}         @ restaur des registres
    bx lr                  @ retour de la fonction en utilisant lr
/***************************************************/
/*   reproduction des poissons                       */
/***************************************************/
// r0 contient l'adresse de la structure aquarium
reproduirePoisson:                  @ INFO: reproduirePoisson
    push {r1-r5,lr}                 @ save des registres
    mov r4,r0
    ldr r6,[r0,#aqua_nbPoissons]
    cmp r6,#1                       @ un seul ou zero poisson pas de reproduction
    ble 100f
    ldr r5,[r0,#aqua_listePoissons] @  balayer la liste des poissons
    mov r7,#0                       @ compteur
1:
    ldr r2,[r5,#liste_pointeur]
    ldr r3,[r2,#poisson_PV]         @ poisson mort ou qui a faim?
    cmp r3,#0
    beq 2f
    add r7,r7,#1                   @ comptage des poissons vivants 
    cmp r3,#PVFAIMPOISSON
    ble 2f
    mov r0,r4
    mov r1,r2
    bl chercherAmeSoeur
2:
    cmp r7,r6                      @ si nombre de poissons au début du tour atteint 
    bge 100f
    ldr r5,[r5,#liste_suivant]
    cmp r5,#0
    bne 1b
100:                       @ fin standard de la fonction
    pop {r1-r5,lr}         @ restaur des registres
    bx lr                  @ retour de la fonction en utilisant    lr
/***************************************************/
/*   recherche autre poisson                       */
/***************************************************/
// r0 contient l'adresse de la structure aquarium
// r1 contient l'adresse de la structure poisson
chercherAmeSoeur:           @ INFO: chercherAmeSoeur
    push {r1-r10,lr}        @ save des registres
    mov r8,r0
    mov r9,r1
    ldr r10,[r8,#aqua_nbPoissons]
    cmp r10,#2               @ si deux poissons on commence au début
    moveq r4,#0
    beq 1f
    mov r0,r10               @ tirage d'un rang dans la liste si plus d'un poisson
    bl genererAleas
    mov r4,r0
1:
    ldr r1,[r8,#aqua_listePoissons] @ chercher le nieme (r2) poisson dans la liste
    mov r3,#0
2:
    ldr r6,[r1,#liste_pointeur]     @ recup structure poisson
    ldr r5,[r6,#poisson_PV]   @ poisson mort ?
    cmp r5,#0
    ble 6f
    cmp r3,r4                 @ cherche nième poisson
    add r3,r3,#1
    blt 6f
    cmp r6,r9                 @ même poisson ?
    beq 6f
    ldr r7,[r6,#poisson_Race]  @ même race ?
    ldr r2,[r9,#poisson_Race]
    cmp r2,r7
    bne 100f                 @ donc rencontre echoue
                             @ recherche du type
    mov r2,#race_Fin
    ldr r5,iAdrtabRace
    mla r7,r2,r7,r5
    ldr r2,[r7,#race_TypeRep]
    cmp r2,#1
    bne 3f
    ldr r7,[r6,#poisson_Sexe]       @ mono sexué
    ldr r2,[r9,#poisson_Sexe]
    cmp r2,r7
    beq 100f                        @ raté car même sexe 
    b 7f
3:
    cmp r2,#2
    bne 4f
    ldr r2,[r9,#poisson_Age]       @ Hermaphrodite avec l'âge
    cmp r2,#AGEREPROHERMA
    ldrlt r2,iAdrszMale
    ldrge r2,iAdrszFemelle
    ldr r7,[r6,#poisson_Sexe]
    cmp r2,r7
    beq 100f                      @ raté car même sexe 
    b 7f    
4:
    cmp r2,#3                 @ il change de sexe et se reproduit
    beq 7f

5:
    ldr r0,iAdrszMessErreurRepro
    bl affichageMess
    bkpt
6:
    ldr r1,[r1,#liste_suivant]
    cmp r1,#0
    bne 2b
    cmp r3,r10                     @ tour complet ?
    bgt 100f 
    ldr r1,[r8,#aqua_listePoissons] @ si fin de liste on repart au debut
    b 2b                            @ sans remettre le compteur à zéro

7:                                 @ TODO: creation du bebe
    ldr r0,iAdrszNomPetit          @ le petit a le nom des 2 parents
    ldr r1,[r9,#poisson_Nom]
    bl insererChaineCar
    ldr r1,[r6,#poisson_Nom]
    bl insererChaineCar
    bl tronquerNom                 @ mais tronqué à 20 caractères
    mov r1,r0                      @ r1 contient l'adresse du nom du poisson
    mov r0,#2                      @ sexe au hasard
    bl genererAleas
    cmp r0,#1
    ldreq r2,iAdrszFemelle
    ldrne r2,iAdrszMale
    // r1 contient l'adresse du nom du poisson
    // r2 contient le sexe
    // r3 contient la race
    // r4 contient l'age
    mov r0,r8
    ldr r3,[r6,#poisson_Race]  @ même race 
    mov r4,#0                  @ age = 0
    mov r5,#PVDEPART           @ PV
    bl ajouterPoisson
    
100:                        @ fin standard de la fonction
    pop {r1-r10,lr}         @ restaur des registres
    bx lr                   @ retour de la fonction en utilisant    lr
iAdrszNomPetit:        .int szNomPetit
iAdrszMessErreurRepro: .int szMessErreurRepro
/***************************************************/
/*   tronquer nom bébé poisson                 */
/***************************************************/
// r0 contient l'adresse du début du nom
// r0 retourne l'adresse du début du nom
tronquerNom:                    @ INFO: tronquerNom
    push {r1,r2,lr}              @ save des registres
    mov r1,#0
1:
    ldrb r2,[r0,r1]
    cmp r2,#0
    beq 100f
    add r1,r1,#1
    cmp r1,#20
    blt 1b
    mov r2,#0
    strb r2,[r0,r1]
    
100:                             @ fin standard de la fonction
    pop {r1,r2,lr}               @ restaur des registres
    bx lr                        @ retour de la fonction en utilisant lr

