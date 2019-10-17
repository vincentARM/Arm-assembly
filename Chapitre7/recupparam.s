/* programme analyse de la ligne de commande  */
/* Assembleur ARM Raspberry  */
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne: .asciz  "\n"

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main               @ 'main' point d'entrée doit être  global

main:                      @ programme principal
    push {fp,lr}           @ save des  2 registres
    add fp,sp,#8           @ fp <- adresse début
    ldr r4,[fp]            @ recup du nombre de parametres de la ligne de commande
    add r5,fp,#4           @ recup adresse du premier parametre
    bl vidtousregistres
    mov r2,#0              @ compteur de boucle
boucle:    
    ldr r0,[r5,r2,lsl #2]  @ recup de l'adresse du parametre à l'indice r2
    bl affichageMess       @ appel procedure
    ldr r0,=szRetourligne
    bl affichageMess       @ pour afficher un retour ligne
    add r2,#1              @ +1 compteur de boucle
    cmp r2,r4              @ nombre de paramètre atteint
    blt boucle   
fin:                       @ fin de programme standard
    pop {fp,lr}            @ restaur des  2 registres
    mov r0,#0
    mov r7, #EXIT          @ appel systeme pour terminer
    swi #0 
