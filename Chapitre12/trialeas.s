/* generation nombre aleatoires et exemple de tri rapide */
/* assembleur ARM Raspberry : Vincent LeBoulou */
/* AVERTISSEMENT : le programmeur ne garantit le bon fonctionnement de ce programme  */
/* que dans les limites pour lesquelles il a été conçu. Il est déconseillé de l'utiliser */
/* dans des environnements dangereux (centrales nucléaires) ou soumis à des contraintes */
/* de sécurité importantes (Avions, voitures sans pilote humain, intelligence artificielle) */
 
/*********************************************/
/*         Constantes du programme           */
/********************************************/
.equ MAXI, 100    /* Nombre de nombre aléatoires */
.equ PLAGE, 100
/*******************************************/
/* FICHIER DES MACROS                      */
/*******************************************/ 
.include "../ficmacros.s"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne: .asciz  "\n"
szMessTemps: .ascii "Durée du tri : "
sSecondes: .fill 10,1,' '
             .ascii " s "
sMicroS:   .fill 10,1,' '
             .asciz " µs\n"
.align 4
iGraine:  .int 1234567
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
dwDebut:    .skip 8
dwFin:      .skip 8
iTabNB:     .skip 4 * MAXI    @ table de stockage des nombres
 
/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main              @ 'main' point d'entrée doit être  global

main:                     @ programme principal
    push {fp,lr}          @ save des  2 registres
    add fp,sp,#8          @ fp <- adresse début
                          @ constitution du tableau nombres aléatoires
    mov r1,#0             @  compteur
    ldr r2,adresse_table
    ldr r3,iMaxi
