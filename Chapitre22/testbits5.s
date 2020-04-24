/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* programme pour test instructions bits */
/* Manipulation de bits      */
/*   */
.data
szMessDebutPgm: 	.asciz "Début du programme. \n"
szMessMajRecOctet: 	.asciz "Maj et récupération d'un octet. \n"
szMessMoyenne:       .asciz "Calcul moyenne \n"
szMessComptage:       .asciz "Comptage des bits à 0. \n"
szMessAjoutValMax:       .asciz "Ajout de 1 aux valeurs maxi. \n"
szMessInstMvn:       .asciz "Cas de l'instruction mvn. \n"
szMessInstAnd:       .asciz "Cas de l'instruction and. \n"
szMessInstOrr:       .asciz "Cas de l'instruction orr. \n"
szMessInstEor:       .asciz "Cas de l'instruction eor. \n"
szMessInstBic:       .asciz "Cas de l'instruction bic. \n"
szMessModifBit:      .asciz "Modification et test de bits. \n" 
szMessDeplBit:      .asciz "Déplacement de bits. \n"
szMessTesttst:      .asciz "Test de tst et tsk . \n"
/*szMessage1: .ascii "bit à zero\n "
.equ LGMESSAGE1, . -  szMessage1 
szMessage2: .ascii "bit à un\n "
.equ LGMESSAGE2, . -  szMessage2 
*/
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
	
    @ test des instructions de rotation
	ldr r0,iAdrszMessMoyenne
	bl affichageMess  /* affichage message dans console   */
    mov r1,#100
	mov r0,#40
	and r3,r1,r0
	eor r4,r1;r0
	add r3,r4
	lsr r3,#1
	
	bl affichage2
	bl affichetat
   
	
    mov r0,#0  /* code retour r0 */
	mov r7, #1 /* code pour la fonction systeme EXIT */
    swi 0      /* appel system */

//iValmax: .int 2 << 31   - 1	
//iValmaxPos: .int 2 << 30   - 1
iAdrszMessDebutPgm: .int szMessDebutPgm	
iAdrszMessMajRecOctet: .int szMessMajRecOctet
iAdrszMessMoyenne: .int szMessMoyenne
iAdrszMessComptage: .int szMessComptage

iDonal: .int 0xAEFB024F 
/******************************************************************/
/*     affichage registre en binaire                              */ 
/******************************************************************/
/* r0 contient le registre */
affichage2:
	push {r0,lr}    /* save des  2 registres */
	push {r1,r2,r3,r4,r5} /* sauvegarde des registres */
	mrs r5,cpsr  /* save du registre d'état  dans r5 */
	ldr r1,=adrzonemess
	ldr r1,[r1]
	mov r2,#0    @ compteur de position du bit lu
    mov r3,#0    @ compteur de position du caractère écrit
1:
    lsls r0,#1  
	movcc r4,#48
	movcs r4,#49
	strb r4,[r1,r3]
	add r2,r2,#1
	add r3,r3,#1
	cmp r2,#8
	addeq r3,r3,#1
	cmp r2,#16
	addeq r3,r3,#1
	cmp r2,#24
	addeq r3,r3,#1
	cmp r2,#31
	ble 1b
	
	ldr r0,=adrzonemessbin
	ldr r0,[r0]
	mov r1,#LGMESSAFFBIN
	push {r0,r1}
	bl affichage
	
100:	
	msr cpsr,r5    /*restaur registre d'état */
	pop {r1,r2,r3,r4,r5}  /* restaur des registres */
	pop {r0,lr}
    bx lr	
adrzonemess: .int sZonemess	   
adrzonemessbin: .int sMessAffBin
/***************************************************/
/*   affichage des drapeaux du registre d'état     */
/***************************************************/
affichetat:
	push {r0,r1,r2,lr}    /* save des registres */
	mrs r2,cpsr  /* save du registre d'état  dans r2 */
	ldr r1,=szLigneEtat
	movne r0,#48    @ flag zero à 0
	moveq r0,#49       @ Zero à 1
	strb r0,[r1,#11]
    @ test du flag N
	movpl r0,#48     @ Flag positif a 0
	movmi r0,#49       @ Flag negatif a 1
	strb r0,[r1,#16]		
	@ test du flag overflot
	movvc r0,#48    @ flag overflow = 0
	movvs r0,#49    @ overflow = 1
	strb r0,[r1,#26]
    @ test du flag carry 	
	movcc r0,#48    @ carry clear = 0
	movcs r0,#49   @ carry set = 1
	strb r0,[r1,#21]
    @ affichage du résultat	
	ldr r0,=szLigneEtat  @ affiche le résultat
	bl affichageMess 
 
100:   
   /* fin standard de la fonction  */
    msr cpsr,r2    /*restaur registre d'état */
	pop {r0,r1,r2,lr}    /* save des registres */
    bx lr                   /* retour de la fonction en utilisant lr  */
