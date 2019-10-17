/* programme assembleur ARM pour Raspberry */
/* affichage d'un registre en hexa, binaire et décimal */
/********************************/
/*  Données initialisées        */
/********************************/ 
.data
sMessageHexa: .ascii "Vidage hexa du registre : "
sZoneHexa: .space 8,' '
              .asciz "\n"
.equ LGMESSAGEHEXA, . -  sMessageHexa       @ calcul de la longueur de la zone precedente
sMessageBin: .ascii "Vidage binaire du registre : "
sZoneBin: .space 32,' '
              .asciz "\n"
.equ LGMESSAGEBIN, . -  sMessageBin 
sMessageDeci: .ascii "Vidage décimal non signé du registre : "
sZoneDeci: .space 11,' '
              .asciz "\n"
.equ LGMESSAGEDECI, . -  sMessageDeci 
sMessageDeciS: .ascii "Vidage décimal signé du registre     : "
sZoneDeciS: .space 11,' '
              .asciz "\n"
.equ LGMESSAGEDECIS, . -  sMessageDeciS 
szMessageT1: .asciz "Vidage registre d'état\n" 
.equ LGMESSAGET1, . -  szMessageT1 
szMessageT2: .asciz "Vidage adresse masque\n" 
.equ LGMESSAGET2, . -  szMessageT2 
/********************************/
/*  Code section                */
/********************************/
.text    
.global main                     @ point d'entrée du programme
main:                            @ Programme principal
    mov r0,#15                   @ pour test
    bl affichage2
    bl affichage16
    bl affichage10
    bl affichage10S
     mov r0,#-1                  @ pour test  nombre negatif
    bl affichage2
    bl affichage16
    bl affichage10
    bl affichage10S
     mov r0,#0                   @ pour test  nombre zero
    bl affichage2
    bl affichage16
    bl affichage10
    bl affichage10S
    
                                 @ Fin standard du programme
    mov r0,#0                    @ code retour r0
    mov r7, #1                   @ code pour la fonction systeme EXIT
    swi 0                        @ appel system
    
/******************************************************************/
/*     affichage registre en binaire                              */ 
/******************************************************************/
/* r0 contient le registre */
affichage2:
    push {fp,lr}                  @ save des  2 registres
    push {r0,r1,r2,r3}            @ sauvegarde des registres
    ldr r1,adrzonemess            @ adresse de stockage du résultat
    mov r2,#0                     @ compteur de position

1:                                @ début de boucle
    lsls r0,#1                    @ deplacement du bits de gauche dans la zone carry
    movcc r3,#48                  @ Carry Clear  : le bit est à zero
    movcs r3,#49                  @ Carry Set    : le bit est à un
    strb r3,[r1,r2]               @ stockage du caractères ascii à l'adresse (r1) plus la position (r2)
    add r2,r2,#1                  @ incrementation du compteur
    cmp r2,#31                    @ 32 bits testés ?
    ble 1b                        @ non donc suite boucle
    
                                  @ affichage du résultat
    ldr r0,=adrzonemessbin
    ldr r0,[r0]                   @ adresse du message
    mov r1,#LGMESSAGEBIN          @ longueur du message
    bl affichageMess
    
                                  @ fin de la procedure
    pop {r0,r1,r2,r3}             @ restaur des registres
    pop {fp,lr}
    bx lr                         @ retour procedure 
adrzonemess:    .int sZoneBin       
adrzonemessbin: .int sMessageBin      
/******************************************************************/
/*     affichage d'un message dans la console                     */ 
/******************************************************************/
/* r0 contient l'adresse du message */
/* r1 contient sa longueur */
affichageMess:
    push {fp,lr}              @ save des  2 registres
    push {r2,r7}              @ save des autres registres */
    mov r2,r1                 @ longueur du message
    mov r1,r0                 @ adresse du message en r1
    mov r0,#1                 @ code pour écrire sur la sortie standard Linux
    mov r7, #4                @ code de l'appel systeme 'write'
    swi #0                    @ appel systeme
    pop {r2,r7}               @ restaur des autres registres
    pop {fp,lr}               @ restaur des  2 registres
    bx lr                     @ retour procedure
/***************************************************/
/*   Affichage d'un registre en hexa               */
/***************************************************/
/* r0 contient le registre   */
affichage16:
    push {fp,lr}              @ save des  2 registres frame et retour
    push {r0,r1,r2,r3,r4,r5}  @ save autres registres
    mov r2,r0                 @ save du registre
    ldr r1,adrzonemessH
    ldr r3,Masque             @ chargement de 0F soit 1111 dans r3
    mov r4,#7                 @ dernière position du résultat
1: 
    and r0,r0,r3              @ application du masque sur le nombre
    cmp r0,#9                 @ comparaison par rapport à 9
    addle r0,r0,#48           @ inferieur ou egal c'est un chiffre
    addgt r0,r0,#55           @ sinon c'est une lettre en hexa
    strb r0,[r1,r4]           @ on le stocke dans le caractère de la position 
    subs r4,#1                @ on enleve 1 au compteur
    blt 1f                    @ inferieur à 0 fin de la conversion
    mov r2,r2,lsr #4          @ sinon on deplace 4 bits du nombre sur la droite
    mov r0,r2                 @ et copie dans r0
    b 1b                      @ puis boucle
1:    
                              @ affichage du résultat
    ldr r0,=adrzonemesshexa
    ldr r0,[r0]
    mov r1,#LGMESSAGEHEXA
    bl affichageMess
                              @ fin standard de la fonction
    pop {r0,r1,r2,r3,r4,r5}   @ restaur des autres registres
    pop {fp,lr}               @ restaur des  2 registres frame et retour
    bx lr                     @ retour de la fonction en utilisant lr
