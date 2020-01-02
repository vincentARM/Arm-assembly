/* programme saisie couleur au clavier dans console  */
/* Assembleur ARM Raspberry  */
/* affichage chaine en couleur  */
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
.equ TAILLEBUF,  100  
.equ STDIN, 0
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szSaisie:         .asciz  "Veuillez saisir un nom de couleur ou fin pour terminer :\n"
szRetourligne:    .asciz  "\n"
sMessFinal:       .ascii  "\033[0mVous avez effectué "
sNombreSaisie:    .space 11,' '
                  .asciz " saisies.\n"
szMessCouleurAbs: .asciz "Couleur non gérée ==> "
szMessErrAppel:   .asciz "Erreur appel systeme. \n"
szRouge:          .asciz "rouge"
szBleu:           .asciz "bleu"
szVert:           .asciz "vert"
szViolet:         .asciz "violet"
szFin:            .asciz "fin"
szClear:          .byte 0x1B 
                  .byte 'c'            @ clear de la console
                  .byte 0
szCodeInit:       .asciz "\033[0m"     @ Pour reinitialiser la couleur
szCodeRouge:      .asciz "\033[31m"    @ couleur police 30 :noir 34 : bleu 31 rouge  32 vert
.equ LGCODE1, . -  szCodeRouge
szCodeBleu:       .asciz "\033[34m"    @ couleur police 30 :noir 34 : bleu 31 rouge  32 vert
szCodeVert:      .asciz "\033[32m"     @ couleur police 30 :noir 34 : bleu 31 rouge  32 vert
szCodeViolet:    .asciz "\033[35m"     @ couleur police 30 :noir 34 : bleu 31 rouge  32 vert
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/
.bss
sBuffer: .skip TAILLEBUF               @ reserve des octets pour stocker chaine saisie

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main                   @ 'main' point d'entrée doit être  global

main:                          @ programme principal
    push {fp,lr}               @ save des  2 registres
    add fp,sp,#8               @ fp <- adresse début
    ldr r0,=szClear
    bl affichageMess           @ affichage message dans console
       mov r6,#0               @ compteur du nombre de saisies
1:                             @ début de boucle de saisie
    ldr r0, adresse_saisie     @ r0 ← adresse chaine
    bl affichageMess           @ affichage message dans console
    mov r0,#STDIN              @ code pour la console d'entrée standard
    ldr r1,adresse_buffer      @ adresse du buffer de saisie
    mov r2,#TAILLEBUF          @ taille buffer
    mov r7, #READ              @ appel système pour lecture saisie
    swi #0 
    cmp r0,#0
    blt 99f
    //bl vidtousregistres      @ pour vérification
    sub r0,#1
    ldr r2,adresse_buffer 
    mov r1,#0
    strb r1,[r2,r0]
    ldr r0,adresse_buffer      @ adresse de la chaine à comparer
    ldr r1,adresse_fin         @ adresse d'une couleur
    bl comparaison             @ comparaison des 2 chaines
    cmp r0,#0
    beq fin
    
    ldr r0,adresse_buffer      @ adresse de la chaine à comparer
    ldr r1,adresse_rouge       @ adresse d'une couleur
    bl comparaison             @ comparaison des 2 chaines
    cmp r0,#0
    beq rouge
    ldr r0,adresse_buffer      @ adresse de la chaine à comparer
    ldr r1,adresse_bleu        @ adresse d'une couleur
    bl comparaison             @ comparaison des 2 chaines
    cmp r0,#0
    beq bleu
    ldr r0,adresse_buffer      @ adresse de la chaine à comparer
    ldr r1,adresse_violet      @ adresse d'une couleur
    bl comparaison             @ comparaison des 2 chaines
    cmp r0,#0
    beq violet
    ldr r0,adresse_buffer      @ adresse de la chaine à comparer
    ldr r1,adresse_vert        @ adresse d'une couleur
    bl comparaison             @ comparaison des 2 chaines
    cmp r0,#0
    beq vert
                               @ defaut
    ldr r0,adresse_couleurabs
    bl affichageMess           @ affichage message dans console
    b affiche
