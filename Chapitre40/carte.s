/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* Création des cartes        */
/*   */
/*********************************************/
/*constantes locales                         */
/********************************************/
.equ HERBE,  1
.equ ARBRE,  2
.equ PONT,  3
.equ EAU,   4
.equ CHEMIN, 5
.equ COUTMINI, 1
.equ COUTMOYEN, 2
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
szMessDebutPgm: 	.asciz "Début du programme. \n"
szMessErrType:       .asciz "Type tuile inconnu. \n"

/* pour test affichage des données d'une tuile */
sMessAffTuile:  .ascii  "Table ligne :"
sLigneTuile:     .fill 11,1,' '
                    .ascii  " colonne : "
sColonneTuile:    .fill 11,1,' '
                    .ascii "\n Adresse :"
sAdresseTuile:     .fill 10,1,' '
                     .ascii " type: "
sTypeTuile:          .fill 11,1,' '
                     .ascii " ligne: "
sLigneIntTuile:          .fill 11,1,' '
                     .ascii " colonne: "
sColonneIntTuile:          .fill 11,1,' '
                     .ascii "\n cout: "
sLigneCout:          .fill 11,1,' '
                      .asciz "\n"
/*  message pour le chemin trouvé */
sMessDistance: .ascii "Chemin trouvé de longueur : "
sDistanceChemin:          .fill 11,1,' '
                     .asciz " \n"
sMessChemin:  .ascii  " ligne : " 
sLigneChemin:          .fill 11,1,' '
                 .ascii " colonne : "
sColonneChemin:          .fill 11,1,' '
                 .ascii " distance : "
