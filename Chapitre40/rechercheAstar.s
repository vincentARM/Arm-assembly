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
.global rechercheAstar     
/* r0 contient l'adresse de la structure du graphe */
rechercheAstar:    
	push {fp,lr}    /* save des  2 registres */
	push {r1-r12} /* sauvegarde des registres */   
    mov r5,r0   @ save carte 
	//ldr r8,[r5,#Graphe_liste_noeuds]
	ldr r10,[r5,#Graphe_arrivee]
	@ calcul des distances estimees
	bl calculDistanceEst
	//vidregtit debutAstar
	@ recherche du noeud de plus courte distance dans liste des noeuds
1:  
	ldr r8,[r5,#Graphe_liste_noeuds]
	cmp r8,#0   @  fin de liste ?
	moveq r0,#-1     @ sortie non trouvée
	beq 100f   @ oui
	ldr r4,[r8,#Liste_adresse]   @ noeud courant
2:  
	ldr r0,[r8,#Liste_adresse]
	ldr r6,[r0,#Noeud_distancedepart]
	ldr r2,[r0,#Noeud_distanceestimee]
	//vidregtit debrechastar1
	add r6,r2
	ldr r7,[r4,#Noeud_distancedepart]
	ldr r2,[r4,#Noeud_distanceestimee]
	add r7,r2
	//vidregtit debrechastar2
	cmp r7,r6    @ comparaison des distances au depart
	movhi r4,r0 @ si plus courte, le noeud traite devient le noeud courant
	ldr r1,[r8,#Liste_suivant] @ puis on boucle sur le noeud suivant
	cmp r1,#0                @ s'il existe
	movne r8,r1
	bne 2b
	cmp r4,r10      @ c'est la sortie ?
	beq 10f 
	@ il faut recherche les noeuds sortants de ce noeud
	mov r0,r4
	bl listearc1noeud  @ liste de tous les arcs accessibles possibles
	mov r7,r0
	@ il faut balayer cette liste
3:
	@ 
	ldr r1,[r7,#Arc_source]
	ldr r2,[r7,#Arc_cout]
	ldr r3,[r1,#Noeud_distancedepart]
	mov r0,r1
	add r2,r3
	ldr r6,[r7,#Arc_cible]
	ldr r0,[r6,#Noeud_distancedepart]
	cmp r0,r2
	bls 4f
	str r2,[r6,#Noeud_distancedepart]
	str r1,[r6,#Noeud_precurseur]
4:
	ldr r0,[r7,#Arc_suivant]
	cmp r0,#0
	movne r7,r0
	bne 3b
	@ il faut enlever le noeud courant de la liste
	mov r0,r4     @ 
	mov r1,r5
	bl rechSuppNoeud
	b 1b
	
10:
	//vidregtit finrechAstar
	@mais on a supprimé des noeuds de la liste il faut donc la remettre en état
	mov r1,#0
	str r1,[r5,#Graphe_liste_noeuds]
	bl listeNoeuds
 
100:	
	pop {r1-r12}  /* restaur des registres */
	pop {fp,lr}
    bx lr	

/******************************************************************/
/*     recherche d'un noeud dans liste                            */ 
/*     si le noeud est trouvé il est invalidé en mettant 0        */
/****************************************************************/
/* r0 contient l'adresse du noeud */
/* r1 l'adresse de la liste des noeuds   */
rechSuppNoeud:
	push {fp,lr}    /* save des  2 registres */
	push {r1-r5} /* sauvegarde des registres */
	//vidregtit recherchenoeud0
	mov r5,r1
	ldr r2,[r5,#Graphe_liste_noeuds]

	mov r4,#0  @ position precedente
1:
	ldr r3,[r2,#Liste_adresse]
	cmp r3,r0
	beq 3f
	@ suite liste
	ldr r3,[r2,#Liste_suivant]  @ deplacement suivant
	cmp r3,#0
	movne r4,r2
	movne r2,r3    @ position suivante et boucle suivant
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
