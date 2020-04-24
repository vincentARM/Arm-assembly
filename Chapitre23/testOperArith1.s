/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* programme pour test mutiplications et divisions par déplacement de bits */
/*   */
/*******************************************/
/* données initialisées                    */
/********************************************/
.data
szMessDebutPgm: 	.asciz "Début du programme. \n"
szMessMult: 	.asciz "Multiplication. \n"
szMessDiv:       .asciz  "Division. \n"

szMessErreur:     .asciz "Une erreur est arrivée. \n"   
	  
.text             /* -- Code section */
.global main      /* point d'entrée du programme  */
main:             /* Programme principal */
	ldr r0,iAdrszMessDebutPgm   /* r0 <-   message debut */
	bl affichageMess  /* affichage message dans console   */
	
    @ test multiplication
	ldr r0,iAdrszMessMult
	bl affichageMess  /* affichage message dans console   */
    mov r0,#5	@ 
	add r0,r0,r0, lsl #2    /* multiplication par 5 signée */
	bl vidtousregistres
	mov r0,#-5	@ 
	add r0,r0,r0, lsl #2    /* multiplication par 5 signée */
	bl vidtousregistres
	mov r0,#10	@ 
	rsb r0,r0,r0, lsl #3    /* multiplication par 7  (r0 * 8) - r0   rsb :  reverse substract */
	bl vidtousregistres
	
	@ division   
	ldr r0,iAdrszMessDiv
	bl affichageMess  /* affichage message dans console   */
	mov r0,#10	@ 
	lsr r0, #1    /*  division par 2 non signe */
	bl vidtousregistres
	mov r2,#-10	@ 
	mov r0,r2, asr #1    /*  division de r2 par 2 signe */
	bl vidtousregistres
	
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
iAdrszMessMult: .int szMessMult
iAdrszMessDiv:        .int szMessDiv

	
	
