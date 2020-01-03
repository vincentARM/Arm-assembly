/* programme analyse données du framebuffer  */
/* ajout du mappage en mémoire               */
/* modification zones mémoire pour verifier affichage */
/*********************************************/
/*constantes */
/********************************************/
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
szParamNom: .asciz "/dev/fb0"
szMessErrFix:  .asciz  "Impossible lire info fix framebuffer  \n"
.equ LGMESSERRFIX, . - szMessErrFix
szMessErrVar:  .asciz  "Impossible lire info var framebuffer  \n"
.equ LGMESSERRVAR, . - szMessErrVar
szLigneVar: .ascii "Variables info : "
largeur:  .fill 11, 1, ' ' 
            .ascii " * "
hauteur:  .fill 11, 1, ' ' 
            .ascii " Bits par pixel : "
bits:         .fill 11, 1, ' '     
             .asciz  "\n"
.equ lGLIGNEVAR, . - szLigneVar        
/*   libelle  */
szId: .ascii "id : "
nom:   .fill 17, 1, ' ' 
.asciz  "\n"
.align 4
FBIOGET_FSCREENINFO: .word 0x4602
FBIOGET_VSCREENINFO: .word 0x4600
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
taille:           .word 0
fbfd:             .int 0             /* file descriptor du framebuffer */

fix_info:
    id:           .skip 16     /* ident sur 16c */
    smem_start:   .int 0       /*  debut zone buffer */
    smem_len:     .int 0       /*  type */
                  .skip 100    /* a revoir plus tard */

var_info:    
    xres:           .int 0
    yres:           .int 0
    xres_virtual:   .int 0    /* virtual resolution        */
    yres_virtual:   .int 0
    xoffset:        .int 0    /* offset from virtual to visible */
    yoffset:        .int 0    /* resolution            */
    bits_per_pixel: .int 0
                    .skip 50
    
buffer:             .skip 500 
/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main             /* 'main' point d'entrée doit être  global */

main:                    /* programme principal */
    push {fp,lr}         /* save des  2 registres */
    add fp,sp,#8         /* fp <- adresse début */
    ldr r0,=szParamNom
    mov r1,#O_RDWR
    mov r2,#0
    mov r7, #OPEN        // open du fichier
    swi 0 
    cmp r0,#0
    ble erreur
    mov r8,r0            @ save du FD
    bl vidtousregistres
    ldr r1,adresse_fbfd
    str r0,[r1]
                         /* lecture donnees */
    ldr r1,=FBIOGET_FSCREENINFO
    ldr r1,[r1]
    ldr r2,=fix_info
    mov r7, #IOCTL       // lecture données du fichier
    swi 0 
    bl vidtousregistres
    cmp r0,#0
    bge suite1
    ldr r0,=szMessErrFix  /* r0 ← adresse chaine */
    mov r1,#LGMESSERRFIX  /* r1 longueur ← longueur message */
    push {r0,r1}
    bl affichage          /*appel procedure  */    
    b 100f
suite1:    
    ldr r0,=fix_info
    add r0,#16
    vidmemtit fix_info r0 2
                          /* copie ID dans le libelle */
    mov r0,#0
    mov r1,#16
    ldr r2,=nom
    ldr r3,=fix_info
3:    
    ldrb r4,[r3,+r0]
    cmp r4,#0
    beq 4f
    strb r4,[r2,+r0]
    add r0,#1
    cmp r0,r1
    blt 3b
4:    
    ldr r0,=szId         /* r0 ← adresse chaine */
    mov r1,#-1           //test calcul longueur
    push {r0,r1}
    bl affichage         /*appel procedure  */    
                         /* acces autres infos */
    ldr r0,adresse_fbfd
    ldr r0,[r0]
    ldr r1,=FBIOGET_VSCREENINFO
    ldr r1,[r1]
    ldr r2,=var_info
    mov r7, #IOCTL      // open du fichier
    swi 0 
    bl vidtousregistres
    cmp r0,#0
    bge suite2
    ldr r0,=szMessErrVar  /* r0 ← adresse chaine */
    mov r1,#LGMESSERRVAR  /* r1 longueur ← longueur message */
    push {r0,r1}
    bl affichage          /*appel procedure  */    
    b 100f
