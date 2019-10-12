/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* modèle B 512MO   */
/*  */
/* Comptage nombre d'instructions de cycles et temps  */
/* en utilisant les fonctions de PERF_EVENT_OPEN      */
/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/
.equ N, 10   
.equ IOCTL,                  0x36    @ Linux syscall
.equ PERF_EVENT_IOC_ENABLE,  0x2400  @ codes fonction ioctl
.equ PERF_EVENT_IOC_DISABLE, 0x2401
.equ PERF_EVENT_IOC_RESET,   0x2403

.equ PERF_TYPE_HARDWARE,        0
.equ PERF_TYPE_SOFTWARE,        1
.equ PERF_TYPE_TRACEPOINT,      2
.equ PERF_TYPE_HW_CACHE,        3
.equ PERF_TYPE_RAW,             4
.equ PERF_TYPE_BREAKPOINT,      5

.equ PERF_COUNT_HW_CPU_CYCLES,               0
.equ PERF_COUNT_HW_INSTRUCTIONS,             1
.equ PERF_COUNT_HW_CACHE_REFERENCES,         2
.equ PERF_COUNT_HW_CACHE_MISSES,             3
.equ PERF_COUNT_HW_BRANCH_INSTRUCTIONS,      4
.equ PERF_COUNT_HW_BRANCH_MISSES,            5
.equ PERF_COUNT_HW_BUS_CYCLES,               6
.equ PERF_COUNT_HW_STALLED_CYCLES_FRONTEND,  7
.equ PERF_COUNT_HW_STALLED_CYCLES_BACKEND,   8
.equ PERF_COUNT_HW_REF_CPU_CYCLES,           9

/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"
/*******************************************/
/* structure de type perf_event_attr  */
/*******************************************/
    .struct  0
perf_event_type:                           @ type
    .struct  perf_event_type + 4
perf_event_size:                           @ taille
    .struct  perf_event_size + 4
perf_event_config:                         @ configuration
    .struct  perf_event_config + 8
perf_event_sample_period:                  @ ou sample_freq
    .struct  perf_event_sample_period + 8
perf_event_sample_type:                    @ type
    .struct  perf_event_sample_type + 8
perf_event_read_format:                    @ read format 
    .struct  perf_event_read_format + 8
perf_event_param:                          @  32 premiers bits voir la documentation
    .struct  perf_event_param + 4
    @ bit disable inherit pinned exclusive exclude_user exclude_kernel exclude_hv exclude_idle etc 

perf_event_suite:
    .struct  perf_event_suite + 68         @ voir la documentation
perf_event_fin:
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessDebutPgm:      .asciz "Début du programme. \n"
szMessErreur:        .asciz "Erreur rencontrée.\n"
szMessFinOK:         .asciz "Fin normale du programme. \n"
sMessResult:         .ascii "Compteur = "
sMessValeur:         .fill 11, 1, ' '            @ taille => 11
szRetourligne:       .asciz  "\n"

/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
stPerf:     .skip  perf_event_fin         @ structure des paramètres
sBuffer:    .skip 100                     @ buffer des résultats

/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text            
.global main                             @ 'main' point d'entrée doit être  global 

main:                                    @ programme principal 
    push {fp,lr}                         @ save des  registres 
    ldr r0,iAdrszMessDebutPgm            @ r0 ← adresse message debut 
    bl affichageMess                     @ affichage message dans console   
    ldr r0,iAdrstPerf                    @ structure parametrage
    mov r1,#PERF_TYPE_HARDWARE           @ type compteurs
    str r1,[r0,#perf_event_type]
    mov r1,#112                          @ longueur de la structure
    str r1,[r0,#perf_event_size]
    mov r1,#0b01100001                   @ bit disabled exclude_kernel exclude_hv
    //rbit r1,r1
    str r1,[r0,#perf_event_param]        @ dans les 8 premiers bits de param
    //mov r1,#PERF_COUNT_HW_INSTRUCTIONS @ compteurs instructions
    mov r1,#PERF_COUNT_HW_CPU_CYCLES     @ compteur cycles
    str r1,[r0,#perf_event_config]
    ldr r0,iAdrstPerf
    vidmemtit Parametres r0, 4
    mov r1,#0                            @ pid
    mov r2,#-1                           @ tout cpu
    mov r3,#-1                           @ leader
    mov r4,#0                            @ flags
    mov r7, #364                         @ call system perf_event_open  
    svc 0 
    cmp r0,#0
    ble 99f
    mov r8,r0                            @ save FD

    vidregtit vidage
    mov r0,r8                            @ FD
    mov r1,#PERF_EVENT_IOC_RESET
    mov r2,#0
    mov r7, #IOCTL                       @ appel systeme 
    svc #0 
    cmp r0,#0
    blt 99f
    mov r0,r8                            @ FD
    mov r1,#PERF_EVENT_IOC_ENABLE
    mov r2,#0
    mov r7, #IOCTL                       @ appel systeme 
    svc #0 
    cmp r0,#0
    blt 99f
    /********************************************/
    //mov r0,#1
    //ldr r0,iAdrstPerf            @ mesure de ces instructions
    //vidmemtit buffer r0, 4
    bl appelProc
    /*********************************************/
    mov r0,r8               @ FD
    mov r1,#PERF_EVENT_IOC_DISABLE
    mov r2,#0
    mov r7, #IOCTL                 @ appel systeme 
    svc #0 
    cmp r0,#0
    blt 99f
    mov r0,r8                      @ FD
    ldr r1,iAdrsBuffer             @ lecture compteur dans ce buffer
    mov r2,#16                     @ TODO a revoir double !!!
    mov r7, #READ                  @ appel systeme 
    svc #0 
    cmp r0,#0
    blt 99f
    ldr r0,iAdrsBuffer             @
    vidmemtit bufferCompteurs r0, 4
    ldr r1,iAdrsBuffer 
    ldr r0,[r1]
    ldr r1,iAdrsMessValeur
    bl conversion10       
    ldr r0,iAdrsMessResult
    bl affichageMess
    ldr r0,iAdrszRetourligne
    bl affichageMess
    ldr r0,iAdrszMessFinOK         @ r0 ← adresse chaine 
    bl affichageMess               @ affichage message dans console 
    mov r0,#0                      @ code retour OK 
    b 100f
99:                                @ affichage erreur 
    ldr r1,iAdrszMessErreur        @ r0 <- code erreur, r1 <- adresse chaine 
    bl   afficheerreur             @ appel affichage message
    mov r0,#1                      @ code erreur 
    b 100f
100:                               @ fin de programme standard  
    pop {fp,lr}                    @ restaur des  registres 
    mov r7, #EXIT                  @ appel fonction systeme pour terminer 
    svc 0 
/************************************/
iAdrszMessDebutPgm:     .int szMessDebutPgm
iAdrszMessErreur:       .int szMessErreur
iAdrszMessFinOK:        .int szMessFinOK
iAdrsBuffer:            .int sBuffer
iAdrstPerf:             .int stPerf
iAdrsMessValeur:        .int sMessValeur
iAdrsMessResult:        .int sMessResult
iAdrszRetourligne:      .int szRetourligne
/***************************************************/
/*   Exemple d'appel d'une fonction               */
/***************************************************/
appelProc:         @ fonction
    push {fp,lr}        @ save des registres
    add fp,sp,#8        @ fp <- adresse début pile
    push {r0-r5}        @ save autres registres
   // vidregtit proc
100:                    @ fin standard de la fonction
    pop {r0-r5}   
    pop {fp,lr}         @ restaur des registres
    bx lr               @ retour de la fonction en utilisant lr
/********************************************************************/
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
    