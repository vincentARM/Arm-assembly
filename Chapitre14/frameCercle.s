/* programme analyse données du FrameBuffer  */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* inspiré du programme fbtest3.c du site http://raspberrycompote.blogspot.fr/2013/ */
/* Cercles de couleur  en 16,24 et 32 bits par pixel */
/* lancer fbset -depth  16 24 avant mais pas de résultat probant sur mon raspberry */

/*********************************************/
/*constantes du programme */
	
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
FBIOPUT_VSCREENINFO: .word 0x4601   @ code pour l'écriture des données variables

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
/* les descriptions des structures sont déportées dans le fichier des includes (voir en fin )*/
.align 4
fix_info: .skip FBFIXSCinfo_fin  /* reserve la place pour la structure FSCREENINFO */
.align 4
var_info: .skip FBVARSCinfo_fin  /* reserve la place pour la structure VSCREENINFO */
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
	ldr r0,=fix_info
	mov r1,#4  /* nombre de bloc a afficher */
    push {r0} /* adresse memoire */	
	push {r1}
    bl affmemoire
	
	
	/* recup de la taille necessaire */
	ldr r1,=fix_info
    ldr r1,[r1,#FBFIXSCinfo_smem_len]    /* nb de caracteres  */
	bl vidtousregistres
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

	mov r0,r9
	mov r1,#10  /* nombre de bloc a afficher */
    push {r0} /* adresse memoire */	
	push {r1}
    bl affmemoire

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
  ldr r6,=var_info
  ldr r6,[r6,#FBVARSCinfo_yres]
  mov r0,r6
  mov r1,#3
  bl division
  mov r7,r2   @ départ couleur rouge
  lsr r1,r6,#2   
  add r8,r7,r1      @ départ couleur verte
  add r11,r8,r1   @   départ couleur bleue
  ldr r6,=var_info
  ldr r6,[r6,#FBVARSCinfo_xres]   @ pour eviter utilisation dans boucle
  
  mov r1,#0     @ position y
1:  @ debut de boucle des y
  mov r0,#0     @ position x
2:  @ debut de boucle des x
  mov r4,r1   @ save de y
  mov r5,r0    @ save de x
  /* Calcul couleur rouge */
  sub r2,r7,r0     @ cr - x
  mul r3,r2,r2     @ au carre
  sub r2,r7,r1     @ cr - y
  mul r0,r2,r2     @ au carre
  add r0,r3     @ somme des 2
  bl racinecarree   @ extraction racine carree
  mov r1,#256      
  mul r0,r1,r0     @   racine carree * 256 
  mov r1,r7        @  division par cr
  bl division
  mov r1,#255    
  sub r10,r1,r2    @ et on l'enleve de 255 pour calculer la couleur rouge
  cmp r10,#0
  movlt r10,#0   @  si negatif on met zero
  /* les indices ont été perdus lors de la division */
  mov r1,r4 @ restaur y
  mov r0,r5 @ restaur x
   /* Calcul couleur verte */
  sub r2,r8,r0     
  mul r3,r2,r2
  sub r2,r7,r1
  mul r0,r2,r2
  add r0,r3
  bl racinecarree
  mov r1,#256      
  mul r0,r1,r0     @   racine carree * 256 
  mov r1,r7
  bl division
  mov r1,#255
  sub r12,r1,r2
  cmp r12,#0
  movlt r12,#0   @ couleur verte
  /* les indices ont été perdus lors de la division */
   mov r1,r4 @ restaur y
   mov r0,r5 @ restaur x
   /* Calcul couleur bleue */
  sub r2,r11,r0     
  mul r3,r2,r2
  sub r2,r7,r1
  mul r0,r2,r2
  add r0,r3
  bl racinecarree
  mov r1,#256
  mul r0,r1,r0
  mov r1,r7
  bl division
  mov r1,#255
  sub r3,r1,r2
  cmp r3,#0
  movlt r3,#0   @ couleur bleue
 /* les indices ont été perdus lors de la division */
  mov r1,r4 @ restaur y
  mov r0,r5 @ restaur x
  mov r2,r6 @ nombre de pixel par ligne 
  ldr r4,=var_info
  ldr r4,[r4,#FBVARSCinfo_bits_per_pixel]
  cmp r4,#16   @ 16 bits par pixel ?
  beq 3f
  cmp r4,#24   @ 24 bits par pixel ?
  beq 4f
  /* par defaut c'est 32 */
  mov r5,r3   @bleue  
  mov r3,r10  @rouge
  mov r4,r12  @vert
  bl put_pixel_RGB32
  b 5f

3:   @ 16 bits par pixel
  mov r5,r3   @bleue
  mov r3,r10  @rouge
  mov r4,r12  @vert
  bl put_pixel_RGB565
  b 5f
  
4:   @ 24 bits par pixel
  mov r5,r3   @bleue
  mov r3,r10  @rouge
  mov r4,r12  @vert
  bl put_pixel_RGB24
 
5:  /* suite des boucles  */
  add r0,#1
  cmp r0,r6    @ fin d'une ligne ?
  blt 2b    @ boucle des x
  add r1,#1
  ldr r5,=var_info
  ldr r5,[r5,#FBVARSCinfo_yres]
  cmp r1,r5
  blt 1b     @ boucle des y
  
100:   
   /* fin standard de la fonction  */
    pop {r1-r12}
   	pop {fp,lr}   /* restaur des  2 registres r6 et retour  */
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
/*   gestion des pixels en 24 bits                  */
/***************************************************/
/* r9 adresse memoire framebuffer  */
/* r0 position x */
/* r1 position y */
/* r2 longueur ligne */
/* r3 couleur  rouge  */
/* r4 couleur  vert  */
/* r5 couleur  bleue  */
put_pixel_RGB24:
   push {fp,lr}    /* save des  2 registres fp et retour */
   push {r0-r6}
   /* calcul position pixel */
   mul r6,r1,r2   @ position y * longueur ligne en pixel
   add r0,r0,r6      @ ajout position x
   mov r6,#3      @ 3 octets par pixel
   mul r0,r6,r0   @ donne la position en mémoire mmap
   strb r5,[r9,r0]
   add r0,#1
   strb r4,[r9,r0]
   add r0,#1
   strb r3,[r9,r0]
   
100:   
   /* fin standard de la fonction  */
    pop {r0-r6}
   	pop {fp,lr}   /* restaur des  2 registres fp et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
/***************************************************/
/*   gestion des pixels en 16 bits                  */
/***************************************************/
/* r9 adresse memoire framebuffer  */
/* r0 position x */
/* r1 position y */
/* r2 longueur ligne */
/* r3 couleur  rouge  */
/* r4 couleur  vert  */
/* r5 couleur  bleue  */
put_pixel_RGB565:
   push {fp,lr}    /* save des  2 registres fp et retour */
   push {r0-r6}
   /* calcul position pixel */
   mul r6,r1,r2   @ calcul de y * nombre de pixels par ligne
   add r0,r0,r6   @ ajout de x
   lsl r0,#1       @ multiplié par 2 (16 bits) pour avoir la position en octets
   lsr r1,r5,#3     @ division bleue par 8
   lsl r1,#11    @ deplacement bits   
   lsr r6,r4,#2    @ division vert par 4
   lsl r6,#5     @ deplacement à la position centrale
   eor r1,r6     @ positionnement 
   lsr r6,r3,#3   @ division rouge par 8
   eor r1,r6      @ positionnement. 
   strh r1,[r9,r0]   @ stockage 2 octets dans zone memoire mmap
     
100:   
   /* fin standard de la fonction  */
    pop {r0-r6}
   	pop {fp,lr}   /* restaur des  2 registres fp et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */		
  	
/********************************************************/
/*   Calcul racine carree entiere par méthode de Heron  */
/*                                                      */
/********************************************************/
/* r0 nombre  */
/* r0 retourne la racine carree */
racinecarree:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r1-r6}   /* save autres registres en nombre pair */
   cmp r0,#0     /* verif différent de zero */
   beq 100f
   mov r4,r0      @ save du nombre 
   lsr r1,r0,#1    @division par 2 -> diviseur
 1:      @ début de boucle
   mov r5,r1   @ save résultat précedent
   mov r0,r4   @ division du nombre de départ par le resultat précedent
   bl division @ attention r0,r2 et r3 sont modifiés
   add r1,r2   @ ajout du quotient au diviseur et qui est aussi le resultat précedent
   lsr r1,#1    @division du tout par 2 
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

