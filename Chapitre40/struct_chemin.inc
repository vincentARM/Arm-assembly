/* definition des structures pour la recherche des chemins */

/* structure graphe  */
    .struct  0
Graphe_nombre_noeuds:
    .struct  Graphe_nombre_noeuds + 4 
Graphe_depart:
    .struct  Graphe_depart + 4 
Graphe_arrivee:
    .struct  Graphe_arrivee + 4 
Graphe_liste_noeuds:
    .struct  Graphe_liste_noeuds + 4 
Graphe_liste_arcs:
    .struct  Graphe_liste_arcs + 4 
Graphe_fin:

/* structure d'une tuile */
    .struct  0
Noeud_precurseur:
    .struct  Noeud_precurseur + 4 
Noeud_distancedepart:            @ entière à adapter pour d'autres configurations
    .struct  Noeud_distancedepart + 4 
Noeud_distanceestimee:           @ entière à adapter pour d'autres configurations
    .struct  Noeud_distanceestimee + 4 
Tuile_type:	 		@ type
    .struct  Tuile_type + 4 
Tuile_ligne:	 		@ 
    .struct  Tuile_ligne + 4 
Tuile_colonne:	 		@ N0 de colonne
    .struct  Tuile_colonne + 4 
Tuile_cout:	 		@ type
    .struct  Tuile_cout + 4 
Tuile_accessible:	 		@ accessible 0 = non 1 = oui
    .struct  Tuile_accessible + 4 
Tuile_fin:

/* structure liste chainée   */
    .struct  0
Liste_adresse:	 		@ adresse du noeud
    .struct  Liste_adresse + 4 
Liste_suivant:	 		@ deplacement pour le noeud suivant
    .struct  Liste_suivant + 4 
Liste_fin:

/* structure d'un arc  */
    .struct  0
Arc_source:	 		@ adresse du noeud départ arc
    .struct  Arc_source + 4 
Arc_cible:	 		@ adresse du noeud arrivée arc
    .struct  Arc_cible + 4 
Arc_cout:	 		@ cout de l'arc
    .struct  Arc_cout + 4 
Arc_suivant:
	.struct Arc_suivant + 4
Arc_fin:
