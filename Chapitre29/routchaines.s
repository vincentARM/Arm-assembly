/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/*  */
/* routines pour chaines de caractères */
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"
/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/
.equ NBPOSTESECLAT, 100
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne: .asciz  "\n"
szMessChaine:  .asciz  "test affichage d'une chaine \n"
//.equ LGMESSCHAINE, . -  szMessChaine /* calcul de la longueur de la zone precedente */

szChaine1: .asciz "Bonjour"
szChaine2: .asciz " monde\n"
szChaine1A: .asciz "aVEv"
szChaine1B: .asciz "aVEX"
szChaineRech1: .asciz "Bon"
szChaineRech2: .asciz "jour"
szChaineRech3: .asciz "nj"
szChaineRech4: .asciz "Bonhe"
szChaine3: .asciz "abboufh"
szChaineRech5: .asciz "bou"
@ table de pointeurs vers les chaines
iTableCh:   .int  szMessChaine
               .int szChaine1
			   .int szChaine2
			   .int szChaine1A
			   .int szChaine1B
			   .int szChaineRech1
			   .int szChaineRech2
			   .int szChaineRech3
			   .int szChaineRech4
			   .int szChaineRech5
			   .int szChaine3
			   .int 0          @ borne de fin de table
			   
pasChaine:   .ascii " chaine éèêà   \1\n"
//pasChaine1:  .ascii "abcdef" 
szchaineaeclater: .asciz "La terre est bleue comme une orange" 
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
zone1:      .skip 50
zone2:      .skip 100

zoneM1:   .skip 10
//zoneM2:   .skip 10
/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main      /* 'main' point d'entrée doit être  global */

main:             /* programme principal */
    push {fp,lr}    /* save des  2 registres */
	ldr r0,=szMessDebutPgm   /* r0 ← adresse message debut */
	bl affichageMess  /* affichage message dans console   */
	ldr r0,=szChaine1
	bl longueurchaine
    vidregtit Longueur_bonjour   @ macro affichage tous registres
	ldr r0,=szMessChaine
	bl longueurchaine
    vidregtit Longueur_Chaine_1   @ macro affichage tous registres
	
	ldr r0,=pasChaine
	bl verifchaine
	ldr r0,=pasChaine
	bl affichageMess
	ldr r0,=pasChaine
	mov r1,#2  /* nombre de bloc a afficher */
    push {r0} /* adresse memoire */	
	push {r1}
    bl affmemoire
	
	ldr r0,=szMessChaine
	ldr r1,=zone1
	bl copiechaine
    vidregtit  copiechaine
	ldr r0,=zone1
	mov r1,#2  /* nombre de bloc a afficher */
    push {r0} /* adresse memoire */	
	push {r1}
    bl affmemoire
	ldr r0,=szChaine1
	ldr r1,=szChaine2
	ldr r2,=zone2
	bl concatchaine
	vidregtit concatchaine
	ldr r0,=zone2
	bl affichageMess
	ldr r0,=zone2
	mov r1,#2  /* nombre de bloc a afficher */
    push {r0} /* adresse memoire */	
	push {r1}
    bl affmemoire
	
	ldr r0,=szChaine1
	ldr r1,=szChaine2
	mov r2,#0
	bl concatchaineTas    @ r0 contient la zone complete
	vidregtit concatchaineTas
	bl affichageMess
	mov r1,#2  /* nombre de bloc a afficher */
    push {r0} /* adresse memoire */	
	push {r1}
    bl affmemoire
	
	ldr r1,=szChaine1
	ldr r0,=szChaine1A
	bl comparchaine
	vidregtit comparchaine
	ldr r0,=szChaine1A
	ldr r1,=szChaine1B
	bl comparchaine
	vidregtit comparchaine_1
	ldr r0,=szChaine1A
	ldr r1,=szChaine1B
	bl comparchaineScasse
	vidregtit comparchaine_Scasse
	ldr r0,=zoneM1
	mov r1,#2  /* nombre de bloc a afficher */
    push {r0} /* adresse memoire */	
	push {r1}
    bl affmemoire
	ldr r0,=szChaine1
	mov r1,#'j'
	bl rechcar
	vidregtit  rechercar
	ldr r0,=szChaine1
	mov r1,#'z'
	bl rechcar
	vidregtit  rechercarZ
	ldr r0,=szChaine1
	ldr r1,=szChaineRech1
	bl rechchaine
	vidregtit  recherchaine1
	ldr r0,=szChaine1
	ldr r1,=szChaineRech2
	bl rechchaine
	vidregtit  recherchaine2
	ldr r0,=szChaine1
	ldr r1,=szChaineRech3
	bl rechchaine
	vidregtit  recherchaine3
	ldr r0,=szChaine1
	ldr r1,=szChaineRech4
	bl rechchaine
	vidregtit  recherchaine4
	ldr r0,=szChaine3
	ldr r1,=szChaineRech5
	bl rechchaine
	vidregtit  recherchaine5
	ldr r0,=szChaine1
	ldr r1,=zone1
	mov r2,#5
	bl copiecarchaine
	vidregtit  copiecarchaine
	ldr r0,=zone1
	mov r1,#2  /* nombre de bloc a afficher */
    push {r0} /* adresse memoire */	
	push {r1}
    bl affmemoire
	ldr r0,=szChaine1
	ldr r1,=szChaine1A
	mov r2,#4
	bl insertchaine
	vidregtit  insertchaine
	//ldr r0,=zone1
	mov r1,#2  /* nombre de bloc a afficher */
    push {r0} /* adresse memoire */	
	push {r1}
    bl affmemoire
	
	/*************************************/
	ldr r0,=iTableCh
	bl affichetable
	vidregtit affichetable
	ldr r0,=iTableCh
	mov r1,#10     @ dernier poste
	bl tritablechaine
	vidregtit aprestri
	ldr r0,=iTableCh
	bl affichetable
	vidregtit affichetableApresTri
	
	ldr r0,=szchaineaeclater
	mov r1,#' '
	bl eclatechaine
	vidregtit eclatechaine
	mov r2,r0    @ recup adresse table
	ldr r4,[r2]  @ recup nombre de zones eclatées
	add r2,#4    @ adresse poste 1 donc première zone eclatée
	mov r3,#0    @ compteur de boucle
