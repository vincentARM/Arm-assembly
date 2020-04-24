/* Exemple programme assembleur ARM Raspberry PI */
/* Auteur  : Vincent Leboulou            */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* Systeme expert  */
/* lecture des regles depuis un fichier */
/* A lancer par nomprogramme nomfichierregles */
/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/
.equ TAILLEBUF, 50000   @ taille du buffer de lecture du fichier des règles
.equ TAILLEBUF1, 80     @ taille buffer pour saisie des valeurs internes
.equ NBFAITS,   100    @ nombre de faits possibles
.equ NBREGLES,   100    @ nombre de regles possibles
.equ NBPREMISSES, 5   @ nombre de prémisses MAXI pour une regle
.equ DEBUG, 0       @ 1 pour afficher tous les faits sinon 0
.equ LGZONENOM,25  @ longueur zone nom pour l'affichage
/***************************************************/
/* structure des faits */	
    .struct  0
fait_nom:	          @ pointeur vers nom
    .struct fait_nom + 4
fait_valeur:	           @ si logique = 0 ou -1 autrement valeur entière
    .struct fait_valeur + 4	 
fait_niveau:	           
    .struct fait_niveau + 4	
fait_type:	               @ fait logique = 0 fait entier = 1
    .struct fait_type + 4	
fait_question:	    @ pointeur vers question     
    .struct fait_question + 4	
fait_fin:	            @ donne la taille de la structure
/***************************************************/
/* structure des regles */	
    .struct  0
regle_nom:	           @ pointeur vers nom
    .struct regle_nom + 4
regle_nbpremisses:	    @ nombre de premisses
    .struct regle_nbpremisses + 4
regle_premisses:	     @ pointeur vers liste de premisses   
    .struct regle_premisses + 4	
regle_conclusion:	      @ pointeur vers un fait    
    .struct regle_conclusion + 4	
regle_fin:	             @ donne la taille de la structure
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne: .asciz  "\n"
/* Libelles Faits */
szLibFait: 
sFnom:  		 .fill LGZONENOM, 1, ' ' 
				.ascii " = "
sFvaleur: 	.fill 15, 1, ' ' 
				.ascii " ("
sFniveau: 	.fill 15,1, ' '
				.asciz ") \n" 	
szLibSol:
sSnom:	 		.fill LGZONENOM, 1, ' ' 
				.ascii " ("
sSniveau: 	.fill 15,1, ' '
				.asciz ") \n" 		
/* Libelles Regles */
szLibTeteRegle:		
sRnom:   			.fill 10, 1, ' ' 
					.asciz " : SI ("		
szLibIntregle: 	.asciz "              ET "
szLibFinregle: 	.asciz "                              ) ALORS "
szLibFinconclusion:   .asciz " \n" 
szLibNumRegle:   .ascii "Règle N° "
numRegle:         .fill 10, 1, ' ' 
                     .asciz " \n"                     

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
NbFaits:  		.skip 4   @ nombre de faits
PtFaits:  		.skip 4   @ pointeur vers la prochaine place vide 
NbRegles: 		.skip 4   @ nombre de regles
PtRegles:  		.skip 4   @ pointeur vers la fin de la base regles
PtCopieRegles: 	.skip 4   @ pointeur vers la prochaine place vide 
NbCopieRegles: 	.skip 4   @ nombre de regles base copiée 
PtPremisses:		.skip 4   @ pointeur vers la prochaine place vide 
PtConclusions: 	.skip 4   @ pointeur vers la prochaine place vide 
sBuffer1:   		.skip TAILLEBUF1 
sBuffer:   		.skip TAILLEBUF    @ remarque ce buffer sert de zones de travail 
.align 4
BaseFaits: 		.skip fait_fin * NBFAITS
BaseRegles: 		.skip regle_fin * NBREGLES
CopieBaseRegles: .skip regle_fin * NBREGLES
Premisses:  		.skip fait_fin * NBPREMISSES * NBREGLES
Conclusions: 	.skip fait_fin * NBREGLES

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main      /* 'main' point d'entrée doit être  global */