1:                        @ debut de boucle 
    ldr r0,iPlage         @ génération nombre compris entre 0 et PLAGE - 1
    sub r0,#1
    bl genereraleas
    str r0,[r2,r1,LSL #2] @ stockage dans la table au poste indexé par r1
    add r1,#1             @ compteur + 1
    cmp r1,r3             @ géneration de MAXI nombres 
    blt 1b                @ boucle

    ldr r0,adresse_table
    vidmemtit tableNombres r0 4
                          @ compteur temps debut
    ldr r0,=dwDebut       @ zone de reception du temps début
    mov r1,#0
    mov r7, #0x4e         @ test appel systeme gettimeofday
    swi #0 
    cmp r0,#0             @ verification si l'appel est OK
    blt erreur
                          @ tri de la table
    ldr r0,adresse_table
    mov r1,#0             @ poste minimun
    ldr r2,iMaxi          @ poste maximun -1 
    sub r2,#1
    bl trirapide
                          @ compteur temps fin
    ldr r0,=dwFin         @ zone de reception du temps fin
    mov r1,#0
    mov r7, #0x4e         @ test appel systeme gettimeofday
    swi #0 
    cmp r0,#0
    blt erreur            @ verification si l'appel est OK
                          @ calcul du temps
    ldr r0,=dwDebut       @ zones avant tri
    ldr r2,[r0]           @ secondes
    ldr r3,[r0,#4]        @ micro secondes
    ldr r0,=dwFin         @ zones après tri
    ldr r4,[r0]           @ secondes
    ldr r5,[r0,#4]        @ micro secondes
    sub r2,r4,r2          @ nombre de secondes ecoulées
    subs r3,r5,r3         @ nombre de microsecondes écoulées
    sublt r2,#1           @ si negatif on enleve 1 seconde aux secondes
    ldr r4,iSecMicro
    addlt r3,r4           @ et on ajoute 1000000 pour avoir un nb de microsecondes exact
    mov r0,r2             @ conversion des secondes en base 10 pour l'affichage
    ldr r1,=sSecondes
    bl conversion10
    mov r0,r3             @ conversion des microsecondes en base 10 pour l'affichage
    ldr r1,=sMicroS
    bl conversion10
    ldr r0,=szMessTemps   @ r0 ← adresse du message
    bl affichageMess      @ affichage message dans console
                          @ verification du tri
    ldr r0,adresse_table
    vidmemtit tableNombresApresTri r0 10
                          @ verification du tri
    mov r1,#0             @  compteur
    ldr r2,adresse_table
    ldr r4,iMaxi
    ldr r0,[r2,r1,LSL #2] @ init avec la première valeur
2:    
    ldr r3,[r2,r1,LSL #2] @ chargement valeur de l'indice r1
    cmp r3,r0             @ comparaison avec valeur précedente
    blt erreur            @ si inférieure il y a une erreur 
    mov r0,r3             @ sinon conservation de la valeur
    add r1,#1             @ ajout de 1 au compteur
    cmp r1,r4             @ Nombre de postes atteint ?
    blt 2b                @ non on boucle

finnormale:    
    ldr r0,=szMessFinOK   @ r0 ← adresse chaine
    bl affichageMess      @ affichage message dans console
    mov r0,#0             @ code retour OK
    b 100f
erreur:                   @ affichage erreur
    bl vidtousregistres
    ldr r1,=szMessErreur  @ r0 <- code erreur, r1 <- adresse chaine
    bl   afficheerreur    @ appel affichage message
    mov r0,#1             @ code erreur
    b 100f

100:                      @ fin de programme standard
    pop {fp,lr}           @ restaur des  2 registres
    mov r7, #EXIT         @ appel fonction systeme pour terminer
    swi 0 
/***************CONSTANTES*********************/
iMaxi:          .int MAXI       
iPlage:         .int PLAGE     
adresse_table:  .word iTabNB
iSecMicro:      .int 1000000
szMessErreur:   .asciz "Erreur rencontrée.\n"
szMessFinOK:    .asciz "Fin normale du programme. \n"
.align 4     /* alignement car l'étiquette de la routine suivante doit être alignée */
/***************************************************/
/*   Génération nombre aleatoire                  */
/***************************************************/
/* r0 plage fin  */
genereraleas:
    push {fp,lr}          @ save des  2 registres frame et retour
    add fp,sp,#8          @ fp <- adresse début
    push {r1,r2,r3,r4}    @ save autres registres en nombre pair
    mov r4,r0             @ save plage
    ldr r0,=iGraine
    ldr r0,[r0]
    ldr r1,iNombre1
    mul r0,r1
    add r0,#1
    ldr r1,=iGraine
    str r0,[r1]
                          @ prise en compte nouvelle graine
    ldr r1,m              @ diviseur pour registre de 32 bits
    bl division
    mov r0,r3             @ division du reste
    ldr r1,m1             @ diviseur  10000
    bl division
    mul r0,r2,r4          @ on multiplie le quotient par la plage demandéé
    mov r6,r0
    ldr r1,m1             @ puis on divise le resultat diviseur
    bl division           @ pour garder les chiffres à gauche significatif.
    mov r0,r2             @ retour du quotient
  
100:                      @ fin standard de la fonction
    pop {r1,r2,r3,r4}     @ restaur des autres registres
    pop {fp,lr}           @ restaur des  2 registres frame et retour
    bx lr                 @ retour de la fonction en utilisant lr
/*******************CONSTANTES****************************************/
iNombre1: .int 31415821
m1:       .int 10000
m:        .int 100000000 

/***************************************************/
/*   Tri  Rapide quicksort               */
/***************************************************/
/* r0 table des nombres à trier  */
/* r1 poste debut  */
/* r2 poste fin  */
trirapide:
   push {fp,lr}                     @ save des  2 registres frame et retour
   push {r1,r2,r3,r4,r5,r6,r7,r8}   @ save autres registres en nombre pair
   bl tri                           @ Appel du tri 
   pop {r1,r2,r3,r4,r5,r6,r7,r8} 
   pop {fp,lr}                      @ restaur des  2 registres frame et retour
   bx lr                            @ retour de la fonction en utilisant lr
/***************************************************/
/*   appel récursif du tri rapide                  */
/***************************************************/
/* r0 table des nombres à trier  */
/* r1 poste debut  */
/* r2 poste fin  */
tri:
   push {fp,lr}     @ save des  2 registres frame et retour
   sub sp,#16       @ reserve 16 octets
   mov fp,sp        @ fp <- adresse début
                    @ fp contient l'indice gauche
                    @ fp + 4 contient l'indice droit
                    @ fp + 8 contient l'indice de partitionnement
                    @ fp +12 contient le debut table
    cmp r1,r2       @ si r1 plus grand que r2
    bge 100f        @ c'est fini
    str r1,[fp]     @ stockage des données sur les octets resevés de la pile
    str r2,[fp,#4]    
    str r0,[fp,#12]
    bl partition    @ appel du découpage en 2 parties
    str r0,[fp,#8]  @ stockage indice retourné
    ldr r1,[fp]     @ on recupere l'indice gauche
    mov r2,r0       @ et on met a jour l'indice droit
    sub r2,#1       @ avec l'indice de découpage moins 1
    ldr r0,[fp,#12] @ restaur du début de table dans r0
    bl tri          @ tri partie inferieure 
    ldr r1,[fp,#8]  @ et on met a jour l'indice gauche
    add r1,#1       @ avec l'indice de découpage plus 1
    ldr r2,[fp,#4]  @ on recupere l'indice droit
    ldr r0,[fp,#12] @ restaur du début de table dans r0
    bl tri          @ tri partie supérieure
   
 100:               @ fin standard de la fonction
    add sp,#16      @ rend les 16 octets reservés
    pop {fp,lr}     @ restaur des  2 registres frame et retour
    bx lr           @ retour de la fonction en utilisant lr
/***************************************************/
/*   Partition                 */
/***************************************************/
/* r0 table des nombres à trier  */
/* r1 poste debut  */
/* r2 poste fin  */
partition:
   push {fp,lr}           @ save des  2 registres frame et retour
   mov r8,r1              @ save de l'indice gauche
   sub r3,r1,#1           @indice de depart gauche moins 1
   mov r4,r2              @indice de départ droit 
   mov r7,r2              @ save de l'indice de depart 
   ldr r5,[r0,r2,lsl #2]  @ chargement de la valeur de l'indice droit
1:                        @ début de boucle
   add r3,#1              @indice de depart gauche plus 1
   ldr r6,[r0,r3,lsl #2]  @ chargement de la valeur de l'indice gauche
   cmp r6,r5              @ valeur indice gauche < valeur indice droit
   blt 1b                 @ oui on boucle
2:                        @ debut 2ième boucle
  sub r4,#1               @indice de départ droit moins 1
  ldr r6,[r0,r4,lsl #2]   @ chargement de la valeur de l'indice droit
  cmp r5,r6               @ valeur indice gauche < valeur indice droit
  bge 2f                  @ fin boucle 2
  cmp r4,r8               @ l'indice est il arrivé au début ?
  beq 2f                  @ oui fin boucle 2
  b 2b
 2:
 cmp  r3,r4               @ l' indice gauche de la boucle 1 >= indice droit de la boucle 2
 bge 3f                   @ on termine
 mov r1,r3                @ sinon on echange les valeurs des 2 postes des indices
 mov r2,r4
 bl echanger
 b 1b                     @ et on recommence 
3: 
 mov r1,r3                @ échange du poste trouvé avec le poste indice gauche de départ
 mov r2,r7
 bl echanger
 mov r0,r3                @ et on retoune l'indice trouvé
 
100:                      @ fin standard de la fonction
    pop {fp,lr}           @ restaur des  2 registres frame et retour
    bx lr                 @ retour de la fonction en utilisant lr
/***************************************************/
/*   Echange de 2 postes de la table                 */
/***************************************************/
/* r0 table des nombres à trier  */
/* r1 poste à echanger  */
/* r2 poste à echanger  */
echanger:
    push {fp,lr}           @ save des  2 registres frame et retour
    push {r3,r4}           @ save autres registres en nombre pair
    ldr r3,[r0,r1,lsl #2]
    ldr r4,[r0,r2,lsl #2]
    str r3,[r0,r2,lsl #2]
    str r4,[r0,r1,lsl #2]
    pop {r3,r4}            @restaur des autres registres
    pop {fp,lr}            @ restaur des  2 registres frame et retour
    bx lr                  @ retour de la fonction en utilisant lr
/*********************************************/
/*              Constantes générales         */
/********************************************/    
.include "../constantesARM.inc"    
