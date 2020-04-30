/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* verification temps de différents algorithmes de division  */
/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/

.equ NBTESTS, 10000
.equ NBMAX, 100000000       @ borne superieure nombre aléatoire
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne: .asciz  "\n"
szMessTemps: .ascii "Durée calculée : "
sSecondes: .fill 10,1,' '
             .ascii " s "
sMicroS:   .fill 10,1,' '
             .asciz " µs\n"	
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
dwDebut:   .skip 8        @ heure de début 
dwFin:      .skip 8        @ heure de fin

Tabledividende: .skip 4 * NBTESTS    @ table des dividendes
Tablediviseur:  .skip 4 * NBTESTS     @ table des diviseurs


/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main      /* 'main' point d'entrée doit être  global */

main:             /* programme principal */
    push {fp,lr}    /* save des  2 registres */
	ldr r0,=szMessDebutPgm   /* r0 ← adresse message debut */
	bl affichageMess  /* affichage message dans console   */

	@ initialisation tables avec nombre aleatoires
	ldr r4,iNbtest    ; compteur nombre de tests
1:  @ géneration des tables de nombres aléatoires
    ldr r0,iMaxAlea
	bl genereraleas
	ldr r1,iAdrTabledividende
	str r0,[r1,r4,lsl #2]         @ stockage dans poste de la table
	ldr r0,iMaxDiviseur
	bl genereraleas
	ldr r1,iAdrTablediviseur
	str r0,[r1,r4,lsl #2]          @ stockage dans poste de la table
	subs r4,#1
	bgt 1b
	
	ldr r5,iAdrTabledividende
	ldr r6,iAdrTablediviseur
	@ cas de la division entière non signée
	ldr r4,iNbtest
	bl debutChrono
2:	
	ldr r0,[r5,r4,lsl #2]      @ init r0 
	ldr r1,[r6,r4,lsl #2]     
	bl division1
	subs r4,#1
	bgt 2b
	bl stopChrono
	vidregtit division1
	ldr r2,iAdrTabledividende
	ldr r3,iAdrTablediviseur
	@ cas de la division float double précision
	ldr r4,iNbtest
	bl debutChrono
3:	
	ldr r2,iAdrTabledividende
	ldr r0,[r2,r4,lsl #2]      @ init r0 
	ldr r1,[r3,r4,lsl #2]     
	bl divisionDP
	subs r4,#1
	bgt 3b
	bl stopChrono
	vidregtit division_DP
	@ Cas de la division entière non signee 
	ldr r4,iNbtest
	ldr r5,iAdrTabledividende
	ldr r6,iAdrTablediviseur
	bl debutChrono
4:	
	ldr r0,[r5,r4,lsl #2]       @ init r0 	
	ldr r1,[r6,r4,lsl #2] 
	bl better_unsigned_division 
	subs r4,#1
	bgt 4b
	bl stopChrono
	vidregtit div_better_unsigned
	@cas de la division U2
	ldr r4,iNbtest
	bl debutChrono
5:	
	ldr r0,[r5,r4,lsl #2]       @ init r0 	
	ldr r1,[r6,r4,lsl #2] 
	bl divisionU2
	subs r4,#1
	bgt 5b
	bl stopChrono
	vidregtit div_U2
	@cas de la division U3
	ldr r4,iNbtest
	bl debutChrono
6:	
	ldr r0,[r5,r4,lsl #2]       @ init r0 	
	ldr r1,[r6,r4,lsl #2] 
	bl divisionU3
	subs r4,#1
	bgt 6b
	bl stopChrono
	vidregtit div_U3
	@ cas de la division U4
	ldr r4,iNbtest
	bl debutChrono
7:	
	ldr r0,[r5,r4,lsl #2]       @ init r0 	
	ldr r1,[r6,r4,lsl #2] 
	bl divisionU4
	subs r4,#1
	bgt 7b
	bl stopChrono
	vidregtit div_U4

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
szMessDebutPgm: .asciz "Début du programme. \n"
szMessFinOK: .asciz "Fin normale du programme. \n"
.align 4 
iNbtest: .int NBTESTS
iMaxAlea: .int NBMAX
iMaxDiviseur: .int NBMAX /10000
iAdrTabledividende: .int Tabledividende
iAdrTablediviseur: .int Tablediviseur

/********************************************************/
/* Lancement du chrono           */
/*  */
debutChrono:
    push {fp,lr}    /* save des  2 registres frame et retour */
	push {r0,r1,r7,r8}
  	ldr r0,iadrdwDebut   @ zone de reception du temps début
	mov r1,#0
	mov r7, #0x4e  @ test appel systeme gettimeofday
    swi #0 
	cmp r0,#0        @ verification si l'appel est OK
	bge 100f
   /* affichage erreur */
	adr r1,szMessErreurCH   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */		
100:   
   /* fin standard  de la fonction  */
    pop {r0,r1,r7,r8}
    pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	 
iadrdwDebut: .int 	dwDebut
szMessErreurCH: .asciz "Erreur debut Chrono rencontrée.\n"
.align 4 	
/********************************************************/
/* arret du chrono et affichage du temps                */
/********************************************************/
stopChrono:
    push {fp,lr}    /* save des  2 registres frame et retour */
	push {r0-r7}
	ldr r0,iadrdwFin   @ zone de reception du temps fin
	mov r1,#0
	mov r7, #0x4e @ test appel systeme gettimeofday
    swi #0 
	cmp r0,#0
	blt 99f     @ verification si l'appel est OK
	/* calcul du temps */
	ldr r0,iadrdwDebut @ zones 
	ldr r2,[r0]        @ secondes
	ldr r3,[r0,#4]       @ micro secondes
	ldr r0,iadrdwFin      @ zones 
	ldr r4,[r0]             @ secondes
	ldr r5,[r0,#4]         @ micro secondes
	sub r2,r4,r2         @ nombre de secondes ecoulées
	subs r3,r5,r3       @ nombre de microsecondes écoulées
	sublt r2,#1        @ si negatif on enleve 1 seconde aux secondes
	ldr r4,iSecMicro
	addlt r3,r4        @ et on ajoute 1000000 pour avoir un nb de microsecondes exact
	mov r0,r2            @ conversion des secondes en base 10 pour l'affichage
	ldr r1,=sSecondes
	bl conversion10
	mov r0,r3            @ conversion des microsecondes en base 10 pour l'affichage
	ldr r1,=sMicroS
	bl conversion10
	ldr r0,iadrszMessTemps   /* r0 ← adresse du message */
	bl affichageMess  /* affichage message dans console   */
	b 100f
99:	/* erreur rencontree */
	adr r1,szMessErreurCHS   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */	
100:   
   /* fin standard  de la fonction  */
    pop {r0-r7}
    pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	 
/* variables */	
iSecMicro:  .int 1000000	
iadrdwFin: .int dwFin 
iadrszMessTemps: .int szMessTemps
szMessErreurCHS: .asciz "Erreur stop Chrono rencontrée.\n"
.align 4 
/*=============================================*/
/* division entiere non signée                */
/* voir chapitre 15 de http://thinkingeek.com/arm-assembler-raspberry-pi/
/*============================================*/
division1:
    /* r0 contains N */
    /* r1 contains D */
    /* r2 contains Q */
    /* r3 contains R */
    push {r4, lr}
	cmp r1,#0   @ division par zero
	moveq r0,#-1
	beq 100f	
    mov r2, #0                 /* r2 ← 0 */
    mov r3, #0                 /* r3 ← 0 */
    mov r4, #32                /* r4 ← 32 */
    b 2f
1:
    movs r0, r0, LSL #1    /* r0 ← r0 << 1 updating cpsr (sets C if 31st bit of r0 was 1) */
    adc r3, r3, r3         /* r3 ← r3 + r3 + C. This is equivalent to r3 ← (r3 << 1) + C */
 
    cmp r3, r1             /* compute r3 - r1 and update cpsr */
    subhs r3, r3, r1       /* if r3 >= r1 (C=1) then r3 ← r3 - r1 */
    adc r2, r2, r2         /* r2 ← r2 + r2 + C. This is equivalent to r2 ← (r2 << 1) + C */
2:
    subs r4, r4, #1        /* r4 ← r4 - 1 */
    bpl 1b            /* if r4 >= 0 (N=0) then branch to .Lloop1 */
 100:
    pop {r4, lr}
    bx lr	

/********************************************************/
/* division double precision                            */
/********************************************************/
/* r0 dividende  */
/* r1 diviseur  */
/* ro retourne le quotient */
/* r1 retourne le reste  */
divisionDP:
    push {r2,lr}    /* save des  2 registres r2 et retour */
	cmp r1,#0   @ division par zero
	moveq r0,#-1
	beq 100f	
	vmov s1, r0          /* copie de r0 dans s1 */
    vcvt.f64.u32 d1, s1 /* conversion en flottant double précision */
	vmov s4, r1         /* copie de r1 dans s2  */
    vcvt.f64.u32 d3, s4 /* conversion en flottant double précision */
	vdiv.f64 d4,d1,d3   /* division */
	vcvt.s32.f64 s0, d4
	vmov r2,s0            /* recup résultat */
	mul r1,r2,r1            /* calcul du reste car instruction vlms non admise */
    sub r1,r0,r1
	mov r0,r2
100:	
   pop {r2,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	 	
/********************************************************/
/* Division entière chapitre 15 du site                 */
/* http://thinkingeek.com/arm-assembler-raspberry-pi/   */
/********************************************************/
better_unsigned_division:
    /* r0 contains N and Ni */
    /* r1 contains D */
    /* r2 contains Q */
    /* r3 will contain Di */
 	cmp r1,#0   @ division par zero
	moveq r0,#-1
	beq 100f
    mov r3, r1                   /* r3 ← r1 */
    cmp r3, r0, LSR #1           /* update cpsr with r3 - r0/2 */
.Lloop2:
    movls r3, r3, LSL #1       /* if r3 <= 2*r0 (C=0 or Z=1) then r3 ← r3*2 */
    cmp r3, r0, LSR #1         /* update cpsr with r3 - (r0/2) */
    bls .Lloop2                /* branch to .Lloop2 if r3 <= 2*r0 (C=0 or Z=1) */
 
    mov r2, #0                   /* r2 ← 0 */
 
.Lloop3:
    cmp r0, r3                 /* update cpsr with r0 - r3 */
    subhs r0, r0, r3           /* if r0 >= r3 (C=1) then r0 ← r0 - r3 */
    adc r2, r2, r2             /* r2 ← r2 + r2 + C.
                                    Note that if r0 >= r3 then C=1, C=0 otherwise */
 
    mov r3, r3, LSR #1         /* r3 ← r3/2 */
    cmp r3, r1                 /* update cpsr with r3 - r1 */
	bhs .Lloop3                /* if r3 >= r1 branch to .Lloop3 */
100:
    bx lr

				
				
/***********************************************/
/* division entière nonsignée  algorithme  2    */
/* livre : modern assembly language programming with arm processor */
/* Larry D.Pyeatt                               */
/***********************************************/
/* r0 contient le nombre à diviser */
/* r1 contient le diviseur  */
/* r0 retourne le quotient et r1 le reste */ 
/* pas de sauvegarde des registres */
divisionU2:
	cmp r1,#0   @ division par zero
	moveq r0,#-1
	beq 100f
	mov r2,r1      @ diviseur dans r2
	mov r1,r0      @ dividende dans r1
	mov r0,#0      @ init du quotient
	mov r3,#1      @ init du bit courant
1:   @ debut de boucle
	cmp r2,#0
	blt 2f
	cmp r2,r1    @ dividende > diviseur
	lslls r2,r2,#1  @ non on déplace le diviseur à gauche
	lslls r3,r3,#1  @ et la position du bit courant 
	bls 1b          @ et on boucle
2:  @ boucle de calcul
	cmp r1,r2   @ dividende > diviseur
	subhs	r1,r1,r2    @ si oui on enleve le diviseur
	addhs  r0,r0,r3    @ et ajout au quotient de la valeur courante
	lsr r2,r2,#1        @ deplacement du diviseur à droite
	lsrs r3,r3,#1      @ deplacement du bit courant à droite
	bcc 2b             @ et boucle si le bit ne se trouve pas dans le carry
100:
    bx lr      @ retour fonction
/***********************************************/
/* division entière nonsignée  algorithme  3    */
/***********************************************/
/* r0 contient le nombre à diviser */
/* r1 contient le diviseur  */
/* r2 retourne le quotient et r3 le reste */ 
/* sauvegarde des registres */
divisionU3:
	push {r4,lr}
	cmp r1,#0   @ division par zero
	moveq r0,#-1    @ à revoir en fonction des besoins
	beq 100f
	clz r4,r0      @ nombre de zeros à gauche du dividende
	mov r3,#0      @ init du reste
	mov r2,#0      @ init du quotient
	lsl r0,r0,r4   @ deplacer à gauche du dividende pour supprimer les 0 inutiles
	rsb r4,r4,#32  @ et calcul du nombre de chiffres utiles 
1:                @ debut boucle calcul
    lsl r3,#1      @ deplacement à gauche du reste
    lsls r0,#1    @ deplacement à gauche du dividende
	addcs r3,#1   @ si carry positionné report du carry sur bit de droite du reste
	lsl r2,#1      @ deplacement à gauche du quotient
	subs r3,r1    @ reste > diviseur
	addhs r2,#1   @ oui donc bits de droite du quotient passe à 1
	addlo r3,r1   @ sinon remise à niveau du reste
	subs r4,#1    @ compteur - 1
	bgt 1b        @ et boucle si pas fini
100:
	pop {r4,lr}
    bx lr      @ retour fonction	
	/***********************************************/
/* division entière nonsignée  algorithme  4    */
/***********************************************/
/* r0 contient le nombre à diviser */
/* r1 contient le diviseur  */
/* r2 retourne le quotient et r3 le reste */ 
/* sauvegarde de r1 et r4  */
divisionU4:
	push {r1,r4,lr}    @ save de r1 car il est détruit par la routine
	cmp r1,#0   	@ division par zero
	moveq r0,#-1    @ à revoir en fonction des besoins
	beq 100f
	clz r4,r0       @ nombre de zeros à gauche du dividende
	rsb r4,r4,#32   @ donc nombre de chiffres utiles
	clz r3,r1       @ nombre de zeros à gauche  du diviseur
	rsb r3,r3,#32   @ donc nombre de chiffres utiles
	subs r4,r3
	lslgt r1,r1,r4   @ aligne le diviseur sur le dividende
	mov r3,r0      @ init reste avec dividende
	mov r2,#0      @ init quotient
1:
	lsl r2,#1      @ deplacement quotient à gauche
	subs r3,r1    @ dividende > diviseur
	addhs r2,#1   @ oui on met le bit à droite du quotient à 1
	addlo r3,r1   @ non on remet r3 à jour
	lsr r1,#1      @ deplace r1 à droite
	subs r4,#1    @ tous les bits sont traités ?
	bge 1b        @ non -> boucle
100:
	pop {r1,r4,lr}
    bx lr      @ retour fonction		
/********************************************************************/
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
	
	