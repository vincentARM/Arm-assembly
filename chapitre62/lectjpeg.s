/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* modèle B 512MO   */
/*  */
/* Traitement image jpeg  programme pour tester les fonctions */
/* de la librairie libjpeg */ 
/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/
.equ TAILLEBUFFER, 128000
.equ JPEG_LIB_VERSION,  62
.equ JPOOL_PERMANENT,   0     @ lasts until master record is destroyed
.equ JPOOL_IMAGE,       1     @ lasts until done with image/datastream
.equ JPOOL_NUMPOOLS,    2
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessTitre:            .asciz "Nom du fichier : "
szMessDebutPgm:         .asciz "Début du programme. \n"
szMessErreur:           .asciz "Erreur rencontrée.\n"
szMessFinOK:            .asciz "Fin normale du programme. \n"
sMessResult:            .ascii " "
sMessValeur:            .fill 11, 1, ' '            @ taille => 11
szRetourligne:          .asciz  "\n"

/*   libelle  */
szId: 	.ascii "rb"

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
iAdrFicName:    .skip 4
sBuffer:         .skip TAILLEBUFFER

.align 4
cinfo:     .skip 1000  @ taille pour test à revoir
.align 4
my_error_mgr:          @ description pour test à revoir
errorexist:        .skip 4
msg_code:          .skip 4
msg_parm:          .skip 80
trace_level:       .skip 4
num_warnings:      .skip 4
jpeg_message_table: .skip 4
last_jpeg_message:  .skip 4
addon_message_table: .skip 4
first_addon_message: .skip 4
last_addon_message:  .skip 4
@
setjmp_buffer:       .skip 4
/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text            
.global main                    @ 'main' point d'entrée doit être  global 

main:                           @ programme principal 
    ldr r0,iAdrszMessDebutPgm   @ r0 ← adresse message debut 
    bl affichageMess            @ affichage message dans console   

    @ extraire le nom du fichier dans la ligne de commande et lecture du fichier
    mov r0,sp
    bl traitFic
    cmp r0,#-1
    beq 99f

    ldr r0,iAdrszMessFinOK      @ r0 ← adresse chaine 
    bl affichageMess            @ affichage message dans console 
    mov r0,#0                   @ code retour OK 
    b 100f
99:                             @ affichage erreur 
    ldr r1,iAdrszMessErreur     @ r0 <- code erreur, r1 <- adresse chaine 
    bl   afficheerreur          @ appel affichage message
    mov r0,#1                   @ code erreur 
    b 100f
100:                            @ fin de programme standard  
    mov r7, #EXIT               @ appel fonction systeme pour terminer 
    svc 0 
/************************************/
iAdrszMessDebutPgm:     .int szMessDebutPgm
iAdrszMessErreur:       .int szMessErreur
iAdrszMessFinOK:        .int szMessFinOK
iAdrszRetourligne:      .int szRetourligne
iAdrsBuffer:            .int sBuffer
iAdrcinfo:              .int cinfo
iAdrerrorexist:         .int errorexist
iAdrmy_error_mgr:        .int my_error_mgr

/******************************************************************/
/*     read file                                                   */ 
/******************************************************************/
/* r0 contient l'adresse de la pile ai départ          */
traitFic:
    push {r1-r8,fp,lr}                  @ save  registers
    mov fp,r0                           @  fp <- start address
    ldr r4,[fp]                         @ number of Command line arguments
    cmp r4,#1
    movle r0,#-1
    ble 99f
    add r5,fp,#8                        @ second parameter address 
    ldr r5,[r5]
    mov r0,r5
    vidmemtit debut r0 2
    ldr r0,iAdriAdrFicName
    str r5,[r0]
    ldr r0,iAdrszMessTitre
    bl affichageMess                    @ display string
    mov r0,r5
    bl affichageMess 
    ldr r0,iAdrszRetourligne
    bl affichageMess                    @ display carriage return
    b 1f                                @ cette fonction ne doit pas être utilisée
    mov r0,r5                           @ file name
    mov r1,#O_RDWR                      @ flags    
    mov r2,#0                           @ mode 
    mov r7, #OPEN                       @ call system OPEN 
    svc 0 
    cmp r0,#0    @ error ?
    ble 99f
