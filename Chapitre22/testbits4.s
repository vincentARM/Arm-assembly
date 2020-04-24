/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */

/* Manipulation de bits      */
.data
szMessDebutPgm: 	.asciz "Début du programme. \n"
szMessRecSigne: 	.asciz "Récupèration du signe. \n"
szMessCasZero:       .asciz "Cas du zéro. \n"
szMessValMax:       .asciz "Valeur maxi. \n"
szMessAjoutValMax:       .asciz "Ajout de 1 aux valeurs maxi. \n"
szMessInstMvn:       .asciz "Cas de l'instruction mvn. \n"
szMessInstAnd:       .asciz "Cas de l'instruction and. \n"
szMessInstOrr:       .asciz "Cas de l'instruction orr. \n"
szMessInstEor:       .asciz "Cas de l'instruction eor. \n"
szMessInstBic:       .asciz "Cas de l'instruction bic. \n"
szMessModifBit:      .asciz "Modification et test de bits. \n" 
szMessDeplBit:      .asciz "Déplacement de bits. \n"
szMessTesttst:      .asciz "Test de tst et tsk . \n"

sMessAffBin: .ascii "Valeur du registre : "
sZonemess: .space 36,' '
              .asciz "\n"
.equ LGMESSAFFBIN, . -  sMessAffBin 	
/* pour affichage du registre d'état   */
szLigneEtat: .asciz "Etats :  Z=   N=   C=   V=       \n"		
/*****************************************/
/*                                       */
/*****************************************/  
.text             /* -- Code section */
.global main      /* point d'entrée du programme  */
main:             /* Programme principal */
	ldr r0,iAdrszMessDebutPgm   /* r0 <-   message debut */
	bl affichageMess  /* affichage message dans console   */
	bl affichage2
	bl affichetat
	@ verif routines neutre
	bl affichage2
	bl affichetat
	ldr r0,iAdrszMessCasZero
	bl affichageMess  /* affichage message dans console   */
    movs r0,#0          @ cas du zero
	bl affichage2
	bl affichetat
	movs r0,#1          @ cas du un
	bl affichage2
	bl affichetat
	movs r0,#-1          @ cas du -1
	bl affichage2
	bl affichetat
	
	ldr r0,iAdrszMessValMax
	bl affichageMess  /* affichage message dans console   */
	ldr r0,iValmax    @ chargement valeur maximum
	cmp r0,#0           @ pour mettre à jour les flags apres un ldr
	bl affichage2
	bl affichetat
	ldr r0,iValmaxPos @ chargement valeur maximum positive
	cmp r0,#0    @ pour mettre à jour les flags apres un ldr
	bl affichage2
	bl affichetat
	@ ajout de 1 aux valeurs maxi
	ldr r0,iAdrszMessAjoutValMax
	bl affichageMess  /* affichage message dans console   */
	ldr r0,iValmax
	tst r0,#0         @ pour verifier l'état des flags
	bl affichetat
	adds r0,#1
	bl affichage2
	bl affichetat
	@ valeur max positive
	ldr r0,iValmaxPos
	adds r0,#1
	bl affichage2
	bl affichetat
	@ pour voir comment est le carry ici ?
	ldr r0,iValmax
	adds r0,#1
	bl affichage2
	bl affichetat
	
	@ recuperation du signe dans r0
	ldr r0,iAdrszMessRecSigne
	bl affichageMess  /* affichage message dans console   */
	mov r0,#100           @ cas du +
	asrs r0,#31             @ pour mettre le signe (0) dans r0
	bl affichage2
	bl affichetat
	mov r0,#-100          @ cas du -
	asrs r0,#31             @ pour mettre le signe (-1) dans r0
	bl affichage2
	bl affichetat
	
	@ instruction mvn
	ldr r0,iAdrszMessInstMvn
	bl affichageMess  /* affichage message dans console   */
	mvns r0,#1
	bl affichage2
	bl affichetat
	adds r0,#1         @ pour calculer un nombre negatif en complement à 2
	bl affichage2
	bl affichetat
	@ cas nombre negatif   pour le passer en positif
	mov r1,#-1
	mov r0,#100
	muls r0,r1,r0    @ pour calculer - 100 d'une autre façon 
	bl affichage2
	bl affichetat
    mvns r0,r0
    adds r0,#1	
	bl affichage2
	bl affichetat
	
	@ cas du and
	ldr r0,iAdrszMessInstAnd
	bl affichageMess  /* affichage message dans console   */
	mov r0,#15
	ands r0,#7
	bl affichage2
	bl affichetat
	@ cas du oor
	ldr r0,iAdrszMessInstOrr
	bl affichageMess  /* affichage message dans console   */
	mov r0,#15
	orrs r0,#7
	bl affichage2
	bl affichetat
	@ cas du eor
	ldr r0,iAdrszMessInstEor
	bl affichageMess  /* affichage message dans console   */
	mov r0,#15
	eors r0,#7
	bl affichage2
	bl affichetat
	@ cas du bic bit clear
	ldr r0,iAdrszMessInstBic
	bl affichageMess  /* affichage message dans console   */
	mov r0,#15
	bics r0,#3    @ raz des 2 premiers bits
	bl affichage2
	bl affichetat
	
	@ deplacement de bits	
	ldr r0,iAdrszMessDeplBit
	bl affichageMess  /* affichage message dans console   */
	mov r0,#11           @ erreur car egal à 1011
	lsl r0,#5
	bl affichage2
	lsl r0,#5
	bl affichage2
	mov r2,#8
	lsrs r0,r2
	bl affichage2
	bl affichetat
	mov r2,#3      @ deplacement de 3 à droite pour mettre un bit à 1 dans le carry
	lsrs r0,r2
	bl affichage2  @ et vérification.
	bl affichetat
	
	@ verif modif de bits
	ldr r0,iAdrszMessModifBit
	bl affichageMess  /* affichage message dans console   */
	mov r0,#30
	bl affichage2
	mov r1,#1
	orr r0,r1,lsl #10   @ change le bit 10 sans bouger les autres
	bl affichage2
	tst r0,r1,lsl #10   @ teste le bit 10 sans modifier r0
	bl affichage2
	bl affichetat
	tst r0,r1,lsl #9    @ teste le bit 9 sans modifier r0
	bl affichage2
	bl affichetat
	bic r0,r1,lsl #10   @ raz du bit 10
	tst r0,r1,lsl #10   @ teste le bit 10 sans modifier r0
	bl affichage2
	bl affichetat
	mov r1,#0b11       @ 3 en binaire
	mov r2,#16
	orr r0,r1,lsl r2   @ change les bit 16 et 17 sans bouger les autres
	tst r0,r1,lsl r2   @ teste les bit 16 et 17 sans modifier r0
	bl affichage2
	bl affichetat
	mov r1,#1
	bic r0,r1,lsl r2   @ raz du bit 16
	tst r0,r1,lsl r2   @ teste le bit 16 sans modifier r0
	bl affichage2
	bl affichetat
	
	@test de tst et teq
	ldr r0,iAdrszMessTesttst
	bl affichageMess  /* affichage message dans console   */
	mov r0,#0b1000    @ 4ieme bits à un
	tst r0,#0b1000    @ test and
	bl affichage2
	bl affichetat
	teq r0,#0b1000    @test or
	bl affichage2
	bl affichetat
	mov r0,#0b0000    @ 4ieme bits à un
	tst r0,#0b1000    @ test and
	bl affichage2
	bl affichetat
	teq r0,#0b1000    @test or
	bl affichage2
	bl affichetat

	
	
    mov r0,#0  /* code retour r0 */
	mov r7, #1 /* code pour la fonction systeme EXIT */
    swi 0      /* appel system */

