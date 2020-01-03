/* programme analyse données du FrameBuffer  */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* modification dessin  */
/* inspiré du programme fbtest3.c du site http://raspberrycompote.blogspot.fr/2013/ */
/* Bandes de couleur  en 32 bits par pixel */
/*********************************************/
/*constantes du programme */
.include "../constantesARM.inc"
/*******************************************/
/* FICHIER DES MACROS                      */
/*******************************************/ 
.include "../ficmacros.s"
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
bits:         .fill 11, 1, ' '     
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
fix_info: .skip FBFIXSCinfo_fin       /* reserve la place pour la structure FSCREENINFO */
.align 4
var_info: .skip FBVARSCinfo_fin       /* reserve la place pour la structure VSCREENINFO */
var_info_save: .skip FBVARSCinfo_fin  /* reserve la place pour la sauvegarde de la structure */
/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main                 /* 'main' point d'entrée doit être  global */

main:                        /* programme principal */
    push {fp,lr}             /* save des  2 registres */
    add fp,sp,#8             /* fp <- adresse début */
    ldr r0,=szMessDebutPgm   /* r0 ← adresse message */
    bl affichageMess         /* affichage message dans console   */    
    ldr r0,=szParamNom       /* nom du device du frameBuffer */
    mov r1,#O_RDWR           /* autorisation lecture ecriture */
    mov r2,#0                /* mode */
    mov r7, #OPEN            @ ouverture device FrameBuffer 
    swi 0 
    cmp r0,#0
    ble erreur
    mov r10,r0               @ save du FD du device FrameBuffer dans r10
    
                             /* acces caracteristiques variables de l'affichage */
    ldr r1,=FBIOGET_VSCREENINFO
    ldr r1,[r1]
    ldr r2,=var_info
    mov r7, #IOCTL           @ appel systeme de lecture des données
    swi 0 
    cmp r0,#0
    blt erreurVar
                             /* recopie des données de la structure pour restaur en fin de programme */
    ldr r0,=var_info
    ldr r1,=var_info_save
    mov r2,#0
