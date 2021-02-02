/*******************************************/
/* Structures                               */
/********************************************/
/* Structure aquarium  */
    .struct  0
aqua_nbPoissons:                     // 
    .struct  aqua_nbPoissons + 4
aqua_nbAlgues:                     // 
    .struct  aqua_nbAlgues + 4
aqua_listePoissons:                     // 
    .struct  aqua_listePoissons + 4
aqua_listeAlgues:                     // 
    .struct  aqua_listeAlgues + 4
aqua_nombreTour:                     // 
    .struct  aqua_nombreTour + 4
aqua_fin:

/* Structure poisson  */
    .struct  0
poisson_Nom:                     // 
    .struct  poisson_Nom + 4
poisson_Sexe:                     // 
    .struct  poisson_Sexe + 4
poisson_Race:                     // 
    .struct  poisson_Race + 4
poisson_PV:                     // 
    .struct  poisson_PV + 4
poisson_Age:                     // 
    .struct  poisson_Age + 4
poisson_Fin:

/* Structure algues  */
    .struct  0
algue_PV:                     // 
    .struct  algue_PV + 4
algue_Age:                     // 
    .struct  algue_Age + 4
algue_Fin:

/* Structure races  */
    .struct  0
race_Nom:                     // 
    .struct  race_Nom + 4
race_Repas:                     // 
    .struct  race_Repas + 4
race_TypeRep:                  // 1 = Mono-sexué 2 = Hermaphrodite avec l'âge
                               // 3 = Hermaphrodite opportuniste
    .struct  race_TypeRep + 4
race_Fin:

/* Structure liste chainée  */
    .struct  0
liste_pointeur:                     // 
    .struct  liste_pointeur + 4
liste_suivant:                     // 
    .struct  liste_suivant + 4
liste_Fin:
