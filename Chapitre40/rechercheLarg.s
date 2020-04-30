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
.align 4
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/
.bss
.align 4    /* Pour  alignement données */
listeNoeudsNonVisites: .skip 4
listeNoeudsAvisiter: .skip 4
/**********************************************/
/* -- Code section                            */
/**********************************************/
.text             /* -- Code section */
.global rechercheLarg     
/* r0 contient l'adresse de la structure Graphe */
rechercheLarg:    
	push {fp,lr}    /* save des  2 registres */
	push {r1-r12} /* sauvegarde des registres */   
    mov r5,r0   @ save graphe
	bl nombreNoeuds
	lsl r0,#3           @ 8 octets par poste de la liste
	mov r8,r0           @ save pour allocation suivante
	bl allocPlace
	cmp r0,#-1
	beq 100f
	//vidregtit debrechlarg
	ldr r1,iAdrlisteNoeudsNonVisites
	str r0,[r1]
	mov r9,r0
	@allocation place pour listes des noeuds à visiter
	mov r0,r8           @ recup taille pour allocation suivante
	bl allocPlace
	cmp r0,#-1
	beq 100f
	//vidregtit debrechlarg01
	ldr r1,iAdrlisteNoeudsAvisiter
	str r0,[r1]
	mov r11,r0     @ pointeur debut de liste
	mov r3,r0      @ adresse tas pour stocker 
	ldr r8,[r5,#Graphe_liste_noeuds]
	ldr r7,[r5,#Graphe_depart]
	ldr r10,[r5,#Graphe_arrivee]
	//vidregtit debrechlarg0
	str r7,[r3,#Liste_adresse]
	mov r0,#0
	str r0,[r3,#Liste_suivant]
	add r3,#Liste_fin      @ adresse de stockage suivante
	mov r5,#1   @ compteur des noeuds de la liste
	mov r12,#0     @ position précédente
1:   @ boucle de recopie de la liste des noeuds
     @ en enlevant le noeud de départ
    ldr r0,[r8,#Liste_adresse]
	cmp r0,r7           @ noeud du départ ?
	ldreq r0,[r8,#Liste_suivant]
	moveq r8,r0
	beq 1b
	str r0,[r9,#Liste_adresse]
	cmp r12,#0
	strne r9,[r12,#Liste_suivant]  @ maj position précedente
	mov r12,r9    @ on conserve la position courante
	mov r0,#0
	str r0,[r9,#Liste_suivant]
	ldr r0,[r8,#Liste_suivant]
	cmp r0,#0
	addne r8,#Liste_fin
	addne r9,#Liste_fin
	bne 1b
	ldr r0,iAdrlisteNoeudsNonVisites

2:  @ debut de boucle de traitement de la liste des noeuds à visiter
	mov r0,r11
	ldr r12,[r0,#Liste_suivant]
	mov r11,r12
	ldr r12,[r0,#Liste_adresse]   @ devient le noeud courant
	sub r5,#1
	cmp r12,r10      @ c'est la sortie ?
	beq 10f
	//vidregtit rechlargencours
	mov r0,r12
	bl listeNoeudsSortants  @ liste de tous les noeuds accessibles possibles
	mov r4,r0
	//vidregtit rechlargencours2A
	@ il faut balayer cette liste
	ldr r2,iAdrlisteNoeudsNonVisites
3:  @ boucle de balayage des noeuds 
	ldr r0,[r4]
	mov r7,r0     @ devient le noeud en cours d'examen
	@Cette procedrure se trouve dans la partie rechercheProf
	@ attention r1 doit contenir le début de la liste
	mov r1,r2      @ car r1 va être ecrasé plus loin
	bl rechercheSupNoeud   @ est-t-il dans la liste des noeuds à examiner ?
    cmp r0,#0    @ le noeud n'est pas dans la liste
	bne 7f
	//vidregtit rechlargencours1A
	@ ajouter le noeud courant dans les precurseurs 
	str r12,[r7,#Noeud_precurseur]
	@calculer la distance du depart
	ldr r6,[r12,#Noeud_distancedepart] @ distance du noeud courant
	mov r0,r12
	mov r1,r7
	bl calculCout
	add r6,r0
	str r6,[r7,#Noeud_distancedepart]
	@et stocker dans la liste des noeuds à visiter
	cmp r11,#0   @le noeud courant est-il le dernier noeud ?
	moveq r11,r3 @ oui
	beq 6f
	@ ce n'était pas le dernier noeud donc il faut balayer la liste pour
	@ trouver le dernier
	mov r6,r11
5:  @ debut de boucle de recherche
	ldr r0,[r6,#Liste_suivant]
	cmp r0,#0    @ c'est le dernier ?
	movne r6,r0
	bne 5b     @ non on boucle
	str r3,[r6,#Liste_suivant]
6: @ stockage du noeud trouvé en fin de liste 
	str r7,[r3,#Liste_adresse]
	mov r0,#0
	str r0,[r3,#Liste_suivant]
	add r3,#Liste_fin
	add r5,#1           @ maj du compteur de noeud
7:  @boucle sur autre noeud accessible
	ldr r0,[r4,#Liste_suivant]
	cmp r0,#0
	addne r4,r0
	bne 3b
	@
	@puis boucler si necessaire
	cmp r5,#0    
	bne 2b
	@ pas de chemin trouvé vers la sortie
	mov r0,#-1
	b 100f
10:
	//vidregtit finrechLarg

 
100:	
	pop {r1-r12}  /* restaur des registres */
	pop {fp,lr}
    bx lr	
iAdrlisteNoeudsNonVisites: .int listeNoeudsNonVisites
iAdrlisteNoeudsAvisiter: .int listeNoeudsAvisiter

/******************************************************************/
/*     Constantes générales                             */ 
/******************************************************************/
.include "../constantesARM.inc"