rouge:
    ldr r0,=szCodeRouge
    bl affichageMess           @ affichage message dans console
    b affiche
bleu:
    ldr r0,=szCodeBleu
    bl affichageMess           @ affichage message dans console
    b affiche    
violet:
    ldr r0,=szCodeViolet
    bl affichageMess           @ affichage message dans console
    b affiche    
vert:
    ldr r0,=szCodeVert
    bl affichageMess           @ affichage message dans console
    b affiche
affiche:
    ldr r0, adresse_buffer     @ r0 ← adresse chaine
    bl affichageMess           @ affichage message dans console
    ldr r0,=szRetourligne 
    bl affichageMess           @ affichage message dans console
    ldr r0,=szCodeInit
    bl affichageMess           @ affichage message dans console
    add r6,#1
    b 1b
fin:
    mov r0,r6
    ldr r1,adresse_nombresaisie
    bl conversion10
    ldr r0, adresse_final      @ r0 ← adresse chaine
    bl affichageMess           @ affichage message dans console
    mov r0,#0                  @ code retour OK
    b 100f
99:                            @ erreur lors de l'appel systeme
    ldr r1,=szMessErrAppel     @ adresse du message
    bl   afficheerreur 
    mov r0,#1                  @ code retour erreur
 100:                          @ fin de programme standard
    pop {fp,lr}                @ restaur des  2 registres
    mov r7, #EXIT              @ appel systeme pour terminer
    swi #0 
/************************************/       
adresse_saisie :      .word szSaisie
adresse_buffer :      .word sBuffer
adresse_nombresaisie: .word sNombreSaisie
adresse_final:        .word sMessFinal
adresse_couleurabs:   .word szMessCouleurAbs
adresse_fin:          .word szFin
adresse_rouge:        .word szRouge
adresse_bleu:         .word szBleu
adresse_violet:       .word szViolet
adresse_vert:         .word szVert
/******************************************************************/
/*     Comparaison de 2 chaines                                   */ 
/******************************************************************/
/* r0 et r1 contiennent les adresses des chaines   */
comparaison:
    push {fp,lr}         @ save des  2 registres
    push {r1,r2,r3,r4}   @ save des registres */
    mov r2,#0            @ indice
1:    
    ldrb r3,[r0,r2]      @ octet chaine 1
    ldrb r4,[r1,r2]      @ octet chaine 2
    cmp r3,r4
    bne 2f               @ pas egaux
    cmp r3,#0            @ 0 final
    beq 3f               @ c'est la fin
    add r2,r2,#1         @ sinon plus 1 dans indice
    b 1b                 @ et boucle
2:
    mov r0,#-1           @ inegalite
    b 100f
3:
    mov r0,#0            @ egalite
100:    
    pop {r1,r2,r3,r4}    @ restaur des autres registres
    pop {fp,lr}          @ restaur des  2 registres
    bx lr                @ retour procedure
/******************************************************************/
/*     Conversion d'un registre en décimal                                 */ 
/******************************************************************/
/* r0 contient la valeur et r1 l' adresse de la zone de stockage   */
conversion10:
    push {fp,lr}         @ save des  2 registres
    push {r1,r2,r3,r4}   @ save des registres
    mov r5,r1
    mov r4,#10
    mov r2,r0
    mov r1,#10           @ conversion decimale
1:                       @ debut de boucle de conversion
    mov r0,r2            @ copie nombre départ ou quotients successifs
    bl division          @ division par le facteur de conversion
    add r3,#48           @ car c'est un chiffre
    strb r3,[r5,r4]      @ stockage du byte au debut zone (r5) + la position (r4)
    sub r4,r4,#1         @ position précedente
    cmp r2,#0            @ arret si quotient est égale à zero
    bne 1b    
                         @ mais il faut completer le debut de la zone avec des blancs
    mov r3,#' '          @ caractere espace
2:    
    strb r3,[r5,r4]      @ stockage du byte
    subs r4,r4,#1        @ position précedente
    bge 2b               @ boucle si r4 plus grand ou egal a zero
    
100:    
    pop {r1,r2,r3,r4}    @ restaur des autres registres
    pop {fp,lr}          @ restaur des  2 registres
    bx lr                @ retour procedure
