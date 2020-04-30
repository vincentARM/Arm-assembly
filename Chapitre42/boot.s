/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* modèle B 512MO   */
/*  */
/* programme d'initialisation des zones pour utilisation sans OS */
/*  */
/*********************************************/
/*           CONSTANTES                      */
/* constantes du programme                 */
/********************************************/
.equ PAGE_SHIFT,	 			12
.equ TABLE_SHIFT, 			9
.equ SECTION_SHIFT,			(PAGE_SHIFT + TABLE_SHIFT)
.equ PAGE_SIZE,   			(1 << PAGE_SHIFT)	
.equ SECTION_SIZE,			(1 << SECTION_SHIFT)	
.equ LOW_MEMORY,				 (2 * SECTION_SIZE)

/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 


/**********************************************/
/* -- Code section                            */
/**********************************************/
.section ".text.boot"
.global _start      /*  point d'entrée doit être  global */

_start:             /* programme principal */

	ldr	r0,ibss_begin       @ ces valeurs seront fournies par le linker
	ldr	r1,ibss_end
	sub	r1, r1, r0
	bl 	memzero             @ initialisation zone bss

	mov	sp, #LOW_MEMORY    @ initialisation de la pile 
	bl	kernel_main        @ appel du 2ième programme principal
	
proc_hang:           @ boucle principale !!!!
	b proc_hang      @ ne devrait jamais être executé !!!

ibss_begin: .int  bss_begin
ibss_end: .int  bss_end