1:  @ boucle affichage de chaque sous chaine
    ldr r0,[r2,r3, lsl #2]   @ recup adresse de chaque zone
	ldr r1,=szRetourligne   @ ajout du retour ligne
	bl concatchaineTas
	bl affichageMess      @ affichage de la zone
	add r3,#1             @ compteur + 1
	cmp r3,r4            @ fin ?
	blt 1b
	
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
/* fin de programme standard  */
100:		
	pop {fp,lr}   /* restaur des  2 registres */
	mov r7, #EXIT /* appel fonction systeme pour terminer */
    swi 0 
/************************************/	   
szMessErreur: .asciz "Erreur rencontrée.\n"
szMessDebutPgm: .asciz "Début du programme. \n"
szMessFinOK: .asciz "Fin normale du programme. \n"
.align 4     /* alignement car l'étiquette de la routine suivante doit être alignée */
/***************************************************/
/*   controle d'une chaine                         */
/* remplace le premier caractere non alphanumerique par un 0 binaire */
/***************************************************/
/* r0 adresse de la chaine    */
/* r0 retourne la longueur */
verifchaine:
    push {r1,r2,lr}
    mov r1,#0    @ init compteur
1:
   ldrb r2,[r0,r1]   @ recup un octet de la chaine
   cmp r2,#0          @ c'est la fin ?
   beq 100f
   cmp r2,#' '    @ < à blanc  
   blt 2f
   lsrs r2,#8    @ decalage pour tester le bit le plus haut de l'octet
   bcs 2f        @ et si ce bit est à un (indique un caractère sur plusieurs octets
                   @ en codage uft8) on considere que c'est la fin de chaine
				   @ donc attention, ne pas utiliser si cractères accentuées présents 
				   @ dans les chaines comme à é è ê etc..
   add r1,#1       @ non donc +1 au compteur
   b 1b            @ et boucle 

2:
   mov r2,#0
   strb r2,[r0,r1]   @ caractere non alpha, forçage du 0 de fin de chaine
   
100:   /* fin standard de la fonction  */
	mov r0,r1
   	pop {r1,r2,lr}  
    bx lr       /* retour de la fonction en utilisant lr  */
/***************************************************/
/*   calcul longueur d'une chaine               */
/***************************************************/
/* r0 adresse de la chaine    */
/* r0 retourne la longueur */
longueurchaine:
    push {r1,r2,lr}
    mov r1,#0    @ init compteur
1:
   ldrb r2,[r0,r1]   @ recup un octet de la chaine
   cmp r2,#0          @ c'est la fin ?
   addne r1,#1       @ non donc +1 au compteur
   bne 1b            @ et boucle 
	
100:   /* fin standard de la fonction  */
	mov r0,r1
   	pop {r1,r2,lr}  
    bx lr       /* retour de la fonction en utilisant lr  */

/***************************************************/
/*   copie d'une chaine                            */
/***************************************************/
/* r0 adresse de la chaine à copier     */
/* r1 adresse de la zone destination */
/* r0 retourne le nombre de caracteres copies y compris le 0 final */
copiechaine:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r2,r3}   /* save autres registres en nombre pair */
   	mov r2,#0
    /* boucle de copie des caractères */
