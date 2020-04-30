/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* modèle B 512MO   */
/* Utilisation du timer du  BCM2835 */
/* à lancer par sudo ./testMemGPIO */
/*********************************************/
/*constantes particulière au programme*/
/********************************************/
.equ TAILLEBUF,  4 * 1024  @  taille d'une page mémoire 1024 mots de 4 octets
//.equ  ST_BASE,  0x20003   @ par page de 4096 caracteres soit 0x1000
.equ  ST_BASE,   0x3F003   @ pour PI3
.equ TIMER_OFFSET, 4

/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"

/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessDebutPgm: .asciz "Début du programme. \n"
szMessFinOK: .asciz "Fin normale du programme. \n"
szMessErreur: .asciz "Erreur ouverture fichier.\n"
szMessErreur1: .asciz "Erreur fermeture fichier.\n"
szMessErreur2: .asciz "Erreur lecture fichier.\n"
szRetourligne: .asciz  "\n"
szMessDuree:  .ascii "Valeur pour 1 s : "
iDuree:       .fill 12, 1, ' '
                   .asciz "\n"

szPeriphNom: .asciz "/dev/mem"

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
/* zones pour l'appel fonction sleep */
iZonesAttente:
 iSecondes: .skip 4
 iMicroSecondes: .skip 4
iZonesTemps: .skip 8


/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main      /* 'main' point d'entrée doit être  global */

main:             /* programme principal */
    push {fp,lr}    /* save des  2 registres */
	add fp,sp,#8    /* fp <- adresse début */
	ldr r0,iAdrszMessDebutPgm   /* r0 ← adresse message */
	bl affichageMess  /* affichage message dans console   */

	/* ouverture du fichier */
	ldr r0,=szPeriphNom   /* nom du fichier à ouvrir */
	ldr r1,#iFlags  /*  flags    */
	mov r2,#0        /* mode */
	mov r7, #OPEN /* appel fonction systeme pour ouvrir */
    swi #0 
	cmp r0,#0    /* si erreur retourne -1 */
	ble erreur
	mov r8,r0    /* save du Fd */ 
	
	/* Mapping du fichier en mémoire */
	mov r0,#0
	ldr r1,iTailleBuf   /* nb de caracteres  */
	ldr r2,iFlagsMmap   /* autorisation d'accès */
	mov r3,#MAP_SHARED
	mov r4,r8             /* contient le FD du fichier ouvert */
	ldr r5,iAdrBase
	mov r7, #192 /* appel fonction systeme pour MMAP2   page 4096 car */
	//mov r7, #90 /* appel fonction systeme pour MMAP */
    swi #0 
	cmp r0,#0     /* retourne 0 en cas d'erreur */
	bgt 1f
	cmp r0,#-124     @ test code erreur > -125 et <0
	bge erreur2
1:	
	mov r6,r0    /* save adresse zone mémoire du map */
	add r5,r6,#TIMER_OFFSET  @ adresse du timer  à l'OFFSET +4
	ldr r3,[r5]   @ init r3 avec valeur du timer 
	@ attente 1s
	mov r0,#1    @ 1 seconde
	mov r1,#0
    bl attente
	mov r7,#5    @ compteur de boucle
2:
	ldr r4,[r5]               @ valeur du timer
	sub r0,r4,r3
	//vidregtit vide_r3_2  @ macro affichage tous registres
	ldr r1,iAdriDuree
	bl conversion10S    @ pour conversion en décimal pour affichage
	ldr r0,iAdrszMessDuree
	bl affichageMess  /* affichage message dans console   */	
	ldr r3,[r5]   @ init r3 avec valeur du timer 
	mov r0,#1
	mov r1,#0
    bl attente
	subs r7,#1
	bge 2b

    
	/* fermeture des ressources */
	mov r0,r6              /* fermeture map  memoire */
	ldr r1,iTailleBuf   /* nb de caracteres  */
	mov r7, #91           /* appel fonction systeme pour UNMAP */
    swi #0 
	cmp r0,#0
	blt erreur1	
	/* fermeture fichier mem */
	mov r0,r8   /* Fd  fichier */
	mov r7, #CLOSE /* appel fonction systeme pour fermer */
    swi #0 
	cmp r0,#0
	blt erreur1	
    /* fin OK */
finnormale:	
    ldr r0,iAdrszMessFinOK   /* r0 ← adresse chaine */
	bl affichageMess  /* affichage message dans console   */	
	mov r0,#0     /* code retour OK */
	b 100f
erreur:		/* erreur d'ouverture du fichier */
	ldr r1,=szMessErreur   /* r0 <- code erreur r1 <- adresse chaine */
    bl   afficheerreur   /*appel procedure  */		
	mov r0,#1       /* erreur */
	b 100f	
