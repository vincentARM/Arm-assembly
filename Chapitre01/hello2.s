/* programme hello  avec la fonction printf du C */
/********************************/
/*  Données initialisées        */
/********************************/
.data
szMessage1: .asciz "Bonjour le Monde.\n"
/********************************/
/*  Code section                */
/********************************/
.text    
.global main                  /* point d'entrée du programme  */
main:                         /* Programme principal */
    ldr r0, =szMessage1       /* adresse du message en r0 */
   
    bl printf                 /* appel de la fonction du C */
    mov r0,#0                 /* code retour r0 */
    mov r7, #1                /* code pour la fonction systeme EXIT */
    swi 0                     /* appel system */
   
