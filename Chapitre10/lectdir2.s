/* programme assembleur ARM  */
/* lecture d'un repertoire  */
/* call system GETDENTS */
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
.equ TAILLEBUF,  16000 
/* type des fichiers possibles */
.equ   DT_UNKNOWN, 0
.equ   DT_FIFO, 1
.equ   DT_CHR,  2
.equ   DT_DIR,  4
.equ   DT_BLK,  6
.equ   DT_REG,  8
.equ   DT_LNK,  10
.equ   DT_SOCK, 12
.equ   DT_WHT,  14
/*******************************************/
/* FICHIER DES MACROS                      */
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

szLibDir: .asciz " est un répertoire"
szLibFic: .asciz " est un fichier"

/* Nom de repertoire à acceder */
szParamNom: .asciz "/home/pi/asm32"

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss

sBuffer:  .skip TAILLEBUF 
.align 4
                             /* structure de type   dirent  : entrée du repertoire  */
    .struct  0
Dir_ino:                     /* inode */
    .struct Dir_ino + 4
Dir_off:                     /* offset vers l'entrée suivante */
    .struct Dir_off + 4    
Dir_reclen:                  /* taille de l'entrée   2 octets */
    .struct Dir_reclen + 2    
Dir_name:
    .struct Dir_name + 64    /* attention contient le nom en caractères plus un padding */
Dir_fin:                     /* calcul à effectuer en fonction de la longueur reclen  */    
                             /* le type de l'entree se trouve à  l'offset (d_reclen - 1)

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main              /* 'main' point d'entrée doit être  global */

main:                     /* programme principal */
    push {fp,lr}          /* save des  2 registres */
    add fp,sp,#8          /* fp <- adresse début */
                          /* ouverture repertoire */
    ldr r0,=szParamNom    /* nom du repertoire  */
    mov r1,#0             /*  flags    */
    mov r2,#0             /* mode */
    mov r7, #OPEN         /* appel fonction systeme pour ouvrir */
    swi 0 
    cmp r0,#0             /* si erreur retourne une valeur negative */
    ble erreur
    mov r8,r0             /* save du Fd dans r8 */ 
                          /* lecture r0 contient le FD du fichier */
    ldr r1,=sBuffer       /*  adresse du buffer de reception    */
    mov r2,#TAILLEBUF     /* nb de caracteres  */
    mov r7, #0x08D        /* appel fonction systeme GETDENTS pour lire un répertoire */
    //mov r7, #0x059 /* appel fonction systeme READDIR mais non iplémentée sur mon systeme */
    swi #0 
    cmp r0,#0
    ble erreur2           /* si erreur retourne une valeur negative */
    mov r6,r0             /* on garde le nombre d'octets récupérés */ 
                          /*  Exemple d'affichage memoire  */
    ldr r0,=sBuffer
    vidmemtit Buffer r0 10
 
    mov r2,r0             /* adresse debut structure dans r2 */
    mov r7,#0
1:                        /* debut de boucle d'affichage */
    add r0,r2,#Dir_name   /* nom du fichier dans r0 */
    bl affichageMess
                          /* recherche autre entree */
    add r0,r2,#Dir_reclen /* adresse de la longueur de l'entrée dans r0 */
    ldrh r1,[r0]          /* recuperation des 2 bytes de la longueur */
    mov r0,r2
    add r0,r1             /* on ajoute a l'adresse de depart */
    add r7,r1             /* et au compteur */
    mov r2,r0             /* save nouvelle adresse */ 
    sub r3,r2,#1          /* le type est stocké à l'adresse suivante moins 1 octet */
    ldrb r3,[r3]          /* récupération du type sur un octet */
    cmp r3,#DT_DIR        /* est ce un répertoire ? */
    beq 2f                /* oui */
    cmp r3,#DT_REG        /*est ce un fichier normal ? */
    beq 3f                /*oui */
    b 9f                  /* tester les autres cas */
2:    
    ldr r0,=szLibDir      /* affichage libelle repertoire */
    bl affichageMess
    b 9f
3:    
    ldr r0,=szLibFic      /* affichage libelle fichier */
    bl affichageMess
    b 9f
9:
    ldr r0,=szRetourligne /* affichage retour ligne */
    bl affichageMess  
    cmp r7,r6             /* tous les octets lus ont-ils été traités ? */
    blt 1b                /* non alors boucle */
    
                          /* fermeture fichier */
    mov r0,r8             /* Fd  fichier */
    mov r7, #CLOSE        /* appel fonction systeme pour fermer */
    swi 0 
    cmp r0,#0
    blt erreur1
    mov r0,#0             /* code retour OK */
    b 100f
erreur:    
    ldr r1,=szMessErreur  /* r1 <- adresse chaine */
    bl   afficheerreur    /*appel procedure  */    
    mov r0,#1             /* erreur */
    b 100f
erreur1:    
    ldr r1,=szMessErreur1 /* r1 <- adresse chaine */
    bl   afficheerreur    /*appel procedure  */    
    mov r0,#1             /* erreur */
    b 100f    
erreur2:    
    ldr r1,=szMessErreur2 /* r0 <- adresse chaine */
    bl   afficheerreur    /*appel procedure  */    
    mov r0,#1             /* erreur */
    b 100f    
                          /* fin de programme standard  */
100:        
    pop {fp,lr}           /* restaur des  2 registres */
    mov r7, #EXIT         /* appel fonction systeme pour terminer */
    swi 0 
/************************************/       

    