1:	                  /* label local */
	ldrb r3,[r0,r2]
	strb r3,[r1,r2]
	cmp r3,#0
	beq 100f         @ c'est fini
	add r2,#1
	b 1b         /* saut au label 1 backward */
100:   
   mov r0,r2
   /* fin standard de la fonction  */
   	pop {r2,r3}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */
/***************************************************/
/*   copie des n caractères d'une chaine                            */
/***************************************************/
/* r0 adresse de la chaine à copier     */
/* r1 adresse de la zone destination */
/* r2 nombre de caractères à copier */
/* r0 retourne le nombre de caracteres copies y compris le 0 final */
/* attention s'arrete au 0 final si nombre de caractères demandé est superieur */
/* à la longueur de la chaine              */
copiecarchaine:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r2-r4}   /* save autres registres  */
   	mov r4,#0
    /* boucle de copie des caractères */
1:	                  /* label local */
	ldrb r3,[r0,r4]
	strb r3,[r1,r4]
	cmp r3,#0
	beq 100f         @ c'est fini
	add r4,#1
	cmp r4,r2
	blt 1b         /* saut au label 1 backward */
100:   
   mov r0,r2
   /* fin standard de la fonction  */
   	pop {r2-r4}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */
	
/***************************************************/
/*   concatenation de chaines                      */
/***************************************************/
/* r0 adresse de la chaine 1     */
/* r1 adresse de la chaine 2     */
/* r2 adresse de la zone destination */
/* r0 retourne le nombre de caracteres copies y compris le 0 final */
concatchaine:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r1-r5}   /* save autres registres en nombre pair */
   	mov r3,r0
	mov r4,r1
	mov r1,r2
	bl copiechaine
	mov r5,r0
	add r1,r2,r5
	mov r0,r4
	bl copiechaine
	add r0,r5
100:   
   /* fin standard de la fonction  */
   	pop {r1-r5}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
	
	/***************************************************/
/*   concatenation de chaines                      */
/***************************************************/
/* r0 adresse de la chaine 1     */
/* r1 adresse de la chaine 2     */
/* la zone de reception est allouee sur le tas */
/* r0 retourne l'adresse de la zone  */
concatchaineTas:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r1-r7}   /* save autres registres en nombre pair */
   	mov r3,r0
	mov r4,r1
	bl longueurchaine
	mov r5,r0
	mov r0,r1
	bl longueurchaine
	add r5,r0
	add r5,#1      @ pour le 0 final
	@ reservation place lg1 + lg2
	mov r0,#0      /* recuperation de l'adresse du tas */
    mov r7, #0x2D                  /* code de l'appel systeme 'brk' */
    swi #0                      /* appel systeme */
	cmp r0,#-1              @ erreur call system
	beq 100f
	mov r6,r0              @ save adresse début zone tas
	add r0,r5                   /* reserve lg1+lg2 octets sur le tas */
	mov r7, #0x2D                  /* code de l'appel systeme 'brk' */
    swi #0                      /* appel systeme */
	cmp r0,#-1                @ erreur call system
	beq 100f
	mov r0,r3
	mov r1,r6
	bl copiechaine
	//mov r5,r0
	add r1,r6,r0
	mov r0,r4
	bl copiechaine
	mov r0,r6
