/* programme analyse données du FrameBuffer  */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/*     */
/* rotation d'un rayon d'un cercle */
/*********************************************/
/*constantes du programme */
/* Important : ces données ne peuvent être changées sauf si vous changer aussi */
/* les dimensions de l'affichage dans les données variables du FrameBuffer */
/* voir le programme précédent.    */
.equ LARGEURECRAN, 800
.equ HAUTEURECRAN, 480
.equ TAILLEECRANOCTET, LARGEURECRAN * HAUTEURECRAN *4
.equ COULEURFOND, 0xFFFFFF  @ blanc	
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne: .asciz  "\n"
/* nom du device pour le FrameBuffer */
szParamNom: .asciz "/dev/fb0"
/*   affichage des caractéristiques de l'affichage   */
szLigneVar: .ascii "Variables info : "
largeur:  .fill 11, 1, ' ' 
            .ascii " * "
hauteur:  .fill 11, 1, ' ' 
            .ascii " Bits par pixel : "
bits: 		.fill 11, 1, ' ' 	
 			.asciz  "\n"
.align 4
/* codes fonction pour la récupération des données fixes et variables */
FBIOGET_FSCREENINFO: .int 0x4602
FBIOGET_VSCREENINFO: .int 0x4600
FBIOPUT_VSCREENINFO: .int 0x4601   @ code pour l'écriture des données variables. */

iTaille: .int TAILLEECRANOCTET
iCouleurFond: .int COULEURFOND
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
/* les descriptions des structures sont déportées dans le fichier des includes (voir en fin )*/
.align 4
fix_info: .skip FBFIXSCinfo_fin  /* reserve la place pour la structure FSCREENINFO */
.align 4
var_info: .skip FBVARSCinfo_fin  /* reserve la place pour la structure VSCREENINFO */
.align 4

