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

.equ STACK_TOP,   			0x10000000
.equ FIQ_STACK_TOP,    		STACK_TOP
.equ IRQ_STACK_TOP,    		STACK_TOP - 0X1000
.equ ABT_STACK_TOP,    		STACK_TOP - 0X2000
.equ UND_STACK_TOP,    		STACK_TOP - 0X3000
.equ MON_STACK_TOP,    		STACK_TOP - 0X4000
.equ SVC_STACK_TOP,    		STACK_TOP - 0X5000
.equ SYS_STACK_TOP,    		STACK_TOP - 0X6000

.equ I_BIT,     0x80        @ si I= 1  IRQ est inactif
.equ F_BIT,     0x40        @ si F= 1  FIQ est inactif

.equ USR_MODE,  0x10
.equ FIQ_MODE,  0x11
.equ IRQ_MODE,  0x12
.equ SVC_MODE,  0x13
.equ ABT_MODE,  0x17
.equ UND_MODE,  0x18
.equ SYS_MODE,  0x1F

/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data

/**********************************************/
/* -- Code section                            */
/**********************************************/
.section ".text.boot"
.global _start      /*  point d'entrée doit être  global */

_start:             /* programme principal */

	/* initialisation adresse de la pile pour chaque mode */
	msr CPSR_c,#FIQ_MODE|I_BIT|F_BIT    @ avec les interruptions inactives
	ldr sp,=FIQ_STACK_TOP
	
	msr CPSR_c,#IRQ_MODE|I_BIT|F_BIT
	ldr sp,=IRQ_STACK_TOP
	
	msr CPSR_c,#ABT_MODE|I_BIT|F_BIT
	ldr sp,=ABT_STACK_TOP
	
	msr CPSR_c,#UND_MODE|I_BIT|F_BIT
	ldr sp,=UND_STACK_TOP
	
	msr CPSR_c,#SYS_MODE|I_BIT|F_BIT
	ldr sp,=SYS_STACK_TOP
	
	@ démarrage final en mode superviseur
	msr CPSR_c,#SVC_MODE|I_BIT|F_BIT
	ldr sp,=SVC_STACK_TOP
	@ et si necessaire ajouter un démarrage MODE_USR avec la pile SYS

	ldr	r0,ibss_begin       @ ces valeurs seront fournies par le linker
	ldr	r1,ibss_end
	sub	r1, r1, r0            @ calcul de la taille de la zone bss
	bl 	memzero             @ initialisation zone bss

	//mov	sp, #LOW_MEMORY    @ autre initialisation de la pile si necessaire
	
	@ ajouter ici si necessaire la gestion des vecteurs d'interruption

	bl	kernel_main        @ appel du 2ième programme principal
	
proc_hang:           @ boucle principale !!!!
	b proc_hang      @ ne devrait jamais être executé !!!

ibss_begin: 	.int  bss_begin
ibss_end: 	.int  bss_end
