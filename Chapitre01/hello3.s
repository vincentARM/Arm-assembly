/* programme hello  avec l'appel systeme Write de Linux */
/********************************/
/*  Données initialisées        */
/********************************/
.data
szMessage1: .asciz "Bonjour le Monde.\n"
.equ LGMESSAGE1, . -  szMessage1 /* calcul de la longueur de la zone precedente */
/********************************/
/*  Code section                */
/********************************/
.text    
.global main                 /* point d'entrée du programme  */
main:                        /* Programme principal */
    mov r0,#1                /* code pour écrire sur la sortie standard Linux */
    ldr r1,=szMessage1       /* adresse du message en r1 */
    mov r2,#LGMESSAGE1       /* longueur du message */
    mov r7, #4               /* code de l'appel systeme 'write' */
    svc #0                   /* appel systeme */
    mov r0,#0                /* code retour r0 */
    mov r7, #1               /* code pour la fonction systeme EXIT */
    svc #0                    /* appel system */
   
