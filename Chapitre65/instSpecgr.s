/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* modèle B 512MO   */
/*  */
/* Comptage nombre d'instructions de cycles et temps  */
/* en utilisant les fonctions de PERF_EVENT_OPEN      */
/* groupement des résultats   */
/*********************************************/
/*           CONSTANTES                      */
/* L'include des constantes générales est   */
/* en fin du programme                      */
/********************************************/
.equ IOCTL,     0x36                @ Linux syscall
.equ PERF_EVENT_IOC_ENABLE,  0x2400 @ codes commande ioctl
.equ PERF_EVENT_IOC_DISABLE, 0x2401
.equ PERF_EVENT_IOC_RESET,   0x2403

.equ PERF_TYPE_HARDWARE,     0
.equ PERF_TYPE_SOFTWARE,     1
.equ PERF_TYPE_TRACEPOINT,   2
.equ PERF_TYPE_HW_CACHE,     3
.equ PERF_TYPE_RAW,          4
.equ PERF_TYPE_BREAKPOINT,   5

.equ PERF_COUNT_HW_CPU_CYCLES,              0
.equ PERF_COUNT_HW_INSTRUCTIONS,            1
.equ PERF_COUNT_HW_CACHE_REFERENCES,        2
.equ PERF_COUNT_HW_CACHE_MISSES,            3
.equ PERF_COUNT_HW_BRANCH_INSTRUCTIONS,     4
.equ PERF_COUNT_HW_BRANCH_MISSES,           5
.equ PERF_COUNT_HW_BUS_CYCLES,              6
.equ PERF_COUNT_HW_STALLED_CYCLES_FRONTEND, 7
.equ PERF_COUNT_HW_STALLED_CYCLES_BACKEND,  8
.equ PERF_COUNT_HW_REF_CPU_CYCLES,          9

.equ PERF_COUNT_SW_CPU_CLOCK,          0
.equ PERF_COUNT_SW_TASK_CLOCK,         1
.equ PERF_COUNT_SW_PAGE_FAULTS,        2
.equ PERF_COUNT_SW_CONTEXT_SWITCHES,   3
.equ PERF_COUNT_SW_CPU_MIGRATIONS,     4
.equ PERF_COUNT_SW_PAGE_FAULTS_MIN,    5
.equ PERF_COUNT_SW_PAGE_FAULTS_MAJ,    6
.equ PERF_COUNT_SW_ALIGNMENT_FAULTS,   7
.equ PERF_COUNT_SW_EMULATION_FAULTS,   8
.equ PERF_COUNT_SW_DUMMY,              9
.equ PERF_COUNT_SW_BPF_OUTPUT,         10

.equ  PERF_FLAG_FD_NO_GROUP,    1 << 0
.equ PERF_FLAG_FD_OUTPUT,       1 << 1
.equ PERF_FLAG_PID_CGROUP,      1 << 2 /* pid=cgroup id, per-cpu mode only */
.equ PERF_FLAG_FD_CLOEXEC,      1 << 3  /* O_CLOEXEC >*/

.equ PERF_FORMAT_TOTAL_TIME_ENABLED,    1 << 0
.equ PERF_FORMAT_TOTAL_TIME_RUNNING,    1 << 1
.equ PERF_FORMAT_ID,                    1 << 2
.equ PERF_FORMAT_GROUP,                 1 << 3

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
    .struct  perf_event_param + 4          @ bit disabled inherit pinned exclusive 
                                           @ exclude_user exclude_kernel exclude_hv exclude_idle etc 
perf_event_suite:
    .struct  perf_event_suite + 68         @ voir documentation 
perf_event_fin:
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessDebutPgm:      .asciz "Début du programme. \n"
szMessErreur:        .asciz "Erreur rencontrée.\n"
szMessFinOK:         .asciz "Fin normale du programme. \n"
sMessResult:         .ascii "Nombre instructions : "
sMessValInst:        .fill 21, 1, ' '            @ taille => 21
                     .ascii "\ncycles              : "
