/* Exemple programme assembleur ARM Raspberry PI */
/* Auteur  : Vincent Leboulou            */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* routines du moteur de Logique floue  */
/* lecture des regles depuis un fichier */
/* Amelioration des routines gestion du tas par brk  */
/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/
.equ TAILLEBUF, 50000   @ taille du buffer de lecture du fichier de configuration
.equ TAILLETAS, 100000   @ taille du tas à suivre
.equ VALYMIN,     0    @ valeur minimum du plateau bas
.equ VALYMAX,   100    @ valeur maximun du plateau haut
.equ LGZONENOM,	30   @ longueur de la zone nom pour affichage des variables
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"
/***************************************************/
/* structure des points */	
    .struct  0
points_X:	          @ position X
    .struct points_X + 4
points_Y:	          @ position Y
    .struct points_Y + 4	  
points_suivant:	          @ pointeur vers point suivant
    .struct points_suivant + 4	 	
points_fin:	            @ donne la taille de la structure
/* structure ensemble flou */	
    .struct  0
flou_points:	          @ pointeur vers liste des points
    .struct flou_points + 4
flou_min:	          
    .struct flou_min + 4	 @ minimun
flou_max:	          
    .struct flou_max + 4	 @ maximun
flou_fin:	            @ donne la taille de la structure
/* structure controleur flou */	
    .struct  0
controle_nom:	          @ pointeur vers nom 
    .struct controle_nom + 4
controle_entrees:	        @ pointeur vers liste des entrees  
    .struct controle_entrees + 4	 
controle_sortie:	         @ pointeur vers sortie 
    .struct controle_sortie + 4	 
controle_nb_regles:          @ nombre de regles
	 .struct controle_nb_regles + 4	 
controle_regles:	         @ pointeur vers liste des régles
    .struct controle_regles + 4	 	
controle_probleme:	         @ pointeur vers liste des problèmes 
    .struct controle_probleme + 4	
controle_tas:	         @ pointeur vers liste des régles
    .struct controle_tas + 4	
controle_reprisetas:	         @ pointeur vers liste des régles
    .struct controle_reprisetas + 4		
controle_buffer:	         @ pointeur vers liste des régles
    .struct controle_buffer + 4			
controle_fin:	            @ donne la taille de la structure
/* structure variable linguistique */	
    .struct  0
variable_nom:	          @ pointeur vers le nom
    .struct variable_nom + 4
variable_min:	          @ minimun
    .struct variable_min + 4	
variable_max:	          @ maximun
    .struct variable_max + 4	 
variable_valeurs:	          @ pointeur vers liste de valeur
    .struct variable_valeurs + 4	 
variable_suivante:	          @ pointeur vers liste de valeur
    .struct variable_suivante + 4		
variable_fin:	            @ donne la taille de la structure
/* structure valeur linguistique */	
    .struct  0
valeur_nom:	          @ pointeur vers le nom
    .struct valeur_nom + 4
valeur_Eflou:	          @ pointeur vers ensemble flou
    .struct valeur_Eflou + 4	
valeur_suivante:	          @ pointeur vers valeur suivante
    .struct valeur_suivante + 4		
valeur_fin:	            @ donne la taille de la structure
/* structure valeur numerique */	
    .struct  0
valnum_ling:	          @ pointeur vers variable linguistique
    .struct valnum_ling + 4
valnum_valeur:	          @ pointeur vers ensemble flou
    .struct valnum_valeur + 4	
valnum_suivante:	          @ pointeur vers ensemble flou
    .struct valnum_suivante + 4	
valnum_fin:	            @ donne la taille de la structure

/* structure expression floue */	
    .struct  0
expflou_ling:	          @ pointeur vers variable linguistique
    .struct expflou_ling + 4
expflou_nom:	          @ pointeur vers nom de l'expression
    .struct expflou_nom + 4	
expflou_suivante:	   @ pointeur vers suivante
    .struct expflou_suivante + 4	
expflou_fin:	            @ donne la taille de la structure

/***************************************************/
/* structure des regles  floues */	
    .struct  0

regle_nbpremisses:	    @ nombre de premisses
    .struct regle_nbpremisses + 4
regle_premisses:	     @ pointeur vers liste de premisses   
    .struct regle_premisses + 4	
regle_conclusion:	      @ pointeur vers conclusion   
    .struct regle_conclusion + 4	
regle_suivante:	      @ pointeur vers regle suivante  
    .struct regle_suivante + 4	
	
regle_fin:	             @ donne la taille de la structure
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szLibEntree:         .asciz  "Entrées" 
szLibSortie:         .asciz  "Sortie"
szLibVariable:        .asciz  "Variable"
szLibValeur: 		.asciz  "Valeur"
szLibValeurEFTG: 		.asciz  "EFTG"
szLibValeurEFTD: 		.asciz  "EFTD"
szLibValeurEFTRI: 		.asciz  "EFTRI"
szLibValeurEFTRA: 		.asciz  "EFTRA"
szLibSI:              .asciz "SI"
szLibEST:				.asciz "EST"
szLibET:				.asciz "ET"
szLibALORS:			.asciz "ALORS"
szRetourligne: 		.asciz  "\n"
szMessErreur: 		.asciz "Erreur rencontrée.\n"
szMessErreurOUV:	 .asciz "Erreur ouverture fichier.\n"
szMessErreurFERM:	 .asciz "Erreur fermeture fichier.\n"
szMessErreurLECT:	 .asciz "Erreur lecture fichier.\n"
szMessAffRegles: 	.asciz "Affichage des règles : \n"
szMessResolution: 	.asciz "*********** Résolution ***********\n"
szMessBary: 			.asciz "Calcul du barycentre.\n"
szMessFinOK: 		.asciz "Fin normale du programme. \n"
szMessVarNonTrouvee: .asciz "Variable non trouvée : "
szMessErreurSyn: 	.asciz "Erreur de syntaxe sur une régle.\n"
szMessErreEntree:   .asciz "Zone entree non trouvée. \n"
szMessErreValeurs:  .asciz "Erreur zones valeurs. \n"
szMessErreSortie:   .asciz "Erreur zone Sortie. \n"
szLibErrRechVal:    .asciz "Variable non trouvée dans les entrées. \n"

/* Libelles Regles */
szLibVide:   .asciz " "
szLibTeteRegle:		.asciz " SI "		
szLibIntregle: 	.asciz "   ET "
szLibFinregle: 	.asciz " ALORS "
szLibEst:   .asciz " EST " 
szLibNumRegle:   .ascii "Règle N° "
numRegle:         .fill 10, 1, ' ' 
                     .asciz " \n"   
szLibEns: .ascii "Ensemble min :"
sMin:          .fill 10, 1, ' ' 
                 .ascii "  max : "
sMax:        .fill 10, 1, ' '
				.ascii "   Adresse : "
sAdresse:	 .fill 10, 1, ' '			
                 .asciz " \n"					 
szLibPoints: .ascii " Adresse : "
sAdressePt: 	  .fill 10, 1, ' ' 
                 .ascii "( "
sX:					  .fill 10, 1, ' ' 
                 .ascii " : "
sY:        .fill 10, 1, ' '
                 .ascii " )  Point suivant :"
sAdressePtsuivant: 	 .fill 10, 1, ' '			 
				 .asciz  " \n"
