/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */

/* modules des fonctions générales   */

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
/* les fonctions doivent être déclarées Globales */
.global memzero, division  

/***************************************************/
/*   raz zone memoire                              */
/***************************************************/
/* r0 contient l'adresse de début   */
/* r1 contient le nombre d'octets (doit être un multiple de 4) */
/* utilise r2    */
/* aucun registre sauvegardé car la pile peut ne pas etre initialisée */
memzero:
	mov r2,#0
1:
    str r2, [r0], #4      @ store r2 et incremente r0 de 4 octets
	subs r1, r1, #4
	bgt 1b
100:   /* fin standard de la fonction  */
    bx lr                   /* retour de la fonction en utilisant lr  */
	
/*=============================================*/
/* division entiere non signée                */
/*============================================*/
division:
    /* r0 contains N */
    /* r1 contains D */
    /* r2 contains Q */
    /* r3 contains R */
    push {r4, lr}
    mov r2, #0                 /* r2 ? 0 */
    mov r3, #0                 /* r3 ? 0 */
    mov r4, #32                /* r4 ? 32 */
    b 2f
1:
    movs r0, r0, LSL #1    /* r0 ? r0 << 1 updating cpsr (sets C if 31st bit of r0 was 1) */
    adc r3, r3, r3         /* r3 ? r3 + r3 + C. This is equivalent to r3 ? (r3 << 1) + C */
 
    cmp r3, r1             /* compute r3 - r1 and update cpsr */
    subhs r3, r3, r1       /* if r3 >= r1 (C=1) then r3 ? r3 - r1 */
    adc r2, r2, r2         /* r2 ? r2 + r2 + C. This is equivalent to r2 ? (r2 << 1) + C */
2:
    subs r4, r4, #1        /* r4 ? r4 - 1 */
    bpl 1b            /* if r4 >= 0 (N=0) then branch to .Lloop1 */
 
    pop {r4, lr}
    bx lr	
	