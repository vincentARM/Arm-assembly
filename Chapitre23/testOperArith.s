/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* programme pour test opérations arithmétiques */
/*   */

/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"
/*******************************************/
/* données initialisées                    */
/********************************************/
.data
szMessDebutPgm: 	.asciz "Début du programme. \n"
szMessMult: 	.asciz "Multiplication. \n"
szMessSous:       .asciz "Soustraction. \n"
szMessDiv:       .asciz  "Division. \n"
szMessAutreIns:       .asciz "Autres instructions mla, mls. \n"
szMessmultLong:       .asciz "Multiplication resultat sur 2 registres. \n"
szMessDivConst:       .asciz "Division par une constante 3 puis 5 puis 10. \n"
szMessErreur:     .asciz "Une erreur est arrivée. \n"   

sMessAffBin: .ascii "Valeur du registre : "
sZonemess: .space 36,' '
              .asciz "\n"
.equ LGMESSAFFBIN, . -  sMessAffBin 	
/* pour affichage du registre d'état   */
szLigneEtat: .asciz "Etats :  Z=   N=   C=   V=       \n"		  
.text             /* -- Code section */
.global main      /* point d'entrée du programme  */
main:             /* Programme principal */
	ldr r0,iAdrszMessDebutPgm   /* r0 <-   message debut */
	bl affichageMess  /* affichage message dans console   */
	
    @ test soustraction
	ldr r0,iAdrszMessSous
	bl affichageMess  /* affichage message dans console   */
    mov r0,#4	@ 
	subs r0,#10
	bl affichetat
	bl vidtousregistres
	mov r1,#10	@ 
	mov r2,#6
	subs r0,r1,r2
	bl affichetat
	bl vidtousregistres
	ldr r1,iValmaxPos	@ 
	add r1,#1
	mov r2,#5
	subs r0,r1,r2
	bl affichetat
	bl vidtousregistres
	
    @ test multiplication
	ldr r0,iAdrszMessMult
    bl affichageMess  /* affichage message dans console   */
	mov r1,#5
	mov r0,#4
	muls r0,r1     @ cas simple
	bl affichetat
	bl vidtousregistres
	mov r1,#5
	mov r2,#3
	muls r0,r1,r2   @ avec 2 registres
	bl affichetat
	bl vidtousregistres
	@ multiplication par un nombre négatif
	mov r1,#-5
	mov r2,#3
	muls r0,r1,r2
	bl affichetat
	bl vidtousregistres
	@ multiplication valeur maxi
	ldr r1,iValmaxPos
	mov r2,#10
	muls r0,r1,r2
	bl affichetat
	bl vidtousregistres    @ le résultat est faux
	
	ldr r1,iValmax           @ la aussi le résultat est faux
	mov r2,#10
	muls r0,r1,r2
	bl affichetat
	bl vidtousregistres
	ldr r1,iValmaxPos
	ldr r2,iValmaxPos
	muls r0,r1,r2
	bl affichetat      @ la aussi le résultat est faux
	bl vidtousregistres
	@multiplication long pour verifier l'overflow
	ldr r0,iAdrszMessmultLong
	bl affichageMess  /* affichage message dans console   */
	ldr r2,iValmax
	ldr r3,iValmax       @ cas non signé
	umulls r0,r1,r2,r3   @ r0 contiendra la partie basse et r1 la partie haute 
	bl affichetat
	bl vidtousregistres
	ldr r2,iValmaxPos
	ldr r3,iValmaxPos       @ cas signé
	umulls r0,r1,r2,r3   @ r0 contiendra la partie basse et r1 la partie haute 
	@
	asr r2,r0,#31
	cmp r2,r1
	bl affichetat
	bl vidtousregistres
	mov r2,#10
	mov r3,#100      @ cas signé
	umulls r0,r1,r2,r3   @ r0 contiendra la partie basse et r1 la partie haute 
	@
	lsr r2,r0,#31
	cmp r2,r1
	bl affichetat
	bl vidtousregistres
	ldr r2,iValmaxPos
	mov r3,#10       @ cas signé
	umulls r0,r1,r2,r3   @ r0 contiendra la partie basse et r1 la partie haute 
	@
	lsr r2,r0,#31
	cmp r2,r1
	bl affichetat
	bl vidtousregistres
	
	
	@ autre instructions
	ldr r0,iAdrszMessAutreIns
    bl affichageMess  /* affichage message dans console   */
	mov r1,#5
	mov r2,#4
	mov r3,#6
	mlas r0,r1,r2,r3
	bl affichetat
	bl vidtousregistres
	@ mls non autorisée
	@multiplication long 
	ldr r0,iAdrszMessmultLong
	bl affichageMess  /* affichage message dans console   */
	ldr r2,iValmaxPos
	ldr r3,iValmaxPos
	umulls r0,r1,r2,r3   @ r0 contiendra la partie basse et r1 la partie haute 
	bl affichetat
	bl vidtousregistres
	ldr r2,iValmax
	ldr r3,iValmax
	umulls r0,r1,r2,r3   @ r0 contiendra la partie basse et r1 la partie haute 
	bl affichetat
	bl vidtousregistres
	ldr r2,iValmax
	ldr r3,iValmax
	umlals r0,r1,r2,r3   @ à r0,r1 ajout de r2*r3 
	bl affichetat
	bl vidtousregistres
	ldr r2,iValmax
	ldr r3,iValmax
	umaal r0,r1,r2,r3   @ à r0,r1 ajout de r1 de r2*r3 
	bl affichetat
	bl vidtousregistres
	ldr r2,iValmax     @ = -1
	ldr r3,iValmax     @ = -1 
	smulls r0,r1,r2,r3   @ multiplication signée longue donc r1,r0 = 1
	bl affichetat
	bl vidtousregistres
	
	@ division   
	ldr r0,iAdrszMessDiv
	bl affichageMess  /* affichage message dans console   */
	ldr r0,iValmax     @ = -1
	ldr r1,iValmax     @ = -1 
	bl division        @ resultat dans r2 et reste dans r3
	bl vidtousregistres
	ldr r0,iValmax     @ = -1
	ldr r1,iValmax     @ = -1 
	bl divisionDP      @ resultat dans r0 
	bl vidtousregistres
	
	@
	ldr r0,iValmax     @ = -1
	ldr r1,iValmaxPos      
	bl divisionS        @ resultat dans r2 et reste dans r3
	bl vidtousregistres
	ldr r0,iValmax     @ = -1
	ldr r1,iValmaxPos     @  
	bl divisionDP      @ resultat dans r0 
	bl vidtousregistres
	
	@ division par une constante
	ldr r0,iAdrszMessDivConst
	bl affichageMess  /* affichage message dans console   */
	mov r0,#21
	bl divipar3
	bl vidtousregistres
	@division par 5
	mov r0,#100
	bl divipar5
	bl vidtousregistres
	@ division par 10
	mov r0,#100
	lsr r0,#1    @ division par 2
	bl divipar5
	bl vidtousregistres
	@division par 5 d'un nombre negatif
	mov r0,#-100
	bl divipar5
	bl vidtousregistres
	@division par 10 d'un nombre negatif
	mov r0,#-104
	asr r0,#1    @ division par 2
	bl divipar5 	
	bl vidtousregistres
	@division par 10 nombre negatif
	mov r0,#-104
	bl divipar10
	bl vidtousregistres
	@division par 10 
	mov r0,#999
	bl divipar10
	vidregtit division10_1
	@autre division par 10 
	mov r0,#104
	bl divipar10_2
	vidregtit div10fin
	mov r0,#999
	bl divipar10_2
	vidregtit div10fin_2
	mov r0,#0  /* code retour r0 */
	b 100f