1:    
    ldrb r3,[r0,r2]
    strb r3,[r1,r2]
    add r2,#1
    cmp r2,#FBVARSCinfo_fin    
    ble 1b
    ldr r0,=var_info_save
    vidmemtit var_info_save r0 5
                                  /* conversion zone dans ligne d'affichage */
    ldr r1,=var_info
    ldr r1,[r1,#FBVARSCinfo_xres]
    ldr r0,=largeur               /*adresse de stockage du resultat */
    mov r2,#10                    /* conversion en base 10 */
    push {r0,r1,r2}               /* parametre de conversion */
    bl conversiondeb
    ldr r1,=var_info
    ldr r1,[r1,#FBVARSCinfo_yres]
    ldr r0,=hauteur               /*adresse de stockage du resultat */
    mov r2,#10                    /* conversion en base 10 */
    push {r0,r1,r2}               /* parametre de conversion */
    bl conversiondeb
    ldr r1,=var_info
    ldr r1,[r1,#FBVARSCinfo_bits_per_pixel]    
    ldr r0,=bits                  /*adresse de stockage du resultat */
    mov r2,#10                    /* conversion en base 10 */
    push {r0,r1,r2}               /* parametre de conversion */
    bl conversiondeb
                                  /*  affichage ligne */
    ldr r0,=szLigneVar            /* r0 ← adresse chaine */
    bl affichageMess              /* affichage message dans console   */
                                  /* changement données variables */
    mov r0,#32                     @ 32 bits par pixel
    ldr r1,=var_info
    str r0,[r1,#FBVARSCinfo_bits_per_pixel]

                                  /* ecriture caracteristiques variables de l'affichage */
    mov r0,r10                    @ recup FD du FB
    ldr r1,=FBIOPUT_VSCREENINFO
    ldr r1,[r1]
    ldr r2,=var_info
    mov r7, #IOCTL                @ appel systeme de gestion des périphériques
    swi 0 
    cmp r0,#0
    blt erreurEcrVar
                                  /* lecture caracteristiques fixes de l'affichage */
    mov r0,r10                    @ recup FD du FB
    ldr r1,=FBIOGET_FSCREENINFO   /* code fonction */
    ldr r1,[r1]
    ldr r2,=fix_info              /* adresse structure de reception */
    mov r7, #IOCTL                @ appel systeme de gestion des périphériques
    swi 0 
    cmp r0,#0
    blt erreurFix
    ldr r0,=fix_info
    vidmemtit fix_info r0 4
                                  /* recup de la taille necessaire */
    ldr r1,=fix_info
    ldr r1,[r1,#FBFIXSCinfo_smem_len] /* nb de caracteres  */
    bl vidtousregistres
                                  /* mapping des donnees */
    mov r0,#0
    ldr r2,iFlagsMmap
    mov r3,#MAP_SHARED
    mov r4,r10
    mov r5,#0
    mov r7, #192                  /* appel fonction systeme pour MMAP */
    swi #0 
    cmp r0,#0                     /* retourne 0 en cas d'erreur */
    beq erreur2    
    mov r9,r0                     /* save adresse retournée par mmap */
    /********************************************************/
    /* pour test, affichage       */

    mov r6,#0                     /* position y */
    ldr r7,=var_info
    ldr r7,[r7,#FBVARSCinfo_yres]
    lsr r7,#1                      @  division par 2
2:                                 @ debut de boucle des lignes
    mov r0,#0                      /* position x */
    ldr r1,=var_info
    ldr r1,[r1,#FBVARSCinfo_xres]    
3:                                 @ debut de boucle des pixels d'une ligne
    mul r4,r6,r1                   /* position y * longueur de la ligne  */
    add r4,r0                      /* calcul de la position du pixel */
    mov r5,r0                      @ save avant division
    mov r3,#8                      /* nombre de couleurs */
    mul r0,r3
    bl division                    /* on prend le quotient pour calculer la couleur à afficher */
    cmp r2,#0
    moveq r2,#0xFF0000             @ devrait être rouge
    beq suite
    cmp r2,#1
    moveq r2,#0xFF                 @  ?
    beq suite
    cmp r2,#2
    ldreq r2,couleur2              @?
    beq suite
    cmp r2,#3
    ldreq r2,couleur3              @?
    beq suite
    cmp r2,#4
    moveq r2,#0xFF00
    beq suite
    cmp r2,#5
    ldreq r2,couleur5              @?
    beq suite
    cmp r2,#6
    ldreq r2,couleur6              @?
    beq suite
    cmp r2,#7
    ldreq r2,couleur7              @?
    beq suite
    cmp r2,#8
    ldreq r2,couleur8              @?
    beq suite
    ldr r2,couleurblanc            @?

suite:    
    mov r3,r4
    lsl r3,#2                      @ position couleur tous les 4 octets
    str r2,[r9,r3]                 @ stockage 32  bits
    mov r0,r5                      @ restaur position x
    add r0,#1
    cmp r0,r1                      @ fin de ligne ?
    blt 3b
    add r6,#1                      @ + 1 position y
    cmp r6,r7                      @  fin affichage ?
    blt 2b
    
    mov r0,r9
    vidmemtit buffer_framebuffer r0 10

    
    ldr r0,iduree
attente:
    sub r0,#1
    cmp r0,#0
    bhi attente
    bl vidtousregistres
                                      /* fermeture mapping */
    mov r0,r9                         /* adresse map  framebuffer */
    ldr r1,=fix_info
    ldr r1,[r1,#FBFIXSCinfo_smem_len] /* nb de caracteres  */
    mov r7, #91                       /* appel fonction systeme pour UNMAP */
    swi #0 
    cmp r0,#0
    blt erreur1    
                                      /* remise à la valeur d'origine des infos variables */
                                      /* ecriture caracteristiques variables de l'affichage */
    mov r0,r10                        @ recup FD du FB
    ldr r1,=FBIOPUT_VSCREENINFO       @ code fonction ecriture données variables
    ldr r1,[r1]
    ldr r2,=var_info_save
    mov r7, #IOCTL                    @ appel systeme de gestion des periphériques
    swi 0 
    cmp r0,#0
    blt erreurEcrVar
regul:    
                                      /* fermeture device */
    mov r0,r10                        /* recup FB du device */
    mov r7, #CLOSE                    /* fermeture */
    swi 0 
    ldr r0,=szMessFinOK               /* r0 ← adresse chaine */
    bl affichageMess                  /* affichage message dans console   */
    b 100f
erreurFix: 
    ldr r1,=szMessErrFix              /* r0 <- code erreur r1 <- adresse chaine */
    bl   afficheerreur                /*appel procedure  */        
    mov r0,#1                         /* erreur */
    b 100f    
erreurVar: 
    ldr r1,=szMessErrVar              /* r0 <- code erreur r1 <- adresse chaine */
    bl   afficheerreur                /*appel procedure  */        
    mov r0,#1                         /* erreur */
    b 100f    
erreurEcrVar: 
    ldr r1,=szMessErrEcrVar           /* r0 <- code erreur r1 <- adresse chaine */
    bl   afficheerreur                /*appel procedure  */        
    mov r0,#1                         /* erreur */
    b 100f        
erreur:    
    ldr r1,=szMessErreur              /* r0 <- code erreur r1 <- adresse chaine */
    bl   afficheerreur                /* appel procedure  */        
    mov r0,#1                         /* erreur */
    b 100f
erreur1:
    ldr r1,=szMessErreur1             /* r1 <- adresse chaine */
    bl   afficheerreur                /* appel procedure  */        
    mov r0,#1                         /* erreur */
    b 100f
erreur2:
    ldr r1,=szMessErreur2             /* r1 <- adresse chaine */
    bl   afficheerreur                /*appel procedure  */        
    mov r0,#1                         /* erreur */
    b 100f
100:                                  /* fin de programme standard  */
    pop {fp,lr}                       /* restaur des  2 registres */
    mov r0,#0
    mov r7, #EXIT                     @ appel fin du programme
    swi 0 
/************************************/       
iFlagsMmap:       .int PROT_READ|PROT_WRITE
iduree:           .int 500000000
couleur2:         .int 0xFFFF00
couleur3:         .int 0xE12F41
couleur5:         .int 0x4A4AE1
couleur6:         .int 0x81872D
couleur7:         .int 0xDD6AE1
couleur8:         .int 0xCE73
couleurblanc:     .int 0xFFFFFF
szMessErreur:     .asciz "Erreur ouverture fichier.\n"
szMessErreur1:    .asciz "Erreur fermeture fichier.\n"
szMessErreur2:    .asciz "Erreur mapping fichier.\n"
szMessDebutPgm:   .asciz "Début du programme. \n"
szMessFinOK:      .asciz "Fin normale du programme. \n"
szMessErrFix:     .asciz  "Impossible lire info fix framebuffer  \n"
szMessErrVar:     .asciz  "Impossible lire info var framebuffer  \n"
szMessErrEcrVar:  .asciz  "Impossible écrire info var framebuffer  \n"

/***************************************************/
.include "../descStruct.inc"

