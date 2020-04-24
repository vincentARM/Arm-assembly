/* Programme assembleur ARM  */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* verification fonction fork 0x02 */
/* attente de la fin du tread    */
/* pgm à lancer par testfork &  puis faire ps pour voir les pid */
/* puis faire kill -STOP pidfils puis kill -CONT pidfils puis kill -TERM pidfils */
/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/
.equ WNOHANG,               1  @  Wait, do not suspend execution
.equ WUNTRACED,               2   @ Wait, return status of stopped child
.equ WCONTINUED,             8   @ Wait, return status of continued child
//.equ WEXITED,                 8   @ Wait for processes that have exited
//.equ WSTOPPED,               16   @ Wait, return status of stopped child
.equ WNOWAIT,                32    @Wait, return status of a child without
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne: .asciz  "\n"
szMessageThread: .asciz "Execution thread. \n" 
szMessageFinThread: .asciz "Fin du thread. \n" 
szMessageParent: .asciz "C'est moi le papa !!\n"

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
zone1:      .skip 4

/* zones pour l'appel fonction sleep */
iZonesAttente:
 iSecondes: .skip 4
 iMicroSecondes: .skip 4
iZonesTemps: .skip 8
 
//ZonesBbs:  .skip 4 
zRusage: .skip 1000
//sBuffer:   .skip 500 

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main      /* 'main' point d'entrée doit être  global */

main:             /* programme principal */
    push {fp,lr}    /* save des  2 registres */
	add fp,sp,#8    /* fp <- adresse début */
	bl vidtousregistres
	@ lancement du thread fils
	mov r0,#0
	mov r7, #0x02 /* appel fonction systeme FORK */
    swi 0 
    cmp r0,#0
	blt erreur
	bne parent   @ si <> zero r0 contient le pid du pere
	@ sinon c'est le fils 
	bl exec_thread
	b finnormale  @ normalement on ne revient jamais ici
parent:	
    bl vidtousregistres  @ le PID du fils est dans r0
	mov r4,r0   @ save du pid fils
	ldr r0,=szMessageParent   /* r0 ← adresse chaine */
    bl affichageMess  /* affichage message dans console   */
1:	 @ debut de boucle d'attente des signaux du fils
    mov r0,r4
	ldr r1,=zone1   @ contient le status de retour
	mov r2,#WCONTINUED | WUNTRACED    @ revoir options
	ldr r3,=zRusage  @ structure contenant les infos de retour 
    mov r7, #0x072 /* appel fonction systeme WAIT4 */
    swi 0 
	cmp r0,#0
	blt erreur
    bl vidtousregistres  @ 
	ldr r0,=zone1  @ analyse du status
	mov r1,#2  /* nombre de bloc a afficher */
    push {r0} /* adresse memoire */	
	push {r1}
    bl affmemoire
	ldr r0,=zone1  @ recup du status
	ldrb r0,[r0]    @ premier octet
	cmp r0,#0X0F    @ fin du thread par kill ?
	beq 2f    @ oui  arret boucle 
	cmp r0,#0   @ fin normale du tread
	beq 2f    @ oui  arret boucle et le 2iéme octet de zone1 contient le code retour
	bl vidtousregistres
	b 1b      @ sinon on boucle 
2:	
	ldr r0,=zRusage
	mov r1,#4  /* nombre de bloc a afficher */
    push {r0} /* adresse memoire */	
	push {r1}
    bl affmemoire

finnormale:	
    ldr r0,=szMessFinOK   /* r0 ← adresse chaine */
	bl affichageMess  /* affichage message dans console   */
	mov r0,#0     /* code retour OK */
	b 100f
erreur:	/* affichage erreur */
	ldr r1,=szMessErreur   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */		
	mov r0,#1       /* code erreur */
	b 100f	
/* fin de programme standard  */
100:		
	pop {fp,lr}   /* restaur des  2 registres */
	mov r7, #EXIT /* appel fonction systeme pour terminer */
    swi 0 
/************************************/	  
szMessErreur: .asciz "Erreur rencontrée.\n"
szMessFinOK: .asciz "Fin normale du programme. \n"
.align 4     /* alignement car l'étiquette de la routine suivante doit être alignée */
/***************************************************/
/*   Exemple d'appel du tr               */
/***************************************************/
exec_thread:
   push {fp,lr}    /* save des  2 registres frame et retour */
   add fp,sp,#8    /* fp <- adresse début */
   push {r1,r2,r3,r4,r5}   /* save autres registres en nombre pair */
   mov r7, #0x40 /* appel fonction systeme pour trouver le pid du pére */
   swi 0 
   bl vidtousregistres  @ voir dans le registre zero
   ldr r0,=szMessageThread   /* r0 ← adresse chaine */
   bl affichageMess  /* affichage message dans console   */
   ldr r0,=iSecondes
	mov r1,#5    @ temps d'attente 5s
	str r1,[r0]
	ldr r0,=iZonesAttente
	ldr r1,=iZonesTemps
	mov r7, #0xa2 /* appel fonction systeme  SLEEPMICRO*/
    swi 0 
	mov r0,#0
	mov r7, #0x1D /* appel fonction systeme PAUSE */
    swi 0           @ mettre cette instruction en commentaire pour voir la fin normale du tread
	bl vidtousregistres
	ldr r0,=szMessageFinThread
	bl affichageMess  /* affichage message dans console   */
	mov r0,#100   @ pour verif de ce code retour
100:   
   /* fin standard de la fonction  */
   	pop {r1,r2,r3,r4,r5}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
	mov r7, #EXIT /* appel fonction systeme pour terminer */
    swi 0 
   
/********************************************************************/
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
	
	