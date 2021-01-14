/* Routines pour assembleur arm raspberry */
/* complément 2021   ajout de la gestion du tas */
/* doit être utilisée avec le script de compil qui définit le tas */

/*******************************************/
/* CONSTANTES                              */
/*******************************************/

.equ CHARPOS,    '@'
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "./ficmacros.s"

/**************************************/
/* Données initialisées               */
/**************************************/
.data
ptZoneTas:          .int heap_begin
ptZoneDebutTas:     .int heap_begin
/**************************************/
/* Code du programme                  */
/**************************************/
.text
.global reserverPlace,insererChaineCar,libererPlace
/***************************************************/
/*   reserver place sur le tas                     */
/***************************************************/
// r0 contient la place à réserver 
// r0 retourne l'adresse de début de la place réservée
reserverPlace:            @ INFO: reserverPlace
    push {r1,r2,r3,lr}    @ save des registres
    mov r1,r0
    tst r1,#0b11          @ la place est un multiple de 4
    beq 1f                @ oui
    and r1,#0xFFFFFFFC    @ sinon ajustement à un multiple de 4 superieur
    add r1,#4
1:
    ldr r2,iAdrptZoneTas
    ldr r0,[r2]
    add r1,r1,r0          @ vérification de dépassement
    ldr r3,iAdrFinTas
    cmp r1,r3
    blt 2f
    adr r0,szMessErrTas
    bl affichageMess
    mov r0,#-1
    b 100f
2:
    str r1,[r2]
   // vidregtit tas
100:                      @ fin standard de la fonction
    pop {r1,r2,r3,lr}     @ restaur des registres
    bx lr                 @ retour de la fonction en utilisant lr
iAdrptZoneTas:       .int ptZoneTas
iAdrFinTas:          .int heap_end
szMessErrTas:        .asciz "Erreur : tas trop petit !!!\n"
.align 4
/***************************************************/
/*   liberer place sur le tas                     */
/***************************************************/
// r0 contient l'adresse de début de la place réservée
libererPlace:               @ INFO: libererPlace
    push {r1,lr}      @ save des registres
    ldr r1,iAdrDebutTas
    cmp r0,r1
    blt 99f
    ldr r1,iAdrFinTas
    cmp r0,r1
    bge 99f
    ldr r1,iAdrptZoneTas
    str r0,[r1]
    b 100f
99:
    adr r0,szMessErrTas1
    bl affichageMess
    mov r0,#-1
100:
    pop {r1,lr}                          @ restaur registers 
    bx lr
iAdrDebutTas:     .int heap_begin
szMessErrTas1:    .asciz "Erreur : adresse plus petite ou plus grande que le tas !!!\n"
.align 4
/******************************************************************/
/*   insert string at character insertion                         */ 
/******************************************************************/
/* r0 contains the address of string 1 */
/* r1 contains the address of insertion string   */
/* r0 return the address of new string  on the heap */
/* or -1 if error   */
insererChaineCar:
    push {r1-r7,lr}                         @ save  registres
    mov r3,#0                                // length counter 
1:                                           // compute length of string 1
    ldrb r4,[r0,r3]
    cmp r4,#0
    addne r3,r3,#1                           // increment to one if not equal
    bne 1b                                   // loop if not equal
    mov r5,#0                                // length counter insertion string
2:                                           // compute length to insertion string
    ldrb r4,[r1,r5]
    cmp r4,#0
    addne r5,r5,#1                           // increment to one if not equal
    bne 2b                                   // and loop
    cmp r5,#0
    beq 99f                                  // string empty -> error
    add r3,r3,r5                             // add 2 length
    add r3,r3,#1                             // +1 for final zero
    mov r6,r0                                // save address string 1
    mov r0,r3
    bl reserverPlace
    cmp r0,#-1
    beq 99f
    mov r5,r0                                // save address heap for output string
 
    mov r2,#0
    mov r4,#0
3:                                           // loop copy string begin 
        ldrb r3,[r6,r2]
        cmp r3,#0
        beq 99f
        cmp r3,#CHARPOS                           // insertion character ?
        beq 5f                                   // yes
        strb r3,[r5,r4]                          // no store character in output string
        add r2,r2,#1
        add r4,r4,#1
        b 3b                                     // and loop
5:                                           // r4 contains position insertion
    add r7,r4,#1                              // init index character output string
                                             // at position insertion + one
    mov r3,#0                                // index load characters insertion string
6:
        ldrb r0,[r1,r3]                          // load characters insertion string
        cmp r0,#0                                // end string ?
        beq 7f                                   // yes 
        strb r0,[r5,r4]                          // store in output string
        add r3,r3,#1                             // increment index
        add r4,r4,#1                             // increment output index
        b 6b                                     // and loop
7:                                           // loop copy end string 
    ldrb r0,[r6,r7]                          // load other character string 1
    strb r0,[r5,r4]                          // store in output string
    cmp r0,#0                                // end string 1 ?
    beq 8f                                   // yes -> end
    add r4,r4,#1                             // increment output index
    add r7,r7,#1                             // increment index
    b 7b                                     // and loop
8:
    mov r0,r5                                // return output string address 
    b 100f
99:                                          // error
    mov r0,#-1
100:
    pop {r1-r7,lr}                          @ restaur registers 
    bx lr
    