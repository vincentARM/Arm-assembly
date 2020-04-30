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
/* Fichier des structures                       */
/********************************************/
.include "./struct_chemin.inc"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessPasChemin:  .asciz "Boucle négative : pas de chemin le plus court !! \n"
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/
.bss
.align 4    /* Pour  alignement données */

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text             /* -- Code section */
.global rechercheBell     
/* r0 contient l'adresse de la structure Graphe */
rechercheBell:    
	push {fp,lr}    /* save des  2 registres */
	push {r1-r12} /* sauvegarde des registres */   
    mov r5,r0   @ save graphe
	bl nombreNoeuds
	sub r3,r0,#1    @ nombre maxi de boucles

1:  @ boucle de recherche
    mov r9,#0        @ top meilleure distance
	@ balayage de la liste des arcs
	ldr r7,[r5,#Graphe_liste_arcs]
2:  @ debut de boucle du balayage
	ldr r4,[r7,#Arc_cout]
	ldr r6,[r7,#Arc_source]    @ adresse de la tuile origine de l'arc
	ldr r8,[r6,#Noeud_distancedepart]
	add r8,r4
	ldr r1,[r7,#Arc_cible]    @ adresse de la tuile cible de l'arc
	ldr r2,[r1,#Noeud_distancedepart]
	cmp r2,r8         @ compare les 2 distances 
	bls 3f
	@ on a trouvé une meilleure distance
	str r8,[r1,#Noeud_distancedepart]    @ mise à jour nouvelle distance
	str r6,[r1,#Noeud_precurseur]         @ mise à jour précurseur
	mov r9,#1     @ top meilleure distance ok
3:
	@ arc suivant
	ldr r0,[r7,#Arc_suivant]
	cmp r0,#0
	movne r7,r0
	bne 2b
	@ suite boucle
	cmp r9,#1
	bne 10f
	subs r3,#1
	bne 1b

10:
	@ fin recherche mais verification si pas de boucle negative
	@ balayage de la liste des arcs
	ldr r7,[r5,#Graphe_liste_arcs]
11:            @ debut de boucle 
	ldr r4,[r7,#Arc_cout]
	ldr r6,[r7,#Arc_source]    @ adresse de la tuile origine de l'arc
	ldr r8,[r6,#Noeud_distancedepart]
	add r8,r4
	ldr r1,[r7,#Arc_cible]    @ adresse de la tuile cible de l'arc
	ldr r2,[r1,#Noeud_distancedepart]
	cmp r2,r8         @ compare les 2 distances
	bls 12f     
	@ il y a un problème !!!
	ldr r0,iAdrszMessPasChemin
	bl affichageMess
	mov r0,#-1
	b 100f
12:
	@ arc suivant
	ldr r0,[r7,#Arc_suivant]
	cmp r0,#0
	movne r7,r0
	bne 11b
	mov r0,#0    @recherche ok
100:	
	pop {r1-r12}  /* restaur des registres */
	pop {fp,lr}
    bx lr	
iAdrszMessPasChemin: .int szMessPasChemin

/******************************************************************/
/*     Constantes générales                             */ 
/******************************************************************/
.include "../constantesARM.inc"