erreur1:	/* erreur fermeture du fichier */
	ldr r1,=szMessErreur1   /* r1 <- adresse chaine */
	bl   afficheerreur   /*appel procedure  */		
	mov r0,#1       /* erreur */
	b 100f	
erreur2:	/* erreur mapping fichier GPIO */
	ldr r1,=szMessErreur2   /* r1 <- adresse chaine */
	bl   afficheerreur   /*appel procedure  */		
	mov r0,#1       /* erreur */
	b 100f		
100:		/* fin de programme standard  */
	pop {fp,lr}   /* restaur des  2 registres */
	mov r0,#0     /* code retour  */
	mov r7, #EXIT /* appel fonction systeme pour terminer */
    swi 0 
iAdrBase:   .int 	ST_BASE
iFlags:     .int 	O_RDONLY 
iFlagsMmap: .int PROT_READ 
iTailleBuf: .int TAILLEBUF
iAdriDuree:  .int iDuree
iAdrszMessDebutPgm: .int szMessDebutPgm
iAdrszMessFinOK: .int szMessFinOK
iAdrszMessDuree: .int  szMessDuree


/***************************************************/
/*   délai attente par appel systeme                             */
/***************************************************/
/* r0 temps en secondes  */
/* r1 temps en nanosecondes 500000000 correspond à 0,5s */
attente:
	push {fp,lr}    /* save des  2 registres frame et retour */
	push {r0-r3,r7}   /* save autres registres en nombre pair */
    ldr r2,=iSecondes
	str r0,[r2]   @ temps d'attente 0s
	str r1,[r2,#4]        @ temps d'attente en nano secondes 
	ldr r0,=iZonesAttente
	ldr r1,=iZonesTemps
	mov r7, #0xa2 /* appel fonction systeme  pour l'attente */
    swi 0 	
100:   
   /* fin standard de la fonction  */
   	pop {r0-r3,r7}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
	
/***************************************************/
/*   conversion registre en décimal   signé  */
/***************************************************/
/* r0 contient le registre   */
/* r1 contient l'adresse de la zone de conversion */
conversion10S:
    push {fp,lr}    /* save des  2 registres frame et retour */
    push {r0-r5}   /* save autres registres  */
    mov r2,r1       /* debut zone stockage */
    mov r5,#'+'     /* par defaut le signe est + */
    cmp r0,#0       /* nombre négatif ? */
    movlt r5,#'-'     /* oui le signe est - */
    mvnlt r0,r0       /* et inversion en valeur positive */
    addlt r0,#1

    mov r4,#10   /* longueur de la zone */
1: /* debut de boucle de conversion */
    bl divisionpar10 /* division  */
    add r1,#48        /* ajout de 48 au reste pour conversion ascii */	
    strb r1,[r2,r4]  /* stockage du byte en début de zone r5 + la position r4 */
    sub r4,r4,#1      /* position précedente */
    cmp r0,#0     
    bne 1b	       /* boucle si quotient different de zéro */
    strb r5,[r2,r4]  /* stockage du signe à la position courante */
    subs r4,r4,#1   /* position précedente */
    blt  100f         /* si r4 < 0  fin  */
    /* sinon il faut completer le debut de la zone avec des blancs */
    mov r3,#' '   /* caractere espace */	
2:
    strb r3,[r2,r4]  /* stockage du byte  */
    subs r4,r4,#1   /* position précedente */
    bge 2b        /* boucle si r4 plus grand ou egal a zero */
100:  /* fin standard de la fonction  */
    pop {r0-r5}   /*restaur des autres registres */
    pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr   

/***************************************************/
/*   division par 10   signé                       */
/* Thanks to http://thinkingeek.com/arm-assembler-raspberry-pi/*  
/* and   http://www.hackersdelight.org/            */
/***************************************************/
/* r0 contient le dividende   */
/* r0 retourne le quotient */	
/* r1 retourne le reste  */
divisionpar10:	
  /* r0 contains the argument to be divided by 10 */
   push {r2-r4}   /* save autres registres  */
   mov r4,r0 
   ldr r3, .Ls_magic_number_10 /* r1 <- magic_number */
   smull r1, r2, r3, r0   /* r1 <- Lower32Bits(r1*r0). r2 <- Upper32Bits(r1*r0) */
   mov r2, r2, ASR #2     /* r2 <- r2 >> 2 */
   mov r1, r0, LSR #31    /* r1 <- r0 >> 31 */
   add r0, r2, r1         /* r0 <- r2 + r1 */
   add r2,r0,r0, lsl #2   /* r2 <- r0 * 5 */
   sub r1,r4,r2, lsl #1   /* r1 <- r4 - (r2 * 2)  = r4 - (r0 * 10) */
   pop {r2-r4}
   bx lr                  /* leave function */
   .align 4
.Ls_magic_number_10: .word 0x66666667
 /*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