iValmax: .int 2 << 31   - 1	
iValmaxPos: .int 2 << 30   - 1
iAdrszMessDebutPgm: .int szMessDebutPgm	
iAdrszMessRecSigne: .int szMessRecSigne
iAdrszMessCasZero: .int szMessCasZero
iAdrszMessValMax: .int szMessValMax
iAdrszMessAjoutValMax: .int szMessAjoutValMax
iAdrszMessInstMvn: .int szMessInstMvn
iAdrszMessInstAnd: .int szMessInstAnd
iAdrszMessInstOrr: .int szMessInstOrr
iAdrszMessInstEor: .int szMessInstEor
iAdrszMessInstBic: .int szMessInstBic
iAdrszMessModifBit: .int szMessModifBit
iAdrszMessDeplBit: .int szMessDeplBit
iAdrszMessTesttst: .int szMessTesttst
/******************************************************************/
/*     affichage registre en binaire                              */ 
/******************************************************************/
/* r0 contient le registre */
affichage2:
	push {r0,lr}    /* save des  2 registres */
	push {r1,r2,r3,r4,r5} /* sauvegarde des registres */
	mrs r5,cpsr  /* save du registre d'état  dans r5 */
	ldr r1,=adrzonemess
	ldr r1,[r1]  @ chargement adresse du message
	mov r2,#0    @ compteur du nombre de bits traités
    mov r3,#0    @ compteur de position des caractères à adfficher
1:
    lsls r0,#1  @ décalage à gauche des bits avec positionnement des flags
	movcc r4,#48 @ si le bit le plus à gauche (et passé dans le carry) = 0
	movcs r4,#49 @ s'il est egal à 1 
	strb r4,[r1,r3]  @ on stocke le caractère code 48 (0) ou 49 (1) dans le message
	add r2,r2,#1       @ passage au bit suivant
	add r3,r3,#1      @ position du caractère suivante
	cmp r2,#8         @ si 8 bits traités, on laisse un blanc 
	addeq r3,r3,#1
	cmp r2,#16         @ si 16 bits traités, on laisse un blanc 
	addeq r3,r3,#1
	cmp r2,#24         @ si 24 bits traités, on laisse un blanc 
	addeq r3,r3,#1
	cmp r2,#31         @ reste des bits ?
	ble 1b            @ oui on boucle 
	
	ldr r0,=adrzonemessbin  @ et on imprime le message
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