100:   
   /* fin standard de la fonction  */
   	pop {r1-r7}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
	
/************************************/	   
/* comparaison de chaines           */
/************************************/	  
/* r0 et r1 contiennent les adresses des chaines */
/* retour 0 dans r0 si egalite */
/* retour -1 si chaine r0 < chaine r1 */
/* retour 1  si chaine r0> chaine r1 */
comparchaine:
	//push {fp,lr}    /* save des  2 registres */
	push {r1-r4}  /* save des registres */
	mov r2,#0   /* indice */
1:	
	ldrb r3,[r0,r2]   /* octet chaine 1 */
    ldrb r4,[r1,r2]   /* octet chaine 2 */
    cmp r3,r4
	movlt r0,#-1	 /* plus petite */ 	
	movgt r0,#1	 /* plus grande */ 	
    bne 100f     /* pas egaux */
	cmp r3,#0   /* 0 final */
	moveq r0,#0    /* egalite */ 	
	beq 100f     /* c'est la fin */
	add r2,r2,#1 /* sinon plus 1 dans indice */
	b 1b         /* et boucle */
100:
    pop {r1-r4}
	//pop {fp,lr}   /* fin procedure */
    bx lr   
/************************************/	   
/* comparaison de chaines sans Casse */
/************************************/	  
/* r0 et r1 contiennent les adresses des chaines */
/* retour 0 dans r0 si egalite */
/* retour -1 si chaine r0 < chaine r1 */
/* retour 1  si chaine r0> chaine r1 */
comparchaineScasse:
	//push {fp,lr}    /* save des  2 registres */
	push {r1-r4}  /* save des registres */
	mov r2,#0   /* indice */
	//ldr r5,=zoneM1
	//ldr r6,=zoneM2
1:	
	ldrb r3,[r0,r2]   /* octet chaine 1 */
    ldrb r4,[r1,r2]   /* octet chaine 2 */
	@ majuscules en minuscules
	cmp r3,#65
	blt 2f
	cmp r3,#90
	bgt 2f
	add r3,#32
	//strb r3,[r5,r2]
2:
	cmp r4,#65
	blt 3f
	cmp r4,#90
	bgt 3f
	add r4,#32
	//strb r4,[r6,r2]
3:	
    cmp r3,r4
	movlt r0,#-1	 /* plus petite */ 	
	movgt r0,#1	 /* plus grande */ 	
    bne 100f     /* pas egaux */
	cmp r3,#0   /* 0 final */
	moveq r0,#0    /* egalite */ 	
	beq 100f     /* c'est la fin */
	add r2,r2,#1 /* sinon plus 1 dans indice */
	b 1b         /* et boucle */
100:
    pop {r1-r4}
	//pop {fp,lr}   /* fin procedure */
    bx lr   	
/************************************/	   
/* recherche un caractères dans une chaine          */
/************************************/	  
/* r0 contient l' adresse de la chaine */
/* r1 le caractère à rechercher */
/* retourne la position dans r0 si trouvé */
/* retour -1 si non trouvé */
rechcar:
	//push {fp,lr}    /* save des  2 registres */
	push {r1-r3}  /* save des registres */
	mov r2,#0   /* indice */
1:	
	ldrb r3,[r0,r2]   /* octet chaine 1 */
    cmp r3,r1
	moveq r0,r2
	beq 100f
	cmp r3,#0
	moveq r0,#-1
	beq 100f
	add r2,r2,#1 /* sinon plus 1 dans indice */
	b 1b         /* et boucle */
100:
    pop {r1-r3}
	//pop {fp,lr}   /* fin procedure */
    bx lr   
/************************************/	   
/* recherche sous-chaine dans une chaine          */
/************************************/	  
/* r0 contient l' adresse de la chaine */
/* r1 contient l'adresse de la souschaine à rechercher */
/* retourne la position dans r0 si trouvé */
/* retour -1 si non trouvé */
rechchaine:
	//push {fp,lr}    /* save des  2 registres */
	push {r1-r6}  /* save des registres */
	mov r2,#0   /* indice ch1*/
	mov r4,#0   /* indice ch2*/
	mov r6,#-1  /* position */
