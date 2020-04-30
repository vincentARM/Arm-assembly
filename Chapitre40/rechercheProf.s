/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* programme de lancement de recherche des chemins  */
/* Recherche en profondeur        */
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
listeNoeudsNonVisites: .skip 4

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text             /* -- Code section */
.global rechercheProf,rechercheSupNoeud     
/* r0 contient l'adresse de la structure graphe */
rechercheProf:    
	push {fp,lr}    /* save des  2 registres */
	push {r1-r12} /* sauvegarde des registres */   
	@copie de la liste des noeuds
    mov r5,r0   @ save graphe
	bl nombreNoeuds
	lsl r0,#3           @ 8 octets par poste de la liste
	bl allocPlace
	cmp r0,#-1
	beq 100f
	//vidregtit debrechprof
	ldr r1,iAdrlisteNoeudsNonVisites
	str r0,[r1]
	mov r9,r0
	ldr r8,[r5,#Graphe_liste_noeuds]
	ldr r7,[r5,#Graphe_depart]
	ldr r10,[r5,#Graphe_arrivee]
	//vidregtit debrechprof0
	push {r7}   @ utilisation de la pile standard comme pile
	mov r5,#1   @ compteur des noeuds sur la pile
	mov r3,#0   @ pour stocker position precedante
	//ldr r8,[r8]
1:   @ boucle de recopie de la liste des noeuds
     @ en enlevant le noeud de départ
    ldr r0,[r8,#Liste_adresse]
	cmp r0,r7      @ noeud de départ ?
	ldreq r0,[r8,#Liste_suivant] @ on n'en tient pas compte
	moveq r8,r0
	beq 1b
	str r0,[r9,#Liste_adresse]   @ et on recopie les autres noeuds
	//vidregtit debrechprof1
	cmp r3,#0
	strne r9,[r3,#Liste_suivant]  @ maj position précedente
	mov r3,r9    @ on conserve la position courante
	mov r0,#0
	str r0,[r9,#Liste_suivant]
	ldr r0,[r8,#Liste_suivant]
	cmp r0,#0      @ fin de la liste des noeuds ?
	addne r8,#Liste_fin
	addne r9,#Liste_fin
	bne 1b
	ldr r0,iAdrlisteNoeudsNonVisites
	ldr r0,[r0]
	//vidmemtit debrechprof1 r0 8
	@ 
2:  @ boucle de traitement principale
	pop {r12}   @ devient le noeud courant
	sub r5,#1
	cmp r12,r10      @ c'est la sortie ?
	beq 10f
	//vidregtit rechprofencours
	mov r0,r12       @ pour rechercher tous les noeuds sortants
	bl listeNoeudsSortants  @ liste de tous les noeuds accessibles possibles
	mov r4,r0
	@ il faut balayer cette liste
	ldr r1,iAdrlisteNoeudsNonVisites
3:
	@ si le noeud est dans la liste des noeuds non visites 
	@ il faut l'enlever
	ldr r0,[r4]
	mov r7,r0     @ devient le noeud en cours d'examen
	bl rechercheSupNoeud
    cmp r0,#0    @ le noeud n'est pas dans la liste
	bne 4f
	@ ajouter le noeud courant dans les precurseurs 
	str r12,[r7,#Noeud_precurseur]
	@calculer la distance du depart
	ldr r6,[r12,#Noeud_distancedepart] @ distance du noeud courant
	mov r11,r1   @ save r1
	mov r0,r12
	mov r1,r7
	bl calculCout
	mov r1,r11
	add r6,r0
	str r6,[r7,#Noeud_distancedepart]
	@et stocker le noeud sur la pile 
	push {r7}
	add r5,#1   @ mise à jour du compteur de noeuds sur la pile
4:  @boucle sur autre noeud accessible
	ldr r0,[r4,#Liste_suivant]
	cmp r0,#0
	addne r4,r0
	bne 3b
	@
	@puis boucler s'il reste des noeuds à examiner sur la pile
	cmp r5,#0    @ 
	bne 2b
	@ il n'ya plus de noeuds à examiner sur la pile et on n'a toujours pas trouvé la sortie
	@ pas de chemin trouvé vers la sortie
	mov r0,#-1
	b 100f
10:
	//vidregtit finrechprof
	@ mais comme on a trouvé la sortie il faut peut être aligner la pile
	@ s'il reste des noeuds non examinés
11:
	cmp r5,#0
	popne {r7}
	subne r5,#1
	bne 11b
 
100:	
	pop {r1-r12}  /* restaur des registres */
	pop {fp,lr}
    bx lr	
iAdrlisteNoeudsNonVisites: .int listeNoeudsNonVisites



/******************************************************************/
/*     recherche d'un noeud dans liste                             */ 
/* si le noeud est trouvé il est supprimé de la liste             */
/******************************************************************/
/* r0 contient l'adresse du noeud */
/* r1 la liste des noeuds   */
rechercheSupNoeud:
	push {fp,lr}    /* save des  2 registres */
	push {r1-r5} /* sauvegarde des registres */
	ldr r2,[r1]
	//mov r3,r0
	//mov r0,r1
   //vidmemtit finrechnoeud r0 8 
	cmp r2,#0    @ table vide !!!
	moveq r0,#-1
	beq 100f
	//mov r0,r3
	mov r4,#0  @ deplacement precedent 
1:
	ldr r3,[r2,#Liste_adresse]
	//vidregtit recherchenoeud
	cmp r3,r0
	beq 2f    @ trouvé
	ldr r3,[r2,#Liste_suivant]  @ deplacement suivant
	cmp r3,#0
	movne r4,r2    @ on garde la position précedente
	movne r2,r3
	bne 1b
	mov r0,#-1    @ non trouve
	b 100f
2:
	ldr r3,[r2,#Liste_suivant]  @ deplacement suivant
    cmp r4,#0
	streq r3,[r1]   @ pour mettre à jour le début de la table
	strne r3,[r4,#Liste_suivant]  @ ou on le stocke dans le precedent

10:
	mov r0,#0   @ trouve
	
	
100:	
	pop {r1-r5}  /* restaur des registres */
	pop {fp,lr}
    bx lr	

/******************************************************************/
/*     Constantes générales                             */ 
/******************************************************************/
.include "../constantesARM.inc"