Masque:          .word 0x0F         
adrzonemessH:    .int sZoneHexa       
adrzonemesshexa: .int sMessageHexa      
/***************************************************/
/*   Affichage d'un registre en décimal non signé  */
/***************************************************/
/* r0 contient le registre   */
affichage10:
    push {fp,lr}               @ save des  2 registres frame et retour
    push {r0,r1,r2,r3,r4,r5}   @ save autres registres
    ldr r5,=adrzonemessD
    ldr r5,[r5]
    mov r4,#10
    mov r2,r0
    mov r1,#10                 @ conversion decimale
1:                             @ debut de boucle de conversion
    mov r0,r2                  @ copie nombre départ ou quotients successifs
    bl divisionEntiere         @ division par le facteur de conversion
    add r3,#48                 @ car c'est un chiffre
    strb r3,[r5,r4]            @ stockage du byte au debut zone (r5) + la position (r4)
    sub r4,r4,#1               @ position précedente
    cmp r2,#0                  @ arret si quotient est égale à zero
    bne 1b    
                               @ mais il faut completer le debut de la zone avec des blancs
    mov r3,#' '                @ caractere espace
2:    
    strb r3,[r5,r4]            @ stockage du byte
    subs r4,r4,#1              @ position précedente
    bge 2b                     @ boucle si r4 plus grand ou egal a zero
                               @ affichage du résultat
    ldr r0,=adrzonemessdeci
    ldr r0,[r0]
    mov r1,#LGMESSAGEDECI
    bl affichageMess
    
                               @ fin standard de la fonction
       pop {r0,r1,r2,r3,r4,r5} @ restaur des autres registres
       pop {fp,lr}             @ restaur des  2 registres frame et retour
    bx lr                      @ retour de la fonction en utilisant lr
        
adrzonemessD:    .int sZoneDeci       
adrzonemessdeci: .int sMessageDeci        

/***************************************************/
/*   Affichage d'un registre en décimal   signé  */
/***************************************************/
/* r0 contient le registre   */
affichage10S:
    push {fp,lr}                     @ save des  2 registres frame et retour
    push {r0,r1,r2,r3,r4,r5,r6,r7}   @ save autres registres
    ldr r5,=adrzonemessDS
    ldr r5,[r5]                      @ chargement debut zone
    mov r6,#'+'                      @ par defaut le signe est +
    cmp r0,#0                        @ nombre négatif ?
    bge 0f
    mov r6,#'-'                      @ oui le signe est - */
    mov r4,#-1
    mov r2,r0                        @ et on multiplie le nombre par -1
    mul r0,r2,r4
0:    
    mov r4,#10                       @ longueur de la zone
    mov r2,r0                        @ nombre de départ des divisions successives
    mov r1,#10                       @ conversion decimale
1:                                   @ debut de boucle de conversion
    mov r0,r2                        @ copie nombre départ ou quotients successifs
    bl divisionEntiere               @ division par le facteur de conversion
    add r3,#48                       @ car c'est un chiffre
    strb r3,[r5,r4]                  @ stockage du byte en début de zone r5 + la position r4
    sub r4,r4,#1                     @ position précedente
    cmp r2,#0                        @ arret si quotient est égale à zero
    bne 1b    
                                     @ stockage du signe à la position courante
    strb r6,[r5,r4] 
    subs r4,r4,#1                    @ position précedente
    blt  3f                          @ si r4 < 0  fin 
                                     @ sinon il faut completer le debut de la zone avec des blancs
    mov r3,#' '                      @ caractere espace
2:    
    strb r3,[r5,r4]                  @ stockage du byte
    subs r4,r4,#1                    @ position précedente
    bge 2b                           @ boucle si r4 plus grand ou egal a zero
    
3:                                   @ affichage du résultat
    ldr r0,=adrzonemessdeciS
    ldr r0,[r0]
    mov r1,#LGMESSAGEDECIS
    bl affichageMess
    
                                     @ fin standard de la fonction
    pop {r0,r1,r2,r3,r4,r5,r6,r7}    @ restaur des autres registres
    pop {fp,lr}                      @ restaur des  2 registres frame et retour
    bx lr                            @ retour de la fonction en utilisant lr
        
adrzonemessDS: .int sZoneDeciS       
adrzonemessdeciS: .int sMessageDeciS        

/**********************************************/      
/* division entiere non signée                */
/* routine trouvée sur Internet               */
/* auteur  Roger Ferrer Ibáñez                */ 
/* site : http://thinkingeek.com/
/**********************************************/
/* attention ne sauve que les registre r4 et lr */      
divisionEntiere:
    /* r0 contient Nombre */
    /* r1 contient Diviseur */
    /* r2 contient Quotient */
    /* r3 contient Reste */
    push {r4, lr}
    mov r2, #0                 @ r2 <- 0
    mov r3, #0                 @ r3 <- 0
    mov r4, #32                @ r4 <- 32 
    b 2f
1:
    movs r0, r0, LSL #1        @ r0 <- r0 << 1 updating cpsr (sets C if 31st bit of r0 was 1)
    adc r3, r3, r3             @ r3 <- r3 + r3 + C. This is equivalent to r3 ? (r3 << 1) + C
 
    cmp r3, r1                 @ compute r3 - r1 and update cpsr
    subhs r3, r3, r1           @ if r3 >= r1 (C=1) then r3 ? r3 - r1 
    adc r2, r2, r2             @ r2 <- r2 + r2 + C. This is equivalent to r2 ? (r2 << 1) + C
2:
    subs r4, r4, #1            @ r4 ? r4 - 1
    bpl 1b                     @ if r4 >= 0 (N=0) then branch to .Lloop1
 
    pop {r4, lr}
    bx lr
