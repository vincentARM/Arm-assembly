/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* modèle B 512MO   */
/*  */
/* verification affichage tous registres  */
/* commentaire */ 
/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/
.equ  TAILLECPT,     4     @ taille en octet du compteur du TIMER
.equ  ATTENTE,       1     @ temps d'attente en secondes
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessDebutPgm: 	.asciz "Début du programme. \n"
szMessErreur: 		.asciz "Erreur rencontrée.\n"
szMessFinOK: 		.asciz "Fin normale du programme. \n"
szMessTemps:        .ascii "Valeur Timer : "
sMessValeur:        .fill  11,1,' '
szRetourligne: 		.asciz  "\n"

szNomDriver:        .asciz "/dev/bcm2708_usec"

.align 4

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
iTemps1:         .skip TAILLECPT
iTemps2:         .skip TAILLECPT
iTemps3:         .skip TAILLECPT
ZonesAttente:
 iSecondes:      .skip 4
 iMicroSecondes: .skip 4
ZonesTemps:      .skip 8
sBuffer:         .skip 500 

/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text            
.global main                       @ 'main' point d'entrée doit être  global 

main:                              @ programme principal 
    push {fp,lr}                   @ save des  registres 
	add fp,sp,#8                   @ fp <- adresse début 
	ldr r0,iAdrszMessDebutPgm      @ r0 ← adresse message debut 
	bl affichageMess               @ affichage message dans console   
	/* ouverture du driver */
	ldr r0,iAdrszNomDriver         @
	mov r1,#O_RDONLY               @ flag
	mov r2,#0                      @ mode
	mov r7,#OPEN                   @ appel fonction systeme pour ouvrir 
    swi #0 
	cmp r0,#0                      @ erreur ?
	ble 99f
	mov r8,r0                      @ save du Fd
    ldr r1,iAdriTemps1
    mov r2,#TAILLECPT
    mov r7,#READ                   @ lecture compteur timer
    svc 0 
    cmp r0,#0                      @ erreur lecture
    ble 99f

	ldr r0,iAdriSecondes
	mov r1,#ATTENTE               @ temps d'attente 
	str r1,[r0]

	ldr r0,iAdrZonesAttente
	ldr r1,iAdrZonesTemps
	mov r7, #0xa2                 @ appel fonction systeme SLEEP
    svc 0 
	cmp r0,#0
	blt 99f

    mov r0,r8
    ldr r1,iAdriTemps2
    mov r2,#TAILLECPT
    mov r7,#READ                 @ lecture compteur timer
    svc 0 
    cmp r0,#0                    @ erreur
    ble 99f
/* calcul du nombre de micro secondes du Timer */
    ldr r0,iAdriTemps2
    ldr r0,[r0]
    ldr r1,iAdriTemps1
    ldr r1,[r1]
    cmp r1,r0
    subls r0,r1                 @ si T1>T1 calcul de T2 - T1
    mvnhi r0,r0                 @ sinon calcul de T2 + (2 ^32 - T1)
    addhi r0,r1
    ldr r1,iAdrsMessValeur
    bl conversion10
    ldr r0,iAdrszMessTemps
	bl affichageMess
    mov r0,r8
    mov r7,#CLOSE               @ fermeture driver
    svc 0 
    cmp r0,#0                   @ erreur
    blt 99f

    ldr r0,iAdrszMessFinOK		@ r0 ← adresse chaine 
	bl affichageMess  			@ affichage message dans console 
	mov r0,#0					@ code retour OK 
	b 100f
99:	@ affichage erreur 
	ldr r1,iAdrszMessErreur		@ r0 <- code erreur, r1 <- adresse chaine 
    bl   afficheerreur   		@ appel affichage message
	mov r0,#1					@ code erreur 
	b 100f	
100:		                    @ fin de programme standard  
	pop {fp,lr}                 @ restaur des  registres 
	mov r7, #EXIT               @ appel fonction systeme pour terminer 
    swi 0 
/************************************/
iAdrszMessDebutPgm: 	.int szMessDebutPgm
iAdrszMessErreur: 		.int szMessErreur
iAdrszMessFinOK: 		.int szMessFinOK
iAdriTemps1:				.int iTemps1
iAdriTemps2:				.int iTemps2
//iAdrsBuffer:				.int sBuffer
iAdrszNomDriver:           .int szNomDriver
iAdriSecondes:             .int iSecondes
iAdrZonesAttente:          .int ZonesAttente
iAdrZonesTemps:            .int ZonesTemps
iAdrsMessValeur:			.int sMessValeur
iAdrszMessTemps:             .int szMessTemps

/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
	