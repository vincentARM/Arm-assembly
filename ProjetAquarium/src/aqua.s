/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* modèle B 512MO   */
/*  */
/* simulation d'un aquarium  */
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
szMessDebutPgm:      .asciz "Début du programme. \n"
szMessErreur:        .asciz "Erreur rencontrée.\n"

szMessFinOK:         .asciz "Fin normale du programme. \n"
szMessAlgues:        .asciz "Nombre d'algues : @ \n"
szMessPoissons:      .asciz "Nom poisson : @  sexe : @  race : @  age : @ PV : @\n"
szMessTour:          .asciz "========== Tour N° @ ==============\n"
szMessCommande:      .asciz "<P>oisson <A>lgue <S>auve <F>in \n"
szMessFinSave:       .asciz "Aquarium sauvé sous @ \n"
szRetourligne:       .asciz  "\n"

szParamRestau:       .asciz "-r"
szParamInit:         .asciz "-i"
szParamLog:          .asciz "-l"

szNomP1:             .asciz "Nemo"
szNomP2:             .asciz "Puce"

szNomFichierSave:     .asciz "Aquarium_@"
.align 4

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
sZoneConv:    .skip 24
iAdrszFicLog: .skip 4
iFdFicLog:    .skip 4
stAquarium:   .skip aqua_fin
sBuffer:      .skip TAILLEBUF
sBufferLect:  .skip TAILLEBUF
/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text            
.global main                    @ 'main' point d'entrée doit être  global 
main:                           @ INFO: programme principal 
    ldr r0,iAdrszMessDebutPgm   @ r0 ← adresse message debut 
    bl affichageMess            @ affichage message dans console
    ldr r0,iAdrstAquarium
    mov r1,sp                   @ adresse pile pour récuperer parametres ligne de commande
    bl traiterCommande
    cmp r0,#0
    bne 1f

    ldr r0,iAdrstAquarium       @ initialisation par défaut 2 algues 2 poissons
    mov r1,#0
    mov r2,#10
    bl ajouterAlgue
    ldr r0,iAdrstAquarium
    mov r1,#0
    mov r2,#10
    bl ajouterAlgue
    
    ldr r0,iAdrstAquarium
    ldr r1,iAdrszNompP1
    ldr r2,iAdrszMale
    mov r3,#5
    mov r4,#0                 @ age
    mov r5,#PVDEPART
    bl ajouterPoisson
    ldr r0,iAdrstAquarium
    ldr r1,iAdrszNompP2
    ldr r2,iAdrszFemelle
    mov r3,#5
    mov r4,#0                 @ age
    mov r5,#PVDEPART
    bl ajouterPoisson
    
1:                            @ debut boucle de simulation
                              @ ici tout le monde vit à chaque tour
    ldr r0,iAdrstAquarium
    bl vieAlgues
    ldr r0,iAdrstAquarium
    bl viePoissons
                              @ ici les poissons mangent
    ldr r0,iAdrstAquarium
    bl repasPoisson
                              @ ici les algues se reproduisent
    ldr r0,iAdrstAquarium
    bl reproduireAlgue
                              @ ici les poissons se reproduisent
    ldr r0,iAdrstAquarium
    bl reproduirePoisson
    
    ldr r0,iAdrstAquarium     @ affichage etat de l'aquarium 
    bl afficherAquarium
                              @ gestion des commandes
    ldr r0,iAdrszMessCommande
    bl affichageMess
    mov r0,#STDIN               @ code pour la console d'entrée standard
    ldr r1,iAdrsBuffer          @ adresse du buffer de saisie
    mov r2,#TAILLEBUF           @ taille buffer
    mov r7,#READ                @ appel système pour lecture saisie
    svc #0 
    cmp r0,#0                   @ erreur ?
    blt 99f
    ldr r1,iAdrsBuffer
    ldrb r0,[r1]
    cmp r0,#'f'
    beq 90f
    cmp r0,#'F'
    beq 90f
    cmp r0,#'a'
    beq 2f
    cmp r0,#'A'
    beq 2f
    cmp r0,#'p'
    beq 3f
    cmp r0,#'P'
    beq 3f
    cmp r0,#'s'
    beq 4f
    cmp r0,#'S'
    beq 4f
    b 10f