erreur: /* affichage erreur */
	ldr r1,iAdrszMessErreur   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */		
	mov r0,#-1       /* code erreur */
	b 100f		
100:	
	mov r7, #1 /* code pour la fonction systeme EXIT */
    swi 0      /* appel system */

iValmax: .int 2 << 31   - 1	
iValmaxPos: .int 2 << 30   - 1
iAdrszMessDebutPgm: .int szMessDebutPgm	
iAdrszMessErreur: .int szMessErreur
iAdrszMessSous: .int szMessSous
iAdrszMessMult: .int szMessMult
iAdrszMessAutreIns: .int szMessAutreIns
iAdrszMessmultLong:  .int szMessmultLong
iAdrszMessDiv:        .int szMessDiv
iAdrszMessDivConst: .int szMessDivConst

	
/***********************************************/
/* division par 3 signée  OK                   */
/***********************************************/
/* r0 contient le nombre à diviser */
/* et retour résultat dans r0   */	 
divipar3:	 
   push {r1,r2,r3}
   ldr r3, .Ls_magic_number_3 /* r1 ? magic_number */
   smull r1, r2, r3, r0   /* r1 ? Lower32Bits(r1*r0). r2 ? Upper32Bits(r1*r0) */
   mov r1, r0, LSR #31    /* r1 ? r0 >> 31 */
   add r0, r2, r1         /* r0 ? r2 + r1 */
   pop {r1,r2,r3}
   bx lr                  /* leave function */
.align 4
.Ls_magic_number_3: .word 0x55555556	
/***********************************************/
/* division par 5 signée  OK                   */
/***********************************************/
/* r0 contient le nombre à diviser */
/* et retour résultat dans r0 */
divipar5:
  push {r1,r2,r3}
   ldr r3, .Ls_magic_number_5 /* r1 ? magic_number */
   smull r1, r2, r3, r0   /* r1 ? Lower32Bits(r1*r0). r2 ? Upper32Bits(r1*r0) */
   mov r2, r2, ASR #1     /* r2 ? r2 >> 1 */
   mov r1, r0, LSR #31    /* r1 ? r0 >> 31 */
   add r0, r2, r1         /* r0 ? r2 + r1 */
   pop {r1,r2,r3}
   bx lr                  /* leave function */
.align 4
.Ls_magic_number_5: .word 0x66666667
/***********************************************/
/* division par 10 signée  OK                   */
/***********************************************/
/* r0 contient le nombre à diviser */
/* et retour résultat dans r0 */
divipar10:
   push {r1,r2,r3}
   ldr r3, .Ls_magic_number_10 /* r1 ? magic_number */
   smull r1, r2, r3, r0   /* r1 ? Lower32Bits(r1*r0). r2 ? Upper32Bits(r1*r0) */
   mov r2, r2, ASR #2     /* r2 ? r2 >> 2 */
   mov r1, r0, LSR #31    /* r1 ? r0 >> 31 */
   add r0, r2, r1         /* r0 ? r2 + r1 */
   pop {r1,r2,r3}
   bx lr                  /* leave function */
.align 4
.Ls_magic_number_10: .word 0x66666667

/***********************************************/
/* division par 10 signée  OK                   */
/***********************************************/
/* r0 contient le nombre à diviser */
/* et retour résultat dans r0 */
divipar10_2:
    push {r1,lr}
    mov r1,#0x6667
	movt r1,#0x6666
	vidregtit divi1
	smmul r0,r0,r1
	vidregtit divi2
	mov r1,r0,asr#2
	vidregtit divi3
	add r0,r1,r0,lsr #31
	vidregtit divi4
    pop {r1,lr}
    bx lr                  /* leave function */
