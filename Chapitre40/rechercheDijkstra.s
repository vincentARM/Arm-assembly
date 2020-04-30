/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* programme de lancement de recherche des chemins  */
/* Algorithme de Dijkstra        */
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
.global rechercheDijkstra     
/* r0 contient l'adresse de la structure du graphe */
rechercheDijkstra:    
	push {fp,lr}    /* save des  2 registres */
	push {r1-r12} /* sauvegarde des registres */   
    mov r5,r0   @ save graphe
	//ldr r8,[r5,#Graphe_liste_noeuds]
	ldr r10,[r5,#Graphe_arrivee]
	//vidregtit debrechdijk0
	@ recherche du noeud de plus courte distance dans liste des noeuds
1:  
	ldr r8,[r5,#Graphe_liste_noeuds]
	cmp r8,#0
	moveq r0,#-1     @ sortie non trouvée
	beq 100f
	//mov r0,r8
	//vidmemtit videnoeud r0 5
    ldr r4,[r8,#Liste_adresse]      @ noeud courant

2:  
	ldr r0,[r8,#Liste_adresse]
	ldr r6,[r0,#Noeud_distancedepart]
	ldr r7,[r4,#Noeud_distancedepart]
	//vidregtit debrechdijk2
	cmp r7,r6    @ comparaison des distances au depart
	movhi r4,r0 @ si plus courte, le noeud traite devient le noeud courant
	ldr r1,[r8,#Liste_suivant] @ puis on boucle sur le noeud suivant
	cmp r1,#0                @ s'il existe
	movne r8,r1
	bne 2b    @ et boucle
	cmp r4,r10      @ le noeud trouvé est la sortie ?
	beq 10f 
	@ il faut recherche les noeuds sortants de ce noeud
	mov r0,r4
	//vidmemtit dijk_____________ r0 2
	//vidregtit debrechdijk3
	bl listearc1noeud  @ liste de tous les arcs accessibles possibles
	//vidmemtit dijk1 r0 4
	mov r7,r0
	@ il faut balayer cette liste
3:
	@ 
	ldr r1,[r7,#Arc_source]
	ldr r2,[r7,#Arc_cout]
	ldr r3,[r1,#Noeud_distancedepart]
	mov r0,r1
	//vidmemtit dijk2 r0 4
	add r2,r3
	ldr r6,[r7,#Arc_cible]
	ldr r0,[r6,#Noeud_distancedepart]
	cmp r0,r2
	bls 4f
	//vidregtit debrechdijk4
	str r2,[r6,#Noeud_distancedepart]
	str r1,[r6,#Noeud_precurseur]
4:
	ldr r0,[r7,#Arc_suivant]
	cmp r0,#0
	movne r7,r0
	bne 3b
	@ il faut enlever le noeud courant de la liste
	mov r0,r4     @ 
	//ldr r1,[r5,#Carte_liste_noeuds]
	mov r1,r5
	bl rechSuppNoeud
	b 1b
	
10:
	@mais on a supprimé des noeuds de la liste il faut donc la remettre en état
	mov r1,#0
	str r1,[r5,#Graphe_liste_noeuds]
	
	bl listeNoeuds

	//vidregtit finrechdijk

 
100:	
	pop {r1-r12}  /* restaur des registres */
	pop {fp,lr}
    bx lr	

/******************************************************************/
/*     recherche d'un noeud dans liste                             */ 
/*     si le noeud est trouvé il est invalidé en mettant 0       */
/*     dans l'adresse   A revoir car complique le balayage des noeuds */
/****************************************************************/
/* r0 contient l'adresse du noeud */
/* r1 l'adresse de la liste des noeuds   */
rechSuppNoeud:
	push {fp,lr}    /* save des  2 registres */
	push {r1-r5} /* sauvegarde des registres */
	mov r5,r1
    ldr r2,[r5,#Graphe_liste_noeuds]
	//mov r2,r1   @ a tester
	mov r4,#0  @ deplacement precedent 
1:
	ldr r3,[r2,#Liste_adresse]
	//vidregtit recherchenoeud
	cmp r3,r0
	beq 3f
2:          @ suite liste
	ldr r3,[r2,#Liste_suivant]  @ deplacement suivant
	cmp r3,#0
	movne r4,r2    @ convervation position
	movne r2,r3    @ boucle suivant
	bne 1b
	mov r0,#-1    @ non trouve
	b 100f
3: @ noeud trouvé il faut l'invalider
	ldr r0,[r2,#Liste_suivant]   @ récupération pointeur vers suivant
	cmp r4,#0
	streq r0,[r5,#Graphe_liste_noeuds]
	strne r0,[r4,#Liste_suivant]
	mov r0,r2
	
100:	
	pop {r1-r5}  /* restaur des registres */
	pop {fp,lr}
    bx lr	

/******************************************************************/
/*     Constantes générales                             */ 
/******************************************************************/
.include "../constantesARM.inc"
