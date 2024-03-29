/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* mod�le B 512MO   */
/***************************************
/* Fichier des macros                 */
/**************************************/
//.altmacro
/****************************************************/
/* macro d'affichage d'un libell�                   */
/****************************************************/
/* pas d'espace dans le libell�  ou entre quotes   */
.macro afficherLib str 
    push {r0}    @ save r0
    mrs r0,cpsr  /* save du registre d'�tat  dans r12 */
    push {r0}
    adr r0,libaff1\@  @ recup adresse libell� pass� dans str
    bl affichageMess
    pop {r0}
    msr cpsr,r0    /*restaur registre d'�tat */
    pop {r0}         @ on restaure R0 pour avoir une pile r�align�e
    b smacroafficheMess\@   @ pour sauter le stockage de la chaine.
libaff1\@:  .ascii "\str"
               .asciz "\n"
.align 4
smacroafficheMess\@:     
.endm   @ fin de la macro
/* macro d'enrobage du vidage des registres  avec �tiquette */
.macro vidregtit str 
    push {r12}    @ save r12
    mrs r12,cpsr  /* save du registre d'�tat  dans r12 */
    push {r12}
    adr r12,lib1\@    @ utilisation de adr suite pb gros programme
    push {r12}    @ passage argument sur la pile
    ldr r12,[sp,#8]   @ on remet en etat r12 pour l'afficher correctement
    bl affregistres  @ affichage des registres
    pop {r12}
    msr cpsr,r12    /*restaur registre d'�tat */
    pop {r12}         @ on restaure R12 pour avoir une pile r�align�e
    b smacro1vidregtit\@   @ pour sauter le stockage de la chaine.    
lib1\@:  .asciz "\str"
.align 4
smacro1vidregtit\@:     
.endm   @ fin de la macro
//.noaltmacro
/****************************************************/
/* macro de vidage memoire                          */
/****************************************************/
/* ne vide que les adresses ou le registre r0       */
.macro vidmemtit str, adr, nb 
    push {r0,r1,r2,r12}    @ save registre
    mrs r12,cpsr  /* save du registre d'�tat  dans r12 */
    adr r2,lib1\@  @ recup libell� pass� dans str
    .ifc \adr,r0
    mov r0,r0
    .else
    .ifc \adr,r1
    mov r0,r1
    .else
    ldr r0,zon1\@
    .endif
    .endif
    mov r1,#\nb  /* nombre de bloc a afficher */
    bl affmemoireTit
    msr cpsr,r12    /*restaur registre d'�tat */
    pop {r0,r1,r2,r12}         @ on restaure R12 pour avoir une pile r�align�e
    b smacro1vidregtit\@   @ pour sauter le stockage de la chaine.
.ifnc \adr,r0
.ifnc \adr,r1
zon1\@:  .int \adr
.endif
.endif
lib1\@:  .asciz "\str"
.align 4
smacro1vidregtit\@:     
.endm   @ fin de la macro
