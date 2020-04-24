/* programme traçage de figures utilisation du FrameBuffer  */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* traçages et remplissage  en 32 bits par pixel */
/*********************************************/
/*constantes du programme */
/* Important : ces données ne peuvent être changées sauf si vous changer aussi */
/* les dimensions de l'affichage dans les données variables du FrameBuffer */
/* voir le programme précédent.    */
.equ LARGEURECRAN, 800
.equ HAUTEURECRAN, 480
.equ TAILLEECRANOCTET, LARGEURECRAN * HAUTEURECRAN *4
	
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
FBIOGET_FSCREENINFO: .word 0x4602
FBIOGET_VSCREENINFO: .word 0x4600
FBIOPUT_VSCREENINFO: .word 0x4601   @ code pour l'écriture des données variables. */
poly1:      @ exemple de polygones  à 4 sommets
             .int 100   @ x point 1 
	         .int 300   @ y point 1
	         .int 80    @ point 2 
			 .int 350
			 .int 200   @ point 3 
			 .int 380
			 .int 220   @ point 4 
			 .int 350
	fin:   .int -1     @ pour signaler la fin des ponits 
poly2:      @ exemple de polygones  à 6 sommets
            .int 300   @ point 1 
	        .int 100
	         .int 300    @ point 2 
			 .int 300
			 .int 350    @ point 3
			 .int 150
			 .int 400   @ point 4 
			 .int 300
			 .int 400   @ point 5
			 .int 100
			 .int 350   @ point 6 
			 .int 150
	fin2:   .int -1     @ pour signaler la fin des points 
triangle1: 	
            .int 400   @ point 1 
	        .int 100
	         .int 400    @ point 2 
			 .int 300
			 .int 450    @ point 3
			 .int 150
			 .int -1
triangle2: 
			 .int 500   @ point 4 
			 .int 300
			 .int 500   @ point 5
			 .int 100
			 .int 450   @ point 6 
			 .int 150
			 .int -1
