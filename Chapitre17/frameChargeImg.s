/* programme analyse données du FrameBuffer  */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/*     */
/* Chargement d'une image bmp */
/*********************************************/
/*constantes du programme */
/* Important : ces données ne peuvent être changées sauf si vous changer aussi */
/* les dimensions de l'affichage dans les données variables du FrameBuffer */
/* voir le programme précédent.    */
.equ LARGEURECRAN, 800
.equ HAUTEURECRAN, 480
.equ TAILLEECRANOCTET, LARGEURECRAN * HAUTEURECRAN *4
.equ COULEURFOND, 0xFFFFFF  @ blanc	
.equ TAILLEBUF,  512
.equ TAILLEBUFIMG,  1000000  
/*********************************/
/* structures pour fichier BMP   */
/* description des entêtes       */
/* structure de type  BITMAPFILEHEADER */
    .struct  0
BMFH_bfType:	          /* identification du type de fichier */
    .struct BMFH_bfType + 2
BMFH_bfSize:	          /* taille de la structure */
    .struct BMFH_bfSize + 4
BMFH_bfReserved1:	          /* reservée */
    .struct BMFH_bfReserved1 + 2	
BMFH_bfReserved2:	          /* reservée */
    .struct BMFH_bfReserved2 + 2	
BMFH_bfOffBits:	          /* Offset pour le début de l'image */
    .struct BMFH_bfOffBits + 4	
BMFH_fin:	
/***************************************/
/* structure de type  BITMAPINFOHEADER */
    .struct  0
BMIH_biSize:	          /* taille */
    .struct BMIH_biSize + 4
BMIH_biWidth:	          /* largeur image */
    .struct BMIH_biWidth + 4	
BMIH_biHeight:	          /* hauteur image */
    .struct BMIH_biHeight + 4
BMIH_biPlanes:	          /* nombre plan */
    .struct BMIH_biPlanes + 2
BMIH_biBitCount:	          /* nombre bits par pixel */
    .struct BMIH_biBitCount + 2
BMIH_biCompression:	          /* type de compression */
    .struct BMIH_biCompression + 4
BMIH_biSizeImage:	          /* taille image */
    .struct BMIH_biSizeImage + 4
BMIH_biXPelsPerMeter:	          /* pixel horizontal par metre */
    .struct BMIH_biXPelsPerMeter + 4
BMIH_biYPelsPerMeter:	          /* pixel vertical par metre */
    .struct BMIH_biYPelsPerMeter + 4
BMIH_biClrUsed:	          /*  */
    .struct BMIH_biClrUsed + 4
BMIH_biClrImportant:	          /*  */
    .struct BMIH_biClrImportant + 4
/* A REVOIR car BITMAPINFO */		
BMIH_rgbBlue:	          /* octet bleu */
    .struct BMIH_rgbBlue + 1
BMIH_rgbGreen:	          /* octet vert */
    .struct BMIH_rgbGreen + 1
BMIH_rgbRed:	          /* octet rouge */
    .struct BMIH_rgbRed + 1
BMIH_rgbReserved:	          /* reserve */
    .struct BMIH_rgbReserved + 1	
BMIH_fin:	
/* */
/**********************************************/
/* structure de type   stat  : infos fichier  */
    .struct  0
Stat_dev_t:	           /* ID of device containing file */
    .struct Stat_dev_t + 4
Stat_ino_t:	          /* inode */
    .struct Stat_ino_t + 2
Stat_mode_t:	          /* File type and mode */
    .struct Stat_mode_t + 2	
Stat_nlink_t:	           /* Number of hard links */
    .struct Stat_nlink_t + 2	
Stat_uid_t:	           /* User ID of owner */
    .struct Stat_uid_t + 2 
Stat_gid_t:	             /* Group ID of owner */
    .struct Stat_gid_t + 2 	
Stat_rdev_t:	            /* Device ID (if special file) */
    .struct Stat_rdev_t + 2 
Stat_size_deb:           /* la taille est sur 8 octets si gros fichiers */
	 .struct Stat_size_deb + 4 
Stat_size_t:	            /* Total size, in bytes */
    .struct Stat_size_t + 4 	
Stat_blksize_t:	            /* Block size for filesystem I/O */
    .struct Stat_blksize_t + 4 	
Stat_blkcnt_t:	           /* Number of 512B blocks allocated */
    .struct Stat_blkcnt_t + 4 	
Stat_atime:	           /*   date et heure fichier */
    .struct Stat_atime + 8     
Stat_mtime:	           /*   date et heure modif fichier */
    .struct Stat_atime + 8 