main:             /* programme principal */
    push {fp,lr}    /* save des  2 registres */
	add fp,sp,#8    /* fp <- adresse début */
	ldr r0,=szMessDebutPgm   /* r0 ← adresse message debut */
	bl affichageMess  /* affichage message dans console   */
	ldr r0,[fp]    /*recup du nombre de parametres de la ligne de commande */
	cmp r0,#1
	ble erreurCom  /* ligne de commande vide */ 
	add r1,fp,#8  /* recup adresse du deuxieme parametre */
    ldr r0,[r1]   /* Donc le nom du fichier à ouvrir */
	bl lectureRegles
	cmp r0,#-1
	beq erreur       @ erreur traitement fichier
    /* Creation base faits */
	ldr r0,=BaseFaits
	ldr r1,=PtFaits
	str r0,[r1]
	ldr r1,=NbFaits
	mov r0,#0
	str r0,[r1]
	/* Creation base régles */
	ldr r0,=BaseRegles
	ldr r1,=PtRegles
	str r0,[r1]
	ldr r1,=NbRegles
	mov r0,#0
	str r0,[r1]
	/* init des premisses */
	ldr r0,=Premisses
	ldr r1,=PtPremisses
	str r0,[r1]
	/* init des conclusions */
	ldr r0,=Conclusions
	ldr r1,=PtConclusions
	str r0,[r1]

	
	/* Ajout des régles dans la base */
	ldr r0,=sBuffer
	ldr r1,=BaseRegles
	bl analyseRegles
	cmp r0,#-1
    beq erreur
	
	/* Affichage des règles pour controle */
	ldr r0,=szMessAffRegles
	bl affichageMess  /* affichage message dans console   */
	ldr r0,=BaseRegles
	bl afficheRegles

    @ résolution par application des règles
	@ éventuellement mettre une boucle pour effectuer plusieurs résolutions
	ldr r0,=szMessResolution
	bl affichageMess  /* affichage message dans console   */
	bl resoudre
	
finnormale:	
    ldr r0,=szMessFinOK   /* r0 ← adresse chaine */
	bl affichageMess  /* affichage message dans console   */
	mov r0,#0     /* code retour OK */
	b 100f
erreur:	/* affichage erreur */
	ldr r1,=szMessErreur   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */		
	mov r0,#1       /* code erreur */
	b 100f	
erreurCom:	/* affichage erreur */
	ldr r1,=szMessErreurCom   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */		
	mov r0,#1       /* code erreur */
	b 100f		
100:		/* fin de programme standard  */
	pop {fp,lr}   /* restaur des  2 registres */
	mov r7, #EXIT /* appel fonction systeme pour terminer */
    swi 0 
/************************************/	   

szMessErreur: .asciz "Erreur rencontrée.\n"
szMessErreurCom: .asciz "Ligne de commande vide.\n"
szMessDebutPgm: .asciz "Début du programme. \n"
szMessAffRegles: .asciz "Affichage des règles : \n"
szMessResolution: .asciz "*********** Résolution ***********\n"
szMessFinOK: .asciz "Fin normale du programme. \n"
.align 4     /* alignement car l'étiquette de la routine suivante doit être alignée */
/***************************************************/
/*   Lecture du fichier des regles                 */
/***************************************************/
/* r0 pointeur sur le nom du fichier à ouvrir */
/* pas de save des registres */
lectureRegles:
	push {fp,lr}    /* save des  2 registres frame et retour */
	
	mov r1,#O_RDWR   /*  flags    */
	mov r2,#0   /* mode */
	mov r7, #OPEN /* appel fonction systeme pour ouvrir */
    swi #0 
	cmp r0,#0    /* si erreur retourne -1 */
	ble erreurOuv
	mov r8,r0    /* save du Fd */ 
	/* lecture r0 contient le FD du fichier */
	ldr r1,=sBuffer   /*  adresse du buffer de reception    */
	ldr r2,=TAILLEBUF   /* nb de caracteres  */
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
	ldr r1,=szMessErreurOUV   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */		
	mov r0,#-1       /* code erreur */
	b 100f	
erreurFerm: /* affichage erreur */
	ldr r1,=szMessErreurFERM   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */		
	mov r0,#-1       /* code erreur */
	b 100f		
erreurLect: /* affichage erreur */
	ldr r1,=szMessErreurLECT   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */		
	mov r0,#-1       /* code erreur */
	b 100f		
100:   
   /* fin standard de la fonction  */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
szMessErreurOUV: .asciz "Erreur ouverture fichier.\n"
szMessErreurFERM: .asciz "Erreur fermeture fichier.\n"
szMessErreurLECT: .asciz "Erreur lecture fichier.\n"
.align 4     /* alignement car l'étiquette de la routine suivante doit être alignée */
/***************************************************/
/*   Moteur inferences   procèdure resoudre            */
/***************************************************/
/* r0 pointeur bases regles
/* r1 pointeur bases faits */
resoudre:
	push {fp,lr}    /* save des  2 registres frame et retour */
	push {r0,r5}
	@ recopie des regles
	ldr r2,=NbRegles
	ldr r2,[r2]
	ldr r3,=NbCopieRegles
	str r2,[r3]                @ nombre de regles
	ldr r0,=BaseRegles      @ base regles origine
	ldr r1,=CopieBaseRegles @ base regles destination
	mov r6,#regle_fin      @ taille d'une  regle
	mul r3,r2,r6         @ multiplié par le nombre de regle
	ldr r5,=PtCopieRegles   @ maj du pointeur de fin
	add r4,r1,r3               @ debut de base + taille 
	str r4,[r5]