iTaille: .int TAILLEECRANOCTET
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
zoneTravail: .skip TAILLEECRANOCTET   /* définition pour le coloriage polygone */

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
	//bl vidtousregistres
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
/*   dessin des figures                            */
/*   ATTENTION : aucun controle de dépassement des */
/*   dimensions de l'écran donc risque d'erreur    */ 
/****************************************************/
/* r9 adresse memoire framebuffer  */
/* tous les registres sont utilisés dans cette procédure */
dessin:
    push {fp,lr}    /* save des  2 registres fp et retour */
    push {r1-r12}
    mov r0,#255   @ rouge
    mov r1,#255   @ vert
    mov r2,#255   @ bleu    3 fois 255 cela fait du blanc
    bl codeRGB      @ fournit le code couleur sur 32 bits
    mov r1,r0      @ couleur du fond
    ldr r0,=fix_info     /* recup de la taille de la zone memoire mmap */
    ldr r0,[r0,#FBFIXSCinfo_smem_len]    
    bl coloriageFond     
@ traçage d'un cercle vide
    mov r0,#0     @ rouge
    mov r1,#255   @ vert
    mov r2,#0     @ bleu 
    bl codeRGB
    mov r4,r0   @ couleur du cercle
    ldr r2,=var_info
    ldr r2,[r2,#FBVARSCinfo_xres]   @ pour longueur de la ligne
    mov r0,#200  @ position X
    mov r1,#110  @ position Y
    mov r3,#20   @ rayon
    mov r5,#0    @vide
    bl traceCercle
  
@ traçage d'un cercle plein
    mov r0,#255     @ rouge
    mov r1,#255   @ vert
    mov r2,#0     @ bleu 
    bl codeRGB
    mov r4,r0   @ couleur du cercle
    ldr r2,=var_info
    ldr r2,[r2,#FBVARSCinfo_xres]   @ pour longueur de la ligne
    mov r0,#200  @ position X
    mov r1,#200  @ position Y
    mov r3,#50   @ rayon
    mov r5,#1    @ pour remplissage du cercle
    bl traceCercle
  
@ traçage d'une droite horizontale
    mov r0,#0   @ rouge
    mov r1,#0   @ vert
    mov r2,#255 @ bleue
    bl codeRGB
    mov r3,r0   @ couleur droite
    ldr r2,=var_info
    ldr r2,[r2,#FBVARSCinfo_xres]   @ pour longueur de la ligne
    mov r0,#0  @ position X
    mov r1,#400  @ position X1
    mov r4,#400   @  position Y
    bl traceDroiteH     @ trace une droite horizontale 
@ autre traçage droite avec longueur	
	mov r0,#0  @ position X
    ldr r1,=#410  @ position Y
    mov r4,#400   @  longueur
    bl traceDroiteH_v2     @ trace une droite horizontale 
  
@ traçage d'une droite verticale
    mov r0,#255   @ rouge
    mov r1,#0   @ vert
    mov r2,#255 @ bleue
    bl codeRGB
    mov r3,r0   @ couleur droite
    ldr r2,=var_info
    ldr r2,[r2,#FBVARSCinfo_xres]   @ pour longueur de la ligne
    mov r0,#0  @ position Y
    mov r1,#200  @ position Yfin
    mov r4,#200   @  position X
    bl traceDroiteV  @ trace une droite verticale 
  
@ traçage d'un triangle à l'aide de 3 droites quelconques
    mov r0,#128   @ rouge
    mov r1,#128   @ vert
    mov r2,#128 @ bleue
    bl codeRGB
    mov r3,r0   @ couleur droite
    ldr r2,=var_info
    ldr r2,[r2,#FBVARSCinfo_xres]   @ pour longueur de la ligne
    mov r0,#50  @ position X
    mov r1,#200  @ position Y
    mov r4,#180   @  position X FIN
    mov r5,#300   @ position Y FIN
    bl traceLigne     @ trace une ligne quelconque
    mov r0,#180  @ position X
    mov r1,#300  @ position Y
    mov r4,#100   @  position X FIN
    mov r5,#50   @ position Y FIN
    bl traceLigne
    mov r0,#100  @ position X
    mov r1,#50  @ position Y
    mov r4,#50   @  position X FIN
    mov r5,#200   @ position Y FIN
    bl traceLigne
  
@ traçage d'un polygone
    mov r0,#255   @ rouge
    mov r1,#0   @ vert
    mov r2,#0 @ bleue
    bl codeRGB
    mov r3,r0   @ couleur droite
    ldr r2,=var_info
    ldr r2,[r2,#FBVARSCinfo_xres]   @ pour longueur de la ligne
    ldr r0,=poly1   @ adresse des points du polygones
    mov r1,#4
    ldr r4,=zoneTravail
    ldr r5,=iTaille
    ldr r5,[r5]
    bl tracePolygone  @ trace un polygone quelconque vide
   @ traçage d'un polygone plein
    mov r0,#0   @ rouge
    mov r1,#255   @ vert
    mov r2,#0 @ bleue
    bl codeRGB
    mov r3,r0   @ couleur 
    ldr r2,=var_info
    ldr r2,[r2,#FBVARSCinfo_xres]   @ pour longueur de la ligne
    ldr r0,=poly2   @ adresse des points du polygones
    mov r1,#6        @ nombre de points
    ldr r4,=zoneTravail
    ldr r5,=iTaille
    ldr r5,[r5]
    bl coloriagePoly  @ trace un polygone quelconque plein 
  
@ correction du défaut précedent en utilisant des triangles
    mov r0,#0   @ rouge
    mov r1,#0   @ vert
    mov r2,#255 @ bleue
    bl codeRGB
    mov r3,r0   @ couleur 
    ldr r2,=var_info
    ldr r2,[r2,#FBVARSCinfo_xres]   @ pour longueur de la ligne
    ldr r0,=triangle1   @ adresse des points du polygones
    mov r1,#3
    ldr r4,=zoneTravail
    ldr r5,=iTaille
    ldr r5,[r5]
    bl coloriagePoly  @ trace un polygone quelconque plein 
    ldr r0,=triangle2   @ adresse des points du polygones
    mov r1,#3
    ldr r4,=zoneTravail
    ldr r5,=iTaille
    ldr r5,[r5]
    bl coloriagePoly  @ trace un polygone quelconque plein 
@ pour synchronisation mémoire mmap et periphérique
  	ldr r1,=fix_info
    ldr r1,[r1,#FBFIXSCinfo_smem_len]    @ nb de caracteres  
	mov r2,#MS_SYNC    
	mov r7, #0x90 @ appel fonction systeme pour Synchro
    swi #0 
    
100:    /* fin standard de la fonction  */
    pop {r1-r12}
   	pop {fp,lr}       /* restaur des  2 registres r6 et retour  */
    bx lr             /* retour de la fonction en utilisant lr  */	

/********************************************************/
/*  Remplissage d'un polygone                           */
/*  limite taille image 4096 pixels                     */
/*  modifier la couleur du fond si dessin polygone en couleur blanc */
/********************************************************/
/* r0 adresse des points  */
/* r1 nombre de points  */
/* r2 longueur résolution X */
/* r3 couleur RGB 32 bits */
/* r4 adresse zone memoire de travail de x * y */
/* r5 taille memoire de travail en octets soit (x * y * 4) */
coloriagePoly:
    push {fp,lr}    /* save des  2 registres fp et retour */
	push {r0-r10,r12}
	mov r12,r9 @ sauver memoire mmap
	mov r11,r0  @ sauver adresse des points
	mov r10,r1  @ sauver nombre de points
	mov r9,r4   @ remplir de blancs la zone de travail de x * y 
	mov r0,r5   @ taille de la zone
	mov r1,#0xFFFFFF  @ couleur blanche 
	bl coloriageFond
	mov r0,r11   @ restaur adresse des points
	mov r1,r10   @ restaur nb de points
	bl tracePolygone  @ dessiner le polygone en zone de travail
	mov r9,r12   @ restaur adresse memoire mmap
	mov r0,r11  @ restaur adresse point
	mov r10,r4  @ save zone memoire de travail
	mov r8,#0 @ balayage des points pour trouver le x et y mini et maxi
	mov r6,#0  @ x maxi
	mov r7,#0xFFFFFF  @ x mini
	mov r5,#0  @ y maxi
	mov r4,#0xFFFFFF  @ y mini
	mov r12,#0xFFFFFF @ Zone couleur blancs pour la comparaison 
1:  
    ldr r11,[r0,r8] @ lecture du x pour chercher le x mini et maxi
    cmp r11,#-1     @ fin des points ?
    beq 2f
    cmp r11,r6
    movgt r6,r11 @ x maxi
    cmp r11,r7
    movlt r7,r11  @ x mini
    add r8,#4  
    ldr r11,[r0,r8] @ lecture du y pour chercher le y mini et maxi
    cmp r11,r5
    movgt r5,r11   @y maxi
    cmp r11,r4
    movlt r4,r11   @ y mini
    add r8,#4      @ ajout au pointeur
    b 1b          @ et on boucle 
2:     
  @ boucle de balayage du y mini à y maxi  trouvés précedement
    mov r11,r7  @ x mini
	mov r0,#0x1000  @ init du registre pour stocker le premier point trouvé
3:  @ boucle de balayage de x mini à x maxi
    mul r8,r2,r4      @ il faut calculer la position en mémoire de travail 
    add r8,r11        @ en multipliant y par la longueur d'une ligne et plus position x
    ldr r8,[r10,r8,lsl #2]    @ en zone de travail
    cmp r8,r12       @ est ce un blanc ?
    beq  4f         @ oui  
    cmp r0,#0x1000  @ premier point ou autre ?
    moveq r0,r11 @ si point1x,y <>blanc le garder nbpoint =1
    beq 4f
    mov r1,r11   @ si point2x,y <> blanc et nbpoint = 1
    bl traceDroiteH @ dessiner une droite horizontale du point1 au point 2 zone affichage FB
    mov r0,#0x1000  @ raz registre
4:   @ x+1 et boucle
    add r11,#1
    cmp r11,r6   @ x maxi atteint ?
    ble 3b
    @ y+1 et boucle 
    add r4,#1
    cmp r4,r5   @ y maxi atteint ?
    ble 2b
  
100:   /* fin standard de la fonction  */ 
    pop {r0-r10,r12}
    pop {fp,lr}   /* restaur des  2 registres fp et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
/********************************************************/
/*   Coloriage du fond                                  */
/********************************************************/
/* r0 contient la taille memoire */
/* r1 contient la couleur 32 bits */
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
/*   Tracage de lignes                                  */
/*   Merci au site http://betteros.org pour cet algoritme */
/********************************************************/
/* r0 position x depart */
/* r1 position y  depart */
/* r2 longueur ligne */
/* r3 couleur RGB 32 bits */
/* r4 position x arrivée */
/* r5 position y arrivée */
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
	mov r8,#0 @ cas 1 variation x > variation y  init indice de boucle
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
	subge r4,r7    @ y - dyabs
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
/*   Tracage polygone quelconque                        */
/*                                                      */
/********************************************************/
/* r0 adresse des points  */
/* r1 nombre de points  */
/* r2 longueur ligne */
/* r3 couleur RGB 32 bits */
tracePolygone:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r0-r9}   /* save autres registres en nombre pair */	
   mov r6,r0
   mov r7,r1  
   mov r8,#0   @ pointeur des points
 1:  
   ldr r0,[r6,r8]    @ x
   add r8,#4
   ldr r1,[r6,r8]    @ y
   add r8,#4
   subs r7,#1
   beq 2f
   ldr r4,[r6,r8]    @ x1
   cmp r4,#-1
   beq 2f
   add r8,#4
   ldr r5,[r6,r8]     @ y1
   cmp r5,#-1
   beq 2f
   bl  traceLigne
   sub r8,#4
   b 1b
2:   @ fermeture du polygone
  mov r8,#0
  ldr r4,[r6,r8]
  add r8,#4
  ldr r5,[r6,r8]
  bl  traceLigne 

100:   
   /* fin standard de la fonction  */
   	pop {r0-r9}   /*restaur des autres registres */
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
    bge 100f
    mov r5,r1
    mov r1,r4    @ position y
1:
    bl  aff_pixel_codeRGB32
	add r0,#1
	cmp r0,r5
	ble 1b
 
100:   /* fin standard de la fonction  */
   	pop {r0-r6}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
		
/********************************************************/
/*   Tracage droite horizontale                         */
/*                                                      */
/********************************************************/
/* r0 position x  */
/* r1 position y  */
/* r2 longueur ligne */
/* r3 couleur RGB 32 bits */
/* r4 longueur */
traceDroiteH_v2:
    push {fp,lr}    /* save des  2 registres frame et retour */
    push {r0-r5}   /* save autres registres en nombre pair */
    cmp r4,#0     /* verif si longueur <> zero */
    beq 100f
	mov r5,r0
1:
    add r0,r5,r4
    bl  aff_pixel_codeRGB32
	subs r4,#1
	bge 1b
 
100:   /* fin standard de la fonction  */
   	pop {r0-r5}   /*restaur des autres registres */
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
    bge 100f
    mov r5,r1
    mov r1,r0
    mov r0,r4    @ position x
1:
    bl  aff_pixel_codeRGB32
	add r1,#1
	cmp r1,r5
	ble 1b
 
100:    /* fin standard de la fonction  */
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
   push {r0-r3}
   mul r1,r2,r1   @ calcul de y * nombre de pixels par ligne
   add r0,r0,r1   @ ajout de x
   str r3,[r9,r0,lsl #2]   @ stockage couleur bleue dans zone memoire mmap multiplié par 4 (32 bits)
   
100:   /* fin standard de la fonction  */
    pop {r0-r3}
   	pop {fp,lr}   /* restaur des  2 registres fp et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */			
/********************************************************/
/*   Creation couleurs RGB                              */
/*                                                      */
/********************************************************/
/* r0 rouge r1 vert  r2 bleu */
/* r0 retourne le code RGB  */
/* ATTENTION pas de save du registre lr, ne jamais faire appel à une sous routines ici */
codeRGB:
  //push {fp,lr}    /* save des  2 registres frame et retour */
    lsl r0,#16
    lsl r1,#8
    eor r0,r1
    eor r0,r2
  //	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	  
/*********************************************/
/*       CONSTANTES GENERALES                */ 
/********************************************/
.include "../constantesARM.inc"
/***************************************************/
/*      DEFINITION DES STRUCTURES                 */
/***************************************************/
.include "../descStruct.inc"