2:
    ldr r0,iAdrstAquarium
    bl saisirAlgue
    b 10f
3:
    ldr r0,iAdrstAquarium
    bl saisirPoisson
    b 10f
4:
    ldr r0,iAdrstAquarium
    bl sauverAquarium
    b 10f
10:
    b 1b                       @ boucle tour

90:
    ldr r0,iAdriFdFicLog1       @ fermeture du fichier log
    ldr r0,[r0]
    cmp r0,#0                   @ si necessaire 
    beq 91f
    mov r7, #CLOSE
    svc 0 
91:
    ldr r0,iAdrszMessFinOK      @ r0 ← adresse chaine 
    bl affichageMess            @ affichage message dans console 
    mov r0,#0                   @ code retour OK 
    b 100f
99:                             @ affichage erreur 
    ldr r1,iAdrszMessErreur     @ r0 <- code erreur, r1 <- adresse chaine 
    bl   afficherErreur          @ appel affichage message
    mov r0,#1                   @ code erreur 
    b 100f
100:                            @ fin de programme standard  
    mov r7, #EXIT               @ appel fonction systeme pour terminer 
    svc 0 
/************************************/
iAdrszMessDebutPgm:     .int szMessDebutPgm
iAdrszMessErreur:       .int szMessErreur
iAdrszMessFinOK:        .int szMessFinOK
iAdrsZoneConv:          .int sZoneConv
iAdrstAquarium:         .int stAquarium
iAdrsBuffer:            .int sBuffer
iAdrszNompP1:           .int szNomP1
iAdrszNompP2:           .int szNomP2
iAdrszMale:             .int szMale
iAdrszFemelle:          .int szFemelle
iAdrszMessCommande:     .int szMessCommande
iAdriFdFicLog1:         .int iFdFicLog
/***************************************************/
/*   traitement de la ligne de commandes           */
/***************************************************/
// r0 contient l'adresse de la structure aquarium
// r1 contient l'adresse de la pile au démarrage du programme 
traiterCommande:                 @ INFO: traiterCommande
    push {r1-r6,lr}              @ save des registres
    mov r5,r0
    mov r3,r1
    mov r7,#0                    @ indicateur restaur
    ldr r4,[r3]                  @ nombre de parametre dans la ligne de commande
    cmp r4,#3                    @ < 3  demarrage vide
    movlt r0,#0
    blt 100f

    add r6,r3,#8                 @ 
    ldr r0,[r6]
    ldr r1,iAdrszParamRestau     @ paramètre = "-r" ?
    bl comparerChaines
    cmp r0,#0
    bne 2f
    add r1,r3,#12                @ 
    ldr r1,[r1]
    mov r0,r5
    bl restaurerAquarium
    mov r7,#1
    b 5f
2:
    ldr r0,[r6]
    ldr r1,iAdrszParamInit       @ paramètre = "-i" ?
    bl comparerChaines
    cmp r0,#0
    bne 3f
    add r1,r3,#12                @ 
    ldr r1,[r1]
    mov r0,r5
    bl commencerAquarium
    mov r7,#1
    b 5f
3:
    ldr r0,[r6]
    ldr r1,iAdrszParamLog        @ paramètre = "-l" ?
    bl comparerChaines
    cmp r0,#0
    bne 5f
    add r1,r3,#12                @ 
    ldr r1,[r1]
    ldr r0,iAdriAdrszFicLog
    str r1,[r0]
5:                               @ 1 autre paramètre ?
    cmp r4,#3                    @ = 3 ?
    beq 10f
    cmp r4,#5                    @ = 5 ?
    bne 10f
    add r6,r3,#16                 @ 
    ldr r0,[r6]
    ldr r1,iAdrszParamRestau     @ paramètre = "-r" ?
    bl comparerChaines
    cmp r0,#0
    bne 6f
    add r1,r3,#20                @ 
    ldr r1,[r1]
    mov r0,r5
    bl restaurerAquarium
    mov r7,#1
 