1:	
	ldrb r3,[r0,r2]   /* octet chaine 1 */
	ldrb r5,[r1,r4]   /* octet chaine 1 */
	cmp r5,#0     @ fin de la sous chaine
	subeq r0,r2,r6
	subeq r0,#1
	beq 100f
    cmp r3,#0
	moveq r0,#-1
	beq 100f
	cmp r3,r5
	bne 2f
	add r6,#1
	add r2,r2,#1
	add r4,r4,#1
	b 1b
2:	
    cmp r6,#-1
	movne r4,#0 @ inegal on revient en arrière
	subne r2,r6
	subne r2,#1
	movne r6,#-1
	add r2,#1
	b 1b
100:
    pop {r1-r6}
	//pop {fp,lr}   /* fin procedure */
    bx lr   
/************************************/	   
/* insertion sous-chaine dans une chaine          */
/************************************/	  
/* r0 contient l' adresse de la chaine */
/* r1 contient l'adresse de la souschaine à inserer */
/* r2 position d'insertion                 */
/* r0 retourne l'adresse de la nouvelle chaine */
/* retour -1 si pb */
insertchaine:
	push {fp,lr}    /* save des  2 registres */
	push {r1-r8}  /* save des registres */	
	@ longueur chaine 1
	mov r4,r0   @ save adresse ch1
	mov r5,r1   @ save adresse ch2
	bl longueurchaine
	mov r3,r0
	@ longueur chaine 2
	mov r0,r1
	bl longueurchaine
	mov r8,r0
	add r3,r8
	add r3,#1   @ pour le 0 final
	@ reservation place lg1 + lg2
	mov r0,#0      /* recuperation de l'adresse du tas */
    mov r7, #0x2D                  /* code de l'appel systeme 'brk' */
    swi #0                      /* appel systeme */
	cmp r0,#-1              @ erreur call system
	beq 100f
	mov r6,r0              @ save adresse début zone tas
	vidregtit brk   @ macro affichage tous registres
	add r0,r3                   /* reserve lg1+lg2 octets sur le tas */
	mov r7, #0x2D                  /* code de l'appel systeme 'brk' */
    swi #0                      /* appel systeme */
	cmp r0,#-1                @ erreur call system
	beq 100f
	@ copie caracteres chaine 1 jusqu'à position demandée
	mov r0,r4
	mov r1,r6
	bl copiecarchaine
	@ copie chaine 2 à la suite
	mov r0,r5
	add r1,r6,r2
	bl copiechaine
	@ copie fin de la chaine 1
	add r0,r4,r2
	add r1,r8
	bl copiechaine
	@retourne adresse de la zone résultat
	mov r0,r6
100:
    pop {r1-r8}
	pop {fp,lr}   /* fin procedure */
    bx lr   	
/*******************************************************************/	   
/* affichage des chaines à partir d'une table de pointeurs         */
/*******************************************************************/	  
/* r0 contient l' adresse de la table */
/* retourne le nombre de poste de la table */
affichetable:
	push {fp,lr}    /* save des  2 registres */
	push {r1-r3}  /* save des registres */	
	mov r3,#0
	mov r2,r0