suite2:        
    ldr r0,=var_info
    add r0,#16
    vidmemtit var_info r0 2
                          /* conversion zone dans ligne d'affichage */
    ldr r1,=xres
    ldr r1,[r1]
    ldr r0,=largeur       /*adresse de stockage du resultat */
    mov r2,#10            /* conversion en base 10 */
    push {r0,r1,r2}       /* parametre de conversion */
    bl conversiondeb
    ldr r1,=yres
    ldr r1,[r1]
    ldr r0,=hauteur       /*adresse de stockage du resultat */
    mov r2,#10            /* conversion en base 10 */
    push {r0,r1,r2}       /* parametre de conversion */
    bl conversiondeb
    ldr r1,=bits_per_pixel
    ldr r1,[r1]
    ldr r0,=bits          /*adresse de stockage du resultat */
    mov r2,#10            /* conversion en base 10 */
    push {r0,r1,r2}       /* parametre de conversion */
    bl conversiondeb
                          /*  affichage ligne */
    ldr r0,=szLigneVar    /* r0 ← adresse chaine */
    mov r1,#lGLIGNEVAR    /*  r1 ← longueur à afficher */
    push {r0,r1}
    bl affichage          /*appel procedure  */    
                          /* recup de la taille du buffer */
    ldr r1,=smem_len
    ldr r1,[r1]           /* nb de caracteres  */
                          /* mapping des donnees */
    mov r0,#0
    ldr r2,iFlagsMmap
    mov r3,#MAP_SHARED
    mov r4,r8
    mov r5,#0
    mov r7, #192          /* appel fonction systeme pour MMAP */
    swi #0 
    cmp r0,#0             /* retourne 0 en cas d'erreur */
    beq erreur2    
    mov r6,r0             /* save adresse retournée par mmap */
    ldr r1,=smem_len
    ldr r1,[r1]           /* nb de caracteres  */
    lsr r1,#3             /*division par 8 */
    mov r2,#0xFF
    mov r3,#0
    bl vidtousregistres
1:                        @ debut de boucle 
       str r2,[r0,r3,lsl #2]
    add r3,#1
    cmp r3,r1
    ble 1b
                          /* SYNC */
    ldr r1,=smem_len
    ldr r1,[r1]           /* nb de caracteres  */
    mov r2,#MS_SYNC       /* A REVOIR CE FLAG ms_sync */

    mov r7, #0x90         /* appel fonction systeme pour PAUSE */
    swi #0 
    
                          /*  verif buffer du framebuffer */
    mov r0,r6
    vidmemtit buffer_framebuffer r0 2

                          /* fermeture mapping */
    mov r0,r6             /* map  framebuffer */
    ldr r1,=smem_len
    ldr r1,[r1]           /* nb de caracteres  */
    mov r7, #91           /* appel fonction systeme pour UNMAP */
    swi #0 
    cmp r0,#0
    blt erreur1    
                          /* fermeture device */
    ldr r0,adresse_fbfd
    ldr r0,[r0]
    mov r7, #CLOSE        // open du fichier
    swi 0 
    ldr r0,=szMessFinOK   /* r0 ← adresse chaine */
    bl affichageMess      /* affichage message dans console   */
    b 100f
    
erreur:
    ldr r1,=szMessErreur  /* r0 <- code erreur r1 <- adresse chaine */
    bl   afficheerreur    /*appel procedure  */        
    mov r0,#1             /* erreur */
    b 100f
erreur1:
    ldr r1,=szMessErreur1 /* r1 <- adresse chaine */
    bl   afficheerreur    /*appel procedure  */        
    mov r0,#1             /* erreur */
    b 100f
erreur2:
    ldr r1,=szMessErreur2 /* r1 <- adresse chaine */
    bl   afficheerreur    /*appel procedure  */        
    mov r0,#1             /* erreur */
    b 100f            
100:                      /* fin de programme standard  */
    pop {fp,lr}           /* restaur des  2 registres */
    mov r0,#0
    mov r7, #EXIT         @ appel fin du programme
    swi 0 
/************************************/       
adresse_fbfd : .word fbfd
iFlagsMmap:    .int PROT_READ|PROT_WRITE
szMessErreur:  .asciz "Erreur ouverture fichier.\n"
szMessErreur1: .asciz "Erreur fermeture fichier.\n"
szMessErreur2: .asciz "Erreur mapping fichier.\n"
szMessFinOK:   .asciz "Fin normale du programme. \n"
.align 4     /* alignement car l'étiquette de la routine suivante doit être alignée */