szResultat:  .ascii "Résultat : "
sResult:    	  .fill 10, 1, ' '
                 .asciz " \n"

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
sLibZone1:         .skip 80
sLibZone2:         .skip 80
sLibZone3:         .skip 80
/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global FLOUcreationcontroleur,FLOUeffacerValeurs,FLOUresoudre,FLOUajoutValeur,FLOUverifEntrees    
.global FLOUverifSortie,FLOUafficheRegles
/***************************************************/
/*   création du controleur                        */
/***************************************************/
/*r0 contient le pointeur vers le nom du fichier de configuration */
/*r0 retourne l'adresse du controleur */
/* r9 contiendra l'adresse du controleur    */
/* r10 l'adresse du tas associé au controleur */
FLOUcreationcontroleur:
	push {fp,lr}    /* save des  2 registres frame et retour */
	push {r1-r10}
	mov r2,r0   @ save nom fichier
	@ Préparation de l'espace necessaire sur le tas 
	mov r0,#0
	mov r7,#0x2D    @ call system  brk
	swi 0            @ pour recupere l'adresse du début du tas (heap)
	mov r10,r0     @ stocker dans r10
	ldr r1,iTailleTas    @ mise à jour du tas(heap) avec la taille de notre tas
	add r0,r1
	mov r7,#0x2D    @ fonction brk
	swi 0
    
	@ creation du controleur
	mov r9,r10     @ sera l'adresse du début du controleur donc apres le buffer
	add r10,#controle_fin   @ ajout de la taille du controleur
	str r10,[r9,#controle_entrees]   @ pointeur du tas est le début de la liste
	str r10,[r10,#variable_suivante] @ sentinelle de fin
	add r10,#variable_fin        @ mise a jour du pointeur du tas
	mov r1,#0                       
	str r1,[r9,#controle_sortie] @ sera mis a jour après
	str r1,[r9,#controle_nb_regles]
	str r10,[r9,#controle_regles]
	str r10,[r10,#regle_suivante] @ sentinelle de fin
	add r10,#regle_fin        @ mise a jour du pointeur du tas
	str r10,[r9,#controle_probleme]
	str r10,[r10,#valnum_suivante]  @ sentinelle de fin
	add r10,#valnum_fin        @ mise a jour du pointeur du tas
    str r10,[r9,#controle_buffer]
	ldr r1,iTailleBuffer   @ et mise à jour du tas avec la taille du buffer de lecture
	add r10,r1
	@ lecture du fichier de configuration
	mov r0,r2    @ restaur du nom du fichier
	ldr r1,[r9,#controle_buffer]   @ adresse du début du buffer
	bl lectureConfig
	cmp r0,#-1
	beq 100f     @ erreur de lecture
	@ traitement du fichier de configuration
	ldr r0,[r9,#controle_buffer]   @ adresse du début du buffer
	bl traitementConfig
	str r10,[r9,#controle_tas]      @ maj adresse du tas
	str r10,[r9,#controle_reprisetas]      @ maj adresse de debut lors de la resolution
	cmp r0,#0
	movle r0,#-1   @ erreur detectee
	movgt r0,r9  @ retour adresse du controleur
100:     /* fin standard de la fonction  */
    pop {r1-r10}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
iTailleTas: .int TAILLETAS
/***************************************************/
/*   Lecture du fichier des regles                 */
/***************************************************/
/* r0 pointeur sur le nom du fichier à ouvrir */
/* r1 adresse du buffer de lecture 
/* pas de save des registres */
lectureConfig:
	push {fp,lr}    /* save des  2 registres frame et retour */
	mov r3,r1   @ save adresse buffer
	mov r1,#O_RDWR   /*  flags    */
	mov r2,#0   /* mode */
	mov r7, #OPEN /* appel fonction systeme pour ouvrir */
    swi #0 
	cmp r0,#0    /* si erreur retourne -1 */
	ble erreurOuv
	mov r8,r0    /* save du Fd */ 
	/* lecture r0 contient le FD du fichier */
	mov r1,r3   /*  adresse du buffer de reception    */
	ldr r2,iTailleBuffer   /* nb de caracteres  */
	mov r7, #READ /* appel fonction systeme pour lire */
    swi 0 
	cmp r0,#0
	ble erreurLect
	/* fermeture fichier paramètre */
	mov r0,r8   /* Fd  fichier */
	mov r7, #CLOSE /* appel fonction systeme pour fermer */
    swi 0 
	cmp r0,#0
	blt erreurFerm
	b 100f
erreurOuv: /* affichage erreur */
	ldr r1,iAdrszMessErreurOUV   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */		
	mov r0,#-1       /* code erreur */
	b 100f	
erreurFerm: /* affichage erreur */
	ldr r1,iAdrszMessErreurFERM   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */		
	mov r0,#-1       /* code erreur */
	b 100f		
erreurLect: /* affichage erreur */
	ldr r1,iAdrszMessErreurLECT   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */		
	mov r0,#-1       /* code erreur */
	b 100f		
100:   
   /* fin standard de la fonction  */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */
iTailleBuffer: .int TAILLEBUF
iAdrszMessErreurOUV: .int szMessErreurOUV
iAdrszMessErreurLECT: .int szMessErreurLECT
iAdrszMessErreurFERM: .int szMessErreurFERM

/***************************************************/
/*   remise à zero des données du problème                       */
/***************************************************/
/* r0 adresse du controleur */
FLOUeffacerValeurs:
	push {r10,lr}    /* save des  2 registres */
	ldr r10,[r0,#controle_reprisetas]      @ recup adresse du tas
	str r10,[r0,#controle_probleme]
	str r10,[r10,#valnum_suivante]  @ sentinelle de fin
	add r10,#valnum_fin        @ mise a jour du pointeur du tas
	str r10,[r0,#controle_tas]      @ maj adresse du tas
100:   
   /* fin standard de la fonction  */
   	pop {r10,lr}   /* restaur des  2 registres  */
    bx lr                   /* retour de la fonction en utilisant lr  */
/***************************************************/
/*   resolution                       */
/***************************************************/
/* r0 adresse du controleur */
FLOUresoudre:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r1-r10}
	mov r5,r0    @ save adresse controleur
	ldr r10,[r0,#controle_tas]      @ recup adresse du tas
	@ récup des valeurs de sortie
	ldr r2,[r0,#controle_sortie]
	ldr r1,[r2,#variable_min]   @ valeur mini
	ldr r2,[r2,#variable_max]   @ valeur maxi
	mov r4,r2  @ save valeur maxi
	@ création de l'ensemble flou résultat
	bl creationEFlou
	mov r7,r0    @ adresse de l'ensemble
	ldr r0,[r7,#flou_points]   @ debut de liste des points
	mov r2,#VALYMIN
	bl ajoutPoints    @ ajout min, 0 
	str r0,[r7,#flou_points]   @ debut de liste 
	mov r1,r4        @ valeur max
	mov r2,#VALYMIN
	bl ajoutPoints    @ ajout min, 0 
    str r0,[r7,#flou_points]   @ debut de liste 
	@ Application des regles
	ldr r6,[r5,#controle_regles]
	
1: @ boucle des règles	
	ldr r3,[r6,#regle_suivante] 
	cmp r3,r6
	beq 2f
	ldr r1,[r5,#controle_probleme]
	mov r0,r6    @ pointeur regle
	bl appliquerRegle
	cmp r0,#0    @ regle non appliquée
	ldreq r3,[r6,#regle_suivante]
	moveq r6,r3  @ boucle sur la suivante
	beq 1b
	//bl afficheEnsemble
	mov r1,r7
	//mov r0,r7
	//bl afficheEnsemble
	mov r2,#2      @ fonction OU (Max)
	bl fusionEns
	mov r7,r0          @ stockage du resultat fusionné
	//bl afficheEnsemble
	ldr r3,[r6,#regle_suivante]  @ boucler sur les regles
	mov r6,r3
	b 1b
	
2:  @ calcul du barycentre
    ldr r0,iAdrszMessBary
	bl affichageMess  /* affichage message dans console   */
    mov r0,r7	
	bl afficheEnsemble
	bl barycentre
	@ r0 contient le résultat
100:   
   /* fin standard de la fonction  */
	str r10,[r5,#controle_tas]              @ mise a jour adresse du tas
    pop {r1-r10}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
iAdrszMessBary: .int szMessBary	
/***************************************************/
/*   Appliquer la règle sur les valeurs d'entrées  */
/***************************************************/
/* r0 adresse de la regle */
/* r1 adresse des donnees du problème */
appliquerRegle:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r1-r9,r11,r12}
	mov r5,r0       @ save pointeur regle
	mov r12,r1      @ save donnees du problème
	mov r2,#VALYMAX     @ degre 
	@balayage des premisses de la regle
	ldr r3,[r0,#regle_premisses]
1:	
	ldr r4,[r3,#expflou_suivante]
	cmp r4,r3
	beq 4f
	mov r6,#0    @ degre local
	mov r7,#0    @ pointeur valeur ling
	ldr r11,[r3,#expflou_ling]
	@ balayage des valeurs du problème
2:	
	ldr r8,[r1,#valnum_suivante]
	cmp r8,r1
	beq 3f
	ldr r9,[r1,#valnum_ling] 
	cmp r9,r11
	movne r1,r8
	bne 2b    @ boucle problème
	@ recherche à faire
	mov r4,r1   @ save r1
	ldr r0,[r3,#expflou_ling]
	ldr r1,[r3,#expflou_nom]
	bl rechercheVarValeur    @ recherche de la variable linguistique
	cmp r0,#0 
	bleq valNonTrouvee
	moveq r1,r8     @non trouvée
	beq 2b    @ boucle problème
	mov r1,r4
	mov r7,r0     @ on garde l'adresse trouvée
	@ recherche valeur d'appartenance avec r0  et r1
	ldr r0,[r0,#valeur_Eflou]   @ recup adresse ensemble flou associe
	//bl afficheEnsemble
	ldr r1,[r1,#valnum_valeur] 
	bl valeurAppartenance
    
3: @ fin des valeurs du problème
    cmp r7,#0    @ verif si variable trouvée 
	moveq r0,#0
    beq 100f
    @ on garde le degre minimun 
    cmp r2,r0     @ A REVOIR r0 	
	movgt r2,r0

    @ boucle sur autre premisse
	mov r1,r12
    ldr r4,[r3,#expflou_suivante]	
	mov r3,r4
	b 1b
	 
	
4: @fin premisses
    @ recherche ensemble flou de la conclusion
	ldr r3,[r5,#regle_conclusion]
	ldr r0,[r3,#expflou_ling]
	ldr r1,[r3,#expflou_nom]
	bl rechercheVarValeur
	cmp r0,#0 
	bleq valNonTrouvee
	beq 100f    @non trouvée
	ldr r0,[r0,#valeur_Eflou]   @ recup adresse ensemble flou associe
	
    mov r1,r2              @  multiplication de l'ensemble par le degré calculé	
    bl multiEns          @ pour chaque premisse
	//bl afficheEnsemble
	
	@ retourne pointeur vers cet ensemble flou
	
100:   
   /* fin standard de la fonction  */
   	pop {r1-r9,r11,r12}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	

/***************************************************/
/*   affichage message variable non trouvee        */
/***************************************************/
/* r1 nom variable */
valNonTrouvee:
	push {fp,lr}    /* save des  2 registres frame et retour */
	push {r0-r2}
	ldr r0,iAdrszMessVarNonTrouvee
	ldr r2,iAdrsLibZone1
	bl concatChaine
	ldr r0,iAdrsLibZone1
	ldr r1,iAdrszRetourLigne
	ldr r2,iAdrsLibZone2
	bl concatChaine
    mov r0,r2
	bl affichageMess  /* affichage message dans console   */
	
100:   
   /* fin standard de la fonction  */
    pop {r0-r2}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
iAdrsLibZone1: .int sLibZone1	
iAdrsLibZone2: .int sLibZone2
iAdrszRetourLigne: .int szRetourligne
iAdrszMessVarNonTrouvee: .int szMessVarNonTrouvee	

/***************************************************/
/*   ajout variable dans les entrees                       */
/***************************************************/
/* r9 adresse du controleur */
/* r1 pointeur nom */
/* r2 minimum
/* r3 maximun */
/* r4 pointeur vers valeurs */
ajoutEntrees:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r5,r6}
	ldr r5,[r9,#controle_entrees]
1:	
	ldr r6,[r5,#variable_suivante]
	ldr r5,[r6,#variable_suivante]
	cmp r5,r6
	movne r5,r6
	bne 1b	
	@ stockage a l'adresse r5
	str r1,[r5,#variable_nom]
	str r2,[r5,#variable_min]
	str r3,[r5,#variable_max]
	str r4,[r5,#variable_valeurs]
	str r10,[r5,#variable_suivante]   @ place vide du tas
	str r10,[r10,#variable_suivante]  @ valeur sentinelle 
	add r10,#variable_fin               @ maj pointeur du tas
	mov r0,r5    @ retourne le pointeur vers la variable creee
100:   
   /* fin standard de la fonction  */
   pop {r5,r6}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
/***************************************************/
/*   creation ensemble flou                        */
/***************************************************/
/* r0 adresse du controleur */
/* r1 minimum
/* r2 maximun */
/* r10 pointeur Tas */
/* retourne l'adresse cree */
creationEFlou:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r5}
	str r1,[r10,#flou_min]	
	str r2,[r10,#flou_max]
	mov r5,r10   @ on garde le pointeur de l'ensemble
	add r10,#flou_fin              @ position tas vide suivante
	@ création liste de points vide
	mov r0,r10       @ debut de liste
	str r0,[r0,#points_suivant]  @ sentinelle
	add r10,#points_fin          @ position vide suivante
	str r0,[r5,#flou_points]
	mov r0,r5   @ retour de l'ensemble crée
100:   
   /* fin standard de la fonction  */
   pop {r5}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
/***************************************************/
/*   multiplication ensemble par valeur et division par 100          */
/***************************************************/
/* r0 adresse ensemble*/
/* r1 valeur  */
/* r0 retourne le nouvel ensemble */
multiEns:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r1-r9}
	mov r8,r0    @ save pointeur
	mov r7,r1    @ save valeur
	ldr r1,[r8,#flou_min]
	ldr r2,[r8,#flou_max]
	bl creationEFlou      @ création d'un nouvel ensemble flou
	mov r9,r0    @ adresse de l'ensemble cree
	ldr r8,[r8,#flou_points]   @ debut de liste des points origine
1:
    ldr r4,[r8,#points_suivant]
    cmp r4,r8
	moveq r0,r9
    beq 100f
    ldr r1,[r8,#points_X]	
	ldr r5,[r8,#points_Y]
	mul r2,r5,r7         @ multiplie Y par valeur
	@ ici division par 100  pour retomber sur la plage 0,100 de Y
	mov r0,r2
	mov r1,#VALYMAX
	bl division
	ldr r1,[r8,#points_X]	 
	ldr r0,[r9,#flou_points]   @ debut de liste des points nouveaux
	bl ajoutPoints    @ ajout points 
    str r0,[r9,#flou_points]   @ debut de liste 
	mov r8,r4
	b 1b
	
	
100:    /* fin standard de la fonction  */
    pop {r1-r9}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */			
/***************************************************/
/*   fusion de 2 ensembles           */
/***************************************************/
/* r0 adresse ensemble  1*/
/* r1 adresse ensemble  2 */
/* r2 methode   1 min 2 max */
/* r0 retourne le nouvel ensemble */
/* Attention les 2 ensembles ne doivent pas être vides   */
fusionEns :
	push {fp,lr}    /* save des  2 registres frame et retour */	
	sub sp,#16      /* reserve 16 octets A RENDRE EN FIN DE PROCEDURE*/  
	mov fp,sp    /* fp <- adresse début */
                /* fp contient save r0 */
				/* fp + 4 save r1  */
				/* fp + 8 save methode */
				/* fp +12 vide */
	push {r2-r9}
	mov r8,r0    @ save pointeur ens 1
	str r0,[fp]   @ save pointeur ens 1
	mov r9,r1    @ save pointeur ens 2
	mov r0,r9
	
	str r1,[fp,#4]  @ save pointeur ens 2
	str r2,[fp,#8]  @ save methode
	ldr r0,[r8,#flou_min]
	ldr r1,[r9,#flou_min]
	cmp r0,r1     @ recherche min des 2  
	movlt r1,r0  @ pour le mettre dans r1
	ldr r0,[r8,#flou_max]
	ldr r2,[r9,#flou_max]
	cmp r0,r2   @ recherche max des 2
	movgt r2,r0  @ pour le mettre dans r2
	bl creationEFlou
	mov r7,r0    @ adresse de l'ensemble cree
	@ préparation des balayage
	ldr r8,[r8,#flou_points]   @ debut de liste des points ens 1
	ldr r9,[r9,#flou_points]   @ debut de liste des points ens 2
	mov r6,#0             @ ancienne position
	ldr r4,[r8,#points_Y]
	ldr r5,[r9,#points_Y]
	cmp r4,r5         @ calcul du sens de la courbe
	movlt r3,#-1 
	movgt r3,#1       @ dans nouvelle position
	moveq r3,#0
	mov r12,r8     @ pour conserver ce point de départ
  
1:
    ldr r4,[r8,#points_suivant] 
	cmp r4,r8
	beq 50f      @ pour traiter la fin du 1er ensemble 
	ldr r5,[r9,#points_suivant] 
	cmp r5,r9
	beq 60f      @  pour traiter la fin du 2eme ensemble
	ldr r1,[r8,#points_X]   @ X1
	ldr r2,[r9,#points_X]   @ X2
    mov r6,r3      @ nouvelle position dans ancienne	
	ldr r4,[r8,#points_Y]
	ldr r5,[r9,#points_Y]
	cmp r4,r5
	movlt r3,#-1 
	movgt r3,#1       @ nouvelle position
	moveq r3,#0
	cmp r6,#0
	beq 10f    @ 
	cmp r3,#0
	beq 10f    @ 
	cmp r3,r6
	beq 10f    @ pas de changement les 2 courbes ne se croisent pas
	cmp r1,r2    @ ici elles se croisent et donc il faut calculer le point intersection
	movlt r5,r1 	 @ soit X1
	movlt r4,r2
	blt 2f
	movge r5,r2 	 @ soit X2  donc min de x1 x2
	movge r4,r1        @  donc max de x1 x2  xprime
	bgt 2f
	ldr r5,[r12,#points_X]   @ soit  X de l'ancien
2:
    @ calcul des pentes
	push {r1,r2,r3,r6,r12}
	mov r1,r5     @ min de X1 x2
	ldr r0,[fp]      @ pointeur vers E1
    bl valeurAppartenance	
	mov r12,r0        @ VA de x dans E1
	ldr r0,[fp]      @ pointeur vers E1
	mov r1,r4     @ valeur calculée
    bl valeurAppartenance	
	mov r6,r0     @    VA du max de r1,r2   
	sub r1,r4,r5   @ x - x prime
	sub r0,r6,r12   @ VA 
	bl divisionS    @ r2 correspond à p1
	mov r6,r2    @ si r6 ne sert plus
	mov r1,r5     @ min de X1 x2
	ldr r0,[fp,#4]      @ pointeur vers E2
    bl valeurAppartenance	
	push {r7}
	mov r7,r0       @ Va de X E2
	ldr r0,[fp,#4]      @ pointeur vers E2
	mov r1,r4     @ valeur calculée
    bl valeurAppartenance	@ VA du max de x1 x2
	sub r0,r0,r7    @ VA 
	sub r1,r4,r5     @ x - x prime
	bl divisionS    @ r2 correspond à p2
	@ calcul du Delta 
	subs r1,r6,r2    @ p1 - p2
	moveq r2,#0
	sub r0,r7,r12     @ 
    blne divisionS
    @ R0 doit contenir le resultat
	add r1,r5,r2      @ X + delta
	ldr r0,[fp]      @ pointeur vers E1
    bl valeurAppartenance	
	@ ajouter le point 
	pop {r7}
	mov r2,r0         @ Y =  X + delta de E1
    ldr r0,[r7,#flou_points]   @ debut de liste  de l'ensemble résultat
	bl ajoutPoints   @ ajout du point  r1=X + delta r2 appartenance
    str r0,[r7,#flou_points]   @ maj du debut de liste
	pop {r1,r2,r3,r6,r12}
	
	cmp r1,r2
	blt 6f
	bgt 8f

	b 1b
	
6:   @ avancement E1
	mov r12,r8
	ldr r4,[r8,#points_suivant]   @ car r4 utilisé plus haut 
	mov r8,r4
	b 1b
8:  @ avancement E2
	ldr r5,[r9,#points_suivant]   @ car r5 utilisé plus haut 
	mov r9,r5
	b 1b
	
10:  @ on doit boucler sur un autre point !!   A REVOIR 
    cmp r1,r2
	blt pluspetit
	bgt plusgrand
    @ les 2 points ont la même abscisse 
	mov r4,r1
    ldr r0,[r8,#points_Y] 
	ldr r1,[r9,#points_Y] 
	ldr r2,[fp,#8]    @ restaur methode
	bl optimum   @ soit Y1 soit Y2 suivant methode
	mov r2,r0
	mov r1,r4
    ldr r0,[r7,#flou_points]   @ debut de liste  de l'ensemble résultat
	bl ajoutPoints   @ ajout du point 
    str r0,[r7,#flou_points]   @ maj du debut de liste 

	@ avancement
	mov r12,r8
	ldr r4,[r8,#points_suivant]   @ car r4 utilisé plus haut 
	mov r8,r4
	ldr r5,[r9,#points_suivant]   @ car r5 utilisé plus haut 
	mov r9,r5
	b 1b
	
pluspetit:
	ldr r0,[fp,#4]      @ pointeur vers E2
	@ calcul appartenance de x1
    bl valeurAppartenance
    ldr r1,[r8,#points_Y] 
    ldr r2,[fp,#8]    @ restaur methode
	bl optimum   @ soit Y soit X1 suivant methode
	mov r2,r0   @ nouveau Y
	ldr r1,[r8,#points_X]   @ recup X
	ldr r0,[r7,#flou_points]   @ debut de liste  de l'ensemble résultat
	bl ajoutPoints   @ ajout du point 
    str r0,[r7,#flou_points]   @ maj du debut de liste 
	
	@ et on passe au point suivant de r1
	mov r12,r8
    ldr r4,[r8,#points_suivant]   @ car r4 utilisé plus haut 
	mov r8,r4

	b 1b         @ boucle  
	
plusgrand:	
	ldr r0,[fp]      @ pointeur vers E1
	mov r1,r2
	@ calcul appartenance de x2
    bl valeurAppartenance
	mov r4,r2   @ save X2
    ldr r1,[r9,#points_Y] 
    ldr r2,[fp,#8]    @ restaur methode
	bl optimum   @ soit Y soit X1 suivant methode
	mov r2,r0    @ nouvel Y
	mov r1,r4   @  X2
	ldr r0,[r7,#flou_points]   @ debut de liste  de l'ensemble résultat
	bl ajoutPoints   @ ajout du point 
    str r0,[r7,#flou_points]   @ maj du debut de liste 
	
	@ et on passe au point suivant de r2
    ldr r5,[r9,#points_suivant]   @ car r4 utilisé plus haut 
	mov r9,r5
	b 1b         @ boucle 
	
50:  @ faut ajouter les points du 2ieme si pas vide lui aussi
	ldr r3,[fp,#8]    @ restaur methode
55:
    ldr r5,[r9,#points_suivant] 
	cmp r5,r9
	beq 100f      @  c'est fini
    ldr r0,[r9,#points_Y]
	mov r1,#0
	mov r2,r3
	bl optimum   @ soit Y soit 0 suivant methode
	mov r2,r0
	ldr r1,[r9,#points_X]   @ recup X
	ldr r0,[r7,#flou_points]   @ debut de liste  de l'ensemble résultat
	bl ajoutPoints   @ ajout du point 
    str r0,[r7,#flou_points]   @ maj du debut de liste 

	mov r9,r5 
	b 55b      @ pour traiter la fin du 2ieme ensemble 
	
  
	
60:  @ faut ajouter les points du 1er si pas vide
	ldr r3,[fp,#8]    @ restaur methode
65:
    ldr r4,[r8,#points_suivant]   @ autre point
	cmp r4,r8
	beq 100f
    ldr r0,[r8,#points_Y]
	mov r1,#0
	mov r2,r3
	bl optimum   @ soit Y soit 0 suivant methode
	mov r2,r0
	ldr r1,[r8,#points_X]   @ recup X
	ldr r0,[r7,#flou_points]   @ debut de liste  de l'ensemble résultat
	bl ajoutPoints   @ ajout du point 
    str r0,[r7,#flou_points]   @ maj du debut de liste 
	mov r8,r4 
	b 65b      @ pour traiter la fin du 1er ensemble 
	

100:    /* fin standard de la fonction  */
    mov r0,r7
    pop {r2-r9}
	add sp,#16      /* rend les 16 octets reservés */  
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		

/***************************************************/
/*   valeur maxi mini            */
/***************************************************/
/* r0  valeur 1  */
/* r1  valeur 2  */
/* r2  methode min = 1 max = 2 */
optimum:
	//push {fp,lr}    /* save des  2 registres frame et retour */	
	cmp r2,#1
	beq 1f
	cmp r2,#2
	beq 2f
	mov r0,#-1    @ erreur codif
	b 100f

1:   @ min
    cmp r0,r1
	blt 100f
	mov r0,r1
	b 100f
 2:  @ max
    cmp r0,r1
	bgt 100f
	mov r0,r1
 
100:    /* fin standard de la fonction  */
   //	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
	
/***************************************************/
/*   affichage d'un ensemble Flou                       */
/***************************************************/
/* r0 pointeur sur ensemble */
afficheEnsemble:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r0-r5}
	mov r5,r0
	ldr r0,[r5,#flou_min]
	ldr r1,iAdrsMin
	bl conversion10
	ldr r0,[r5,#flou_max]
	ldr r1,iAdrsMax
	bl conversion10
	ldr r0,iAdrszLibEns
	mov r1,r5
	ldr r0,iAdrsAdresse 
    mov r2,#16    /* conversion en base 16 */
    push {r0,r1,r2}	 /* parametre de conversion */
    bl conversion
	ldr r0,iAdrszLibEns
	bl affichageMess  /* affichage message dans console   */
	ldr r0,[r5,#flou_points]
	bl affPoints
	
100:   
    /* fin standard de la fonction  */
    pop {r0-r5}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
iAdrsMin: .int sMin 
iAdrsMax: .int sMax
iAdrszLibEns: .int szLibEns
iAdrsAdresse: .int sAdresse 
/***************************************************/
/*   calcul valeur d'appartenance                  */
/***************************************************/
/* r0 pointeur sur ensemble flou */
/* r1 valeur */
valeurAppartenance:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r1-r8}
	mov r5,r0
	ldr r2,[r0,#flou_min]
	cmp r1,r2
	movlt r0,#0
	blt 100f
	
	ldr r2,[r0,#flou_max]
	cmp r1,r2
	movgt r0,#0
	bgt 100f
	ldr r2,[r0,#flou_points]
	ldr r3,[r2,#points_suivant]
	cmp r2,r3      @ si pas de premier point
	moveq r0,#0    
	beq 100f
   	ldr r5,[r2,#points_X]	  @   premier point ?
	cmp r1,r5   @ x egaux ?
	ldreq r0,[r2,#points_Y]   @  oui trouvé on retourne Y 
	beq 100f
1:   @ debut de boucle de recherche
	ldr r3,[r2,#points_suivant]
	ldr r4,[r3,#points_suivant]
	cmp r3,r4      @ fin des points 
	moveq r0,#0   @ on retourne Zero 
	beq 100f

    ldr r5,[r3,#points_X]	
	cmp r1,r5
	ldreq r0,[r3,#points_Y]   @ trouvée on retourne Y 
	beq 100f   @ egalite
	@ on avance d'un point si plus grand
	movgt r2,r3       @ point en cours devient le point avant
	bgt 1b            @ boucle

   @ plus petit faut calculer l'interpolation
    ldr r4,[r2,#points_Y]
	ldr r5,[r3,#points_Y]
	cmp r4,r5      @ les 2 points sont au même niveau 
	moveq r0,r4   @ donc on retourne la valeur de Y
	beq 100f
	subgt r6,r4,r5
	movgt r8,#-1
	sublt r6,r5,r4
	movle r8,#0 
	ldr r5,[r2,#points_X]
	sub r1,r5
	mul r6,r1
	ldr r4,[r3,#points_X]
	ldr r5,[r2,#points_X]
	sub r7,r4,r5
	ldr r5,[r2,#points_Y]
	mov r0,r6
	mov r1,r7
	bl division
	cmp r8,#0
	addeq r5,r2
	subne r5,r2
	mov r0,r2      @ retourne la valeur
	
100:   
   /* fin standard de la fonction  */
    pop {r1-r8}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
/***************************************************/
/*   calcul du barycentre d'un ensemble de points           */
/***************************************************/
/* r0 adresse ensemble*/
/* r0 retourne la valeur */
barycentre:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r1-r9}
	mov r9,r0
	ldr r4,[r9,#flou_points]   @ debut de liste des points 
	ldr r5,[r4,#points_suivant]
	cmp r5,r4
	moveq r0,#0
	beq 100f
	mov r12,r4    @ ancien point
	mov r8,#0     @ aire pondere 
	mov r7,#0     @ aire totale
	mov r6,#0     @ aire locale
1:
    mov r4,r5 
   	ldr r5,[r4,#points_suivant]
	cmp r5,r4
	beq 10f
	@calcul barycentre local
	ldr r2,[r4,#points_Y]
	ldr r3,[r12,#points_Y]    @ ancien point
	cmp r2,r3
	bne 2f
	@ rectangle
	ldr r0,[r4,#points_X]
	ldr r1,[r12,#points_X]    @ ancien point
    sub r3,r0,r1
    mul r6,r2,r3
    add r7,r6
	lsr r0,r3,#1   @  divisé par 2
	add r0,r1
	mul r0,r6,r0
	add r8,r0
	@ point suivant
	mov r12,r4    @ ancien point
	b 1b
2: @ c'est un trapeze
    @ 1 rectangle
	cmp r2,r3
	movle r6,r2
    movgt r6,r3
    ldr r0,[r4,#points_X]
	ldr r1,[r12,#points_X]    @ ancien point
    sub r11,r0,r1
    mul r6,r11,r6   @ aire locale 1
	add r7,r6
	lsr r0,r11,#1
	add r0,r1
	mul r0,r6,r0
	add r8,r0
	@2   reste triangle
    cmp r2,r3
	suble r6,r3,r2
    subgt r6,r2,r3
    mul r6,r11
    lsr r6,#1    @ divisé par 2
    add r7,r6    @ aire totale
    cmp r2,r3
    blt 3f	
	@ barycentre à 1/3 coté
	lsl r0,r11,#1    @ * par 2
	mov r11,r1    @ save ancien x
	mov r1,#3
	bl division
	add r2,r11  @ ajout ancien x à  r2
	mul r6,r2
	add r8,r6    @  aire pondérée
	mov r12,r4    @ ancien point
	b 1b
3:	
	@ barycentre à 1/3 coté ancien
	mov r0,r11 
	mov r11,r1    @ save ancien x
	mov r1,#3
	bl division
	add r2,r11 @ ajout ancien x à  r2
	mul r6,r2
	add r8,r6    @  aire pondérée
	mov r12,r4    @ ancien point
	b 1b
	
10: @ fin calcul du barycentre
    mov r0,r8     @ aire ponderee
	cmp r7,#0     @ verif aire totale  
	moveq r0,#0
    beq 100f
    mov r1,r7    @ aire totale  
    bl division
    mov r0,r2	   @ retour barycentre
	
100:    /* fin standard de la fonction  */
    pop {r1-r9}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
	
/***************************************************/
/*   creation ensemble flou type Trapeze gauche     */
/***************************************************/
/* r0 adresse du controleur */
/* r1 minimum
/* r2 maximun */
/* r3 finplateauhaut */
/* r4 debutplateaubas */
/* r10 pointeur du tas */
/* retourne l'adresse cree */
creationEFTG :
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r5,r6}
	bl creationEFlou
	mov r5,r0    @ adresse de l'ensemble
	ldr r0,[r5,#flou_points]   @ debut de liste des points
	mov r6,r2   @ save maxi
	mov r2,#VALYMAX
	bl ajoutPoints    @ ajout min, 100 
    str r0,[r5,#flou_points]   @ debut de liste 
	
	@ autre point
	mov r1,r3
    mov r2,#VALYMAX
	bl ajoutPoints   @ ajout finplateauhaut, 100 
    str r0,[r5,#flou_points]   @ debut de liste 	
	
    @ autre point
	mov r1,r4
    mov r2,#VALYMIN
	bl ajoutPoints   @ ajout debutplateaubas, 0 
    str r0,[r5,#flou_points]   @ debut de liste 	
	
	@ autre point 
	mov r1,r6
    mov r2,#VALYMIN
	bl ajoutPoints  @ ajout maxi, 1 
    str r0,[r5,#flou_points]   @ debut de liste
	
	mov r0,r5   @ retourne le pointeur de l'ensemble
	
100:   
   /* fin standard de la fonction  */
   pop {r5,r6}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
/***************************************************/
/*   ajout de points dans un ensemble              */
/***************************************************/
/* r0 adresse début de liste */
/* r1 position X */
/* r2 position Y */ 
ajoutPoints:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r4,r5,r6,r7}
	mov r7,r0   @ save debut de liste
	ldr r5,[r0,#points_suivant]
	cmp r5,r0
	bne 1f
	@ premier point
	str r1,[r0,#points_X]
	str r2,[r0,#points_Y]
	str r10,[r0,#points_suivant]
	str r10,[r10,#points_suivant]   @ sentinelle
	add r10,#points_fin
	mov r0,r7   @ retour debut de liste
	b 100f
1:	
    ldr r4,[r0,#points_X]
	cmp r1,r4   @ test des valeurs pour insertion
	bgt 2f
	@ position X à inserer < position stockée
	str r1,[r10,#points_X]   @ stockage du nouveau point sur le tas
	str r2,[r10,#points_Y]
	str r0,[r10,#points_suivant]  @ on stocke le point deja present dans suivant
    mov r0,r10                    @ on retourne le pointeur pour maj du poste de l'appelant
    add r10,#points_fin   @ nouvelle position vide
    b 100f
2:	
    mov r6,r0  @ on garde la position precedente
    ldr r5,[r0,#points_suivant]   @ points suivant
	cmp r5,r0   @ dernier point ?
	beq 3f
	ldr r4,[r5,#points_X]
	cmp r1,r4   @ position X à inserer < position stockée
	blt 4f
	mov r0,r5
	b 2b    @ on boucle sur suivant
3:   @ stockage sur le dernier poste
	str r1,[r5,#points_X]   @ stockage du nouveau point 
	str r2,[r5,#points_Y]
	str r10,[r5,#points_suivant]  @ 
	//add r10,#points_fin   @ nouvelle position vide
	str r10,[r10,#points_suivant]  @ sentinelle
	add r10,#points_fin  @ nouvelle position vide
	mov r0,r7
	b 100f
4:	@ insertion dans la liste
    str r10,[r6,#points_suivant]  @ on stocke le nouveau point dans le point precedent
    str r1,[r10,#points_X]   @ stockage du nouveau point sur le tas
	str r2,[r10,#points_Y]
	str r5,[r10,#points_suivant]  @ on stocke le point deja present dans suivant
    mov r0,r7                   @ on retourne le debut de liste
    add r10,#points_fin   @ nouvelle position vide
	
100:   
   /* fin standard de la fonction  */
    pop {r4,r5,r6,r7}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
/***************************************************/
/*   affichage  entrees                       */
/***************************************************/
/* r0 adresse du controleur */
FLOUverifEntrees:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r0,r1,r5,r6}
	ldr r5,[r0,#controle_entrees]
1:	
	ldr r0,[r5,#variable_nom]
	bl affichageMess  /* affichage message dans console   */
	ldr r0,=szRetourligne
	bl affichageMess  /* affichage message dans console   */
	ldr r0,[r5,#variable_valeurs]
2:	
    mov r6,r0
	ldr r0,[r0,#valeur_nom]
	bl affichageMess  /* affichage message dans console   */
	ldr r0,=szRetourligne
	bl affichageMess  /* affichage message dans console   */
    ldr r1,[r6,#valeur_Eflou]
	ldr r0,[r1,#flou_points]
	bl affPoints
	ldr r0,[r6,#valeur_suivante]
	ldr r6,[r0,#valeur_suivante]
	cmp r0,r6
	bne 2b
	ldr r6,[r5,#variable_suivante]
    ldr r5,[r6,#variable_suivante]
	cmp r5,r6
	movne r5,r6
	bne 1b
100:    /* fin standard de la fonction  */
    pop {r0,r1,r5,r6}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
/***************************************************/
/*   affichage  Sortie pour controle                       */
/***************************************************/
/* r0 adresse du controleur */

FLOUverifSortie:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r0,r1,r5,r6}
	ldr r5,[r0,#controle_sortie]
1:	
	ldr r0,[r5,#variable_nom]
	bl affichageMess  /* affichage message dans console   */
	ldr r0,=szRetourligne
	bl affichageMess  /* affichage message dans console   */
	ldr r0,[r5,#variable_valeurs]
2:	
    mov r6,r0
	ldr r0,[r0,#valeur_nom]
	bl affichageMess  /* affichage message dans console   */
	ldr r0,=szRetourligne
	bl affichageMess  /* affichage message dans console   */
    ldr r1,[r6,#valeur_Eflou]
	ldr r0,[r1,#flou_points]
	bl affPoints
	ldr r0,[r6,#valeur_suivante]
	ldr r6,[r0,#valeur_suivante]
	cmp r0,r6
	bne 2b

100:    /* fin standard de la fonction  */
    pop {r0,r1,r5,r6}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
/***************************************************/
/*   affichage des points                       */
/***************************************************/
/* r0 adresse structure points */
affPoints:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r1,r2,r5,r6}
	mov r5,r0
1:	
	mov r1,r5
	ldr r0,iAdrsAdressePt 
    mov r2,#16    /* conversion en base 16 */
    push {r0,r1,r2}	 
    bl conversion
	ldr r1,[r5,#points_suivant]
	ldr r0,iAdrsAdressePtsuivant 
    mov r2,#16    /* conversion en base 16 */
    push {r0,r1,r2}	 /* parametre de conversion */
    bl conversion
	
	ldr r0,[r5,#points_X]
	ldr r1,=sX
	bl conversion10
	ldr r0,[r5,#points_Y]
	ldr r1,=sY
	bl conversion10
	ldr r0,=szLibPoints
	bl affichageMess  /* affichage message dans console   */
	ldr r0,[r5,#points_suivant]
	ldr r6,[r0,#points_suivant]
	cmp r0,r6
	movne r5,r0
	bne 1b
100:   
   /* fin standard de la fonction  */
   pop {r1,r2,r5,r6}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
iAdrsAdressePt: .int sAdressePt	
iAdrsAdressePtsuivant: .int sAdressePtsuivant
/***************************************************/
/*   creation ensemble flou type Trapeze          */
/***************************************************/
/* r0 adresse du controleur */
/* r1 minimum
/* r2 maximun */
/* r3 debut base */
/* r4 debut plateau */
/* r5 fin plateau  */
/* r6 fin base   */
/* r10 pointeur tas */
/* retourne l'adresse cree */
creationEFTRA :
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r6,r7,r8,r9}
	bl creationEFlou
	mov r7,r0    @ adresse de l'ensemble crée
	mov r8,r2   @ save maxi
	ldr r0,[r7,#flou_points]   @ debut de liste 
	mov r2,#VALYMIN     @ ajout min,0
	bl ajoutPoints
    str r0,[r7,#flou_points]   @ debut de liste 
	@ autre point
	mov r1,r3
    mov r2,#VALYMIN
	bl ajoutPoints   @ ajout debut base,0
    str r0,[r7,#flou_points]   @ debut de liste 	
    @ autre point
	mov r1,r4
    mov r2,#VALYMAX
	bl ajoutPoints @ ajout debutplateau,100
    str r0,[r7,#flou_points]   @ debut de liste 	
	@ autre point 
	mov r1,r5
    mov r2,#VALYMAX
	bl ajoutPoints  @ ajout finplateau,100
    str r0,[r7,#flou_points]   @ debut de liste
  @ autre point
	mov r1,r6
    mov r2,#VALYMIN
	bl ajoutPoints   @ ajout finbase,0
    str r0,[r7,#flou_points]   @ debut de liste 	
	 @ autre point
	mov r1,r8
    mov r2,#VALYMIN
	bl ajoutPoints   @ ajout max,0
    str r0,[r7,#flou_points]   @ debut de liste
	mov r0,r7   @ retourne le pointeur de l'ensemble
	
100:   
   /* fin standard de la fonction  */
   pop {r6,r7,r8,r9}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
/***************************************************/
/*   creation ensemble flou type Trapeze droit     */
/***************************************************/
/* r0 adresse du controleur */
/* r1 minimum
/* r2 maximun */
/* r3 finplateaubas */
/* r4 debutplateauhaut */
/* r10 pointeur du tas */
/* retourne l'adresse cree */
creationEFTD :
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r5,r6}
	bl creationEFlou
	mov r5,r0    @ adresse de l'ensemble
	ldr r0,[r5,#flou_points]   @ debut de liste des points
	mov r6,r2   @ save maxi
	mov r2,#VALYMIN
	bl ajoutPoints    @ ajout min, 0 
    str r0,[r5,#flou_points]   @ debut de liste 
	
	@ autre point
	mov r1,r3
    mov r2,#VALYMIN
	bl ajoutPoints   @ ajout finplateaubas, 0 
    str r0,[r5,#flou_points]   @ debut de liste 	
	
    @ autre point
	mov r1,r4
    mov r2,#VALYMAX
	bl ajoutPoints   @ ajout debutplateauhaut, 100 
    str r0,[r5,#flou_points]   @ debut de liste 	
	
	@ autre point 
	mov r1,r6
    mov r2,#VALYMAX
	bl ajoutPoints  @ ajout maxi, 100 
    str r0,[r5,#flou_points]   @ debut de liste
	
	mov r0,r5   @ retourne le pointeur de l'ensemble
	
100:   
   /* fin standard de la fonction  */
   pop {r5,r6}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
.align 4     /* alignement car l'étiquette de la routine suivante doit être alignée */
/***************************************************/
/*   creation ensemble flou type Triangle         */
/***************************************************/
/* r0 adresse du controleur */
/* r1 minimum
/* r2 maximun */
/* r3 debutbase */
/* r4 sommet */
/* r5 fin base  */
/* retourne l'adresse cree */
creationEFTRI :
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r5,r6,r7}
	bl creationEFlou
	mov r7,r0    @ adresse de l'ensemble
	ldr r0,[r7,#flou_points]   @ debut de liste des points
	mov r6,r2   @ save maxi
	mov r2,#VALYMIN
	bl ajoutPoints    @ ajout min, 0 
    str r0,[r7,#flou_points]   @ debut de liste 
	
	@ autre point
	mov r1,r3
    mov r2,#VALYMIN
	bl ajoutPoints   @ ajout debutbase, 0 
    str r0,[r7,#flou_points]   @ debut de liste 	
	
    @ autre point
	mov r1,r4
    mov r2,#VALYMAX
	bl ajoutPoints   @ ajout sommet, 100
    str r0,[r7,#flou_points]   @ debut de liste 	
	
	@ autre point
	mov r1,r5
    mov r2,#VALYMIN
	bl ajoutPoints   @ ajout fin base, 0
    str r0,[r7,#flou_points]   @ debut de liste 
	
	@ autre point 
	mov r1,r6
    mov r2,#VALYMIN
	bl ajoutPoints  @ ajout maxi, 0 
    str r0,[r7,#flou_points]   @ debut de liste
	
	mov r0,r7   @ retourne le pointeur de l'ensemble
	
100:   
   /* fin standard de la fonction  */
   pop {r5,r6,r7}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		

/***************************************************/
/*   traitement du fichier de configuration        */
/***************************************************/
/* r0 pointeur vers buffer de lecture */
/* r9 pointeur vers controleur */
/* r10 pointeur vers notre tas */
traitementConfig:
	push {fp,lr}    /* save des  2 registres frame et retour */
    push {r1-r9}
	mov fp,sp     /* frame buffer */
	mov r2,r0     @ save début du buffer
	@recherche du nom du controleur
	bl  elimblanc   @ elimine les blancs
	mov r3,r2   @ debut du nom 
	add r2,#1
    bl chercheSuite
	str r3,[r9,#controle_nom]  @ maj du nom du controleur
	
	@ maintenant les entrees
	mov r3,r2   @ debut de la zone lue 
	add r2,#1
    bl chercheSuite
	cmp r4,#0
	beq  erreursyn1
	mov r0,r3
    ldr r1,iAdrszLibEntree
	bl comparaison
	bne erreursyn1
 @ boucle d'analyse des entrees
    mov r5,r2   @ debut de la zone lue nom ou libelle Sortie
    bl chercheSuite
	cmp r4,#0
	beq  erreursyn1	
1:	@ boucle d'analyse des entrees
	mov r0,r5
    ldr r1,iAdrszLibSortie
	bl comparaison
	beq suiteSortie
	mov r6,r2   @ debut de la zone lue nom
    bl chercheSuite
	cmp r4,#0
	beq  erreursyn1	

	mov r5,r2   @ debut de la zone mini
    bl chercheSuite
	cmp r4,#0
	beq  erreursyn1	
	mov r0,r5
	bl conversionAtoD
	mov r7,r0
	mov r5,r2   @ debut de la zone maxi
    bl chercheSuite
	cmp r4,#0
	beq  erreursyn1	
	mov r0,r5
	bl conversionAtoD
	mov r8,r0
	mov r12,r2    @ save r2
	@ création de l'entrée
	mov r0,r9  @adresse du controleur
	mov r1,r6     @ nom variable
	mov r2,r7     @ mini
	mov r3,r8     @ maxi
	mov r4,r10    @ zone tas
	str r10,[r10,#valeur_suivante]
	add r10,#valeur_fin
	bl ajoutEntrees
	//vidregtit ajoutEntrees
	mov r1,r0
	mov r2,r12   @ restaur buffer
	@ et maintenant il faut ajouter chaque valeur
	bl analyseValeurs
	mov r5,r0   @ pour récuperer le debut de zone lue
	@ et on boucle 
	b 1b
suiteSortie:   @ analyse de la partie sortie
    bl analyseSortie
	@ et maintenant faut analyser les regles
	@ici nous sommes sur le début de la première règles
    bl analyseRegles
	b 100f
erreursyn1:	
	ldr r0,iAdrszMessErreEntree
	bl affichageMess  /* affichage message dans console   */
	mov r0,#-1       /* code erreur */	
	
100:     /* fin standard de la fonction  */
	pop {r1-r9}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
iAdrszLibEntree: .int  szLibEntree
iAdrszMessErreEntree: .int szMessErreEntree
iAdrszLibSortie: .int szLibSortie
/***************************************************/
/*   analyse des lignes valeurs            */
/***************************************************/
/* r1 pointeur variable linguistique */
/* r2 indice caractère du buffer  */
analyseValeurs:
	push {fp,lr}    /* save des  2 registres frame et retour */
    push {r1,r3-r9}	
	mov fp,sp
1:  @ boucle des valeurs	
	mov r5,r2   @ debut de la zone lue 	
	add r2,#1
    bl chercheSuite
	cmp r4,#0
	beq  erreursyn2
	mov r0,r5
    ldr r1,iAdrszLibValeur
	bl comparaison
	movne r0,r5 
	bne 100f    @ et r0 contiendra le debut de zone lue
	mov r6,r2   @ debut de la zone lue 	
	add r2,#1
	bl chercheSuite   @ recup nom
	cmp r4,#0
	beq  erreursyn2
	mov r8,r2   @ debut de la zone lue 
	add r2,#1
	 bl chercheSuite   @ recup type ensemble Flou
	cmp r4,#0
	beq  erreursyn2
	@ suivant le type, lecture et traitement de chaque valeur
	mov r0,r8
	ldr r1,iAdrszLibValeurEFTG
	bl comparaison
	mov r0,r9	
	bleq prepEFTG
	beq 2f
	mov r0,r8 
	ldr r1,iAdrszLibValeurEFTD
	bl comparaison
	mov r0,r9	
	bleq prepEFTD
	beq 2f
	mov r0,r8
	ldr r1,iAdrszLibValeurEFTRI
	bl comparaison
	mov r0,r9	
	bleq prepEFTRI
	beq 2f
	mov r0,r8
	ldr r1,iAdrszLibValeurEFTRA
	bl comparaison
	mov r0,r9	
	bleq prepEFTRA
	beq 2f
	b erreursyn2
2:	
    ldr r1,[fp]    @ on recupere le pointeur r1 de la variable
	ldr r3,[r1,#variable_valeurs]
3:
    ldr r4,[r3,#valeur_suivante]
    cmp r4,r3
    movne r3,r4
    bne 3b	
	str r6,[r3,#valeur_nom]
	str r0,[r3,#valeur_Eflou]
	str r10,[r3,#valeur_suivante]
	str r10,[r10,#valeur_suivante]
    add r10,#valeur_fin
	b 1b   @ boucle sur autre valeur 
	
erreursyn2:	
	ldr r0,iAdrszMessErreValeurs
	bl affichageMess  /* affichage message dans console   */
	mov r0,#-1       /* code erreur */	
100:     /* fin standard de la fonction  */
	pop {r1,r3-r9}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
iAdrszMessErreValeurs: .int szMessErreValeurs	
iAdrszLibValeur: .int szLibValeur
iAdrszLibValeurEFTG: .int szLibValeurEFTG
iAdrszLibValeurEFTD: .int szLibValeurEFTD
iAdrszLibValeurEFTRI: .int szLibValeurEFTRI
iAdrszLibValeurEFTRA:  .int szLibValeurEFTRA
/***************************************************/
/*   analyse de la zone Sortie           */
/***************************************************/
/* r9 pointeur controleur  */
/* r2 pointeur  vers buffer */
/* r10 pointeur du tas */ 
analyseSortie:
	push {fp,lr}    /* save des  2 registres frame et retour */
    push {r1,r3-r9}	
	mov fp,sp
	mov r6,r2   @ debut de la zone lue libellée variable
    bl chercheSuite
	cmp r4,#0
	beq  erreursynS1	   @Faudrait  vérifier le libellé!!!!!
	mov r0,r6 
    ldr r1,iAdrszLibVariable
	bl comparaison
	bne erreursynS1    @ erreur
	mov r6,r2   @ debut de la zone lue nom
    bl chercheSuite
	cmp r4,#0
	beq  erreursynS1
	mov r5,r2   @ debut de la zone mini
    bl chercheSuite
	cmp r4,#0
	beq  erreursynS1	
	mov r0,r5
	bl conversionAtoD
	mov r7,r0
	mov r5,r2   @ debut de la zone maxi
    bl chercheSuite
	cmp r4,#0
	beq  erreursynS1	
	mov r0,r5
	bl conversionAtoD
	mov r8,r0
	mov r12,r2    @ save r2
	@ création de la sortie à l'adresse r10 libre
	str r6,[r10,#variable_nom]
	str r7,[r10,#variable_min]
	str r8,[r10,#variable_max]
	str r10,[r9,#controle_sortie]   @ maj pointeur sortie du controleur
	mov r1,r10   @ on garde le pointeur
	add r10,#variable_fin         @ maj pointeur tas
    @ init de la liste des valeurs
	str r10,[r1,#variable_valeurs]
	str r10,[r10,#valeur_suivante]
	add r10,#valeur_fin
	mov r2,r12   @  restaur buffer
	@ et maintenant il faut ajouter chaque valeur
	bl analyseValeurs
	b 100f
erreursynS1:	
	ldr r0,iAdrszMessErreSortie
	bl affichageMess  /* affichage message dans console   */
	mov r0,#-1       /* code erreur */		
100:     /* fin standard de la fonction  */
	pop {r1,r3-r9}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
iAdrszMessErreSortie: .int szMessErreSortie	
iAdrszLibVariable: .int szLibVariable
/***************************************************/
/*   preparation création EFTG           */
/***************************************************/
/* r2 pointeur  vers buffer  */
prepEFTG:
	push {fp,lr}    /* save des  2 registres frame et retour */
	sub sp,#16      /* reserve 16 octets A RENDRE EN FIN DE PROCEDURE*/  
	mov fp,sp    /* fp <- adresse début */
                /* fp contient save point 1 */
				/* fp + 4 save point 2  */
				/* fp + 8 save point 3 */
				/* fp +12 save point 4 */
    push {r3-r6}	
	mov r5,#0
1:	
	mov r6,r2   @ debut de la zone lue 
	add r2,#1
	bl chercheSuite   @ recup valeurs 
	cmp r4,#0
	beq  erreursyn2
	mov r0,r6
    bl conversionAtoD
    str r0,[fp,r5,lsl #2]
	add r5,#1
	cmp r5,#4
	blt 1b
	
	mov r6,r2 
	@ ajout valeur 
	ldr r1,[fp]             @ valeur mini
	ldr r2,[fp,#12]   @ valeur maxi
	ldr r3,[fp,#4]             @ point 1
	ldr r4,[fp,#8]             @ point 2
	bl creationEFTG
	mov r2,r6
	@ r0 retourne le pointeur sur l'ensemble
100:     /* fin standard de la fonction  */
	pop {r3-r6}
	add sp,#16      /* rend les 16 octets reservés */  
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
/***************************************************/
/*   preparation création EFTD           */
/***************************************************/
/* r2 pointeur  vers buffer */
prepEFTD:
	push {fp,lr}    /* save des  2 registres frame et retour */
	sub sp,#16      /* reserve 16 octets A RENDRE EN FIN DE PROCEDURE*/  
	mov fp,sp    /* fp <- adresse début */
                /* fp contient save point 1 */
				/* fp + 4 save point 2  */
				/* fp + 8 save point 3 */
				/* fp +12 save point 4 */
    push {r3-r6}	
	mov r5,#0
1:	
	mov r6,r2   @ debut de la zone lue 
	add r2,#1
	bl chercheSuite   @ recup valeurs 
	cmp r4,#0
	beq  erreursyn2
	mov r0,r6
    bl conversionAtoD
    str r0,[fp,r5,lsl #2]
	add r5,#1
	cmp r5,#4
	blt 1b
	
	mov r6,r2 
	@ ajout valeur 
	ldr r1,[fp]             @ valeur mini
	ldr r2,[fp,#12]   @ valeur maxi
	ldr r3,[fp,#4]             @ point 1
	ldr r4,[fp,#8]             @ point 2
	bl creationEFTD
	mov r2,r6
	@ r0 retourne le pointeur sur l'ensemble
100:     /* fin standard de la fonction  */
	pop {r3-r6}
	add sp,#16      /* rend les 16 octets reservés */  
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
/***************************************************/
/*   preparation création EFTRA           */
/***************************************************/
/* r0 pointeur  vers buffer des regles  */
/* r2 indice caractères */
prepEFTRA:
	push {fp,lr}    /* save des  2 registres frame et retour */
	sub sp,#24      /* reserve 16 octets A RENDRE EN FIN DE PROCEDURE*/  
	mov fp,sp    /* fp <- adresse début */
                /* fp contient save point 1 */
				/* fp + 4 save point 2  */
				/* fp + 8 save point 3 */
				/* fp +12 save point 4 */
				/* fp +16 save point 5 */
				/* fp +20 save point 6 */
    push {r3-r7}	
	mov r5,#0
1:	
	mov r6,r2   @ debut de la zone lue 
	add r2,#1
	bl chercheSuite   @ recup valeurs 
	cmp r4,#0
	beq  erreursyn2
	mov r0,r6
    bl conversionAtoD
    str r0,[fp,r5,lsl #2]
	add r5,#1
	cmp r5,#6
	blt 1b
	mov r7,r2 
	@ ajout valeur 
	ldr r1,[fp]             @ valeur mini
	ldr r2,[fp,#20]   @ valeur maxi
	ldr r3,[fp,#4]             @ point 1
	ldr r4,[fp,#8]             @ point 2
	ldr r5,[fp,#12]             @ point 2
	ldr r6,[fp,#16]             @ point 2
	bl creationEFTRA
	mov r2,r7
	@ r0 retourne le pointeur sur l'ensemble
100:     /* fin standard de la fonction  */
	pop {r3-r7}
	add sp,#24      /* rend les 16 octets reservés */  
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */			
/***************************************************/
/*   preparation création EFTRI           */
/***************************************************/
/* r0 pointeur  vers buffer des regles  */
/* r2 indice caractères */
prepEFTRI:
	push {fp,lr}    /* save des  2 registres frame et retour */
	sub sp,#20      /* reserve 20 octets A RENDRE EN FIN DE PROCEDURE*/  
	mov fp,sp    /* fp <- adresse début */
                /* fp contient save point 1 */
				/* fp + 4 save point 2  */
				/* fp + 8 save point 3 */
				/* fp +12 save point 4 */
				/* fp +16 save point 5 */
    push {r3-r6}	
	mov r5,#0
1:	
	mov r6,r2   @ debut de la zone lue 
	add r2,#1
	bl chercheSuite   @ recup valeurs 
	cmp r4,#0
	beq  erreursyn2
	mov r0,r6
    bl conversionAtoD
    str r0,[fp,r5,lsl #2]
	add r5,#1
	cmp r5,#5    @ 5 données non controlées !!!
	blt 1b
	
	mov r6,r2 
	@ ajout valeur 
	ldr r1,[fp]             @ valeur mini
	ldr r2,[fp,#16]   @ valeur maxi
	ldr r3,[fp,#4]             @ point 1
	ldr r4,[fp,#8]             @ point 2
	ldr r5,[fp,#12]             @ point 3
	bl creationEFTRI
	mov r2,r6
	@ r0 retourne le pointeur sur l'ensemble
100:     /* fin standard de la fonction  */
	pop {r3-r6}
	add sp,#20      /* rend les 20 octets reservés */  
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */			
/***************************************************/
/*   analyse du fichier des regles            */
/***************************************************/
/* r0 pointeur  vers buffer des regles  */
/* r9 pointeur controleur */
/* r2 indice caractères */
analyseRegles:
	push {fp,lr}    /* save des  2 registres frame et retour */
    push {r1-r9}	
1:  @ début de boucle des régles
    bl ajoutRegle
	mov r5,r0    @ save pointeur de la nouvelle regle
	bl elimblanc  
    mov r3,r2   @ debut de la zone lue 
	add r2,#1
    bl chercheSuite
	cmp r4,#0
	moveq r0,#108
	beq  erreursyn
	mov r0,r3
    ldr r1,iAdrszLibSI
	bl comparaison
	movne r0,#108
	bne erreursyn

2:	 @ debut de boucle des prémisses
	@ doit être le début d'une premisse
	mov r3,r2   @ debut du nom 
	add r2,#1
	bl chercheSuite
	@ il faut cherche le EST
    mov r0,r2       @ debut de zone pour EST
	add r2,#1
	bl chercheSuite
	ldr r1,iAdrszLibEST
	bl comparaison
	movne r0,#100
	bne erreursyn

	@ ici on doit etre au debut 2ieme partie
	mov r6,r2     @ pointeur debut nom
	add r2,#1
	bl chercheSuite
	
	@ il faut rechercher la variable linguistique déjà créee
	mov r0,r3   @ save du buffer
	mov r0,r9   @ pointeur du controleur
	mov r1,r3   @ pointeur du nom
	bl rechercheVar
	cmp r0,#0
	moveq r0,#101     @ variable non trouvée
	beq erreursyn
	mov r8,r2   @ save buffer
	mov r1,r0   @ ajout variable trouvée
	mov r0,r5    @ pointeur regle
	mov r2,r6    @ nom
	bl ajoutPremisse
	mov r2,r8   @ restaur buffer
    mov r6,r2
	add r2,#1
	bl chercheSuite
	mov r0,r6
	ldr r1,iAdrszLibET
	bl comparaison
	beq 2b            @ et boucle sur autre premisses
	mov r0,r6
	//bl affichageMess
	ldr r1,iAdrszLibALORS
	bl comparaison
	movne r0,#103
	bne erreursyn
    @ doit être sur le ALORS
	mov r3,r2       @ debut variable
	add r2,#1
	bl chercheSuite
	mov r0,r2       @ recherche le EST
	add r2,#1
	bl chercheSuite
	ldr r1,iAdrszLibEST
	bl comparaison
	movne r0,#104
	bne erreursyn
	mov r6,r2       @ debut nom
	add r2,#1
	bl chercheSuite
	
	@ il faut rechercher la variable linguistique déjà créee
	mov r0,r9   @ pointeur du controleur
	mov r1,r3   @ pointeur du nom
	bl rechercheVar
	cmp r0,#0
	moveq r0,#105     @ variable non trouvée
	beq erreursyn	
	@ que faut il faire ?  creer la conclusion
	str r0,[r10,#expflou_ling]
	str r6,[r10,#expflou_nom]
	str r10,[r5,#regle_conclusion]
	add r10,#expflou_fin
	@ on cherche la ligne suivante
    ldrb r4,[r2]
    cmp r4,#0
    beq 100f     @ fin de fichier

	ldr r3,[r9,#controle_nb_regles]
	add r3,#1
	str r3,[r9,#controle_nb_regles]  @ maj nombre de regles 
	b 1b        @ regle suivante

erreursyn:	/* affichage erreur */
	ldr r1,iAdrszMessErreurSyn   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */
	ldr r0,[r9,#controle_nb_regles]
	add r0,r0,#1
	ldr r1,iAdrnumRegle
	bl conversion10
	ldr r0,iAdrszLibNumRegle
	bl affichageMess  /* affichage message dans console   */
	mov r0,#-1       /* code erreur */	
100:     /* fin standard de la fonction  */
	pop {r1-r9}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
iAdrszMessErreurSyn: .int szMessErreurSyn	
iAdrszLibNumRegle: .int szLibNumRegle
iAdrnumRegle: .int numRegle
iAdrszLibSI: .int szLibSI
iAdrszLibEST: .int szLibEST
iAdrszLibET: .int szLibET
iAdrszLibALORS: .int szLibALORS
/***************************************************/
/*   ajout d'une regle                             */
/***************************************************/
/* r9 pointeur du controleur  */
/* r10 pointeur du tas */
/* r0 retourne le pointeur vers la régle */
ajoutRegle:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r2,r3}
	ldr r2,[r9,#controle_regles]  @ début de liste
1:	
	ldr r0,[r2,#regle_suivante]
	cmp r2,r0
	movne r2,r0
	bne 1b
    str r10,[r2,#regle_suivante]
	str r10,[r10,#regle_suivante]   @ sentinelle
	mov r0,r2
	add r10,#regle_fin
	@ init de la liste des premisses
	str r10,[r2,#regle_premisses]
	str r10,[r10,#expflou_suivante]  @ sentinelle
	add r10,#expflou_fin
	
100:     /* fin standard de la fonction  */
    pop {r2,r3}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
/***************************************************/
/*   ajout d'une premisse                             */
/***************************************************/
/* r0 pointeur de la regle  */
/* r1 pointeur vers la variable */
/* r2 pointeur vers le nom */
/* r10 pointeur du tas */
ajoutPremisse:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r2,r3}
	ldr r3,[r0,#regle_premisses]  @ début de liste
1:	
	ldr r0,[r3,#expflou_suivante]
	cmp r3,r0
	movne r3,r0
	bne 1b
	str r1,[r3,#expflou_ling] 
	str r2,[r3,#expflou_nom]
	str r10,[r3,#expflou_suivante]  @ premisse suivante
	str r10,[r10,#expflou_suivante]  @ sentinelle
	add r10,#expflou_fin               @ maj pointeur du tas
	
100:     /* fin standard de la fonction  */
    pop {r2,r3}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		

/***************************************************/
/*   ajout d'une valeur  numerique                 */
/***************************************************/
/* r0 pointeur vers le controleur  */
/* r1 pointeur vers le nom de la valeur */
/* r2 contient la valeur */
FLOUajoutValeur:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r2,r3,r4,r7,r10}
	ldr r10,[r0,#controle_tas]      @ recup adresse du tas
	
	@ recherche de la variable des entrées correspondant au nom 
	mov r7,r0   @ save controleur
	bl rechercheVar
	cmp r0,#0
	beq erreurVal	@ non trouvée

	ldr r3,[r7,#controle_probleme]  @ début de liste
1:	
	ldr r4,[r3,#valnum_suivante]
	cmp r3,r4
	movne r3,r4
	bne 1b
	str r0,[r3,#valnum_ling] 
	str r2,[r3,#valnum_valeur]
	str r10,[r3,#valnum_suivante]  @ valeur suivante
	str r10,[r10,#valnum_suivante]  @ sentinelle
	add r10,#valnum_fin              @ maj pointeur du tas
    b 100f
erreurVal:	
	ldr r0,iAdrszLibErrRechVal
	bl affichageMess  /* affichage message dans console   */	
100:     /* fin standard de la fonction  */
    str r10,[r7,#controle_tas]      @ maj adresse du tas
    pop {r2,r3,r4,r7,r10}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
iAdrszLibErrRechVal: .int szLibErrRechVal
/***************************************************/
/*   recherche par nom d'une variable linguistique           */
/***************************************************/
/* r0 pointeur du controleur  */
/* r1 pointeur du nom  */
/* r0 retourne le pointeur vers la variable ou null */
rechercheVar:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r2,r3,r4}
	ldr r2,[r0,#controle_entrees]  @ début de listes
	mov r4,r0   @ save controleur
1:
    ldr r3,[r2,#variable_suivante]
	cmp r3,r2
	moveq r0,#0 
	beq 2f
	ldr r0,[r2,#variable_nom]
	bl comparaison
	cmp r0,#0
	moveq r0,r2
	beq 100f
	mov r2,r3
	b 1b
2:	@ non trouvée dans les entrees c'est peut être une sortie
	ldr r2,[r4,#controle_sortie]  
	ldr r0,[r2,#variable_nom]
	//mov r0,r2
	//mov r1,#2  /* nombre de bloc a afficher */
    //push {r0} /* adresse memoire */	
	//push {r1}
    //bl affmemoire
	bl comparaison
	cmp r0,#0
	moveq r0,r2
	movne r0,#0 
	
100:     /* fin standard de la fonction  */
    pop {r2,r3,r4}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
/***************************************************/
/*   recherche par nom d'une valeur linguistique           */
/***************************************************/
/* r0 pointeur de la variable  */
/* r1 pointeur du nom  */
/* r0 retourne le pointeur vers la variable ou null */
rechercheVarValeur:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	push {r2,r3}
	ldr r2,[r0,#variable_valeurs]  @ début de listes
1:
    ldr r3,[r2,#valeur_suivante]
	cmp r3,r2
	moveq r0,#0 
	beq 100f
	ldr r0,[r2,#valeur_nom]
	bl comparaison
	cmp r0,#0
	moveq r0,r2
	beq 100f
	mov r2,r3
	b 1b
100:     /* fin standard de la fonction  */
    pop {r2,r3}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
/************************************/	   
/* affichage des règles             */
/************************************/	  
/* r0 adresse du controleur */
FLOUafficheRegles:
	push {fp,lr}    /* save des  2 registres */
	push {r1-r7}  /* save des registres */
	mov r5,r0
	ldr r6,[r5,#controle_regles]
1:	@ boucle des regles
	ldr r7,[r6,#regle_suivante]
	cmp r6,r7
	beq 100f 
	ldr r0,=szLibTeteRegle
	bl affichageMess  /* affichage message dans console   */
	@ affichage des premisses 
	ldr r3,[r6,#regle_premisses]
	ldr r0,=szLibVide
2:	
	ldr r4,[r3,#expflou_suivante]
	cmp r4,r3
	beq 3f
    ldr r5,[r3,#expflou_ling]
	
	ldr r1,[r5,#variable_nom]
	ldr r2,=sLibZone1
	bl concatChaine
	ldr r0,=sLibZone1
	ldr r1,=szLibEst
	ldr r2,=sLibZone2
	bl concatChaine
	ldr r0,=sLibZone2
	ldr r1,[r3,#expflou_nom]
	ldr r2,=sLibZone1
	bl concatChaine
	ldr r0,=sLibZone1
	ldr r1,=szRetourligne
	ldr r2,=sLibZone2
	bl concatChaine
	ldr r0,=sLibZone2
	bl affichageMess  /* affichage message dans console   */
	ldr r0,=szLibIntregle
	mov r3,r4
	b 2b
3:	
	ldr r3,[r6,#regle_conclusion]
	ldr r4,[r3,#expflou_ling]
	ldr r0,=szLibFinregle
	ldr r1,[r4,#variable_nom]
	ldr r2,=sLibZone1
	bl concatChaine
	ldr r0,=sLibZone1
	ldr r1,=szLibEst
	ldr r2,=sLibZone2
	bl concatChaine
	ldr r0,=sLibZone2
	ldr r1,[r3,#expflou_nom]
	ldr r2,=sLibZone1
	bl concatChaine
	ldr r0,=sLibZone1
	ldr r1,=szRetourligne
	ldr r2,=sLibZone2
	bl concatChaine
	ldr r0,=sLibZone2
	bl affichageMess  /* affichage message dans console   */
	
	@regle suivante
	mov r6,r7
	b 1b
100:
    pop {r1-r7}
	pop {fp,lr}   /* fin procedure */
    bx lr   	
/**********************************************/
/* pour eliminer les blabcs               */	
/* r0 adresse courante d'un caractere du buffer */	
/* utilise r4 */
elimblanc:
1:   
	ldrb r4,[r2]
	cmp r4,#' '         @ elimine les blancs
	addeq r2,#1
	beq 1b
	bx lr  
/**********************************************/
/* pour retrouver la fin d'un mot             */
/* positionne le 0 final */	
/* r2 : adresse courante du buffer de lecture */	
/* utilise r4 */
/* se repositionne sur le premier caractère */
/* different de blanc, de : de retour ligne */
/* mais retourne 00 dans r4 pour la fin de fichier */	
/* et le registre r2 progresse  */
chercheSuite:
	push {fp,lr}    /* save des  2 registres */
1:
    ldrb r4,[r2]
	cmp r4,#' '         @ cherche le premier caracteres blanc
	beq 2f
	cmp r4,#58         @ ou les 2 points
	beq 4f
	cmp r4,#0x0D         @ ou la fin de ligne
	beq 3f
	cmp r4,#0        @ ou la fin de fichier
	beq 100f
    add r2,#1    @ sinon on boucle sur le caractère suivant
    b 1b
2:	 @ caractère blanc
    mov r4,#0
    strb r4,[r2]   @ fin de chaine
	add r2,#1    @ caractère suivant
	bl elimblanc
21:
	@ et on peut retomber sur une fin de ligne ou fin de fichier
	cmp r4,#0         @ ou la fin de fichier
	beq 100f
	cmp r4,#0x0D         @ ou la fin de ligne
	beq 31f
	cmp r4,#58         @ ou les 2 points
	addeq r2,#1       @ donc on l'elimine
	bleq elimblanc  @ et les blancs eventuels
	b 100f
3: @ fin de ligne
    mov r4,#0
    strb r4,[r2]   @ fin de chaine
31:
	add r2,#2    @ pour eliminer le 0D0A
	bl elimblanc
	b 100f 	
4:  @ 2 points
	mov r4,#0
    strb r4,[r2]   @ fin de chaine
	add r2,#1    @ pour eliminer le :
	bl elimblanc
	b 21b	
100:
	pop {fp,lr}   /* fin procedure */
	bx lr  

/********************************************************************/
/*********************************************/
/*constantes */
/********************************************/ 
.include "../constantesARM.inc"	
/*********************************************/

	