1: @ boucle de recopie des regles
	ldrb r4,[r0,r3]       @ lecture d'un octet de la base depart 
	strb r4,[r1,r3]       @ stockage dans base destination
	subs r3,#1          @ octet précedent
	bge 1b              @ si pas negatif on boucle
   
   @ vider la base des faits
	ldr r0,=BaseFaits
	ldr r1,=PtFaits     @ maj pointeur faits au début base faits
	str r0,[r1]
	ldr r1,=NbFaits     @ raz compteur de faits
	mov r0,#0
	str r0,[r1]
  
 2: @ boucle des regles
    ldr r0,=CopieBaseRegles
	bl trouverRegle    @ trouver une regle applicable
    cmp r0,#-1    @ pas de regle
    beq 4f
    mov r6,r0    @ niveau
	mov r7,r2    @ rang regle
    @ appliquer la regle
    ldr r2,[r1,#regle_conclusion]
    @ ajouter la conclusion à la base des faits
    ldr r4,=PtFaits
    ldr r5,[r4]
    ldr r0,[r2,#fait_valeur]
    str r0,[r5,#fait_valeur]
    ldr r0,[r2,#fait_nom]	
    str r0,[r5,#fait_nom]
    ldr r0,[r2,#fait_type]
    str r0,[r5,#fait_type]
    add r0,r6,#1                @ +1 dans le niveau maxi récupéré
    str r0,[r5,#fait_niveau]
    ldr r0,[r2,#fait_question]
    str r0,[r5,#fait_question]
    add r5,#fait_fin
    str r5,[r4]
	ldr r4,=NbFaits     @ maj du nombre de faits
	ldr r5,[r4]
	add r5,#1
	str r5,[r4]
    @enlever la regle en recopiant la dernière à l'emplacement
    ldr r2,=NbCopieRegles
    ldr r3,[r2]
    mov r4,#regle_fin
    add r7,#1
    mul r3,r4
    mul r7,r4
    ldr r0,=CopieBaseRegles
3:  
	ldrb r5,[r0,r3]
	strb r5,[r0,r7]
	sub r3,#1
	sub r7,#1
	subs r4,#1
	bge 3b
	ldr r3,[r2]   @ maj nombre de regles
	sub r3,#1
	str r3,[r2]
	@ boucle sur autre regle
	ldr r0,=CopieBaseRegles
	cmp r3,#0
	bgt 2b
   
 4:  
	@ afficher les faits après tri par niveau
	ldr r0,=BaseFaits
	ldr r1,=NbFaits
	ldr r1,[r1]
	bl triInsertion     @ tri des faits
	
	ldr r0,=BaseFaits    @ et affichage du résultat
	bl afficherBaseFait
 	 
100:    /* fin standard de la fonction  */
    pop {r0,r5}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */
/***************************************************/
/*   chercher et trouver une regle applicable             */
/***************************************************/
/* r0 pointeur base copiée */
trouverRegle:
    push {fp,lr}    /* save des  2 registres frame et retour */
    push {r3-r5}
	mov r4,r0
	ldr r5,=NbCopieRegles
	ldr r5,[r5]
	mov r2,#0       @ indice de recherche 
	mov r3,#regle_fin   @ taille d'un poste
1:   @ boucle de traitement des règles
    mul r0,r2,r3	  @ calcul du pointeur correspondant à l'indice
	add r1,r0,r4      @ ajout début de table 
	mov r0,r1
	bl estApplicable   @ la regle s'applique -t-elle ?
	cmp r0,#-1
	bne 2f
	add r2,#1  @ regle suivante
	cmp r2,r5
	blt 1b
	mov r0,#-1
	b 100f
2:   @regle trouvée	
     @ r0 contient le niveau retourné par estApplicable
	 @ r1 le pointeur
	 @ r2 le rang

100:     /* fin standard de la fonction  */
    pop {r3-r5}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */   	
/***************************************************/
/*   verifier que la regle est bien applicable            */
/***************************************************/
/* r0 pointeur regle */
estApplicable:
	push {fp,lr}    /* save des  2 registres frame et retour */
	push {r1-r6}
	mov r5,r0  @ save pointeur
	mov r6,#-1    @ contiendra le niveau le plus haut
	@ balayage des premisses
	ldr r2,[r0,#regle_premisses]
	ldr r3,[r0,#regle_nbpremisses]
1:
	ldr r0,[r2,#fait_nom] 
	@ avec le nom chercher dans la base des faits
	ldr r1,=BaseFaits
	bl chercherFait
	@ si non trouve
	cmp r0,#0
	bne 3f
	@ et si question, on pose la question
	ldr r0,[r2,#fait_question]   @ pointeur question
	cmp r0,#0                     @ si zéro pas de question
	moveq r0,#-1            @ A REVOIR 
	beq 100f                @ on retourne moins 1
	ldr r1,[r2,#fait_type]    
	bl demanderValeur         @ appel avec r0 question et r1 type
	@ et on stocke le fait
2:  
	@ r0 contient la valeur ou 0
	ldr r4,=PtFaits
	ldr r5,[r4]
    str r0,[r5,#fait_valeur]
    ldr r0,[r2,#fait_nom]
    str r0,[r5,#fait_nom]
    ldr r0,[r2,#fait_type]
    str r0,[r5,#fait_type]
    mov r0,#0
    str r0,[r5,#fait_niveau]
    str r0,[r5,#fait_question]
    mov r0,r5
    //bl vidtousregistres
    add r5,#fait_fin
    str r5,[r4]
   	ldr r4,=NbFaits
	ldr r5,[r4]
	add r5,#1
	str r5,[r4]
3:   @ ici a verifier les 2 cas r0 doit contenir le pointeur trouve ou cree
   @ mais a-til la meme valeur que celle attendue par la premisse
   ldr r1,[r0,#fait_valeur]
   ldr r4,[r2,#fait_valeur]
   //bl vidtousregistres
   cmp r1,r4
   @ si non on retourne -1
   movne r0,#-1
   bne 100f
   @ si oui on prend le plus haut niveau
   ldr r1,[r0,#fait_niveau]
   cmp r1,r6
   movgt r6,r1
   @ et on boucle sur autre premisse
   add r2,#fait_fin
    //bl vidtousregistres
   subs r3,#1    @ moins 1 dans le nb de premisses
   bne 1b      @ s'il en reste on boucle
   
   @ sinon on retourne le niveau 
   mov r0,r6 
   //bl vidtousregistres
100:   
   /* fin standard de la fonction  */
    pop {r1-r6}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */   
/***************************************************/
/*   Demander la valeur d'un fait                 */
/***************************************************/
/* r0 pointeur question */
/*  r1 nature du fait */
demanderValeur:
    push {fp,lr}    /* save des  2 registres frame et retour */
    push {r1-r3,r7}
	mov r3,r1
    bl affichageMess  /* affichage question dans console   */
	cmp r3,#0  
	ldreq r0,=szMessCpl
	bleq affichageMess  /* affichage oui/non dans console   */
    @ attente reponse
    mov r0,#0
	ldr r1,=sBuffer1  /* adresse du buffer de saisie */
	mov r2,#TAILLEBUF1  /* taille buffer */
	mov r7, #READ /* Appel system pour lecture saisie clavier */
    swi #0 
	cmp r0,#0
	ble erreursaisie
	cmp r3,#0    
	beq 1f   @ fait entier convertion nombre saisi
	ldr r0,=sBuffer1
	bl conversionAtoD   @ conversion saisie
	b 100f 
1:
    ldr r1,=sBuffer1
    ldrb r2,[r1]	
	cmp r2,#'O'
	moveq r0,#0
	beq 100f
	cmp r2,#'o'
	moveq r0,#0
	beq 100f
	mov r0,#-1
    b 100f
erreursaisie:
	ldr r1,=szMessErreurSai   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */		
	mov r0,#0       /*  retourne 0 */
	b 100f	
100:     /* fin standard de la fonction  */
    pop {r1-r3,r7}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */ 
szMessCpl: .asciz "\n (O ou N) ? : "	
szMessErreurSai: .asciz "Erreur de saisie. \n"
.align 4	
/***************************************************/
/*   ajout fait à la base des faits             */
/***************************************************/
/* r1 pointeur nom */
/* r2 valeur     */
/* r3 niveau     */
/* r4 pointeur question */
//ajoutFait:
//   push {fp,lr}    /* save des  2 registres frame et retour */
//   push {r0,r5}
//   ldr r5,=PtFaits
//   ldr r0,[r5]
//   bl majFait
//   add r0,#fait_fin
//   str r0,[r5] 
//100:   
   /* fin standard de la fonction  */
//    pop {r0,r5}
 //  	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
//    bx lr                   /* retour de la fonction en utilisant lr  */

/***************************************************/
/*   maj fait              */
/***************************************************/
/* r0 pointeur fait */
/* r1 pointeur nom */
/* r2 valeur     */
/* r3 niveau     */
/* r4 pointeur question */
//majFait:
//   push {fp,lr}    /* save des  2 registres frame et retour */
//   str r1,[r0,#fait_nom]
//   str r2,[r0,#fait_valeur]
//   str r3,[r0,#fait_niveau]
//   str r4,[r0,#fait_question]
//100:   
   /* fin standard de la fonction  */
//   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
//    bx lr                   /* retour de la fonction en utilisant lr  */
/***************************************************/
/*   affichage d'un fait              */
/***************************************************/
/* r0 pointeur Base fait */
afficherBaseFait:
    push {fp,lr}    /* save des  2 registres frame et retour */
    push  {r0-r6}
	mov r2,r0
	mov r6,#DEBUG
    ldr r0,=szMessDebBaseFait
    bl affichageMess  /* affichage message dans console   */
	ldr r5,=sSnom
1:	@ debut de boucle des faits
    ldr r0,[r2,#fait_nom]	
    mov r4,#0
2:    @ recopie du nom dans la zone d'affichage
    ldrb r3,[r0,r4]
    cmp r3,#0     @ fin de chaine
    beq 3f
    strb r3,[r5,r4]    
    add r4,#1
    b 2b
3:            @ on complete la zone d'affichage avec des blancs
    mov r3,#' '
	strb r3,[r5,r4] 
    add r4,#1
    cmp r4,#LGZONENOM
    blt 3b	
    @ conversion du niveau
    ldr r0,[r2,#fait_niveau]
	cmp r6,#1        @ si DEBUG
	beq  4f
	cmp r0,#0     @ pas d'impression niveau 0  sauf si DEBUG
	ble 5f
4:	
    ldr r1,=sSniveau
    bl conversion10 
	ldr r0,=szLibSol
	bl affichageMess  /* affichage message dans console   */
5: 	
    add r2,#fait_fin   @ ajout taille du poste au pointeur des faits
    ldr r1,[r2,#fait_nom]	@ reste-t-il un fait à afficher ?
    cmp r1,#0      @ si oui on boucle
	bne 1b
   
100:   
   /* fin standard de la fonction  */
    pop {r0-r6}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
szMessDebBaseFait: .asciz "\nSolution(s) trouvée(s) : \n"	
.align 2
/***************************************************/
/*   affichage d'un fait                           */
/***************************************************/
/* r0 pointeur fait */
afficheFait:
	push {fp,lr}    /* save des  2 registres frame et retour */
	push {r0-r5}
	@ copie du nom dans la zone d'affichage
	ldr r1,[r0,#fait_nom]
	ldr r2,=sFnom
	mov r4,#0
1: 
	ldrb r3,[r1,r4]
	cmp r3,#0
	beq 2f
	strb r3,[r2,r4]    
	add r4,#1
	b 1b
2:  @ complement par des blancs
    mov r3,#' '
	//add r4,#1
3:
	strb r3,[r2,r4] 
    add r4,#1	
	cmp r4,#LGZONENOM
	blt 3b
	@ conversion de la valeur
	mov r2,r0  @ save r0
	ldr r0,[r0,#fait_valeur]
	ldr r1,=sFvaleur
	bl conversion10 
	@ conversion du niveau
	ldr r0,[r2,#fait_niveau]
	ldr r1,=sFniveau
	bl conversion10 
	ldr r0,=szLibFait
	bl affichageMess  /* affichage message dans console   */
 
100:   /* fin standard de la fonction  */
    pop {r0-r5}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */
/***************************************************/
/*   recherche d'un fait dans la base              */
/***************************************************/
/* r0 pointeur  nom fait  à rechercher */
/* r1 pointeur vers base des faits  */
chercherFait:
	push {fp,lr}    /* save des  2 registres frame et retour */
	push {r1-r2}
	mov r2,r1   @ save r1  pointeur base
	mov r1,r0   @ car invariable nom a chercher
1:   
	ldr r0,[r2,#fait_nom]    @ recup pointeur nom
	cmp r0,#0    @ fin du tableau si zero
	beq 100f    @ on retourne zero
	bl Comparaison  @ sinon on compare r0 et r1
	cmp r0,#0         @ egalité
	addne r2,#fait_fin  @ non on boucle au fait suivant
	bne 1b
    @ trouvé don on retourne le pointeur du fait
	mov r0,r2   
  
100:   
   /* fin standard de la fonction  */
    pop {r1-r2}
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */
 
/***************************************************/
/*   Affichage des regles de la base règle         */
/***************************************************/
/* r0 pointeur  vers base regle  */
afficheRegles:
	push {fp,lr}    /* save des  2 registres frame et retour */
	push {r0-r7}  /* save des registres */ 
    ldr r7,=NbRegles
	ldr r7,[r7]      @ compteur de règles
	mov r5,r0  @ save r0
1:  @ debut de boucle des règles
    @ recopie du nom de la regle
	ldr r1,[r5,#regle_nom]
	ldr r2,=sRnom
	mov r4,#0       @ compteur
2:  @ boucle de copie des caractères 
	ldrb r3,[r1,r4]
	cmp r3,#0
	beq 3f
	strb r3,[r2,r4]
	add r4,#1
	b 2b 
3:   
    ldr r0,=szLibTeteRegle
    bl affichageMess  /* affichage message dans console   */
    @ il faut afficher les premisses
    ldr r6,[r5,#regle_nbpremisses]     @ nombre de prémisses de la regle
    ldr r0,[r5,#regle_premisses]        @ pointeur début des prémisses
4:	
    bl afficheFait
	add r0,#fait_fin
	subs r6,#1
	ble 5f
	mov r2,r0
	ldr r0,=szLibIntregle
	bl affichageMess
	mov r0,r2
	b 4b
5:	
    ldr r0,=szLibFinregle
    bl affichageMess  /* affichage message dans console   */
	@ affichage de la conclusion
	ldr r0,[r5,#regle_conclusion]
	ldr r0,[r0,#fait_nom]
	bl affichageMess  /* affichage message dans console   */
	ldr r0,=szLibFinconclusion
    bl affichageMess  /* affichage message dans console   */
	
	add r5,#regle_fin  @ règle suivante
	subs r7,#1         @ reste des regles ?
	bgt 1b          @ boucle 
	
100:    /* fin standard de la fonction  */
    pop {r0-r7}  
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */   
/***************************************************/
/*   analyse du fichier des regles            */
/***************************************************/
/* r0 pointeur  vers buffer des regles  */
/* r1 pointeur vers début base règles   */
analyseRegles:
	push {fp,lr}    /* save des  2 registres frame et retour */	
	mov r5,r1    @ save BaseRegles
	mov r2,#0    @ indice caractère
1:   
	ldrb r4,[r0,r2]
	cmp r4,#' '         @ elimine les blancs
	addne r9,r0,r2    @ debut du nom de la regle
	bne 2f
	add r2,#1
	b 1b 
 
2:   @ recherche fin du nom
	add r2,#1
	ldrb r4,[r0,r2]
	cmp r4,#' '
	bne 2b
	mov r4,#0        @ ajout fin de chaine
	strb r4,[r0,r2]

3: @ saut des blancs jusqu'au SI
	add r2,#1
	ldrb r4,[r0,r2]
	cmp r4,#' '
	beq 3b 
	cmp r4,#':'  @ on saute aussi le : après le nom
	beq 3b
	cmp r4,#'S'   @ erreur si le caractère trouvée n'est pas un S
    movne r0,#100  
	bne erreursyn
	add r2,#1     
	ldrb r4,[r0,r2]
	cmp r4,#'I'     @ erreur si le caractère suivant n'est pas un I
	movne r0,#101     
	bne erreursyn
	ldr r3,=PtPremisses
	ldr r6,[r3]    @ on garde le début des premisses
	//bl vidtousregistres
	mov r12,#0
	@ Debut de boucle d'analyse des premisses
4:  @ saut des blancs jusqu'au début premisses
	add r2,#1
	ldrb r4,[r0,r2]
	cmp r4,#' '
	beq 4b 
	cmp r4,#'('  @ elimination parenthése entrante
	addeq r2,#1
	// bl vidtousregistres  
	@ chercher les premisses  avec r0 et r2

5:  
	ldr r3,=PtPremisses
	bl ajoutPremisse
	add r12,#1
	ldrb r4,[r0,r2]   @ on recupere le dernier caractère lu
	cmp r4,#'A'        @ c'est la fin des premisses
	beq 6f
	//mov r11,#0x94
	//bl vidtousregistres  
	cmp r4,#'E'        @ c'est peut être un ET ?
	movne r0,#102     @ sinon c'est une erreur
	bne erreursyn
	// mov r11,#0x94
	//bl vidtousregistres  
	add r2,#2      @ elimination du ET
	b 4b      @ et boucle pour autre premisses
	
6:  @ chercher la conclusion  
	@ ici r6 contient le pointeur de debut des premisses
	@ et r12 le nombre de premisses
	add r2,#5      @ elimination du ALORS
7: @ saut des blancs jusqu'au début conclusion
	add r2,#1
	ldrb r4,[r0,r2]
	cmp r4,#' '
	beq 7b   
	@ traiter la conclusion
	mov r8,r0   @ save r0
	bl ajout_conclusion
	//bl vidtousregistres
	@ stocker les donnees dans la base des regles
	str r9,[r5,#regle_nom] 
	str r12,[r5,#regle_nbpremisses]
	str r6,[r5,#regle_premisses]
	str r0,[r5,#regle_conclusion]
	@ mettre à jour les pointeurs
	add r5,#regle_fin
	ldr r0,=PtRegles
	str r5,[r0]
	ldr r0,=NbRegles
	ldr r1,[r0]
	add r1,#1
	str r1,[r0]     @ maj compteur de regles
  
	@ normalement r5 pointe sur la dernière regle
	mov r0,r8   @ restaur adresse buffer
	ldrb r4,[r0,r2]   @ ici on doit être soit en debut de regle soit sur le 00 de fin de fichier
    //bl vidtousregistres
	cmp r4,#0
	bne 1b        @ si pas fin de fichier on boucle
    mov r0,#0       @ retour OK
	b 100f
erreursyn:	/* affichage erreur */
    ldr r5,=NbRegles
	ldr r5,[r5]
	ldr r1,=szMessErreurSyn   /* r0 <- code erreur, r1 <- adresse chaine */
    bl   afficheerreur   /*appel affichage message  */
	ldr r0,=NbRegles
	ldr r0,[r0]
	add r0,r0,#1
	ldr r1,=numRegle
	bl conversion10
	ldr r0,=szLibNumRegle
	bl affichageMess  /* affichage message dans console   */
	mov r0,#-1       /* code erreur */
	b 100f	 
100:   
   /* fin standard de la fonction  */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */
szMessErreurSyn: .asciz "Erreur de syntaxe sur une régle.\n"
.align 4	
/************************************/	   
/* ajout premisses dans la base des faits  */
/************************************/	  
/* r0 contient le pointeur du debut du libelle de la regle */
/* r1 contient le pointeur de l'adresse vide du tas */
/* r2 contient l'indice du caractère courant */
/* r3 contient le pointeur vers position vide des premisses */
/* retour 0 dans r0 si egalite */
ajoutPremisse:
	push {fp,lr}    /* save des  2 registres */
	push {r3-r12}  /* save des registres */
	@ ici on doit être en debut de premisse
	mov r8,#0    @ valeur par defaut fait boolean   1 pour entier
	mov r9,#0    @ valeur par defaut du fait (ou true pour boolean)
	mov r7,#0    @ adresse de la question
    add r6,r0,r2     @ save du debut du nom du fait
 1:  @ boucle recherche fin du nom 
    ldrb r4,[r0,r2]
    cmp r4,#' '
    beq 2f
	cmp r4,#')'
    beq 2f
    cmp r4,#'='
    beq 3f
 	cmp r4,#'!'
    beq 4f
	add r2,#1
	b 1b
2:   @ fin du nom du fait   mais attention il peut y avoir un blanc intermediaire
      @ donc on n'autorise pas les blancs dans les mots clés    
    mov r5,r4	  
	mov r4,#0
	strb r4,[r0,r2]
	add r2,#1  @ pour avancer sur le caractère suivant
	ldrb r4,[r0,r2]
	cmp r4,#')'
	addeq r2,#1   @ pour eliminer parenthése 
	b suiteAnalyse
3:
	@ fin du nom du fait de type entier
	mov r8,#1          @ type entier
	mov r4,#0
	strb r4,[r0,r2]       @ remplace le = par le 0 final
	add r2,#1   @ elimine le = 
	add r10,r0,r2
 31:  @ recherche blanc
    ldrb r4,[r0,r2]
	cmp r4,#' '      @ ATTENTION si valeur collée à la suite ==> pb
	beq 32f
	add r2,#1
	b 31b
32:	
	mov r4,#0
	strb r4,[r0,r2]   @ on force zero pour fin de la valeur à decoder
   @ conversion valeur
   mov r11,r0  @ save r0
   mov r0,r10
   bl conversionAtoD
   mov r9,r0
   mov r0,r11   @ restaur r0
   add r2,#1
   b suiteAnalyse
4:   @ valeur boolean false
     mov r9,#-1
	 add r2,#1       @ elimine le !
	 add r6,r0,r2     @ save du debut du nom du fait moins le !
	 b 1b
suiteAnalyse:
    ldrb r4,[r0,r2]     @ élimination des blancs
    cmp r4,#' '
    bne 8f
    add r2,#1
    b suiteAnalyse
8:
    cmp r4,#'('    @ est ce une question ?
    bne 11f
	@  recup question
	 add r2,#1    @ elimination de (
	 add r7,r0,r2    @ début de la question
9:
    ldrb r4,[r0,r2]
	cmp r4,#')'
	//addeq r2,#1
	beq 10f
	add r2,#1
	b 9b
10:
    mov r4,#0
	strb r4,[r0,r2]      @ 0 final pour la question
	add r2,#1           @ caractère suivant
    ldrb r4,[r0,r2]
    cmp r4,#')'   @ pour eliminer 2ieme parenthese eventuelle
	addeq r2,#1

11: @ 	elimination des blancs
    ldrb r4,[r0,r2]
	cmp r4,#' '
	addeq r2,#1
	beq 11b
	
    @ ici on doit être sur le E du ET ou le A de ALORS
	@ creation de la premisse 
	ldr r5,[r3]
    str r6,[r5,#fait_nom]
    str r8,[r5,#fait_type]
    str r9,[r5,#fait_valeur]	
	str r7,[r5,#fait_question]
	mov r4,#0
	str r4,[r5,#fait_niveau]
	add r5,#fait_fin  
	str r5,[r3]       @ mise a jour du pointeur premisses
	add r12,#1     @ nombre de premisses
	
100:
    pop {r3-r12}
	pop {fp,lr}   /* fin procedure */
    bx lr   
/************************************/	   
/* ajout conclusion                 */
/************************************/	  
/* r0 et r2 contiennent l'adresse et la position du caractère courant */
/* retour pointeur dans r0 */
ajout_conclusion:
	push {fp,lr}    /* save des  2 registres */
	add fp,sp,#8    /* fp <- adresse début */
	push {r1,r3,r4}  /* save des registres */
	@ on va utiliser simplement le pointeur vers la fin de la regle pour le nom
	@ de la conclusion
	ldr r1,=PtConclusions
	ldr r3,[r1]
	add r4,r0,r2
	str r4,[r3,#fait_nom]
	@ recherche fin de conclusion
1: 
    add r2,#1
    ldrb r4,[r0,r2]
    cmp r4,#' '
    beq 2f
	cmp r4,#0x0D       @ fin de ligne du fichier
	beq 3f
	cmp r4,#0           @ fin du fichier
	beq 4f              @ fin de conclusion = fin du fichier le 0 final est ok
	b 1b               @ boucle autre caractères
2: 	
    mov r4,#0
    strb r4,[r0,r2]     @ on remplace les blancs par 0 pour fin de chaine
    b 1b         @ et on boucle pour trouver la fin de ligne 
	
3: 
    mov r4,#0
    strb r4,[r0,r2]     @ on remplace 0D par 0 pour fin de chaine
    add r2,#2          @ et on avance de 2 caractères (OD0A) pour soit ligne suivante soit fin fichier	
4:  @ stockage conclusion
	mov r4,#0               @ toutes les autres données sont à zero
	str r4,[r3,#fait_valeur]
	str r4,[r3,#fait_niveau]
	str r4,[r3,#fait_type]
	str r4,[r3,#fait_question]
	mov r0,r3    @ pour retourner le pointeur 
	add r3,#fait_fin
	str r3,[r1]  @ mise à jour du pointeur prochaine position libre conclusion
	
100:
    pop {r1,r3,r4}
	pop {fp,lr}   /* fin procedure */
    bx lr   	
/************************************/	   
/* comparaison de chaines           */
/************************************/	  
/* r0 et r1 contiennent les adresses des chaines */
/* retour 0 dans r0 si egalite sinon -1 */
Comparaison:
	push {fp,lr}    /* save des  2 registres */
	add fp,sp,#8    /* fp <- adresse début */
	push {r1,r2,r3,r4}  /* save des registres */
	mov r2,#0   /* indice */
1:	@ boucle de comparaison
	ldrb r3,[r0,r2]   /* octet chaine 1 */
    ldrb r4,[r1,r2]   /* octet chaine 2 */
    cmp r3,r4
	movne r0,#-1	 /* inegalite */ 
    bne 100f     /* c'est fini */
	cmp r3,#0   /* 0 final */
	moveq r0,#0    /* egalite */ 	
	beq 100f     /* c'est la fin */
	add r2,r2,#1 /* sinon plus 1 dans indice */
	b 1b         /* et boucle */
		
100:
    pop {r1,r2,r3,r4}
	pop {fp,lr}   /* fin procedure */
    bx lr   
/********************************************/	   
/* Tri par insertion                        */
/* attention ce tri n'est pas performant    */
/* pour de grands nombres d'enregistrements */
/********************************************/	  
/* r0 contient le pointeur base des faits */
/* r1 contient le nombre de faits */
triInsertion:
	push {fp,lr}    /* save des  2 registres */
	push {r1-r11}  /* save des registres */
	sub r1,#1       @ indice dernier poste
	mov r2,#1       @ indice de départ
	mov r3,#fait_fin  @ taille d'un fait
	add r4,r1,#1      @ dernier poste plus un 
	mul r12,r4,r3     @ pour stocker les donnees deplacées
	add r12,r0        @ et donc sert de zone intermèdiaire 
1:
    mul r4,r3,r2    @ extraction du niveau correspondant à l'indice r2
	add r4,r0       @ de la base des faits
    ldr r5,[r4,#fait_niveau]
	mov r9,r4       @ conservation du pointeur vers ce poste
	mov r10,r12     @ copie des données du poste vers le poste tampon (r12)
	bl copieFait
    mov r6,r2       @ indice de départ
2:
    sub r7,r6,#1    
    mul r7,r3,r7
	add r7,r0
    ldr r8,[r7,#fait_niveau]	
	cmp r8,r5      @ comparaison des niveaux des 2 postes
    bgt 3f
	mov r9,r7    @ pointeur du poste comme origine
	mul r10,r6,r3  @ calcul du pointeur du poste de l'indice de départ
	add r10,r0
    bl copieFait  @ copie des données
    subs r6,#1     @ boucle autre poste
    bgt 2b
3:
	mov r9,r12   @ on reprend le poste stockée au début comme origine
	mul r10,r6,r3 @ calcul du poste à l'indice r6
	add r10,r0
	bl copieFait  @ et copie des données
	add r2,#1      @ poste suivant
	cmp r2,r1      @ et boucle au debut si pas fini
	ble 1b   
	mov r1,#0       @ raz du poste tampon
	str r1,[r12] 
100:  /* fin procedure */
    pop {r1-r11}
	pop {fp,lr}  
    bx lr  
/* copie des données d'un poste à un autre */	
/* attention cette routine ne sauvegarde aucun registre */
/* ne jamais appeler une autre sous routine à l'intérieur */
/* r9 pointeur sur les données origine */
/* r10 pointeur sur les données destination */
/* utilise r11 */
copieFait:
    ldr r11,[r9,#fait_nom]
    str r11,[r10,#fait_nom] 	
	ldr r11,[r9,#fait_valeur]
    str r11,[r10,#fait_valeur]
	ldr r11,[r9,#fait_niveau]
    str r11,[r10,#fait_niveau]
	ldr r11,[r9,#fait_type]
    str r11,[r10,#fait_type]
	ldr r11,[r9,#fait_question]
    str r11,[r10,#fait_question]
	bx lr 
/********************************************************************/
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
	
	