sDistanceDepartChemin:          .fill 11,1,' '
				.asciz " \n"

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/
.bss
.align 4    /* Pour  alignement données */
iNbLignes: 			.skip 4
iNbColonnes:   		.skip 4
ptCarteTuiles: 		.skip 4  
stGraphe:  			.skip Graphe_fin           @ reserve place pour la structure graphe
NoeudsSortants:  	.skip Liste_fin * 4     @ il n'ya que 4 noeuds adjacents à un noeud
ArcsSortants:    	.skip Arc_fin * 4    @ et que 4 arcs
/**********************************************/
/* -- Code section                            */
/**********************************************/
.text             /* -- Code section */
.global carte,nombreNoeuds,listeNoeudsSortants,reconstruireChemin,effacer     /* routines programmes  */
.global listearc1noeud,calculDistanceEst,listeNoeuds,calculCout
/******************************************/
/* creation des cartes */
@r0 adresse chaine de caractères description de la carte
@r1 ligne de départ
@r2 colonne de départ
@r3 ligne arrivée
@r4 colonne arrivée
carte:          
	push {fp,lr}    /* save des  2 registres */
	push {r1-r10,r12} /* sauvegarde des registres */
	mov fp,sp    /* fp <- adresse pile */
	/* eclatement des données en lignes */
	ldr r9,iAdrstGraphe
	mov r1,#'\n'
	bl eclatechaine 
	mov r8,r0     @ adresse table retour eclatement
	ldr r5,[r0]     @ nombre de lignes
	ldr r9,iAdriNbLignes
	str r5,[r9]
	add r0,#4
	ldr r0,[r0]   @ recup ligne
	bl longueurchaine
	ldr r9,iAdriNbColonnes
	str r0,[r9]
	mov r6,r0   @ nombre de colonnes
	mul r0,r5,r6
	ldr r9,iAdrstGraphe
	str r0,[r9,#Graphe_nombre_noeuds]  @ maj du nombre total de noeuds 
	@ il faut aussi reserver la place pour la structure tuile
	mov r7,#Tuile_fin
	mul r0,r7,r0         @ nombre de tuiles (noeuds) * par la taille d'une tuile
	bl allocPlace
	cmp r0,#-1
	beq 100f
	ldr r9,iAdrptCarteTuiles
	str r0,[r9]    @ debut table tuiles
	mov r10,r0     @   r10 servira de pointeur pour le stockage des tuiles
	
	/* boucle de création des tuiles */
	mov r1,#0     @ indice ligne
	add r8,#4     @ adresse 1ere ligne
	ldr r3,iAdriNbColonnes
	ldr r3,[r3]

1:    @debut boucle ligne
	ldr r4,[r8,r1,lsl #2]  @adresse de chaque ligne
	mov r2,#0     @ indice colonne
2:   @ debut boucle colonne
    ldrb r0,[r4,r2]    @ extraction du caractère de la colonne
	bl creationTuile
	cmp r0,#0
	beq 100f    @ erreur
	@suite boucle
	add r2,#1
	cmp r2,r6
	blt 2b
	add r1,#1
	cmp r1,r5
	blt 1b
	
	@ suite carte
	@ calcul de l'adresse du noeud de depart
	ldr r1,[fp]    @recup noeud depart sur la pile
	ldr r2,[fp,#+4] 
	mov r3,#Tuile_fin
	mul r7,r6,r3  @ taille d'une ligne
	mul r7,r1         @ calcul deplacement ligne
	mul r12,r3,r2     @ calcul deplacement colonne
	add r7,r12 
	add r0,r7,r10
	ldr r9,iAdrstGraphe   @ maj départ
	str r0,[r9,#Graphe_depart]
		@ calcul de l'adresse du noeud d'arrivee
	ldr r1,[fp,#+8]    @recup noeud arrivee sur la pile
	ldr r2,[fp,#+12] 
	//vidregtit recupreg2
	mul r7,r6,r3    @ taille d'une ligne
	mul r7,r1       @ deplacement ligne
	mul r12,r3,r2    @ calcul deplacement colonne
	add r7,r12 
	add r0,r7,r10
	str r0,[r9,#Graphe_arrivee]
    @ création de la liste des noeuds
	bl listeNoeuds
	//vidmemtit listeN r0 10
	@ création de la liste des arcs
	bl listeArcs


	/* pour test affichage d'une tuile quelconque */
	//mov r1,#1
	//mov r2,#2
	//bl afficheTuile
	
	/* fin préparation carte */
	ldr r0,iAdrstGraphe         @ retourne l'adresse de la structure graphe
100:
	pop {r1-r10,r12}  /* restaur des registres */
	pop {fp,lr}
    bx lr	

iAdrstGraphe: .int stGraphe
iAdrptCarteTuiles: .int ptCarteTuiles
iAdriNbLignes: .int iNbLignes
iAdriNbColonnes: .int iNbColonnes
iValmaxPos: .int 2 << 30   - 1
iAdrszMessDebutPgm: .int szMessDebutPgm	
/******************************************************************/
/*     création d'une tuile                              */ 
/******************************************************************/
/* r0 contient le caractère extrait de la définition */
/* r1 contient le N° de ligne */
/* r2 contient le N° de colonne */
/* r3 contient le nombre de colonnes par ligne */
/* r10 adresse de la table des tuiles */
/* r0 retourne un pointeur sur la tuile */
creationTuile:
	push {fp,lr}    /* save des  2 registres */
	push {r1-r5} /* sauvegarde des registres */
	@ calcul de la position de stockage de la tuile dans la table */
	mov r5,#Tuile_fin
	mul r4,r5,r3    @ taille d'une ligne
	mul r4,r1       @ deplacement ligne
	mul r3,r5,r2    @ calcul deplacement colonne
	add r4,r3
	add r4,r10      @ adresse de stockage de la tuile
	@ type de tuiles
	cmp r0,#' '
	beq herbe
	cmp r0,#'.'
	beq chemin
	cmp r0,#'*'
	beq arbre
	cmp r0,#'='
	beq pont
	cmp r0,#'X'
	beq eau
	@ erreur du type de tuile
	ldr r0,iAdrszMessErrType
	bl affichageMess
	mov r0,#0
	b 100f
herbe:
	mov r3,#HERBE
	str r3,[r4,#Tuile_type]
	mov r3,#COUTMOYEN
	str r3,[r4,#Tuile_cout]
	mov r3,#1
	str r3,[r4,#Tuile_accessible]
	b 1f
chemin:
	mov r3,#CHEMIN
	str r3,[r4,#Tuile_type]
	mov r3,#COUTMINI
	str r3,[r4,#Tuile_cout]
	mov r3,#1
	str r3,[r4,#Tuile_accessible]
	b 1f
arbre:
	mov r3,#ARBRE
	str r3,[r4,#Tuile_type]
	ldr r3,iValmaxPos
	str r3,[r4,#Tuile_cout]
	mov r3,#0
	str r3,[r4,#Tuile_accessible]
	b 1f
pont:
	mov r3,#PONT
	str r3,[r4,#Tuile_type]
	mov r3,#COUTMOYEN
	str r3,[r4,#Tuile_cout]
	mov r3,#1
	str r3,[r4,#Tuile_accessible]
	b 1f
eau:
	mov r3,#EAU
	str r3,[r4,#Tuile_type]
	ldr r3,iValmaxPos
	str r3,[r4,#Tuile_cout]
	mov r3,#0
	str r3,[r4,#Tuile_accessible]
	b 1f
1:
	str r1,[r4,#Tuile_ligne]
	str r2,[r4,#Tuile_colonne]
	mov r0,r4     @ retourne adresse tuile
100:	
	pop {r1-r5}  /* restaur des registres */
	pop {fp,lr}
    bx lr	
iAdrszMessErrType: .int szMessErrType
/******************************************************************/
/*     calcul du cout                                             */ 
/******************************************************************/
/* r0 tuile origine  */
/* r1 tuile destination */
@ ici c'est simplement le cout de la tuile de destination
calculCout:
    ldr r0,[r1,#Tuile_cout]
    bx lr	
/******************************************************************/
/*     affichage d'une tuile                              */ 
/******************************************************************/
/* r0 non utilisé  */
/* r1 N° de ligne */
/* r2 N° de colonne */
afficheTuile:
	push {fp,lr}    /* save des  2 registres */
	push {r0-r9} /* sauvegarde des registres */
	ldr r7,iAdrptCarteTuiles
	ldr r7,[r7]
	ldr r6,iAdriNbColonnes
	ldr r6,[r6]
	mov r3,#Tuile_fin
	mul r4,r6,r3    @ taille d'une ligne
	mul r8,r4,r1   @ deplacement ligne
	mul r4,r2,r3           @ deplacement colonne
	add r8,r4
	add r9,r7,r8
	mov r6,r2
	mov r5,r1
	ldr r0,iAdrsAdresseTuile
	mov r1,r9
	mov r2,#16
	push {r0,r1,r2}	
    bl conversion
	
	mov r0,r5
	ldr r1,iAdrsLigneTuile
	bl conversion10
	mov r0,r6
	ldr r1,iAdrsColonneTuile
	bl conversion10

	ldr r0,[r9,#Tuile_type]
	ldr r1,iAdrsTypeTuile
	bl conversion10
	ldr r0,[r9,#Tuile_ligne]
	ldr r1,iAdrsLigneIntTuile
	bl conversion10
	ldr r0,[r9,#Tuile_colonne]
	ldr r1,iAdrsColonneIntTuile
	bl conversion10
	ldr r0,[r9,#Tuile_cout]
	ldr r1,iAdrsLigneCout
	bl conversion10
	
	@affichage ligne
	ldr r0,iAdrsMessAffTuile
	bl affichageMess
100:	
	pop {r0-r9}  /* restaur des registres */
	pop {fp,lr}
    bx lr	
iAdrsLigneTuile: .int sLigneTuile
iAdrsColonneTuile: .int sColonneTuile
iAdrsTypeTuile: .int sTypeTuile
iAdrsMessAffTuile: .int sMessAffTuile
iAdrsLigneIntTuile: .int sLigneIntTuile
iAdrsColonneIntTuile: .int sColonneIntTuile
iAdrsAdresseTuile: .int sAdresseTuile
iAdrsLigneCout:  .int sLigneCout

/******************************************************************/
/*     liste des noeuds d'une carte                             */ 
/******************************************************************/
/* r0 retourne l'adresse contenant l'adresse du debut de liste  */

listeNoeuds:
	push {fp,lr}    /* save des  2 registres */
	push {r1-r10} /* sauvegarde des registres */
	ldr r3,iAdrstGraphe
	ldr r4,[r3,#Graphe_liste_noeuds]
	cmp r4,#0      @ liste déjà creee
	movne r0,r4
	bne 100f
	ldr r5,iAdriNbLignes
	ldr r5,[r5]
	ldr r6,iAdriNbColonnes
	ldr r6,[r6]
	mov r1,#Liste_fin
	mul r0,r6,r1           @ taille d'une ligne de noeud
	mul r0,r5              @ taille totale
	bl allocPlace
	cmp r0,#-1
	beq 100f
	mov r10,r0
	str r10,[r3,#Graphe_liste_noeuds]  @ maj debut liste
	ldr r7,iAdrptCarteTuiles
	ldr r7,[r7]
	mov r1,#0    @ indice lignes
	mov r9,#0
1:
	mov r2,#0    @ indice colonnes
2:
    @ calcul position table départ
	mov r0,#Tuile_fin
	mul r8,r6,r0           @ longueur poste 
	mul r4,r8,r1        @ deplacement ligne
	mul r8,r2,r0    @ deplacement colonne
	add r8,r4
	add r0,r7,r8
	str r0,[r10,#Liste_adresse]
	cmp r9,#0
	strne r10,[r9,#Liste_suivant]   @ maj poste precedent
	mov r0,#0
	str r0,[r10,#Liste_suivant]
	mov r9,r10  @ conservation adresse
	add r10,#Liste_fin    @ position suivante dans la liste
	add r2,#1
	cmp r2,r6    @ plus de colonnes ?
	blt 2b
	add r1,#1
	cmp r1,r5    @ plus de lignes ?
	blt 1b
	ldr r0,[r3,#Graphe_liste_noeuds]  @ retour debut liste
	
100:	
	pop {r1-r10}  /* restaur des registres */
	pop {fp,lr}
    bx lr	
	
/******************************************************************/
/*     liste des noeuds adjacents à un noeud                      */ 
/******************************************************************/
/* r0 contient le noeud source   */
/* r0 retourne l'adresse contenant l'adresse du debut de liste  */

listeNoeudsSortants:
	push {fp,lr}    /* save des  2 registres */
	push {r1-r12} /* sauvegarde des registres */
	ldr r7,iAdrptCarteTuiles
	ldr r7,[r7]
	ldr r5,iAdriNbLignes
	ldr r5,[r5]
	ldr r6,iAdriNbColonnes
	ldr r6,[r6]
	ldr r10,iAdrNoeudsSortants
	mov r12,#0
	str r12,[r10,#Liste_adresse]   @ raz debut liste
	ldr r1,[r0,#Tuile_ligne]
	ldr r2,[r0,#Tuile_colonne]
	@ test de la tuile de la colonne inférieure 
	subs r2,#1
	bmi 1f    @ negatif
	mov r0,#Tuile_fin
	mul r4,r6,r0    @ taille d'une ligne
	mul r8,r4,r1   @ deplacement ligne
	mul r4,r2,r0           @ deplacement colonne
	add r8,r4
	add r9,r7,r8          @ adresse de la tuile
	ldr r0,[r9,#Tuile_accessible]
	cmp r0,#1
	bne 1f    @ la tuile n'est pas accessible
	ldr r10,iAdrNoeudsSortants
	str r9,[r10,#Liste_adresse]
	mov r9,#0
	str r9,[r10,#Liste_suivant]
	mov r12,r10   @ conservation position actuelle
	add r10,#Liste_fin
1:  @ test de la tuile de la colonne supèrieure
    add r2,#2     @ car on a enleve 1 
    cmp r2,r6
    bge 2f
	mov r0,#Tuile_fin
	mul r4,r6,r0    @ taille d'une ligne
	mul r8,r4,r1   @ deplacement ligne
	mul r4,r2,r0          @ deplacement colonne
	add r8,r4
	add r9,r7,r8
	ldr r0,[r9,#Tuile_accessible]
	cmp r0,#1
	bne 2f   @ la tuile n'est pas accessible
	//vidregtit noeudsortant2
	cmp r12,#0
	movne r0,#Liste_fin
	strne r0,[r12,#Liste_suivant]
	str r9,[r10,#Liste_adresse]
	mov r9,#0
	str r9,[r10,#Liste_suivant]
	mov r12,r10   @ conservation position actuelle
	add r10,#Liste_fin
2:
    sub r2,#1     @ pour revenir à la valeur de départ
	subs r1,#1
    bmi 3f
	mov r0,#Tuile_fin
	mul r4,r6,r0    @ taille d'une ligne
	mul r8,r4,r1   @ deplacement ligne
	mul r4,r2,r0           @ deplacement colonne
	add r8,r4
	add r9,r7,r8
	ldr r0,[r9,#Tuile_accessible]
	cmp r0,#1
	bne 3f
	//vidregtit noeudsortant3
	cmp r12,#0
	movne r0,#Liste_fin
	strne r0,[r12,#Liste_suivant]
	str r9,[r10,#Liste_adresse]
	mov r9,#0
	str r9,[r10,#Liste_suivant]
	mov r12,r10   @ conservation position actuelle
	add r10,#Liste_fin
3:
    add r1,#2     @ car on a enleve 1 
    cmp r1,r5
    bge 4f
	mov r0,#Tuile_fin
	mul r4,r6,r0    @ taille d'une ligne
	mul r8,r4,r1   @ deplacement ligne
	mul r4,r2,r0           @ deplacement colonne
	add r8,r4
	add r9,r7,r8
	ldr r0,[r9,#Tuile_accessible]
	cmp r0,#1
	bne 4f
	//vidregtit noeudsortant4
	cmp r12,#0
	movne r0,#Liste_fin
	strne r0,[r12,#Liste_suivant]
	str r9,[r10,#Liste_adresse]
	mov r9,#0
	str r9,[r10,#Liste_suivant]
	mov r12,r10   @ conservation position actuelle
	add r10,#Liste_fin

4:
	ldr r0,iAdrNoeudsSortants
100:	
	pop {r1-r12}  /* restaur des registres */
	pop {fp,lr}
    bx lr	
iAdrNoeudsSortants: .int NoeudsSortants
/******************************************************************/
/*     liste des arcs a partir d'un noeud                                     */ 
/******************************************************************/
/* r0 contient l'adresse de la tuile  */

listearc1noeud:
	push {fp,lr}    /* save des  2 registres */
	push {r1-r12} /* sauvegarde des registres */
	ldr r1,[r0,#Tuile_ligne]
	ldr r2,[r0,#Tuile_colonne]
	ldr r7,iAdrptCarteTuiles
	ldr r7,[r7]
	ldr r5,iAdriNbLignes
	ldr r5,[r5]
	ldr r6,iAdriNbColonnes
	ldr r6,[r6]
	
	mov r3,r0   @ save noeud départ
	ldr r10,iAdrArcsSortants
	mov r12,#0
	@ test des cases adjacentes
	subs r2,#1
	bmi 3f
	mov r0,#Tuile_fin
	mul r4,r6,r0    @ taille d'une ligne
	mul r8,r4,r1   @ deplacement ligne
	mul r4,r2,r0           @ deplacement colonne
	add r8,r4
	add r9,r7,r8              @ tuile fin arc
	ldr r0,[r9,#Tuile_accessible]
	cmp r0,#1
	bne 3f
	cmp r12,#0
	strne r10,[r12,#Arc_suivant]
	str r3,[r10,#Arc_source]
	str r9,[r10,#Arc_cible]
	//vidregtit arcs1
	ldr r9,[r9,#Tuile_cout]
	str r9,[r10,#Arc_cout]
	mov r9,#0
	str r9,[r10,#Arc_suivant]
	mov r12,r10   @ conservation position actuelle
	add r10,#Arc_fin
3:
	add r2,#2
	cmp r2,r6
	bge 4f
	mov r0,#Tuile_fin
	mul r4,r6,r0    @ taille d'une ligne
	mul r8,r4,r1   @ deplacement ligne
	mul r4,r2,r0           @ deplacement colonne
	add r8,r4
	add r9,r7,r8              @ tuile fin arc
	ldr r0,[r9,#Tuile_accessible]
	cmp r0,#1
	bne 4f
	cmp r12,#0
	strne r10,[r12,#Arc_suivant]
	str r3,[r10,#Arc_source]
	str r9,[r10,#Arc_cible]
	//vidregtit arcs2
	ldr r9,[r9,#Tuile_cout]
	str r9,[r10,#Arc_cout]
	mov r9,#0
	str r9,[r10,#Arc_suivant]
	mov r12,r10   @ conservation position actuelle
	add r10,#Arc_fin
	
4:
	sub r2,#1
	subs r1,#1
	bmi 5f
	mov r0,#Tuile_fin
	mul r4,r6,r0    @ taille d'une ligne
	mul r8,r4,r1   @ deplacement ligne
	mul r4,r2,r0           @ deplacement colonne
	add r8,r4
	add r9,r7,r8              @ tuile fin arc
	ldr r0,[r9,#Tuile_accessible]
	cmp r0,#1
	bne 5f
	cmp r12,#0
	strne r10,[r12,#Arc_suivant]
	str r3,[r10,#Arc_source]
	str r9,[r10,#Arc_cible]
	//vidregtit arcs3
	ldr r9,[r9,#Tuile_cout]
	str r9,[r10,#Arc_cout]
	mov r9,#0
	str r9,[r10,#Arc_suivant]
	mov r12,r10   @ conservation position actuelle
	add r10,#Arc_fin
	
5:
	add r1,#2
	cmp r1,r5
	bge 6f
	mov r0,#Tuile_fin
	mul r4,r6,r0    @ taille d'une ligne
	mul r8,r4,r1   @ deplacement ligne
	mul r4,r2,r0           @ deplacement colonne
	add r8,r4
	add r9,r7,r8              @ tuile fin arc
	ldr r0,[r9,#Tuile_accessible]
	cmp r0,#1
	bne 6f
	cmp r12,#0
	strne r10,[r12,#Arc_suivant]
	str r3,[r10,#Arc_source]
	str r9,[r10,#Arc_cible]
	//vidregtit arcs4
	ldr r9,[r9,#Tuile_cout]
	str r9,[r10,#Arc_cout]
	mov r9,#0
	str r9,[r10,#Arc_suivant]
	mov r12,r10   @ conservation position actuelle
	add r10,#Arc_fin
6:
	ldr r0,iAdrArcsSortants
	
100:	
	pop {r1-r12}  /* restaur des registres */
	pop {fp,lr}
    bx lr	
iAdrArcsSortants: .int ArcsSortants
/******************************************************************/
/*     liste de tous les arcs                        */ 
/******************************************************************/
/* r0 retourne l'adresse de la liste  */

listeArcs:
	push {fp,lr}    /* save des  2 registres */
	push {r1-r12} /* sauvegarde des registres */
	ldr r3,iAdrstGraphe
	ldr r7,iAdrptCarteTuiles
	ldr r7,[r7]
	ldr r5,iAdriNbLignes
	ldr r5,[r5]
	ldr r6,iAdriNbColonnes
	ldr r6,[r6]
	ldr r3,iAdrstGraphe
	ldr r10,[r3,#Graphe_liste_arcs]
	cmp r10,#0   @ liste déjà créee ?
	movne r0,r10
	bne 100f
	mov r0,#Arc_fin
	mul r1,r6,r5           @ nombre de tuiles
	lsl r1,#2           @ 4 arcs par tuile : c'est majoré !!!!
	mul r0,r1,r0       @ * par la taille d'un arc
	bl allocPlace
	cmp r0,#-1
	beq 100f
	mov r10,r0
	str r0,[r3,#Graphe_liste_arcs]  @ maj debut liste
	mov r12,#0
	//vidregtit debutarc
	mov r1,#0
1:
	mov r2,#0
2:
	mov r0,#Tuile_fin
	mul r4,r6,r0    @ taille d'une ligne
	mul r8,r4,r1   @ deplacement ligne
	mul r4,r2,r0           @ deplacement colonne
	add r8,r4
	add r3,r7,r8              @ tuile debut arc
	ldr r0,[r3,#Tuile_accessible]    
	cmp r0,#1
	bne 7f
	@ test des cases adjacentes si la tuile est accessible
	subs r2,#1
	bmi 3f
		mov r0,#Tuile_fin
	mul r4,r6,r0    @ taille d'une ligne
	mul r8,r4,r1   @ deplacement ligne
	mul r4,r2,r0           @ deplacement colonne
	add r8,r4
	add r9,r7,r8              @ tuile fin arc
	ldr r0,[r9,#Tuile_accessible]
	cmp r0,#1
	bne 3f
	cmp r12,#0
	strne r10,[r12,#Arc_suivant]
	str r3,[r10,#Arc_source]
	str r9,[r10,#Arc_cible]
	//vidregtit arcs1
	ldr r9,[r9,#Tuile_cout]
	str r9,[r10,#Arc_cout]
	mov r9,#0
	str r9,[r10,#Arc_suivant]
	mov r12,r10   @ conservation position actuelle
	add r10,#Arc_fin
3:
	add r2,#2
	cmp r2,r6
	bge 4f
	mov r0,#Tuile_fin
	mul r4,r6,r0    @ taille d'une ligne
	mul r8,r4,r1   @ deplacement ligne
	mul r4,r2,r0           @ deplacement colonne
	add r8,r4
	add r9,r7,r8              @ tuile fin arc
	ldr r0,[r9,#Tuile_accessible]
	cmp r0,#1
	bne 4f
	cmp r12,#0
	strne r10,[r12,#Arc_suivant]
	str r3,[r10,#Arc_source]
	str r9,[r10,#Arc_cible]
	//vidregtit arcs2
	ldr r9,[r9,#Tuile_cout]
	str r9,[r10,#Arc_cout]
	mov r9,#0
	str r9,[r10,#Arc_suivant]
	mov r12,r10   @ conservation position actuelle
	add r10,#Arc_fin
	
4:
	sub r2,#1
	subs r1,#1
	bmi 5f
	mov r0,#Tuile_fin
	mul r4,r6,r0    @ taille d'une ligne
	mul r8,r4,r1   @ deplacement ligne
	mul r4,r2,r0           @ deplacement colonne
	add r8,r4
	add r9,r7,r8              @ tuile fin arc
	ldr r0,[r9,#Tuile_accessible]
	cmp r0,#1
	bne 5f
	cmp r12,#0
	strne r10,[r12,#Arc_suivant]
	str r3,[r10,#Arc_source]
	str r9,[r10,#Arc_cible]
	//vidregtit arcs3
	ldr r9,[r9,#Tuile_cout]
	str r9,[r10,#Arc_cout]
	mov r9,#0
	str r9,[r10,#Arc_suivant]
	mov r12,r10   @ conservation position actuelle
	add r10,#Arc_fin
	
5:
	add r1,#2
	cmp r1,r5
	bge 6f
	mov r0,#Tuile_fin
	mul r4,r6,r0    @ taille d'une ligne
	mul r8,r4,r1   @ deplacement ligne
	mul r4,r2,r0           @ deplacement colonne
	add r8,r4
	add r9,r7,r8              @ tuile fin arc
	ldr r0,[r9,#Tuile_accessible]
	cmp r0,#1
	bne 6f
	cmp r12,#0
	strne r10,[r12,#Arc_suivant]
	str r3,[r10,#Arc_source]
	str r9,[r10,#Arc_cible]
	//vidregtit arcs4
	ldr r9,[r9,#Tuile_cout]
	str r9,[r10,#Arc_cout]
	mov r9,#0
	str r9,[r10,#Arc_suivant]
	mov r12,r10   @ conservation position actuelle
	add r10,#Arc_fin
6:
	sub r1,#1    @ pour remise à niveau 
7:
	//vidregtit boucle
	add r2,#1
	cmp r2,r6    @ 
	blt 2b
	add r1,#1
	cmp r1,r5
	blt 1b

	ldr r3,iAdrstGraphe
	ldr r0,[r3,#Graphe_liste_arcs]  @ retour debut liste
	
	
100:	
	pop {r1-r12}  /* restaur des registres */
	pop {fp,lr}
    bx lr	
/******************************************************************/
/*     reconstruction du chemin trouvé                             */ 
/******************************************************************/
/* r0 contient l'adresse de la structure graphe  */
reconstruireChemin:
	push {fp,lr}
	push {r1,r5}
	ldr r4,[r0,#Graphe_arrivee]   @ tuile d'arrivée
	@TODO recherche dans la table des noeuds la tuile d'arrivée
	ldr r0,[r4,#Noeud_distancedepart]  @ préparation message de la distance trouvée
	ldr r1,iAdrsDistanceChemin
	bl conversion10
	ldr r0,iAdrsMessDistance
	bl affichageMess

1:
	ldr r0,[r4,#Tuile_ligne]
	ldr r1,iAdrsLigneChemin
	bl conversion10
	ldr r0,[r4,#Tuile_colonne]
	ldr r1,iAdrsColonneChemin
	bl conversion10
	ldr r0,[r4,#Noeud_distancedepart]
	ldr r1,iAdrsDistanceDepartChemin
	bl conversion10
	@affichage ligne
	ldr r0,iAdrsMessChemin
	bl affichageMess
	ldr r1,[r4,#Noeud_precurseur]
	cmp r1,#0
	beq 100f
	mov r4,r1
	b 1b

100:
	pop {r1,r5}
	pop {fp,lr}
    bx lr	
iAdrsLigneChemin: .int sLigneChemin
iAdrsColonneChemin: .int sColonneChemin
iAdrsMessChemin: .int sMessChemin
iAdrsMessDistance: .int sMessDistance
iAdrsDistanceChemin: .int sDistanceChemin
iAdrsDistanceDepartChemin: .int sDistanceDepartChemin
/******************************************************************/
/*     nombre de noeuds de la carte                               */ 
/******************************************************************/
/* aucun parametres */
nombreNoeuds:
	push {r1,r2}
	ldr r1,iAdriNbLignes
	ldr r1,[r1]
	ldr r2,iAdriNbColonnes
	ldr r2,[r2]
	mul r0,r1,r2
	pop {r1,r2}
    bx lr	
/******************************************************************/
/*     effacement des nonnées necessaires aux recherches          */ 
/******************************************************************/
/* r0 contient l'adresse de la structure du graphe  */
effacer:
	push {fp,lr}    /* save des  2 registres */
	push {r0-r9} /* sauvegarde des registres */
	mov r4,r0   @ save adresse structure graphe
	mov r1,#0
	@ effacement des données de chaque tuile
	ldr r5,iAdriNbLignes
	ldr r5,[r5]
	ldr r6,iAdriNbColonnes
	ldr r6,[r6]

	mov r1,#0    @ indice lignes
	ldr r7,iAdrptCarteTuiles
	ldr r7,[r7]
	mov r3,#Tuile_fin
	mov r9,#0
1:              @ debut boucle des lignes
	mov r2,#0    @ indice colonnes
2:              @ debut boucle des colonnes
    @ calcul position table 
	mul r8,r6,r3           @ longueur poste 
	mul r0,r8,r1        @ deplacement ligne
	mul r8,r2,r3   @ deplacement colonne
	add r8,r0
	add r9,r7,r8
    mov r0,#0
	str r0,[r9,#Noeud_precurseur]
	ldr r0,iValmaxPos
	str r0,[r9,#Noeud_distancedepart]
	add r2,#1
	cmp r2,r6   
	blt 2b
	add r1,#1
	cmp r1,r5
	blt 1b
	@ maj noeud initial
	ldr r0,[r4,#Graphe_depart]
	ldr r1,[r0,#Tuile_cout]
	str r1,[r0,#Noeud_distancedepart]
	
100:	
	pop {r0-r9}  /* restaur des registres */
	pop {fp,lr}
    bx lr	
/******************************************************************/
/*     calcul de la distance estimée à l'arrivée pour chaque case */ 
/******************************************************************/
calculDistanceEst:
	push {fp,lr}    /* save des  2 registres */
	push {r0-r12} /* sauvegarde des registres */
	ldr r4,iAdrstGraphe   @ adresse structure Graphe
	ldr r10,[r4,#Graphe_arrivee]
	ldr r12,[r10,#Tuile_ligne]
	ldr r10,[r10,#Tuile_colonne]
	mov r1,#0
	@ calcul distance de chaque tuile
	ldr r5,iAdriNbLignes
	ldr r5,[r5]
	ldr r6,iAdriNbColonnes
	ldr r6,[r6]
	mov r1,#0    @ indice lignes
	ldr r7,iAdrptCarteTuiles
	ldr r7,[r7]
	mov r9,#0
1:              @ debut boucle des lignes
	mov r2,#0    @ indice colonnes
2:              @ debut boucle des colonnes
    @ calcul position table 
	mov r0,#Tuile_fin
	mul r8,r6,r0          @ longueur poste 
	mul r3,r8,r1        @ deplacement ligne
	mul r8,r2,r0    @ deplacement colonne
	add r8,r3
	add r9,r7,r8      @ adresse de la tuile
	cmp r12,r1
	subgt r8,r12,r1
	suble r8,r1,r12
	cmp r10,r2
	subgt r3,r10,r2
	suble r3,r2,r10
	add r3,r8
	str r3,[r9,#Noeud_distanceestimee]
	add r2,#1
	cmp r2,r6   
	blt 2b
	add r1,#1
	cmp r1,r5
	blt 1b

	
100:	
	pop {r0-r12}  /* restaur des registres */
	pop {fp,lr}
    bx lr	
/******************************************************************/
/*     Constantes générales                             */ 
/******************************************************************/
.include "../constantesARM.inc"
