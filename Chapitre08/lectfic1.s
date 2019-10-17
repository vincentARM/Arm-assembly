/* programme assembleur ARM  */
/* lecture d'un fichier  */
/* commentaire */
/*******************************************/
/*         Constantes                      */
/*******************************************/
.include "../constantesARM.inc"
.equ TAILLEBUF,  512  
/*  en commentaire car elles sont aussi dans le fichier plus haut
.equ EXIT, 1
.equ READ, 3
.equ WRITE, 4
.equ OPEN, 5
.equ CLOSE, 6
*/
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessErreur:  .asciz "Erreur ouverture fichier.\n"
szMessErreur1: .asciz "Erreur fermeture fichier.\n"
szMessErreur2: .asciz "Erreur lecture fichier.\n"
szRetourligne: .asciz "\n"

//szParamNom: .asciz "/home/pi/vincent/asm/projet3/fic1.txt"
szParamNom: .asciz "fic1.txt"

/*******************************************/
/* DONNEES NON INITIALISEES                */
/*******************************************/ 
.bss
sBuffer:  .skip TAILLEBUF 

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main               @ 'main' point d'entrée doit être  global

main:                      @ programme principal
    push {fp,lr}           @ save des  2 registres
    add fp,sp,#8           @ fp <- adresse début
                           @  ouverture fichier
    ldr r0,=szParamNom     @ nom du fichier
    mov r1,#O_RDWR         @  flags
    mov r2,#0              @ mode
    mov r7, #OPEN          @ appel fonction systeme pour ouvrir
    swi 0                  @ ou svc 
    cmp r0,#0              @ si erreur
    ble erreur
    bl vidtousregistres
    mov r8,r0              @ save du Fd
                           @ lecture, r0 contient le FD du fichier
    ldr r1,=sBuffer        @ adresse du buffer de reception
    mov r2,#TAILLEBUF      @ nb de caracteres
    mov r7, #READ          @ appel fonction systeme pour lire
    swi 0 
    cmp r0,#0
    ble erreur2
    bl vidtousregistres
                           @ Exemple d'affichage memoire
    ldr r0,=sBuffer
    mov r1,#5              @ nombre de bloc a afficher
    push {r0}              @ adresse memoire pour verification zones
    push {r1}
    bl affmemoire

                           @ fermeture fichier
    mov r0,r8              @ Fd  fichier
    mov r7, #CLOSE         @ appel fonction systeme pour fermer
    swi 0 
    cmp r0,#-1
    beq erreur1

    mov r0,#0              @ code retour OK
    b 100f
erreur:    
    ldr r1,=szMessErreur   @ r0 <- adresse chaine 
    bl   afficheerreur     
    mov r0,#1              @ erreur
    b 100f
erreur1:    
    ldr r1,=szMessErreur1  @ r0 <- adresse chaine 
    bl   afficheerreur 
    mov r0,#1              @ code retour erreur
    b 100f    
erreur2:    
    ldr r1,=szMessErreur2  @ r0 <- adresse chaine
    bl   afficheerreur 
    mov r0,#1              @ erreur
    b 100f
100:                       @ fin de programme standard
    pop {fp,lr}            @ restaur des  2 registres
    mov r7, #EXIT          @ appel fonction systeme pour terminer
    swi #0 
/************************************/       