sMessValCycles:      .fill 21, 1, ' '            @ taille => 21
                     .ascii "\ntemps (µs)          : "
sMessValTemps:       .fill 21, 1, ' '            @ taille => 21
szRetourligne:       .asciz  "\n"

dDouble1:            .quad   8234567890123456789
/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
stPerf:     .skip perf_event_fin        @ structure infos leader
stPerf1:    .skip perf_event_fin        @ structure infos fils 1
stPerf2:    .skip perf_event_fin        @ structure infos fils 2
sBuffer:    .skip 100                   @ buffer de lecture 
 @ chaque zone du buffer  a une longueur de 64 bits 
 @ la première zone contient le nombre de compteurs lus (ici 3)
sBuffer1:    .skip 100                   @ buffer pour test conversion 
/**********************************************/
/* SECTION CODE                              */
/**********************************************/
.text            
.global main                            @ 'main' point d'entrée doit être  global 

main:                                   @ programme principal 
    push {fp,lr}                        @ save des  registres 
    ldr r0,iAdrszMessDebutPgm           @ r0 ← adresse message debut 
    bl affichageMess                    @ affichage message dans console   
  
    ldr r0,iAdrstPerf                   @ préparation données du leader
    mov r1,#PERF_TYPE_HARDWARE          @ type de compteur
    str r1,[r0,#perf_event_type]
    mov r1,#112                         @ longueur de la structure
    str r1,[r0,#perf_event_size]
    mov r1,#0b01100001                  @ bit disabled(1) exclude_kernel exclude_hv
    str r1,[r0,#perf_event_param]       @ dans les 8 premiers bits de param
    mov r1,#PERF_COUNT_HW_INSTRUCTIONS  @ compteur instructions
    //mov r1,#PERF_COUNT_HW_CPU_CYCLES
    str r1,[r0,#perf_event_config]
    mov r1,#PERF_FORMAT_GROUP           @ lecture commune de tous les compteurs
    str r1,[r0,#perf_event_read_format]
    //ldr r0,iAdrstPerf
    //vidmemtit buffer r0, 4
    mov r1,#0                           @ pid
    mov r2,#-1                          @ tout cpu
    mov r3,#-1                          @ c'est le leader
    mov r4,#0                           @ flags
    mov r7, #364                        @ call system perf_event_open   leader
    svc 0 
    cmp r0,#0
    ble 99f                             @ erreur ?
    mov r8,r0                           @ save FD du leader
    vidregtit fils
    @***********************Fils 1
    ldr r0,iAdrstPerf1
    mov r1,#PERF_TYPE_HARDWARE
    //mov r1,#PERF_TYPE_SOFTWARE
    str r1,[r0,#perf_event_type]
    mov r1,#112
    str r1,[r0,#perf_event_size]
    mov r1,#0b01100000                  @ bit disabled(0) exclude_kernel exclude_hv
    str r1,[r0,#perf_event_param]       @ dans les 8 premiers bits de param
    //mov r1,#PERF_COUNT_HW_INSTRUCTIONS
    mov r1,#PERF_COUNT_HW_CPU_CYCLES
    //mov r1,#PERF_COUNT_HW_REF_CPU_CYCLES
    str r1,[r0,#perf_event_config]
    mov r1,#0                           @ pid
    mov r2,#-1                          @ tout cpu
    mov r3,r8                           @ FD du leader
    mov r4,#0
    mov r7, #364                        @ call system perf_event_open   fils
    svc 0 
    cmp r0,#0
    ble 99f
    //mov r9,r0                         @ eventuellement save du FD du fils
    @***********************Fils 2
    ldr r0,iAdrstPerf2
    //mov r1,#PERF_TYPE_HARDWARE
    mov r1,#PERF_TYPE_SOFTWARE
    str r1,[r0,#perf_event_type]
    mov r1,#112
    str r1,[r0,#perf_event_size]
    mov r1,#0b01100000                  @ bit disabled(0) exclude_kernel exclude_hv
    str r1,[r0,#perf_event_param]       @ dans les 8 premiers bits de param

    mov r1,#PERF_COUNT_SW_TASK_CLOCK
    //mov r1,#PERF_COUNT_SW_CPU_CLOCK  
    str r1,[r0,#perf_event_config]
    mov r1,#0                           @ pid
    mov r2,#-1                          @ tout cpu
    mov r3,r8                           @ FD du leader
    mov r4,#0
    mov r7, #364                        @ call system perf_event_open   fils 2
    svc 0 
    cmp r0,#0
    ble 99f
    //mov r6,r0                         @ save eventuelle du FD fils 2
    mov r1,#2
    /****************************************/
    @ lancement mesure
    vidregtit mesure
    mov r0,r8                           @ FD du leader 
    mov r1,#PERF_EVENT_IOC_RESET
    mov r2,#0
    mov r7, #IOCTL                      @ appel systeme 
    svc #0 
    cmp r0,#0
    blt 99f
    mov r0,r8                           @ FD du leader
    mov r1,#PERF_EVENT_IOC_ENABLE
    mov r2,#0
    mov r7, #IOCTL                      @ appel systeme 
    svc #0 
    cmp r0,#0
    blt 99f

    /********************************************/
    //mov r0,#1                         @ mesure de ces instructions
    bl appelProc
    /*********************************************/
    @ fin mesure
    mov r0,r8                           @ FD du leader
    mov r1,#PERF_EVENT_IOC_DISABLE
    mov r2,#0
    mov r7, #IOCTL                      @ appel systeme 
    svc #0 
    cmp r0,#0
    blt 99f
    @ lecture des compteurs
    mov r0,r8                           @ FD
    ldr r1,iAdrsBuffer                  @ un seul buffer 
    mov r2,#48                          @ longueur lecture
    mov r7, #READ                       @ appel systeme 
    svc #0 
    cmp r0,#0
    blt 99f
    ldr r0,iAdrsBuffer                  @ pour vérification
    vidmemtit buffer r0, 8

    ldr r0,iAdrsBuffer 
    add r0,#8                           @ récupération du nombre d'instructions
    ldr r1,iAdrsMessValInst
    bl conversionDoubleU
    ldr r0,iAdrsBuffer
    add r0,#16                          @ recuperation du nombre de cycles
    ldr r1,iAdrsMessValCycles
    bl conversionDoubleU
    ldr r0,iAdrsBuffer
    add r0,#24                          @ recuperation du temps
    ldr r1,iAdrsMessValTemps
    bl conversionDoubleU

    ldr r0,iAdrsMessResult
    bl affichageMess
    ldr r0,iAdrszRetourligne
    bl affichageMess

    ldr r0,iAdrszMessFinOK              @ fin OK
    bl affichageMess
    mov r0,#0                           @ code retour OK 
    b 100f
99:                                     @ affichage erreur 
    ldr r1,iAdrszMessErreur             @ r0 <- code erreur, r1 <- adresse chaine 
    bl   afficheerreur                  @ appel affichage message
    mov r0,#1                           @ code erreur 
    b 100f
100:                                    @ fin de programme standard  
    pop {fp,lr}                         @ restaur des  registres 
    mov r7, #EXIT                       @ appel fonction systeme pour terminer 
    svc 0 
/************************************/
//iAdrszMessChaine:      .int szMessChaine
iAdrszMessDebutPgm:      .int szMessDebutPgm
iAdrszMessErreur:        .int szMessErreur
iAdrszMessFinOK:         .int szMessFinOK
iAdrsBuffer:             .int sBuffer
iAdrstPerf:              .int stPerf
iAdrstPerf1:             .int stPerf1
iAdrstPerf2:             .int stPerf2
iAdrsMessValCycles:      .int sMessValCycles
iAdrsMessValInst:        .int sMessValInst
iAdrsMessValTemps:       .int sMessValTemps
iAdrsMessResult:         .int sMessResult
iAdrszRetourligne:       .int szRetourligne
/***************************************************/
/*   Exemple d'appel d'une fonction               */
/***************************************************/
appelProc:              @ fonction
    push {fp,lr}        @ save des registres
    add fp,sp,#8        @ fp <- adresse début pile
    push {r0-r5}        @ save autres registres
    // vidregtit proc   @ pour mesure différents cas
    //ldr r0,iAdrdDouble1
    //ldr r1,iAdrsBuffer1
    //bl conversionDoubleU
100:                    @ fin standard de la fonction
    pop {r0-r5}   
    pop {fp,lr}         @ restaur des registres
    bx lr               @ retour de la fonction en utilisant lr
iAdrdDouble1:      .int dDouble1
iAdrsBuffer1:      .int sBuffer1
/***************************************************/
/*   conversion d'un entier double 64bits          */
/***************************************************/
/* r0 contient l'adresse du double  */
/* r1 contient l'adresse de la zone de reception */
conversionDoubleU:
    push {r0-r5,lr}     @ save des  registres
    mov r5,r1           @ save adresse
    ldrd r0,r1,[r0]     @ recupération du double
    mov r4,#19          @ position départ
    mov r2,#10          @ conversion decimale
1:                      @ debut de boucle de conversion
    bl divisionReg64U   @ division par le facteur de conversion
    add r3,#48          @ car c'est un chiffre
    strb r3,[r5,r4]     @ stockage du byte au debut zone (r5) + la position (r4)
    sub r4,r4,#1        @ position précedente
    cmp r0,#0           @ partie basse quotient égale à zero 
    bne 1b              @ non boucle
    cmp r1,#0           @ partie haute quotient égale à zero 
    bne 1b              @ non boucle
                        @ mais il faut completer le debut de la zone avec des blancs
    mov r3,#' '         @ caractere espace
2:    
    strb r3,[r5,r4]     @ stockage du blanc
    subs r4,r4,#1       @ position précedente
    bge 2b              @ boucle si r4 plus grand ou egal a zero 
    
100:                    @ fin standard de la fonction
       pop {r0-r5,lr}   @ restaur des registres
    bx lr               @ retour de la fonction en utilisant lr
/***************************************************/
/*   division d un nombre de 64 bits par un nombre de 32 bits */
/***************************************************/
/* r0 contient partie basse dividende */
/* r1 contient partie haute dividente */
/* r2 contient le diviseur */
/* r0 retourne partie basse quotient */
/* r1 retourne partie haute quotient */
/* r3 retourne le reste */
divisionReg64U:
    push {r4,r5,lr}    @ save des registres
    mov r5,#0          @ raz du reste R
    mov r3,#64         @ compteur de boucle
    mov r4,#0          @ dernier bit
1:
    lsl r5,#1          @ on decale le reste de 1
    lsls r1,#1         @ on decale la partie haute du quotient de 1
    orrcs r5,#1        @ et on le pousse dans le reste R
    lsls r0,#1         @ puis on decale la partie basse 
    orrcs r1,#1        @ et on pousse le bit de gauche dans la partie haute
    orr r0,r4          @ position du dernier bit du quotient
    mov r4,#0          @ raz du bit
    cmp r5,r2
    subhs r5,r2        @ si plus grand ou égal on enleve le diviseur du reste
    movhs r4,#1        @ et on positionne le dernier bit à 1
3:                     @ et boucle
    subs r3,#1
    bgt 1b    
    lsl r1,#1          @ on decale le quotient de 1
    lsls r0,#1         @ puis on decale la partie basse 
    orrcs r1,#1
    orr r0,r4          @ position du dernier bit du quotient
    mov r3,r5
100:                   @ fin standard de la fonction
    pop {r4,r5,lr}  @ restaur des registres
    bx lr              @ retour de la fonction en utilisant lr

/********************************************************************/
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
    