Stat_ctime:	           /*   date et heure creation fichier */
    .struct Stat_atime + 8 	
Stat_Fin:		
	

/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szRetourligne: .asciz  "\n"
/* nom du fichier image */
szNomImage: .asciz "dessinCercles1.bmp"
//szNomImage: .asciz "eximggrande.bmp"
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
sBuffer:  .skip TAILLEBUFIMG 

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
	/* chargement image      */
	bl chargeImage

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
/*   Chargement d'une image au format BMP          */
/***************************************************/
/* r9 adresse memoire framebuffer  */
/* r8 servira pour stocker le FD du fichier image */
/* tous les registres sont utilisés dans cette procédure */
chargeImage:
    push {fp,lr}    /* save des  2 registres fp et retour */
    push {r1-r12}
    ldr r1,=iCouleurFond
    ldr r1,[r1]   @ couleur du fond
    ldr r0,=fix_info     /* recup de la taille de la zone memoire mmap */
    ldr r0,[r0,#FBFIXSCinfo_smem_len]    
    bl coloriageFond  
	
   /* ouverture fichier image */
	ldr r0,=szNomImage    /* nom du fichier  */
	mov r1,#O_RDWR   /*  flags    */
	mov r2,#0   /* mode */
	mov r7, #OPEN /* appel fonction systeme pour ouvrir */
    swi 0 
	cmp r0,#0    /* si erreur */
	ble erreurCI
	mov r8,r0    /* save du Fd */ 
	/* recherche de la taille du fichier image */
	ldr r1,=sBuffer   /*  adresse du buffer de reception    */
	mov r7, #0x6c /* appel fonction systeme pour NEWFSTAT */
    swi 0 
	cmp r0,#0     /* si erreur */
	blt erreurCI4
	mov r0,r8     /* Fd du fichier */
	ldr r1,=sBuffer   /*  adresse du buffer de reception    */
	ldr r2,[r1,#Stat_size_t] /* taille du fichier attention sera perdu apres la lecture */
	ldr r3,=#TAILLEBUFIMG    /*  taille du buffer de reception    */
	cmp r2,r3            /* taille suffisante ? */
	bgt erreurCI7
	mov r7, #READ /* appel fonction systeme pour lire le fichier */
    swi 0 
	cmp r0,#0    /* si erreur de lecture */
	ble erreurCI2
	/*  Exemple d'affichage memoire  */
	ldr r0,=sBuffer
	mov r1,#10  /* nombre de bloc a afficher */
    push {r0} /* adresse memoire pour verification zones data*/	
	push {r1}
    bl affmemoire
	@verification type fichier
	ldr r0,=sBuffer
	ldrh r0,[r0]
	ldr r1,=#0x4D42   @ code type de fichier = BMP
	cmp r0,r1
	bne erreurCI3
	@verification nombre de bits par pixel
	ldr r0,=sBuffer
	add r0,#BMFH_fin
	ldr r1,[r0,#BMIH_biBitCount]  @ nombre de bits par Pixel
	cmp r1,#24               @ doit être 24 (3 octets).
	bne erreurCI5
	@ Verification taille de l'image
	ldr r6,[r0,#BMIH_biWidth]    @ largeur de la ligne BMP en pixel 
	ldr r7,=var_info
    ldr r7,[r7,#FBVARSCinfo_xres]   @ pour largeur de l'ecran
	cmp r6,r7
	bgt erreurCI6
	@ il faudrait aussi verifier la hauteur !!
	@ calcul longueur d'une ligne du fichier en octet 
	mov r12,r6,lsl #1    @ on multiplie largeur en pixel par 2 et on ajoute une fois
	add r12,r6    @ car 3 octets par pixel
	@ et si la ligne n'est pas un multiple de 4, il faut la completer 
	mov r11,r12
	mov r10,#4
	ands r11,#0b011    @ verif si la taille se termine par 2 bits à 00
	subne r11,r10,r11   @ sinon on calcule le complement a 4 
	addne r12,r11       @ et on l'ajoute a la ligne (et il va servir plus loin ) 
	@ calcul du complement en octet qu'il faudra ajouter pour completer une ligne
	@ pour remplirs une ligne de l'écran
	sub r7,r6    @ complement d'une ligne en pixel
	lsl r7,#2    @ * 4 pour l'avoir en nombre d'octets
	ldr r0,=sBuffer
	ldr r4,[r0,#BMFH_bfSize]  @ nombre d'octets total de l'image y compris les entetes
	ldr r2,[r0,#BMFH_bfOffBits] @ offset qui indique le début des bits de l'image
	sub r4,r2    @ donc on enlever l'offset pour avoir la taille exacte
	@ et il faut partir de la fin car l'image en BMP est inversée !!!!!!
	ldr r2,[r0,#BMFH_bfSize]  @ nombre d'octets de l'image
	mov r5,#0        @ compteur total des octets écrits dans la memoire du mapping
	mov r10,#0       @ compteur du nombre de pixel par ligne
	bl vidtousregistres
	sub r2,r12    @ on enleve le nombre d'octet de la ligne bmp du total 
1:  @ boucle de copie d'une ligne
    ldrb r3,[r0,r2]  @ lecture d'un octet dans le buffer de lecture   rouge
    strb r3,[r9,r5]  @ stockage de l'octet dans la memoire du mapping
    add r2,#1         @ maj des compteurs 
	add r5,#1
    ldrb r3,[r0,r2]  @ stockage du 2ième octet   bleu
    strb r3,[r9,r5]
    add r2,#1
	add r5,#1
    ldrb r3,[r0,r2]   @ stockage du 3ième octet  vert
    strb r3,[r9,r5]
    add r2,#1	
	add r5,#1
	mov r3,#0
	strb r3,[r9,r5]   @ et on stocke 0 pour completer l'affichage en 3é bits
	add r5,#1
	add r10,#1
	cmp r10,r6       @ Nombre de pixel d'une ligne image atteint ?
	blt 1b          @ non on boucle
	 @ complement et fin de la ligne
	add r2,r11    @ ajout du complement de la ligne BMP
	sub r2,r12    @ on enleve le nombre d'octet de la ligne bmp pour revenir au debut
	sub r2,r12    @  et on enleve encore le nombre d'octet pour passer à la suivante
	mov r10,#0    @ raz du compteur de pixel de l'image
	add r5,r7     @ et il faut ajouter au compteur ecran le nombre d'octer pour completer 
	cmp r2,#0     @  C'est fini ?
	bgt 1b       @ non on boucle pour traiter une autre ligne

	@fermeture fichier de l'image BMP
	mov r0,r8   /* Fd  fichier */
	mov r7, #CLOSE /* appel fonction systeme pour fermer */
    swi 0 
    mov r0,#0    @ retour ok
    b 100f
	
erreurCI:	
	ldr r1,=szMessOuvImg   /* r0 <- adresse chaine */
	bl   afficheerreur 	
	mov r0,#1       /* erreur */
	b 100f
erreurCI2:	
	ldr r1,=szMessLectImg   /* r0 <- adresse chaine */
	bl   afficheerreur 	
	mov r0,#1       /* erreur */
	b 100f	
erreurCI3:	
	ldr r1,=szMessErrImg   /* r0 <- adresse chaine */
	bl   afficheerreur 	
	mov r0,#1       /* erreur */
	b 100f		
erreurCI4:	
	ldr r1,=szMesslecTaiImg   /* r0 <- adresse chaine */
	bl   afficheerreur 	
	mov r0,#1       /* erreur */
	b 100f  
erreurCI5:	
	ldr r1,=szMessErrNbBits   /* r0 <- adresse chaine */
	bl   afficheerreur 	
	mov r0,#1       /* erreur */
	b 100f 	
erreurCI6:	
	ldr r1,=szMessErrLargImg   /* r0 <- adresse chaine */
	bl   afficheerreur 	
	mov r0,#1       /* erreur */
	b 100f  
erreurCI7:	
	ldr r1,=szMessErrBuffer   /* r0 <- adresse chaine */
	bl   afficheerreur 	
	mov r0,#1       /* erreur */
	b 100f  	
100:   
   /* fin standard de la fonction  */
    pop {r1-r12}
   	pop {fp,lr}   /* restaur des  2 registres	et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
szMessOuvImg: .asciz "Erreur ouverture fichier image.\n"
szMessLectImg: .asciz "Erreur lecture fichier image.\n"
szMessErrImg: .asciz "Erreur ce fichier image n'a pas le format bmp.\n"
szMesslecTaiImg: .asciz "Erreur de lecture de la taille du fichier.\n"
szMessErrNbBits: .asciz "Taille pixel incompatible avec ce programme (24 bits).\n"
szMessErrLargImg: .asciz "Largeur image plus grande que largeur ecran.\n"
szMessErrBuffer: .asciz "Buffer de lecture de l'image trop petit.\n"
.align 4
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
	
/*********************************************/
/*       CONSTANTES GENERALES                */ 
/********************************************/
.include "../constantesARM.inc"
/***************************************************/
/*      DEFINITION DES STRUCTURES                 */
/***************************************************/
.include "../descStruct.inc"

