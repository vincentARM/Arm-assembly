/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* modèle B 512MO   */
/* Simulation d'un feu tricolore  */
/*********************************************/
/*constantes particulière au programme*/
/********************************************/
.equ TAILLEBUF,  4 * 41  @ 41 registres de 32 bits pour le GPIO
.equ    INPUT,0           @  pin utilisé en entrée
.equ    OUTPUT,1          @  pin utilisé en sortie
.equ    GPSET0,0x1c      @ offset du début des registres d'allumage	
.equ    GPCLR0,0x28      @ offset du debut des registres d'extinction
.equ    GPLEV0,0x34      @ offset du debut des registres d'état
.equ    GPEDS0,0x40      @ offset du debut des registres de detection   
.equ    MASKPIN,0b111    @ masque pour 3 bits
.equ    NUMPINROUGE,  18        @ N° du pin utilisé (18 correspond à la broche physique 12)
.equ    NUMPINORANGE,  23        @ N° du pin utilisé (23 correspond à la broche physique 16)
.equ    NUMPINVERT,  25        @ N° du pin utilisé (25 correspond à la broche physique 22)
.equ    NUMPINBOUTON,  4        @ N° du pin utilisé (4 correspond à la broche physique 7)

/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessErreur: .asciz "Erreur ouverture fichier.\n"
szMessErreur1: .asciz "Erreur fermeture fichier.\n"
szMessErreur2: .asciz "Erreur lecture fichier.\n"
szMessAttBouton: .asciz "Attente appui bouton.\n"
szRetourligne: .asciz  "\n"

szGpioNom: .asciz "/dev/gpiomem"

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
iFdGpio: .skip 4
/* zones pour l'appel fonction sleep */
iZonesAttente:
 iSecondes: .skip 4
 iMicroSecondes: .skip 4
iZonesTemps: .skip 8

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main      /* 'main' point d'entrée doit être  global */

main:             /* programme principal */
    push {fp,lr}    /* save des  2 registres */
	add fp,sp,#8    /* fp <- adresse début */
	ldr r0,=szMessDebutPgm   /* r0 ← adresse message */
	bl affichageMess  /* affichage message dans console   */	
	/* ouverture du fichier */
	ldr r0,=szGpioNom   /* Donc le nom du fichier à ouvrir */
	ldr r1,#iFlags  /*  flags    */
	mov r2,#0        /* mode */
	mov r7, #OPEN /* appel fonction systeme pour ouvrir */
    swi #0 
	cmp r0,#0    /* si erreur retourne -1 */
	ble erreur
	ldr r1,=iFdGpio
	str r0,[r1]    /* save du Fd */ 
	
	/* Mapping du fichier en mémoire */
	mov r4,r0             /* contient le FD du fichier ouvert */
	mov r0,#0
	ldr r1,iTailleBuf   /* nb de caracteres  */
	ldr r2,iFlagsMmap   /* autorisation d'accès */
	mov r3,#MAP_SHARED
	mov r5,#0
	mov r7, #192 /* appel fonction systeme pour MMAP */
    swi #0 
	cmp r0,#0     /* retourne 0 en cas d'erreur */
	beq erreur2
	mov r8,r0    /* save adresse zone mémoire du map */
	
	bl traitement
	
	
	/* fermeture des ressources */
	mov r0,r8              /* fermeture map  gpio */
	ldr r1,iTailleBuf   /* nb de caracteres  */
	mov r7, #91           /* appel fonction systeme pour UNMAP */
    swi #0 
	cmp r0,#0
	blt erreur1	
	/* fermeture fichier GPIO */
	ldr r0,=iFdGpio
	ldr r0,[r0]   /* Fd  fichier */
	mov r7, #CLOSE /* appel fonction systeme pour fermer */
    swi #0 
	cmp r0,#0
	blt erreur1	
    /* fin OK */
finnormale:	
    ldr r0,=szMessFinOK   /* r0 ← adresse chaine */
	bl affichageMess  /* affichage message dans console   */	
	mov r0,#0     /* code retour OK */
	b 100f
erreur:		/* erreur d'ouverture du fichier */
	ldr r1,=szMessErreur   /* r0 <- code erreur r1 <- adresse chaine */
    bl   afficheerreur   /*appel procedure  */		
	mov r0,#1       /* erreur */
	b 100f	
erreur1:	/* erreur fermeture du fichier */
	ldr r1,=szMessErreur1   /* r1 <- adresse chaine */
	bl   afficheerreur   /*appel procedure  */		
	mov r0,#1       /* erreur */
	b 100f	
erreur2:	/* erreur mapping fichier GPIO */
	ldr r1,=szMessErreur2   /* r1 <- adresse chaine */
	bl   afficheerreur   /*appel procedure  */		
	mov r0,#1       /* erreur */
	b 100f		
100:		/* fin de programme standard  */
	pop {fp,lr}   /* restaur des  2 registres */
	mov r0,#0     /* code retour  */
	mov r7, #EXIT /* appel fonction systeme pour terminer */
    swi 0 