1:
	ldr r0,[r2,r3,lsl #2]
	cmp r0,#0
	beq 100f
	ldr r1,=szRetourligne
	bl concatchaineTas
	bl affichageMess
	add r3,#1
	b 1b
	
100:
	mov r0,r3 
    pop {r1-r3}
	pop {fp,lr}   /* fin procedure */
    bx lr   	
/*******************************************************************/	   
/* tri des chaines à partir d'une table de pointeurs               */
/* il s'agit d'un tri shell avec un increment simplifié            */
/* peut ne pas etre performant sur certains nombres d'elements     */
/*******************************************************************/	  
/* r0 contient l' adresse de la table */
/* r1  nombre maxi de postes    */
tritablechaine:
	push {fp,lr}    /* save des  2 registres */
	push {r0-r8}  /* save des registres */	
   mov r8,r0  @ adresse de la table
   mov r7,r1  @ nombre d'element
   mov r2,r1  @ init de l'ecart 
 1:     @ début de boucle de traitement de chaque ecart
   lsrs r2,#1   @ division par 2 de l'ecart
   beq 5f       @ et si egal à zero le tri est fini
   mov r3,r2     @ sinon il sert de base 
2:       @ debut de boucle de balayage 
   ldr r4,[r8,r3,lsl #2]  @ recup dans la table du pointeur de la chaine 
   mov r5,r3   @ pour commencer la recherche
 3:  
   cmp r5,r2   @ pour finir la recherche s'il devient plus petit que
   blt 4f     @ l'indice de depart
   sub r6,r5,r2 @ sinon calcul de la difference
   ldr r1,[r8,r6,lsl #2]  @et recup du pointeur de la deuxieme chaine
   @ comparaison de chaines  r0 et r1 contiennent les pointeurs vers les chaines 
   mov r0,r4  
   bl comparchaineScasse
   cmp r0,#0
   bge 4f    @ la chaine de debut est plus grande que celle traitee
   str r1,[r8,r5,lsl #2]  @ et si plus petite on stocke la chaine 2
   sub r5,r2      @ recherche suivante
   b 3b
4:   @ la chaine de debut est plus grande que celle traitee
   str r4,[r8,r5,lsl #2]  @ et donc on la stocke à la place
   add r3,#1   @ poste suivant ?
   cmp r3,r7   @ fin de table depassée ?
   ble 2b     @ non boucle au debut
   b 1b        @ sinon on recommence avec un nouvel ecart
5:
	
100:
    pop {r0-r8}
	pop {fp,lr}   /* fin procedure */
    bx lr   	
	
	
/*******************************************************************/	   
/* eclatement d'une chaine en fonction d'un séparateur              */
/* retourne dans r0 une table avec premier poste = nombre de zones  */
/* autres postes   pointeurs vers chaque zone eclatée             */
/* les zones eclatées sont stockées sur le tas                    */
/*******************************************************************/	  
/* r0 contient l' adresse de la chaine */
/* r1 contient le caractère séparateur    */
eclatechaine:
	push {fp,lr}    /* save des  2 registres */
	push {r1-r8}  /* save des registres */		
	mov r6,r0
	mov r8,r1
	@ calcul longueur chaine pour reservation place sur le tas
	bl longueurchaine
	mov r4,r0
	ldr r5,iTailleTable
	add r5,r0
	and r5,#0xFFFFFFFC
	add r5,#4              @ pour alignement du tas sur 4 octets
	@ reservation place + place pour la table (100 postes) 
	mov r0,#0      /* recuperation de l'adresse du tas */
    mov r7, #0x2D                  /* code de l'appel systeme 'brk' */
    swi #0                      /* appel systeme */
	cmp r0,#-1              @ erreur call system
	beq 100f
	mov r3,r0              @ save adresse début zone tas
	add r0,r5                   /* reserve r5 octets sur le tas */
	mov r7, #0x2D                  /* code de l'appel systeme 'brk' */
    swi #0                      /* appel systeme */
	cmp r0,#-1                @ erreur call system
	beq 100f

	
	@ copie chaine sur le tas
	mov r0,r6
	mov r1,r3
	bl copiechaine
	@ init table  0 poste et debut chaine dans poste 1
	add r4,r3     @ r4 contiendra l'adresse de début de table
	mov r0,#0
	str r0,[r4]
	str r3,[r4,#4]
	mov r2,#1
1:	@ balayage de la chaine jusquà la fin
	ldrb r0,[r3]
	cmp r0,#0
	beq 2f    @ c'est la fin
	cmp r0,r8
	addne r3,#1
	bne 1b
	@ si caractère = separateur
	@ alors mettre zero binaire, ajouter 1 au nb de zones mettre adresse suivante dans poste
	mov r0,#0
	strb r0,[r3]
	add r3,#1
	add r2,#1
	str r3,[r4,r2, lsl #2]
    @ et boucler.
	b 1b
    @ en fin retourner l'adresse début de table	
2:
    str r2,[r4]     @ nombre de zones trouvées
    mov r0,r4
100:
    pop {r1-r8}
	pop {fp,lr}   /* fin procedure */
    bx lr   	
iTailleTable: .int 4 * NBPOSTESECLAT
/******************************************/
vidage:
	push {fp,lr}
	vidregtit inegal
	pop  {fp,lr}
	bx lr
	
	
/********************************************************************/
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
	
	