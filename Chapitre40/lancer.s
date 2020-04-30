/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* programme de lancement de recherche des chemins  */
/* Création des cartes        */
/*   */
/*********************************************/
/*constantes */
/********************************************/
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessDebutPgm: 	.asciz "Début du programme. \n"
szMessFinOK: .asciz "Fin normale du programme. \n"
szMessNonTrouve:       .asciz "Chemin non trouvé \n"
szMessAlgProf:       .asciz "Algorithme Recherche en profondeur \n"
szMessAlgLarg:       .asciz "Algorithme Recherche en largeur \n"
szMessAlgBell:       .asciz "Algorithme de Bellman-Ford \n"
szMessAlgDijk:       .asciz "Algorithme de Dijkstra \n"
szMessAlgAstar:       .asciz "Algorithme A*  \n"
carteStr0:            @ pour tests  chemin simple
        .ascii ".. \n"
		.ascii " . \n"      
		.asciz " .."     @ attention dernière ligne sans \n
/* Cartes exemples . = chemin * = arbre X = eau = = pont et espace = herbe */
carteStr1: 
        .ascii "..  XX   .\n"
		.ascii "*.  *X  *.\n"      
		.ascii " .  XX ...\n"       
		.ascii " .* X *.* \n"      
		.ascii " ...=...  \n"     
		.ascii " .* X     \n"      
		.ascii " .  XXX*  \n"       
		.ascii " .  * =   \n"     
		.ascii " .... XX  \n"      
		.asciz "   *.  X* "       @ attention dernière ligne sans \n
carteStr2:
		.ascii "...*     X .*    *  \n"
		.ascii " *..*   *X .........\n"
		.ascii "   .     =   *.*  *.\n"
		.ascii "  *.   * XXXX .    .\n"
		.ascii "XXX=XX   X *XX=XXX*.\n"
		.ascii "  *.*X   =  X*.  X  \n"
		.ascii "   . X * X  X . *X* \n"
		.ascii "*  .*XX=XX *X . XXXX\n"
		.ascii " ....  .... X . X   \n"
		.asciz " . *....* . X*. = * "
.align 4
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/
.bss
.align 4    /* Pour  alignement données */
/**********************************************/
/* -- Code section                            */
/**********************************************/
.text             /* -- Code section */
.global main      /* point d'entrée du programme  */
main:             /* Programme principal */
	ldr r0,iAdrszMessDebutPgm   /* r0 <-   message debut */
	bl affichageMess  /* affichage message dans console   */
	/* Parametres de recherche */
	/* pour carte 0 mettre iAdrcarteStr0 et 2, 2 pour l'arrivée */
	/* pour carte 1 mettre iAdrcarteStr1 et 9, 9 pour l'arrivée */
	/* pour carte 2 mettre iAdrcarteStr2 et 9, 19 pour l'arrivée */
	ldr r0,iAdrcarteStr2
    mov r1,#0     @ ligne départ
	mov r2,#0     @ colonne départ
	mov r3,#9     @ ligne arrivee
	mov r4,#19     @ colonne arrivee
	bl carte
	mov r5,r0     @ adresse de la structure graphe
	vidregtit Retourcarte
	bl effacer
	ldr r0,iAdrszMessAlgProf
	bl affichageMess
	bl debutChrono
	mov r0,r5        @ adresse de la structure graphe
	bl rechercheProf
	//vidregtit RetourProf
	bl stopChrono
	cmp r0,#-1    @ chemin non trouvé
	beq 99f
	mov r0,r5
	bl reconstruireChemin
	mov r0,r5
	bl effacer
	//vidregtit suiteeffacer
	ldr r0,iAdrszMessAlgLarg
	bl affichageMess
	bl debutChrono
	mov r0,r5        @ adresse de la structure graphe
	bl rechercheLarg
	//vidregtit RetourLarg
	bl stopChrono
	cmp r0,#-1    @ chemin non trouvé
	beq 99f
	mov r0,r5
	bl reconstruireChemin
	mov r0,r5
 	bl effacer
	//vidregtit suiteeffacer
	ldr r0,iAdrszMessAlgBell
	bl affichageMess
	bl debutChrono
	mov r0,r5        @ adresse de la structure graphe
	bl rechercheBell
	//vidregtit RetourBell
	bl stopChrono
	cmp r0,#-1    @ chemin non trouvé
	beq 99f
	mov r0,r5
	bl reconstruireChemin
	mov r0,r5
	 bl effacer
	//vidregtit suiteeffacer
	ldr r0,iAdrszMessAlgDijk
	bl affichageMess
	bl debutChrono
	mov r0,r5        @ adresse de la structure graphe
	bl rechercheDijkstra
	//vidregtit RetourDijk
	bl stopChrono
	cmp r0,#-1    @ chemin non trouvé
	beq 99f
	mov r0,r5
	bl reconstruireChemin
	mov r0,r5
	bl effacer
	//vidregtit suiteeffacer
	ldr r0,iAdrszMessAlgAstar
	bl affichageMess
	bl debutChrono
	mov r0,r5        @ adresse de la structure graphe
	bl rechercheAstar
	//vidregtit RetourAstar
	bl stopChrono
	cmp r0,#-1    @ chemin non trouvé
	beq 99f
	mov r0,r5
	bl reconstruireChemin
 
	b 100f
99:
	ldr r0,iAdrszMessNonTrouve
	bl affichageMess
100:
	ldr r0,iAdrszMessFinOK   /* r0 <-   message debut */
	bl affichageMess  /* affichage message dans console   */
    mov r0,#0  /* code retour r0 */
	mov r7, #1 /* code pour la fonction systeme EXIT */
    swi 0      /* appel system */

iAdrcarteStr1: .int carteStr1
iAdrcarteStr0: .int carteStr0
iAdrcarteStr2: .int carteStr2
iValmaxPos: .int 2 << 30   - 1
iAdrszMessDebutPgm: .int szMessDebutPgm	
iAdrszMessFinOK: .int szMessFinOK
iAdrszMessNonTrouve: .int szMessNonTrouve
iAdrszMessAlgProf: .int szMessAlgProf
iAdrszMessAlgLarg: .int szMessAlgLarg
iAdrszMessAlgBell: .int szMessAlgBell
iAdrszMessAlgDijk: .int szMessAlgDijk
iAdrszMessAlgAstar: .int szMessAlgAstar
/******************************************************************/
/*     Constantes générales                             */ 
/******************************************************************/
.include "../constantesARM.inc"