iFlags: .int 	O_RDWR |O_SYNC
iFlagsMmap: .int PROT_READ|PROT_WRITE
iTailleBuf: .int TAILLEBUF
iduree: .int 50000000
szMessDebutPgm: .asciz "Début du programme. \n"
szMessFinOK: .asciz "Fin normale du programme. \n"
.align 4     /* alignement car l'étiquette de la routine suivante doit être alignée */
/***************************************************/
/*   Traitement principal                          */
/***************************************************/
/* r0 et r8 adresse GPIO memoire  */
traitement:
   push {fp,lr}    /* save des  2 registres r0 et retour */
   push {r1-r6}   /* save autres registres en nombre pair */
	/* Gestion des pins du GPIO */
    mov     r1,#NUMPINROUGE      @ N° du pin à utiliser  
    mov     r2,#OUTPUT      @ fonction SORTIE
    bl      selectPin       @ Appel selection 
	mov		r0,r8
	mov     r1,#NUMPINORANGE      @ N° du pin à utiliser  
    mov     r2,#OUTPUT      @ fonction SORTIE
    bl      selectPin       @ Appel selection 
	mov 	r0,r8
	mov     r1,#NUMPINVERT      @ N° du pin à utiliser  
    mov     r2,#OUTPUT      @ fonction SORTIE
    bl      selectPin       @ Appel selection 
	mov 	r0,r8
	mov     r1,#NUMPINBOUTON      @ N° du pin à utiliser  
    mov     r2,#INPUT      @ fonction ENTREE
    bl      selectPin       @ Appel selection 
	
	mov     r0, r8          @ Adresse zones mémoire du map GPIO
    mov     r1,#NUMPINBOUTON          @ N° du pin à utiliser  broche physique 12
    bl      clearPin      @ Appel extinction
	@ 
	ldr r0,=szMessAttBouton   /* r1 <- adresse message */
	bl affichageMess          /*appel procedure  */	
1:	
	mov 	r0,r8
	mov     r1,#NUMPINBOUTON      @ N° du pin à utiliser  
    bl      etatPin       @ Appel selection 
	cmp r0,#1
	bne 1b
	
	/*******************************************************/
	/* IMPORTANT, effectuer toujours un clear avant un set */
	/*******************************************************/
	mov     r0, r8          @ Adresse zones mémoire du map GPIO
    mov     r1,#NUMPINROUGE          @ N° du pin à utiliser  broche physique 12
    bl      clearPin      @ Appel extinction
	mov     r0, r8          @ Adresse zones mémoire du map GPIO
    mov     r1,#NUMPINORANGE          @ N° du pin à utiliser  broche physique 12
    bl      clearPin      @ Appel extinction
	mov     r0, r8          @ Adresse zones mémoire du map GPIO
    mov     r1,#NUMPINVERT          @ N° du pin à utiliser  broche physique 12
    bl      clearPin      @ Appel extinction
2: @ debut de boucle	
	@ allumage feu rouge
	mov     r0, r8          @ Adresse zones mémoire GPIO
    mov     r1,#NUMPINROUGE          @ N° du pin à utiliser  broche physique 12
    bl      setPin         @ Appel allumage
	mov r0,#20     @ 20 secondes
	mov r1,#0
    bl attente
	@ extinction feu rouge
	mov     r0, r8          @ Adresse zones mémoire du map GPIO
    mov     r1,#NUMPINROUGE          @ N° du pin à utiliser  broche physique 12
    bl      clearPin      @ Appel extinction   
  
	@ allumage feu VERT
	mov     r0, r8          @ Adresse zones mémoire GPIO
    mov     r1,#NUMPINVERT          @ N° du pin à utiliser  broche physique 12
    bl      setPin         @ Appel allumage
	mov r0,#30     @ 30 secondes
	mov r1,#0
    bl attente
	@ extinction feu VERT
	mov     r0, r8          @ Adresse zones mémoire du map GPIO
    mov     r1,#NUMPINVERT          @ N° du pin à utiliser  broche physique 12
    bl      clearPin      @ Appel extinction
 	@ allumage feu ORANGE
	mov     r0, r8          @ Adresse zones mémoire GPIO
    mov     r1,#NUMPINORANGE          @ N° du pin à utiliser  broche physique 12
    bl      setPin         @ Appel allumage
	mov r0,#5     @ 5 secondes
	mov r1,#0
    bl attente
	@ extinction feu ORANGE
	mov     r0, r8          @ Adresse zones mémoire du map GPIO
    mov     r1,#NUMPINORANGE          @ N° du pin à utiliser  broche physique 12
    bl      clearPin      @ Appel extinction

	@ boucle au début
	b 2b
	
100:   
   /* fin standard de la fonction  */
   	pop {r1-r6}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres r0 et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	   