zonePoints2: .skip 8 * 5000   @ Taille à adapter 
nbpointsdr2: .skip 4
.align 4
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
	ldr r0,=szParamNom  /* nom du device du frameBuffer */
	mov r1,#O_RDWR       /* autorisation lecture ecriture */
	mov r2,#0           /* mode */
	mov r7, #OPEN  @ ouverture device FrameBuffer 
    swi 0 
	cmp r0,#0
	ble erreur
    mov r10,r0     @ save du FD du device FrameBuffer dans r10
	
	/* acces caracteristiques variables de l'affichage */
	ldr r1,=FBIOGET_VSCREENINFO
	ldr r1,[r1]
	ldr r2,=var_info
	mov r7, #IOCTL @ appel systeme de lecture des données
    swi 0 
	cmp r0,#0
	blt erreurVar
	/* conversion zone dans ligne d'affichage */
	ldr r1,=var_info
	ldr r1,[r1,#FBVARSCinfo_xres]
	ldr r0,=largeur  /*adresse de stockage du resultat */
    mov r2,#10    /* conversion en base 10 */
    push {r0,r1,r2}	 /* parametre de conversion */
    bl conversiondeb
	ldr r1,=var_info
	ldr r1,[r1,#FBVARSCinfo_yres]
	ldr r0,=hauteur  /*adresse de stockage du resultat */
    mov r2,#10        /* conversion en base 10 */
    push {r0,r1,r2}	 /* parametre de conversion */
    bl conversiondeb
    ldr r1,=var_info
	ldr r1,[r1,#FBVARSCinfo_bits_per_pixel]	
	ldr r0,=bits  /*adresse de stockage du resultat */
    mov r2,#10    /* conversion en base 10 */
    push {r0,r1,r2}	 /* parametre de conversion */
    bl conversiondeb
	/*  affichage ligne */
	ldr r0,=szLigneVar   /* r0 ← adresse chaine */
	bl affichageMess  /* affichage message dans console   */
	
	

	/* lecture des données fixes */
	mov r0,r10     @ recup FD du FB
	/* lecture caracteristiques fixes de l'affichage */
	ldr r1,=FBIOGET_FSCREENINFO   /* code fonction */
	ldr r1,[r1]
	ldr r2,=fix_info           /* adresse structure de reception */
	mov r7, #IOCTL   @ appel systeme de gestion des périphériques
    swi 0 
	cmp r0,#0
	blt erreurFix
	
	/* recup de la taille necessaire */
	ldr r1,=fix_info
    ldr r1,[r1,#FBFIXSCinfo_smem_len]    /* nb de caracteres  */
	/* mapping des donnees */
    mov r0,#0
	ldr r2,iFlagsMmap
	mov r3,#MAP_SHARED
	mov r4,r10
	mov r5,#0
	mov r7, #192 /* appel fonction systeme pour MMAP */
    swi #0 
	cmp r0,#0     /* retourne 0 en cas d'erreur */
	beq erreur2	
	mov r9,r0   /* save adresse retournée par mmap */
	/********************************************************/
	/* calcul du dessin à afficher       */
	bl dessin

    /* fermeture mapping */
	mov r0,r9   /* adresse map  framebuffer */
	ldr r1,=fix_info
    ldr r1,[r1,#FBFIXSCinfo_smem_len]    /* nb de caracteres  */
	mov r7, #91 /* appel fonction systeme pour UNMAP */
    swi #0 
	cmp r0,#0
	blt erreur1	

	/* fermeture device */
	mov r0,r10     /* recup FB du device */
	mov r7, #CLOSE /* fermeture */
    swi 0 
	ldr r0,=szMessFinOK   /* r0 ← adresse chaine */
	bl affichageMess  /* affichage message dans console   */
	b 100f
erreurFix: 
	ldr r1,=szMessErrFix  /* r0 <- code erreur r1 <- adresse chaine */
    bl   afficheerreur   /*appel procedure  */		
	mov r0,#1       /* erreur */
	b 100f	
erreurVar: 
	ldr r1,=szMessErrVar  /* r0 <- code erreur r1 <- adresse chaine */
    bl   afficheerreur   /*appel procedure  */		
	mov r0,#1       /* erreur */
	b 100f	

erreur:	
	ldr r1,=szMessErreur   /* r0 <- code erreur r1 <- adresse chaine */
    bl   afficheerreur   /*appel procedure  */		
	mov r0,#1       /* erreur */
	b 100f	
erreur1:	
	ldr r1,=szMessErreur1   /* r1 <- adresse chaine */
	bl   afficheerreur   /*appel procedure  */		
	mov r0,#1       /* erreur */
	b 100f			
erreur2:	
	ldr r1,=szMessErreur2   /* r1 <- adresse chaine */
	bl   afficheerreur   /*appel procedure  */		
	mov r0,#1       /* erreur */
	b 100f			
		/* fin de programme standard  */
100:		
	pop {fp,lr}   /* restaur des  2 registres */
	mov r0,#0
	mov r7, #EXIT @ appel fin du programme
    swi 0 
/************************************/	   
iFlagsMmap: .int PROT_READ|PROT_WRITE
szMessErreur: .asciz "Erreur ouverture fichier.\n"
szMessErreur1: .asciz "Erreur fermeture fichier.\n"
szMessErreur2: .asciz "Erreur mapping fichier.\n"
szMessDebutPgm: .asciz "Début du programme. \n"
szMessFinOK: .asciz "Fin normale du programme. \n"
szMessErrFix:  .asciz  "Impossible lire info fix framebuffer  \n"
szMessErrVar:  .asciz  "Impossible lire info var framebuffer  \n"
.align 4
/***************************************************/
/*   dessin                  */
/***************************************************/
/* r9 adresse memoire framebuffer  */
/* tous les registres sont utilisés dans cette procédure */
dessin:
    push {fp,lr}    /* save des  2 registres fp et retour */
    push {r1-r12}
    ldr r1,=iCouleurFond
    ldr r1,[r1]   @ couleur du fond
    ldr r0,=fix_info     /* recup de la taille de la zone memoire mmap */
    ldr r0,[r0,#FBFIXSCinfo_smem_len]    
    bl coloriageFond  
  
  @ calcul des points du cercle
     mov r0,#200    @ position x du centre
     mov r1,#200    @ position y du centre
     ldr r2,=var_info
     ldr r2,[r2,#FBVARSCinfo_xres]   @ pour largeur de l'écran 
     mov r3,#80     @ rayon du cercle
     ldr r4,=zonePoints2   @ zone de stockage des points
     ldr r5,=nbpointsdr2   @ nombre de points pour un octant
     bl enregCercleSH
     ldr r0,=nbpointsdr2
     ldr r0,[r0]

  @ affichage du cercle à partir des points calculés
  mov r0,#0   @ rouge
  mov r1,#255   @ vert
  mov r2,#0     @ bleu
  bl codeRGB
  mov r4,r0   @ couleur cercle 
  ldr r2,=var_info
  ldr r2,[r2,#FBVARSCinfo_xres]   @  pour largeur de l'écran
  ldr r0,=zonePoints2
  ldr r1,=nbpointsdr2   @ attention pour un octant
  ldr r1,[r1]
  lsl r1,#3    @ multiplie par 8
  bl balayageCercle
 
  @ rotation du rayon
  ldr r0,=zonePoints2
  ldr r1,=nbpointsdr2   @ attention pour un octant
  ldr r1,[r1]
  ldr r2,=var_info
  ldr r2,[r2,#FBVARSCinfo_xres]   @ pour largeur de l'écran
  mov r4,#200     @ position x du centre
  mov r5,#200     @ position y du centre
  bl rotationRayon
 
    
100:   
   /* fin standard de la fonction  */
    pop {r1-r12}
   	pop {fp,lr}   /* restaur des  2 registres r6 et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	

/********************************************************/
/*   Coloriage du fond                                  */
/********************************************************/
/* r0 contient la taille memoire */
/* r1 contient la couleur 32 bits */
/* r9 adresse memoire framebuffer  */
coloriageFond:
  push {r2,lr}    /* save des  2 registres r2 et retour */
  mov r2,#0
1:
  str r1,[r9,r2]
  add r2,#4
  cmp r2,r0
  blt 1b  
100:   
   /* fin standard de la fonction  */ 
   pop {r2,lr}   /* restaur des  2 registres r2 et retour  */
   bx lr                   /* retour de la fonction en utilisant lr  */	


/********************************************************/
/*   Enregistrement des points du cercle en mémoire    */
/*   Sens Horaire                                                    */
/********************************************************/
/* r0 position x  */
/* r1 position y  */
/* r2 longueur ligne */
/* r3 rayon      */
/* r4 zone mémoire d'enregistrement */
/* r5 zone mémoire nombre de points */
enregCercleSH:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r0-r10}   /* save autres registres en nombre pair */
   cmp r3,#0     /* verif rayon différent de zero */
   beq 100f
   mov r7,r0    @save position x
   mov r8,r1    @ position y
   bl comptepointsOctant
   str r0,[r5]   @ stockage nombre de point 
   sub r5,r0,#1  @ position de stockage dans un octant (nb points - 1)
   mov r11,r0   @ save nombre de points pour calcul octant
   mov r10,r3  @ save du rayon
   mov r9,r4    @ save adresse memoire stockage   
   mov r6,#0 
   sub r4,r6,r10    @ r4 <-   -rayon
  mov r3,#0     @ position du stockage dans l'octant
 1:      @ début de boucle
   @ cas du premier octant 
   add r0,r7,r6    @ calcul position x d'un point
   sub r1,r8,r10    @ calcul position y d'un point
   mov r2,#0         @ début nb point octant
   add r2,r3         @ calcul de l'indice de stockage en croissant
   lsl r2,#1         @ multiplié par 2 car on stocke x et y
   str r0,[r9,r2,lsl #2]    @ stockage x en memoire à l'indice r2 * 4 octets
   add r2,#1            @ + 1 dans l'indice 
   str r1,[r9,r2,lsl #2] @ pour stocker y
     @ cas du deuxieme octant 
   add r0,r7,r10   @ calcul x
   sub r1,r8,r6    @ calcul y
   mov r2,#1         @ ajout 1 fois nb points octant
   mul r2,r11,r2    @ 
   add r2,r5        @ calcul de l'indice de stockage en decroissant
   lsl r2,#1
   str r0,[r9,r2,lsl #2]    @ 
   add r2,#1
   str r1,[r9,r2,lsl #2]
      @ cas du troisieme octant 
   add r0,r7,r10   @ calcul x 
   add r1,r8,r6     @ calcul y
   mov r2,#2         @ ajout 2 fois nb points octant
   mul r2,r11,r2    @ 
   add r2,r3         @ calcul de l'indice de stockage en croissant
   lsl r2,#1
   str r0,[r9,r2,lsl #2]    @ 
   add r2,#1
   str r1,[r9,r2,lsl #2]
   @ cas du 4ieme octant 
   add r0,r7,r6
   add r1,r8,r10
   mov r2,#3         @ ajout 3 fois nb point octant
   mul r2,r11,r2    @ 
   add r2,r5
   lsl r2,#1
   str r0,[r9,r2,lsl #2]    @   
   add r2,#1
   str r1,[r9,r2,lsl #2]
   @ cas du 5ieme octant 
   sub r0,r7,r6
   add r1,r8,r10
   mov r2,#4         @ ajout 4 fois nb point octant
   mul r2,r11,r2    @ 
   add r2,r3
   lsl r2,#1
   str r0,[r9,r2,lsl #2]    @ nouveau 5 OK
   add r2,#1
   str r1,[r9,r2,lsl #2]
   @ cas du 6ieme octant 
   sub r0,r7,r10
   add r1,r8,r6
   mov r2,#5         @ ajout 5 fois nb point octant
   mul r2,r11,r2    @ 
   add r2,r5
   lsl r2,#1
   str r0,[r9,r2,lsl #2]    @ octant 6  nouveau 6  OK
   add r2,#1
   str r1,[r9,r2,lsl #2]
   @cas du 7ieme octant 
   sub r0,r7,r10
   sub r1,r8,r6
   mov r2,#6         @ ajout 6 fois nb point octant
   mul r2,r11,r2    @ 
   add r2,r3
   lsl r2,#1
   str r0,[r9,r2,lsl #2]    @ 7
   add r2,#1
   str r1,[r9,r2,lsl #2]
   @ cas du 8ieme octant 
   sub r0,r7,r6
   sub r1,r8,r10
   mov r2,#7         @ ajout 7 fois nb point octant
   mul r2,r11,r2    @ 
   add r2,r5
   lsl r2,#1
   str r0,[r9,r2,lsl #2]    @ 
   add r2,#1
   str r1,[r9,r2,lsl #2]
   
   @ suite des calculs pour les boucles  
   add r3,#1    @ pour calcul indice croissant
   sub r5,#1    @ pour calcul indice decroissant
   add r4,r6    @ ajout y à ecart
   add r6,#1    @ Y + 1
   add r4,r6     @ ajout y à ecart
   cmp r4,#0     @ ecart > 0
   subge r4,r10   @ oui on enleve X
   subge r10,#1   @ x - 1
   subge r4,r10    @ oui on enleve X
   cmp r10,r6   @   x>= y ?
   bge 1b      @   oui boucle 
   @c'est fini
      
100:   
   /* fin standard de la fonction  */
   	pop {r0-r10}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
	
	
/********************************************************/
/*   Comptage nombre points du cercle en mémoire    */
/*                                                      */
/********************************************************/
/* r0 position x  */
/* r1 position y  */
/* r2 longueur ligne */
/* r3 rayon      */
/* r0 retoune le nombre de points */
comptepointsOctant:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r1-r10}   /* save autres registres en nombre pair */
   cmp r3,#0     /* verif rayon différent de zero */
   beq 100f
   mov r6,#0    
   sub r4,r6,r3    @ r4 <-   -rayon
   mov r7,r0    @ position x
   mov r8,r1    @ position y
   mov r0,#0
 1:      @ début de boucle
   add r0,#1     @ comptage pour un octant
   
   add r4,r6   @ suite des calculs pour les boucles  
   add r6,#1    @ Y + 1
   add r4,r6
   cmp r4,#0
   subge r4,r3
   subge r3,#1   @ x - 1
   subge r4,r3
   cmp r3,r6   @ 
   bge 1b
   @c'est fini
      
100:   
   /* fin standard de la fonction  */
   	pop {r1-r10}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	

/********************************************************/
/*   rotation d'un rayon autour du centre               */
/*                                                      */
/********************************************************/
/* r0 adresse des points  */
/* r1 nombre de points  */
/* r2 largeur ecran     */
/* r3 couleur RGB 32 bits */
/* r4 pos x du centre */
/* r5 pos y du centre */ 
rotationRayon :
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r0-r9}   /* save autres registres en nombre pair */	
   mov r6,r0
   lsl r7,r1,#3  /* * 8 nombre de points total sur le cercle */ 
   mov r0,r4
   mov r1,r5
   mov r8,#0   @ indice de boucle
 1:   @ boucle  
   lsl r10,r8,#3    @ * 8 octets
   ldr r4,[r6,r10]    @ position x arrivée
   add r10,#4
   ldr r5,[r6,r10] @ position y arrivée
   ldr r3,rouge   @ couleur du rayon
   /* r0 position x depart */
/* r1 position y  depart */
/* r2 longueur ligne */
/* r3 couleur RGB 32 bits */
/* r4 position x arrivée */
/* r5 position y arrivée */
    bl traceLigne
	push {r0-r2,r7}
	
	mov r0,r9
	ldr r1,=fix_info
    ldr r1,[r1,#FBFIXSCinfo_smem_len]    @ nb de caracteres  
	mov r2,#MS_SYNC    @ A REVOIR CE FLAG ms_sync 
	mov r7, #0x90 @ appel fonction systeme pour SYNC 
    swi #0 
	ldr r0,=iSecondes
	mov r1,#0    @ temps d'attente 0s
	str r1,[r0]
	ldr r1,=#500000000    @ temps d'attente en nano secondes soit 0,5s
	str r1,[r0,#4]
	ldr r0,=iZonesAttente
	ldr r1,=iZonesTemps
	mov r7, #0xa2 /* appel fonction systeme  pour l'attente */
    swi 0 	

	pop {r0-r2,r7}
	ldr r3,=iCouleurFond
    ldr r3,[r3]   @ pour effacer la ligne avec couleur du fond
	bl traceLigne
	add r8,#1
	cmp r8,r7
	blt 1b    @ boucle
	
	
100:   
   /* fin standard de la fonction  */
   	pop {r0-r9}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
rouge: .int 0xFF0000	

/********************************************************/
/*   balayage point du cercle et affichage              */
/*               pour controle                          */
/********************************************************/
/* r0 adresse des points  */
/* r1 nombre de points  */
/* r2 longueur ligne */
/* r3 couleur RGB 32 bits */
balayageCercle:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r0-r9}   /* save autres registres en nombre pair */	
   mov r5,#0
   mov r6,r0
   mov r7,r1
 1:  
   lsl r8,r5,#1
   ldr r0,[r6,r8,lsl #2]
   cmp r0,#0
   beq 2f
   add r8,#1
   ldr r1,[r6,r8,lsl #2]
   cmp r1,#0
   beq 2f
   bl  aff_pixel_codeRGB32
2:
  add r5,#1
  cmp r5,r7
  blt 1b
  
100:   
   /* fin standard de la fonction  */
   	pop {r0-r9}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */			
/********************************************************/
/*   Tracage de lignes                                  */
/*   Merci au site http://betteros.org pour cet algoritme */
/********************************************************/
/* r0 position x depart */
/* r1 position y  depart */
/* r2 longueur ligne */
/* r3 couleur RGB 32 bits */
/* r4 position x arrivée */
/* r5 position y arrivée */
/* r9 adresse memoire framebuffer  */
traceLigne:
    push {fp,lr}    /* save des  2 registres frame et retour */
    push {r0-r11}   /* save autres registres en nombre pair */
	cmp r4,r0       @ arrivee x > départ x 
    subge r6,r4,r0   @ oui calcul écart
	movge r10,#1     @ et maj indice à 1
	sublt r6,r0,r4   @sinon calcul ecart inverse dxabs 
	movlt r10,#-1   @  et maj indice à -1 sdx
	cmp r5,r1        @ idem pour les y
	subge r7,r5,r1
	movge r11,#1
	sublt r7,r1,r5  @dyabs
	movlt r11,#-1  @ sdy
	lsr r4,r7,#1   @x  Ok c'est bien de dyabs !!
	lsr r5,r6,#1   @y 
	cmp r6,r7 @ comparaison des variations
	blt 2f   @ cas 2  variation de x plus petite que variation de y
	mov r8,#0 @ cas 1 variation x >= variation y  init indice de boucle
 1:     @ debut de boucle       
    add r5,r7    @ y + dyabs
	cmp r5,r6
	subge r5,r6    @ y - dxabs
	addge r1,r11
	add  r0,r10   @ on ajoute ou retranche 1 à x
	bl  aff_pixel_codeRGB32     @ affichage du pixel r0,r1
    add r8,#1
	cmp r8,r6   @ nombre de pixels axe x atteinte ?
    blt 1b     @ non on boucle
	b 100f
 2:  
    mov r8,#0   @ cas 2  init indice de boucle
 3:
    add r4,r6    @ x + dxabs
	cmp r4,r7
	subge r4,r7    @ x - dyabs
	addge r0,r10
	add  r1,r11   @ on ajoute ou retranche 1 à y
	bl  aff_pixel_codeRGB32   @ affichage du pixel r0,r1
    add r8,#1
	cmp r8,r7  @ nombre de pixels axe y atteinte ?
    blt 3b    @ non on boucle
 
 
100:   
    /* fin standard de la fonction  */
    pop {r0-r11}   /* save autres registres en nombre pair */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
  	
/********************************************************/
/*   Tracage de cercles                                 */
/*                                                      */
/********************************************************/
/* r0 position x  */
/* r1 position y  */
/* r2 longueur ligne */
/* r3 rayon      */
/* r4 couleur RGB 32 bits */
/* r5 0 = vide  1 = plein  */
/* r9 adresse memoire framebuffer  */
traceCercle:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r0-r10}   /* save autres registres en nombre pair */
   cmp r3,#0     /* verif rayon différent de zero */
   beq 100f
   mov r10,r3  @ save du rayon
   mov r3,r4   @ couleur
   mov r6,#0    
   sub r4,r6,r10    @ r4 <-   -rayon
   mov r7,r0    @ position x
   mov r8,r1    @ position y
 1:      @ début de boucle
   add r0,r7,r10   @ ajout du rayon à la position x de départ
   add r1,r8,r6    
   bl  aff_pixel_codeRGB32
   sub r0,r7,r10
   add r1,r8,r6
   bl  aff_pixel_codeRGB32
   add r0,r7,r10
   sub r1,r8,r6
   bl  aff_pixel_codeRGB32
   sub r0,r7,r10
   sub r1,r8,r6
   bl  aff_pixel_codeRGB32 
   @ 2ième
   add r0,r7,r6
   add r1,r8,r10
   bl  aff_pixel_codeRGB32
   sub r0,r7,r6
   add r1,r8,r10
   bl  aff_pixel_codeRGB32
   add r0,r7,r6
   sub r1,r8,r10
   bl  aff_pixel_codeRGB32
   sub r0,r7,r6
   sub r1,r8,r10
   bl  aff_pixel_codeRGB32
   cmp r5,#0          @  cercle vide ou plein ?
   beq 2f
   mov r11,r4         @ on le remplit en tracant des droites horizontales  
   add r1,r7,r6
   sub r0,r7,r6
   add r4,r8,r10
   bl traceDroiteH
   add r1,r7,r6
   sub r0,r7,r6
   sub r4,r8,r10
   bl traceDroiteH
   add r1,r7,r10
   sub r0,r7,r10
   add r4,r8,r6
   bl traceDroiteH
   add r1,r7,r10
   sub r0,r7,r10
   sub r4,r8,r6
   bl traceDroiteH
   mov r4,r11
   
2:   @ suite des calculs pour les boucles  
   add r4,r6
   add r6,#1    @ Y + 1
   add r4,r6
   cmp r4,#0
   subge r4,r10
   subge r10,#1   @ x - 1
   subge r4,r10
   cmp r10,r6   @ 
   bge 1b
   @c'est fini
      
100:   
   /* fin standard de la fonction  */
   	pop {r0-r10}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
	
/********************************************************/
/*   Tracage droite horizontale                         */
/*                                                      */
/********************************************************/
/* r0 position x  */
/* r1 position x fin  */
/* r2 longueur ligne */
/* r3 couleur RGB 32 bits */
/* r4 position y */
traceDroiteH:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r0-r6}   /* save autres registres en nombre pair */
   cmp r0,r1     /* verif x fin différent de x */
   beq 100f
   mov r5,r1
   mov r1,r4    @ position y
 1:
    bl  aff_pixel_codeRGB32
	add r0,#1
	cmp r0,r5
	ble 1b
 
100:   
   /* fin standard de la fonction  */
   	pop {r0-r6}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
/********************************************************/
/*   Tracage droite verticale                         */
/*                                                      */
/********************************************************/
/* r0 position y  */
/* r1 position y fin  */
/* r2 longueur ligne */
/* r3 couleur RGB 32 bits */
/* r4 position x */
traceDroiteV:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r0-r6}   /* save autres registres en nombre pair */
   cmp r0,r1     /* verif x fin différent de x */
   beq 100f
   mov r5,r1
   mov r1,r0
   mov r0,r4    @ position x
 1:
    bl  aff_pixel_codeRGB32
	add r1,#1
	cmp r1,r5
	ble 1b
 
100:   
   /* fin standard de la fonction  */
   	pop {r0-r6}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */			

/***************************************************/
/*   gestion des pixels en 32 bits                  */
/***************************************************/
/* r9 adresse memoire framebuffer  */
/* r0 position x */
/* r1 position y */
/* r2 longueur ligne */
/* r3 couleur  rouge  */
/* r4 couleur  vert  */
/* r5 couleur  bleue  */
put_pixel_RGB32:
   push {fp,lr}    /* save des  2 registres fp et retour */
   push {r0-r6}
   /* calcul position pixel */
   mul r6,r1,r2   @ calcul de y * nombre de pixels par ligne
   add r0,r0,r6   @ ajout de x
   mov r6,#4
   mul r0,r6,r0    @ multiplié par 4 (32 bits) pour avoir la position en octets
   strb r5,[r9,r0]   @ stockage couleur bleue dans zone memoire mmap
   add r0,#1
   strb r4,[r9,r0]    @ stockage couleur verte
   add r0,#1
   strb r3,[r9,r0]     @ stockage couleur rouge
   add r0,#1
    mov r6,#0         @ stockage zero dans 4 ième octet
   strb r6,[r9,r0]  
   
100:   
   /* fin standard de la fonction  */
    pop {r0-r6}
   	pop {fp,lr}   /* restaur des  2 registres fp et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
/***************************************************/
/*   affichage des pixels en 32 bits                  */
/***************************************************/
/* r9 adresse memoire framebuffer  */
/* r0 position x */
/* r1 position y */
/* r2 longueur ligne */
/* r3 couleur code RGB sur 32 bits  */

aff_pixel_codeRGB32:
   push {fp,lr}    /* save des  2 registres fp et retour */
   push {r0-r4}
   /* calcul position pixel */
   mul r4,r1,r2   @ calcul de y * nombre de pixels par ligne
   add r0,r0,r4   @ ajout de x
   mov r4,#4
   mul r0,r4,r0    @ multiplié par 4 (32 bits) pour avoir la position en octets
   str r3,[r9,r0]   @ stockage couleur bleue dans zone memoire mmap
   
100:   
   /* fin standard de la fonction  */
    pop {r0-r4}
   	pop {fp,lr}   /* restaur des  2 registres fp et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */			
/********************************************************/
/*   Creation couleurs RGB                              */
/*                                                      */
/********************************************************/
/* r0 rouge r1 vert  r2 bleu */
/* r0 retourne le code RGB  */
/* ATTENTION pas de save du registre lr, ne jamais faire appel à une sous routine ici */
codeRGB:
  //push {fp,lr}    /* save des  2 registres frame et retour */
    lsl r0,#16
    lsl r1,#8
    eor r0,r1
    eor r0,r2
  //	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */
/***************************************************/
/*   Calcul racine carree entiere par méthode de Heron  */
/*                                                 */
/***************************************************/
/* r0 nombre  */
/* r0 retourne la racine carree */
racinecarree:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r1-r6}   /* save autres registres en nombre pair */
   cmp r0,#0     /* verif différent de zero */
   beq 100f
   mov r4,r0      @A
   lsr r1,r0,#1    @division par 2 -> diviseur
 1:
   mov r5,r1   @ save résultat précedent
   mov r0,r4   @ division de A par le resultat précedent
   bl division @ attention r0,r2 et r3 sont modifiés
   add r1,r2   @ ajout du quotient au resultat précedent
   lsr r1,#1    @division du tout par 2 
   // bl vidtousregistres
   cmp r5,r1   @comparaison du resultat au résultat précedent
   bhi 1b     @ boucle si supérieur
   mov r0,r1    @ et on retourne le résultat.
   
100:   
   /* fin standard de la fonction  */
   	pop {r1-r6}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	   	
/*********************************************/
/*       CONSTANTES GENERALES                */ 
/********************************************/
.include "../constantesARM.inc"
/***************************************************/
/*      DEFINITION DES STRUCTURES                 */
/***************************************************/
.include "../descStruct.inc"