1:  @ utilisation de fopen
    mov r0,r5                           @ file name
    ldr r1,iAdrszId
    bl fopen
    cmp r0,#0
    ble 99f
    mov r8,r0                           @ File Descriptor
    adr r0,my_error_exit
    ldr r1,iAdrmy_error_mgr
    str r0,[r1]
    ldr r0,iAdrmy_error_mgr
    bl jpeg_std_error
    vidregtit retour
    ldr r1,iAdrcinfo
    str r0,[r1]
    str r0,[r1,#12]
    ldr r0,iAdrcinfo
    //vidmemtit cinfoerr r0 5
    ldr r0,iAdrsetjmp_buffer
    bl setjmp                               @ fonction inutile ici !!
@
    ldr r0,iAdrcinfo
    mov r1,#JPEG_LIB_VERSION
    mov r2,#464
    bl jpeg_CreateDecompress
    ldr r0,iAdrcinfo
    //vidmemtit cinfo r0 5
    mov r1,r8
    ldr r0,iAdrcinfo
    vidregtit avant
    bl jpeg_stdio_src                       @ indique le fichier source

    ldr r0,iAdrcinfo
    mov r1,#1             @ TRUE
    bl jpeg_read_header
    ldr r0,iAdrcinfo
    ldr r1,[r0,#28]      @ largeur
    ldr r6,[r0,#32]      @ hauteur
    ldr r3,[r0,#36]      @ components
    ldr r4,[r0,#40]      @ colorspace
    vidregtit info
    mul r7,r1,r3
    //ldr r0,iAdrcinfo
    //vidmemtit affcinfo r0 20
    ldr r0,iAdrcinfo
    bl jpeg_start_decompress
    ldr r0,iAdrcinfo
    vidmemtit affcinfo r0 20
    @ creation buffer
    ldr r0,iAdrcinfo
    ldr r5,[r0,#4]
    ldr r4,[r5,#8]
    ldr r0,iAdrcinfo
    mov r1,#JPOOL_IMAGE
    mov r2,r7
    mov r3,#1
    blx r4
    vidregtit retourbuffer
    mov r9,r0
2:
    mov r1,r9
    ldr r0,iAdrcinfo
    mov r2,#1
    bl jpeg_read_scanlines
    //vidregtit info1

    @ ici il faut mettre les instructions de traitement de chaque ligne

    ldr r0,[r9]
    vidmemtit affBuffer r0 5
    ldr r0,iAdrcinfo 
    ldr r1,[r0,#140]        @ zone de récupération du compteur de ligne
    vidregtit zone
    cmp r1,r6               @ si < à la hauteur de l'image
    blt 2b                  @ boucle lecture ligne
    //ldr r0,[r9]
    //vidmemtit affBuffer r0 10
    
    ldr r0,iAdrcinfo
    bl jpeg_finish_decompress      @ fin de la décompression
    vidregtit fin
    ldr r0,iAdrcinfo
    bl jpeg_destroy_decompress     @ liberation des ressources
    @TODO Close le fichier 
    b 100f
   
    mov r8,r0                                     @ File Descriptor
    ldr r1,iAdrsBuffer                            @ buffer address
    mov r2,#TAILLEBUFFER                          @ buffer size
    mov r7,#READ                                  @ read file
    svc #0
    cmp r0,#0                                     @ error ?
    blt 99f
    @ extraction datas
    ldr r1,iAdrsBuffer                            @ buffer address
    add r1,r0
    mov r0,#0                                     @ store zéro final
    strb r0,[r1] 

    @ TODO fermer le fichier
    mov r0,r8
    mov r7, #CLOSE 
    svc 0 
    mov r0,#0
    b 100f
99:  @ error
    ldr r1,iAdrszMessErreur                      @ error message
    bl   afficheerreur
    mov r0,#-1
100:
    pop {r1-r8,fp,lr}                   @ restaur registers 
    bx lr                            @return
iAdriAdrFicName:              .int iAdrFicName
iAdrszMessTitre:              .int szMessTitre
iAdrsetjmp_buffer:            .int setjmp_buffer
iAdrszId:                     .int szId
//iAdrszRetourLigne:            .int szRetourLigne
/****************************************/
/* TODO gestion des erreurs             */
/****************************************/
my_error_exit:
    vidregtit erreur_exit
    bkpt
/********************************************************************/
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
	