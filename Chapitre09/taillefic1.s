/* programme assembleur ARM  */
/* lecture d'un fichier  */
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
.equ TAILLEBUF,  512  
/*  en commentaire car elles sont aussi dans le fichier plus haut
.equ EXIT, 1
.equ READ, 3
.equ WRITE, 4
.equ OPEN, 5
.equ CLOSE, 6
*/
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.include "../ficmacros.s"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessErreur:  .asciz "Erreur ouverture fichier.\n"
szMessErreur1: .asciz "Erreur fermeture fichier.\n"
szMessErreur2: .asciz "Erreur lecture fichier.\n"
szRetourligne: .asciz  "\n"

//szParamNom: .asciz "/home/pi/vincent/asm/projet3/fic1.txt"
szParamNom: .asciz "fic1.txt"

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss

sBuffer:  .skip TAILLEBUF 

.align 4
/* structure de type   stat  : infos fichier  */
    .struct  0
Stat_dev_t:               /* ID of device containing file */
    .struct Stat_dev_t + 4
Stat_ino_t:              /* inode */
    .struct Stat_ino_t + 2
Stat_mode_t:              /* File type and mode */
    .struct Stat_mode_t + 2    
Stat_nlink_t:               /* Number of hard links */
    .struct Stat_nlink_t + 2    
Stat_uid_t:               /* User ID of owner */
    .struct Stat_uid_t + 2 
Stat_gid_t:                 /* Group ID of owner */
    .struct Stat_gid_t + 2     
Stat_rdev_t:                /* Device ID (if special file) */
    .struct Stat_rdev_t + 2 
Stat_size_deb:           /* la taille est sur 8 octets si gros fichiers */
     .struct Stat_size_deb + 4 
Stat_size_t:                /* Total size, in bytes */
    .struct Stat_size_t + 4     
Stat_blksize_t:                /* Block size for filesystem I/O */
    .struct Stat_blksize_t + 4     
Stat_blkcnt_t:               /* Number of 512B blocks allocated */
    .struct Stat_blkcnt_t + 4     
Stat_atime:               /*   date et heure fichier */
    .struct Stat_atime + 8     
Stat_mtime:               /*   date et heure modif fichier */
    .struct Stat_atime + 8 
Stat_ctime:               /*   date et heure creation fichier */
    .struct Stat_atime + 8     
Stat_Fin:    
    
    
/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main            /* 'main' point d'entrée doit être  global */

main:                     /* programme principal */
    push {fp,lr}          /* save des  2 registres */
    add fp,sp,#8          /* fp <- adresse début */
                          /* ouverture fichier */
    ldr r0,=szParamNom    /* nom du fichier  */
    mov r1,#O_RDWR        /*  flags    */
    mov r2,#0             /* mode */
    mov r7, #OPEN         /* appel fonction systeme pour ouvrir */
    swi 0 
    cmp r0,#0             /* si erreur */
    ble erreur
    bl vidtousregistres
    mov r8,r0             /* save du Fd */ 
                          /* lecture r0 contient le FD du fichier */
    ldr r1,=sBuffer       /*  adresse du buffer de reception    */
    mov r7, #0x6c         /* appel fonction systeme pour NEWFSTAT */
    swi 0 
    cmp r0,#0
    blt erreur2
    bl vidtousregistres
    ldr r0,=sBuffer
    vidmemtit Buffer r0 5

    ldr r1,[r0,#Stat_size_t]
    bl vidtousregistres
                         /* fermeture fichier */
    mov r0,r8            /* Fd  fichier */
    mov r7, #CLOSE       /* appel fonction systeme pour fermer */
    swi 0 
    cmp r0,#-1
    beq erreur1

    mov r0,#0            /* code retour OK */
    b 100f
erreur:    
    ldr r1,=szMessErreur  /* r0 <- adresse chaine */
    bl   afficheerreur     
    mov r0,#1             /* erreur */
    b 100f
erreur1:    
    ldr r1,=szMessErreur1 /* r0 <- adresse chaine */
    bl   afficheerreur 
    mov r0,#1             /* code retour erreur */   
    b 100f    
erreur2:    
    ldr r1,=szMessErreur2 /* r0 <- adresse chaine */
    bl   afficheerreur 
    
    mov r0,#1             /* erreur */
    b 100f    
                         /* fin de programme standard  */
100:        
    pop {fp,lr}          /* restaur des  2 registres */
    mov r7, #EXIT        /* appel fonction systeme pour terminer */
    swi #0 
/************************************/

    