6:
    ldr r0,[r6]
    ldr r1,iAdrszParamLog        @ paramètre = "-l" ?
    bl comparerChaines
    cmp r0,#0
    bne 10f
    add r1,r3,#20                @ 
    ldr r1,[r1]
    ldr r0,iAdriAdrszFicLog
    str r1,[r0]
    
10:
    mov r0,r7                  @ fin
100:                            @ fin standard de la fonction
    pop {r1-r6,lr}              @ restaur des registres 
    bx lr                       @ retour de la fonction en utilisant lr
iAdriAdrszFicLog:          .int iAdrszFicLog
iAdrszParamRestau:         .int szParamRestau
iAdrszParamLog:            .int szParamLog
iAdrszParamInit:           .int szParamInit
/***************************************************/
/*   affichage situation aquarium                */
/***************************************************/
// r0 contient l'adresse de la structure aquarium
afficherAquarium:                    @ INFO: afficherAquarium
    push {r1-r7,lr}                  @ save des registres
    mov r5,r0
    ldr r1,[r5,#aqua_nombreTour]     @ affichage nombre de tour
    add r0,r1,#1                     @ increment nombre de tour
    str r0,[r5,#aqua_nombreTour]
    ldr r1,iAdrsZoneConv
    bl conversion10
    ldr r0,iAdrszMessTour
    ldr r1,iAdrsZoneConv             @ insertion valeur dans message
    bl insererChaineCar
    bl ecrireLog                     @ ecriture éventuelle log
    bl affichageMess                 @ et affichage
    bl libererPlace
    
    ldr r0,[r5,#aqua_nbAlgues]        @ affichage nombre d'algues
    ldr r1,iAdrsZoneConv
    bl conversion10
    ldr r0,iAdrszMessAlgues
    ldr r1,iAdrsZoneConv              @ insert value conversion in message
    bl insererChaineCar
    bl ecrireLog
    bl affichageMess
    bl libererPlace
    ldr r2,[r5,#aqua_listePoissons]   @ affichage des poissons
    ldr r5,iAdrtabRace
    mov r6,#race_Fin
1:
    cmp r2,#0
    beq 100f         @ fin de liste
    ldr r3,[r2,#liste_pointeur]
    ldr r1,[r3,#poisson_PV]            @ poisson mort ?
    cmp r1,#0
    ble 2f
    ldr r0,iAdrszMessPoissons
    ldr r1,[r3,#poisson_Nom]
    bl insererChaineCar
    ldr r1,[r3,#poisson_Sexe]
    bl insererChaineCar
    ldr r4,[r3,#poisson_Race]
    mla r4,r6,r4,r5             @ calcul offset race
    ldr r1,[r4,#race_Nom]
    bl insererChaineCar
    mov r7,r0
    
    ldr r0,[r3,#poisson_Age]        @ affichage age
    ldr r1,iAdrsZoneConv
    bl conversion10
11:                              @ suppression blancs
    ldrb r0,[r1]
    cmp r0,#' '
    addeq r1,#1
    beq 11b
    mov r0,r7
    bl insererChaineCar
    mov r7,r0
    ldr r0,[r3,#poisson_PV]        @ affichage PV
    ldr r1,iAdrsZoneConv
    bl conversion10
12:                              @ suppression blancs
    ldrb r0,[r1]
    cmp r0,#' '
    addeq r1,#1
    beq 12b
    mov r0,r7
    bl insererChaineCar
    bl ecrireLog
    bl affichageMess
    bl libererPlace
2:
    ldr r2,[r2,#liste_suivant]
    b 1b

100:                            @ fin standard de la fonction
    pop {r1-r7,lr}              @ restaur des registres 
    bx lr                       @ retour de la fonction en utilisant lr
iAdrszMessAlgues:       .int szMessAlgues
iAdrszMessPoissons:     .int szMessPoissons
iAdrszRetourligne:      .int szRetourligne
iAdrszMessTour:         .int szMessTour
iAdrtabRace:            .int tabRace

/***************************************************/
/*   sauver les données de l'aquarium                */
/***************************************************/
// r0 contient l'adresse de la structure aquarium
sauverAquarium:                   @ INFO: sauverAquarium
    push {r1-r10,lr}              @ save des registres
    mov r12,r0
                                   @ debut nomfichier+Tour
    ldr r0,[r0,#aqua_nombreTour]
    ldr r1,iAdrsZoneConv
    bl conversion10
1:                                 @ suppression blancs
    ldrb r0,[r1]
    cmp r0,#' '
    addeq r1,#1
    beq 1b
    mov r4,r1
    ldr r0,iAdrszNomFichierSave
    bl insererChaineCar
    mov r5,r0                      @ save nom
                                   @ ouvrir fichier
    ldr r1,oficmask1               @  flags
    mov r2,#0                      @ mode
    mov r7,#CREATE                 @ appel fonction systeme pour creer le fichier
    svc 0 
    cmp r0,#0                      @ si erreur retourne -1
    ble 99f
    mov r8,r0                      @ save du Fd
    ldr r0,iAdrsBuffer1
    mov r1,#0                      @copie le N° du tour dans le buffer
    ldr r2,[r12,#aqua_nombreTour]
    bl ecrireBuffer
    mov r2,#0xA
    strb r2,[r0,r1]
    add r1,r1,#1
                                   @ ecrire les algues
    ldr r7,[r12,#aqua_listeAlgues] @ balayer la liste des algues
    cmp r7,#0                      @ liste vide ?
    beq 41f
3:
    ldr r6,[r7,#liste_pointeur]
    ldr r2,[r6,#algue_PV]          @ algue morte ?
    cmp r2,#0
    ble 4f
    mov r3,#'A'
    strb r3,[r0,r1]
    add r1,r1,#1
    mov r3,#';'
    strb r3,[r0,r1]
    add r1,r1,#1
    bl ecrireBuffer
    mov r2,#';'
    strb r2,[r0,r1]
    add r1,r1,#1
    ldr r2,[r6,#algue_Age]
    bl ecrireBuffer
    mov r2,#0xA
    strb r2,[r0,r1]
    add r1,r1,#1
4:
    ldr r7,[r7,#liste_suivant]
    cmp r7,#0
    bne 3b                           @ et boucle 
41:
                                     @ecrire les poissons
    ldr r7,[r12,#aqua_listePoissons] @  balayer la liste des poissons
    cmp r7,#0                        @ liste vide
    beq 7f
5:
    ldr r6,[r7,#liste_pointeur]
    ldr r2,[r6,#poisson_PV]          @ poisson mort ?
    cmp r2,#0
    ble 6f
    mov r3,#'P'
    strb r3,[r0,r1]
    add r1,r1,#1
    mov r3,#';'
    strb r3,[r0,r1]
    add r1,r1,#1
    ldr r2,[r6,#poisson_Nom]
    bl ecrireChaineBuffer
    mov r2,#';'
    strb r2,[r0,r1]
    add r1,r1,#1
    ldr r2,[r6,#poisson_Sexe]
    bl ecrireChaineBuffer
    mov r2,#';'
    strb r2,[r0,r1]
    add r1,r1,#1
    ldr r2,[r6,#poisson_Race]
    bl ecrireBuffer
    mov r2,#';'
    strb r2,[r0,r1]
    add r1,r1,#1
    ldr r2,[r6,#poisson_Age]
    bl ecrireBuffer
    mov r2,#';'
    strb r2,[r0,r1]
    add r1,r1,#1
    ldr r2,[r6,#poisson_PV]
    bl ecrireBuffer
    mov r2,#0xA
    strb r2,[r0,r1]
    add r1,r1,#1
6:
    ldr r7,[r7,#liste_suivant]
    cmp r7,#0
    bne 5b                     @ et boucle 
 
7:                             @ ecrire le buffer
    mov r0,r8                  @ Fd du fichier de sortie
    
    mov r2,r1                  @ contient la longueur à ecrire 
    ldr r1,iAdrsBuffer1
    mov r7, #WRITE
    svc #0
    cmp r0,#0                  @ erreur ?
    blt 99f
    
                               @ fermer le fichier
    mov r0,r8                  @ Fd  fichier
    mov r7, #CLOSE
    svc 0 
    cmp r0,#0
    blt 99f
    
    ldr r0,iAdrszMessFinSave
    mov r1,r5
    bl insererChaineCar
    bl ecrireLog
    bl affichageMess
    mov r0,#0
    b 100f
99:  
    adr r0,szMessErrFic
    bl affichageMess
    mov r0,#-1
100:                             @ fin standard de la fonction
    pop {r1-r10,lr}               @ restaur des registres
    bx lr                        @ retour de la fonction en utilisant lr
iAdrszNomFichierSave:       .int szNomFichierSave
iAdrszMessFinSave:          .int szMessFinSave
iAdrsBuffer1:               .int sBuffer
oficmask1:                  .octa 0644 
szMessErrFic:               .asciz "Problème opération fichier !!!\n"
.align 4
/***************************************************/
/*   ecrire dans le buffer de sortie                */
/***************************************************/
// r0 contient l'adresse du buffer
// r1 contient la position dans le buffer  et retounera la nouvelle position
// r2 contient la valeur à écrire
ecrireBuffer:                   @ INFO: ecrireBuffer
    push {r2-r4,lr}             @ save des registres
    mov r3,r0
    mov r4,r1
    mov r0,r2
    ldr r1,iAdrsZoneConv1
    bl conversion10
1:                              @ suppression blancs
    ldrb r2,[r1]
    cmp r2,#' '
    addeq r1,#1
    beq 1b
    mov r2,#0                   @ copie le résultat dans le buffer
    mov r0,r3
2:
    ldrb r3,[r1,r2]
    cmp r3,#0
    strneb r3,[r0,r4]
    addne r4,r4,#1
    addne r2,r2,#1
    bne 2b
    mov r1,r4
    
100:                            @ fin standard de la fonction
    pop {r2-r4,lr}              @ restaur des registres
    bx lr                       @ retour de la fonction en utilisant lr
iAdrsZoneConv1:   .int sZoneConv
/***************************************************/
/*   ecrire dans le buffer de sortie                */
/***************************************************/
// r0 contient l'adresse du buffer
// r1 contient la position dans le buffer  et retounera la nouvelle position
// r2 contient l'adresse de la chaine 
ecrireChaineBuffer:              @ INFO: ecrireChaineBuffer
    push {r2-r4,lr}              @ save des registres
    mov r3,#0
1:
    ldrb r4,[r2,r3]
    cmp r4,#0
    strneb r4,[r0,r1]
    addne r1,r1,#1
    addne r3,r3,#1
    bne 1b
100:                             @ fin standard de la fonction
    pop {r2-r4,lr}               @ restaur des registres
    bx lr                        @ retour de la fonction en utilisant lr
/***************************************************/
/*   restaurer l'aquarium                */
/***************************************************/
// r0 contient l'adresse de la structure aquarium
// r1 contient l'adresse du fichier de restaur
restaurerAquarium:               @ INFO: restaurerAquarium
    push {r1-r10,lr}             @ save des registres
    mov r10,r0
    mov r0,r1              @ nom du fichier
                           @ ouverture
    mov r1,#O_RDWR         @  flags
    mov r2,#0              @ mode
    mov r7, #OPEN          @ appel fonction systeme pour ouvrir
    svc 0                  @ ou svc 
    cmp r0,#0              @ si erreur
    ble 99f
    
    mov r12,r0             @ save du Fd
                           @ lecture, r0 contient le FD du fichier
    ldr r1,iAdrsBufferLect @ adresse du buffer de reception
    mov r2,#TAILLEBUF      @ nb de caracteres
    mov r7, #READ          @ appel fonction systeme pour lire
    svc 0 
    cmp r0,#0
    ble 99f
    
    ldr r9,iAdrsBufferLect
    mov r8,#0              @ position caractère buffer
    ldr r0,iAdrsBufferLect
1:
    ldrb r1,[r9,r8]
    cmp r1,#0xA
    addne r8,r8,#1
    bne 1b
    mov r1,#0
    strb r1,[r9,r8]
    add r8,r8,#1
    bl conversionAtoD
    str r0,[r10,#aqua_nombreTour]
    
    mov r7,#0           @ compteur des algues
2:
    ldrb r1,[r9,r8]
    cmp r1,#'A'         @ eclatement des algues
    bne 5f
    add r8,r8,#2
    add r0,r9,r8        @ debut PV
3:
    ldrb r1,[r9,r8]
    cmp r1,#';'
    addne r8,r8,#1
    bne 3b
    mov r1,#0
    strb r1,[r9,r8]
    add r8,r8,#1
    bl conversionAtoD
    mov r4,r0
    add r0,r9,r8        @ debut age
4:
    ldrb r1,[r9,r8]
    cmp r1,#0xA
    addne r8,r8,#1
    bne 4b
    mov r1,#0
    strb r1,[r9,r8]
    add r8,r8,#1
    bl conversionAtoD
    mov r1,r0         @ r1 contient l'age de l'algue
    mov r0,r10        @ r0 contient l'adresse de la structure aquarium
    mov r2,r4         @ r2 contient les points de vie
    bl ajouterAlgue
    add r7,r7,#1
    b 2b              @ boucle algue 
    
5:                    @ maj compteur algues
    str r7,[r10,#aqua_nbAlgues]
    mov r7,#0         @ compteur de poissons
6:
    ldrb r1,[r9,r8]
    cmp r1,#'P'         @ eclatement des poissons
    bne 15f
    add r8,r8,#2
    add r0,r9,r8        @ debut nom
7:
    ldrb r1,[r9,r8]
    cmp r1,#';'
    addne r8,r8,#1
    bne 7b
    mov r1,#0
    strb r1,[r9,r8]
    add r8,r8,#1
    mov r6,r0            @ nom poisson
    add r0,r9,r8         @ debut sexe
8:
    ldrb r1,[r9,r8]
    cmp r1,#';'
    addne r8,r8,#1
    bne 8b
    mov r1,#0
    strb r1,[r9,r8]
    add r8,r8,#1
    mov r2,r0            @ adresse sexe poisson
    ldr r1,iAdrszFemelle1
    bl comparerChaines
    moveq r2,r1          @ bonne adresse des libellés de sexe
    ldrne r2,iAdrszMale1
    add r0,r9,r8        @ debut race 
9:
    ldrb r1,[r9,r8]
    cmp r1,#';'
    addne r8,r8,#1
    bne 9b
    mov r1,#0
    strb r1,[r9,r8]
    add r8,r8,#1
    bl conversionAtoD
    mov r3,r0           @ race
    add r0,r9,r8        @ debut age
10:
    ldrb r1,[r9,r8]
    cmp r1,#';'
    addne r8,r8,#1
    bne 10b
    mov r1,#0
    strb r1,[r9,r8]
    add r8,r8,#1
    bl conversionAtoD
    mov r4,r0           @ age
    add r0,r9,r8        @ debut PV
11:
    ldrb r1,[r9,r8]
    cmp r1,#0xA
    addne r8,r8,#1
    bne 11b
    mov r1,#0
    strb r1,[r9,r8]
    add r8,r8,#1
    bl conversionAtoD
    mov r5,r0           @ PV
    
    mov r0,r10         @ structure aquarium
    mov r1,r6          @ r1 contient l'adresse du nom du poisson
                       @ r2 contient le sexe
                       @ r3 contient la race
                       @ r4 contient l'age
    bl ajouterPoisson
    
    add r7,r7,#1
    b 6b
15:                             @ fermer le fichier 
    str r7,[r10,#aqua_nbPoissons]
    mov r0,r12                  @ Fd  fichier
    mov r7, #CLOSE
    svc 0 
    cmp r0,#0
    blt 99f
    b 100f
99:  
    adr r0,szMessErrFic1
    bl affichageMess
    bkpt                        @ arret 

100:                             @ fin standard de la fonction
    pop {r1-r10,lr}              @ restaur des registres
    bx lr                        @ retour de la fonction en utilisant lr
iAdrsBufferLect:   .int sBufferLect
iAdrszFemelle1:    .int szFemelle
iAdrszMale1:       .int szMale
szMessErrFic1:     .asciz "Problème restaur opération fichier !!!\n"
.align 4
/***************************************************/
/*   écrire dans le fichier log                    */
/***************************************************/
// r0 contient l'adresse du message
// attention r0 ne doit pas être détruit
ecrireLog:                      @ INFO: ecrireLog
    push {r0-r7,lr}             @ save des registres
    mov r5,r0
    ldr r1,iAdriAdrszFicLog1
    ldr r1,[r1]
    cmp r1,#0                   @ fichier log renseigné ?
    beq 100f
    ldr r4,iAdriFdFicLog
    ldr r0,[r4]
    cmp r0,#0                   @ fichier déja ouvert ?
    bne 1f
    mov r0,r1
                                @ fichier log à ouvrir
    ldr r1,oficmask1            @  flags
    mov r2,#0                   @ mode
    mov r7,#CREATE
    svc 0 
    cmp r0,#0                   @ si erreur retourne -1
    ble 99f
    str r0,[r4]                 @ stocke le FD 
1:
    mov r2,#0                   @ calcule la longueur du message
2:
    ldrb r3,[r5,r2]
    cmp r3,#0
    addne r2,r2,#1
    bne 2b
    mov r4,r2                  @ contient la longueur 
                               @ Fd du fichier de sortie dans r0
    mov r1,r5                  @ adresse message à ecrire
    mov r7, #WRITE
    svc #0
    cmp r0,#0                  @ erreur ?
    blt 99f
    mov r3,#0                  @ remise en place du zéro final
    strb r3,[r5,r4] 
    b 100f
99:
    adr r0,szMessErrFic1
    bl affichageMess
    bkpt                        @ arret 
100:                            @ fin standard de la fonction
    pop {r0-r7,lr}              @ restaur des registres 
    bx lr                       @ retour de la fonction en utilisant lr
iAdriFdFicLog:              .int iFdFicLog
iAdriAdrszFicLog1:          .int iAdrszFicLog
/***************************************************/
/*   initialisation de l'aquarium avec un fichier (-i)    */
/***************************************************/
// r0 contient l'adresse de la structure aquarium
// r1 contient l'adresse du fichier d'initialisation
commencerAquarium:         @ INFO: commencerAquarium
    push {r1-r10,lr}       @ save des registres
    mov r10,r0
    mov r0,r1              @ nom du fichier
                           @ ouverture
    mov r1,#O_RDWR         @  flags
    mov r2,#0              @ mode
    mov r7, #OPEN          @ appel fonction systeme pour ouvrir
    svc 0                  @ ou svc 
    cmp r0,#0              @ si erreur
    ble 99f
    
    mov r12,r0             @ save du Fd
                           @ lecture, r0 contient le FD du fichier
    ldr r1,iAdrsBufferLect @ adresse du buffer de reception
    mov r2,#TAILLEBUF      @ nb de caracteres
    mov r7, #READ          @ appel fonction systeme pour lire
    svc 0 
    cmp r0,#0
    ble 99f
    
    mov r0,#0             @ init nombre de tours
    str r0,[r10,#aqua_nombreTour]
    
    ldr r9,iAdrsBufferLect
    mov r8,#0              @ position caractère buffer
    ldr r0,iAdrsBufferLect
    mov r7,#0           @ compteur des algues
1:
    ldrb r1,[r9,r8]
    cmp r1,#'A'         @ eclatement des algues
    bne 5f
    add r8,r8,#2
    add r0,r9,r8        @ debut nombre
2:
    ldrb r1,[r9,r8]
    cmp r1,#';'
    addne r8,r8,#1
    bne 2b
    mov r1,#0
    strb r1,[r9,r8]
    add r8,r8,#1
    bl conversionAtoD
    mov r4,r0
    add r0,r9,r8        @ debut age
3:
    ldrb r1,[r9,r8]
    cmp r1,#0XD
    addeq r8,r8,#1
    beq 3b
    cmp r1,#0xA
    addne r8,r8,#1
    bne 3b
    mov r1,#0
    strb r1,[r9,r8]
    add r8,r8,#1
    bl conversionAtoD
    mov r1,r0
    mov r5,#0
4:
    mov r0,r10  @ r0 contient l'adresse de la structure aquarium
                @ r1 contient l'age de l'algue
                @ r2 contient les points de vie
    mov r2,#PVDEPART
    bl ajouterAlgue
    add r7,r7,#1
    add r5,r5,#1
    cmp r5,r4
    blt 4b            @ compteur atteint ?
    
    b 1b              @ boucle algue 
    
5:                    @ maj compteur algues
    str r7,[r10,#aqua_nbAlgues]
    mov r7,#0         @ compteur de poissons
6:
    ldrb r1,[r9,r8]
    cmp r1,#'P'         @ eclatement des poissons
    bne 15f
    add r8,r8,#2
    add r0,r9,r8        @ debut nom
7:
    ldrb r1,[r9,r8]
    cmp r1,#';'
    addne r8,r8,#1
    bne 7b
    mov r1,#0
    strb r1,[r9,r8]
    add r8,r8,#1
    mov r6,r0            @ nom poisson
    add r0,r9,r8        @ debut sexe
8:
    ldrb r1,[r9,r8]
    cmp r1,#';'
    addne r8,r8,#1
    bne 8b
    mov r1,#0
    strb r1,[r9,r8]
    add r8,r8,#1
    mov r2,r0            @ adresse sexe poisson
    ldr r1,iAdrszFemelle1
    bl comparerChaines
    moveq r2,r1          @ bonne adresse des libellés de sexe
    ldrne r2,iAdrszMale1
    add r0,r9,r8        @ debut race 
9:
    ldrb r1,[r9,r8]
    cmp r1,#';'
    addne r8,r8,#1
    bne 9b
    mov r1,#0
    strb r1,[r9,r8]
    add r8,r8,#1
    bl conversionAtoD
    mov r3,r0           @ race
    add r0,r9,r8        @ debut age
10:
    ldrb r1,[r9,r8]
    cmp r1,#0XD
    addeq r8,r8,#1
    beq 10b
    cmp r1,#0XA
    addne r8,r8,#1
    bne 10b
    mov r1,#0
    strb r1,[r9,r8]
    add r8,r8,#1
    bl conversionAtoD
    mov r4,r0           @ age

    
    mov r0,r10        @ structure aquarium 
    mov r1,r6         @ r1 contient l'adresse du nom du poisson
                      @ r2 contient le sexe
                      @ r3 contient la race
                      @ r4 contient l'age
    mov r5,#PVDEPART
    bl ajouterPoisson
    
    add r7,r7,#1
    b 6b
10: 
    cmp r1,#0                   @ fin du buffer
    beq 15f
                                @ mais il s'agit d'un commentaire ou autres
                                @ donc elimination de la ligne
    add r8,r8,#1 
11:
    ldrb r1,[r9,r8]
    cmp r1,#0
    beq 15f
    cmp r1,#0XD
    addeq r8,r8,#1
    beq 11b
    cmp r1,#0xA
    addne r8,r8,#1
    bne 11b
    add r8,r8,#1
    b 1b
15:                             @ fermer le fichier 
    str r7,[r10,#aqua_nbPoissons]
    mov r0,r12                  @ Fd  fichier
    mov r7, #CLOSE
    svc 0 
    cmp r0,#0
    blt 99f
    b 100f
99:  
    adr r0,szMessErrFic2
    bl affichageMess
    bkpt                         @ arret 

100:                             @ fin standard de la fonction
    pop {r1-r10,lr}              @ restaur des registres
    bx lr                        @ retour de la fonction en utilisant lr

szMessErrFic2:     .asciz "Problème init opération fichier !!!\n"
.align 4
/*********************************************/
/*constantes */
/********************************************/
//.include "../../constantesARM.inc"