/***************************************************/
/*   Selection pin GPIO                  */
/***************************************************/
/* r0 adresse GPIO memoire  */
/* r1 N° du pin  code FSEL ou code BCM */
/* r2 code fonction */
selectPin:
   push {r0,lr}    /* save des  2 registres r0 et retour */
   push {r1-r6}   /* save autres registres en nombre pair */
   mov r5,r0      /* save adresse */ 
   mov r6,r2      /* save fonction */
   /* calcul du registre à selectionner (GPFSEL) et du rang du pin par division par 10 */
   mov r0,r1
   mov r1,#10
   bl division
   @r2 contient le N° du registre (GPFSEL) et r3 le rang
   @ le registre 0 sera à l'adresse memoire, le 1 à l'offset +4 et le 2 à l'offset +8
   mov r4,r2   @ save registre GPIO calculé
   ldr r2,[r5,r4,lsl#2]   @ chargement du registre complet de la mémoire
                          @ et du bon offset r5 + (r4*4)
   mov r0,r3             @ rang du pin dans le registre
   add r3,r3,r0,lsl #1   @ calcul de la position dans le registre = rang * 3
   mov r1,#MASKPIN       @ masque des 3 bits à selectionner 
   lsl r1,r1,r3           @ déplacement du masque en fonction de la position
   bic r2,r2,r1           @ raz des 3 bits concernés dans le registre
   lsl r6,r6,r3           @ deplacement du code fonction à la bonne position
   orr r2,r2,r6           @ maj du code fonction à la bonne position
   str r2,[r5,r4,lsl#2]   @ stockage du registre à sa bonne place dans la mémoire
	
100:   
   /* fin standard de la fonction  */
   	pop {r1-r6}   /*restaur des autres registres */
   	pop {r0,lr}   /* restaur des  2 registres r0 et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
 
/***************************************************/
/*   allumage (set) pin GPIO                             */
/***************************************************/
/* r0 adresse GPIO memoire  */
/* r1 N° du pin */
setPin:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r0-r3}    /* save autres registres en nombre pair */
   add r0,#GPSET0    @ position du registre d'allumage dans la zone mémoire 
   mov r3,#0             @ registre 0
   cmp r1,#32            @ et si pin > 31 c'est le registre 1
   movge r3,#1          
   subge r1,#32    @ et recalcul de la position dans le registre r1  		  
   mov r2,#1        @ 1 = code selection
   lsl r2,r2,r1     @ deplacement à la position du pin dans le registre 
   str r2,[r0,r3,lsl#2]   @ stockage du registre à sa bonne place dans la mémoire
  
100:   
   /* fin standard de la fonction  */
   	pop {r0-r3}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
	
/***************************************************/
/*   extinction (clear) pin GPIO                             */
/***************************************************/
/* r0 adresse GPIO memoire  */
/* r1 N° du pin */
clearPin:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r0-r3}   /* save autres registres en nombre pair */
   add r0,#GPCLR0    @ position du registre d'extinction
   mov r3,#0             @ registre 0
   cmp r1,#32            @ et si pin > 31 c'est le registre 1
   movge r3,#1          
   subge r1,#32    @ et recalcul de la position dans le registre r1  	
   mov r2,#1  @ 1 = code selection du pin
   lsl r2,r2,r1   @ deplacement à la position du pin dans le registre 	
   str r2,[r0,r3,lsl#2]   @ stockage du registre à sa bonne place dans la mémoire
   
	
100:   
   /* fin standard de la fonction  */
   	pop {r0-r3}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
/***************************************************/
/*   Etat d'un pin  du GPIO                             */
/***************************************************/
/* r0 adresse GPIO memoire  */
/* r1 N° du pin */
/* au retour r0 contient 0 pin etat bas */
/*                       1 pin etat haut*/
etatPin:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r1-r4}   /* save autres registres en nombre pair */
   add r0,#GPLEV0    @ position du registre d'extinction
   mov r3,#0             @ registre 0
   cmp r1,#32            @ et si pin > 31 c'est le registre 1
   movge r3,#1          
   subge r1,#32    @ et recalcul de la position dans le registre r1  	
   mov r4,#1  @ 1 = code selection du pin
   lsl r4,r4,r1   @ deplacement à la position du pin dans le registre 	
   ldr r2,[r0,r3,lsl#2]   @ lecture du registre à la bonne place dans la mémoire
   ands r0,r2,r4
   movne r0,#1
  
  //  bl vidtousregistres
	//mov r4,r0
	//mov r0,r2
   // mov r1,#2
	//push {r1}  @ base vidage ici en base 2
	//push {r0}  @ registre à afficher
	//bl vidregistre
	//mov r0,r4
	
	
100:   
   /* fin standard de la fonction  */
   	pop {r1-r4}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
/***************************************************/
/*   délai attente par appel systeme                             */
/***************************************************/
/* r0 temps en secondes  */
/* r1 temps en nanosecondes 500000000 correspond à 0,5s */
attente:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r0-r2,r7}   /* save autres registres en nombre pair */
    ldr r2,=iSecondes
	str r0,[r2]   @ temps d'attente 0s
	str r1,[r2,#4]        @ temps d'attente en nano secondes 
	ldr r0,=iZonesAttente
	ldr r1,=iZonesTemps
	mov r7, #0xa2 /* appel fonction systeme  pour l'attente */
    swi 0 	

100:   
   /* fin standard de la fonction  */
   	pop {r0-r2,r7}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
	
 /*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
