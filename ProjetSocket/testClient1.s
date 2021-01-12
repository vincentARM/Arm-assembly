/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* programme pour test client fonctions socket */

/*******************************************/
/* Constantes du programme                 */
/********************************************/
.equ INVALID_SOCKET,        -1
.equ AF_INET,                2    @ Internet IP Protocol
.equ STDIN,                  0    @ Standard input linux
.equ STDOUT,                 1    @ Standard output linux
.equ STDERR,                 2    @ Standard erreur linux
.equ EXIT,                   1
.equ CLOSE,                  6
.equ READ,                   3
.equ BASECALL,               250
.equ SOCKET,                 31
.equ CONNECT,                33
.equ LISTEN,                 34
.equ ACCEPT,                 35
.equ RECV,                   41
.equ RECVFROM,               42
.equ SEND,                   39
.equ SENDTO,                 40
.equ SOCK_STREAM,            1        @ stream (connection) socket
.equ SOCK_DGRAM,             2        @ datagram (conn.less) socket

.equ LGBUFFERPAGE,         10000
.equ TAILLEBUF,            100
.equ TAILLETAS,            1000     @ TODO: a corriger script linker 
.global TAILLETAS
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"
/*******************************************/
/* Structures                             */
/********************************************/
/* définition structure de type sockaddr_in */
    .struct  0
sin_family:              @ famille : AF_INET
    .struct  sin_family + 2 
sin_port:                @ le numèro de port
   .struct   sin_port + 2 
sin_addr:                @ l'adresse internet
    .struct  sin_addr + 4 
sin_zero:                @ un champ de 8 zéros
    .struct  sin_zero + 8
sin_fin:
/*******************************************/
/* données initialisées                    */
/********************************************/
.data
szMessDebutPgm:   .asciz "Début du programme. \n"

szMessErreur:     .asciz "Une erreur est arrivée. \n"   
szMessCommande:   .asciz "Entrez une commande (stop pour arrêter le serveur fin pour finir) : \n"

szCmdFin:  .ascii "fin"
           .byte 0xA,0

/* structure de type sockaddr   */
struct_addr:
.ascii "\x02\x0"       @ AF_INET
.ascii "\x11\x5c"      @ port number 4444 
.byte 0,0,0,0          @ IP Address 
.byte 0,0,0,0,0,0,0,0  @ 8 zeros binaires 

szIP:              .ascii "192.168.1.14"

.align 4
hPort:             .hword 4444
/*******************************************/
/* données  non initialisées               */
/********************************************/
.bss
stSocketServeur:     .skip sin_fin
sBufferPage:         .skip LGBUFFERPAGE
sBuffer:             .skip TAILLEBUF
/**************************************/
/* -- Code section                  */
/**************************************/
.text 
.global main                            @ point d'entrée du programme
main:                                   @ Programme principal
    ldr r0,iAdrszMessDebutPgm           @ r0 <-   message debut
    bl affichageMess                    @ affichage message dans console
    
    ldr r1,iAdrstSocketServeur          @ preparation de la structure
    ldr r2,iAdrhPort                    @ stockage du port
    ldrb r3,[r2]
    strb r3,[r1,#sin_port+1]
    ldrb r3,[r2,#1]
    strb r3,[r1,#sin_port]
    mov r2,#AF_INET                     @ Internet IP Protocol
    strh r2,[r1,#sin_family]
    ldr r0,iAdrszIP
    bl convertirIP
                                        @création socket
    mov r0, #AF_INET
    mov r1, #SOCK_STREAM
    mov r2, #0                          @  null
    mov r7, #BASECALL                   @ call system linux (socket 281)
    add r7, #SOCKET
    svc #0
    cmp r0,#INVALID_SOCKET
    beq erreur
    
    mov r9, r0                          @ save ident socket dans r4
    vidregtit debut_socket
    
                                       @ connection 
    ldr  r1,iAdrstSocketServeur        @ adresse de la structure
    mov r2,#sin_fin                    @ longueur de la structure
    mov r7,#BASECALL                   @ linux call system 283 (connect)
    add r7,#CONNECT
    svc #0
    cmp r0,#INVALID_SOCKET
    ble erreur
    vidregtit connection
1:
    ldr r0,iAdrszMessCommande
    bl affichageMess
    mov r0,#STDIN                      @ code pour la console d'entrée standard
    ldr r1,iAdrsBuffer                 @ adresse du buffer de saisie
    mov r2,#TAILLEBUF                  @ taille buffer
    mov r7,#READ                       @ appel système pour lecture saisie
    svc #0 
    cmp r0,#0                          @ erreur ?
    blt erreur
    mov r2,r0                          @ longueur de la requête
    ldr r1,iAdrsBuffer                 @ adresse requete
    mov r0,#0
    strb r0,[r1,r2]
    vidmemtit retour r1 2
    ldr r0,iAdrszCmdFin
    bl comparaison
    beq 10f
    mov r0,#0xA
    strb r0,[r1,r2]
    vidregtit apressaisie
//    mov r2,#0
//    ldr r1,iAdrszRequete1           @ adresse requete 
//1:                                  @ calcul de la longueur de la requète
//    ldrb r0,[r1,r2]
//    cmp r0,#0
//    addne r2,#1
//    bne 1b
                                    @ envoi requète
    mov r0,r9                       @ socket
    ldr r1,iAdrsBuffer           @ adresse requete 
                                    @ ici r1 contient l'adresse de la requète et r2 sa longueur
    mov r3,#0
    mov r4,#0
    mov r5,#0
    mov r7,#BASECALL                   @ linux call system (sendto  290)
    add r7,#SENDTO
    svc #0
    cmp r0,#0
    blt erreur
    ldr r6,iAdrsBufferPage
    vidregtit apres_send
2:                                     @ début de boucle de lecture des résultats
    mov r0,r9
    mov r1,r6
    mov r2,#LGBUFFERPAGE - 1
    mov r3,#0
    mov r4,#0
    mov r5,#0
    mov r7,#BASECALL                    @ linux call system (recvfrom 292)
    add r7,#RECVFROM
    svc #0
    vidregtit retourlect
    cmp r0,#0
    blt erreur
    beq 5f

    ldr r0,iAdrsBufferPage              @ pour afficher le contenu de la page
    bl affichageMess
    
5:
    b 1b

10:
    mov r0,r9                           @ socket
    mov r7,#CLOSE                       @ fermeture socket
    svc 0
    vidregtit closer9
    mov r0,#0                           @ requete OK
    
    b 100f
erreur:                                 @ affichage erreur 
    ldr r1,iAdrszMessErreur             @ r0 <- code erreur, r1 <- adresse chaine 
    bl   afficheerreur                  @ appel affichage message 
    mov r0,#-1                          @ code erreur 
    b 100f
100:
    mov r7, #EXIT
    svc #0                              @appel system 
iAdrstSocketServeur:      .int stSocketServeur
iAdrhPort:                .int hPort
iAdrszIP:                 .int szIP
//iAdrstruct_addr:          .int struct_addr
iAdrszMessDebutPgm:       .int szMessDebutPgm    
iAdrszMessErreur:         .int szMessErreur
iAdrsBufferPage:          .int sBufferPage
iAdrsBuffer:              .int sBuffer
iAdrszMessCommande:       .int szMessCommande
iAdrszCmdFin:             .int szCmdFin
/*********************************************************/
/*   Conversion chaine adresse IP  en octet structure sockaddr_in */
/*********************************************************/
/* r0  adresse de la chaine   */
/* r1  adresse de la structure de type sockaddr_in */
convertirIP:
    push {r1-r6,lr}              @ save des registres
    mov r5,r0                    @ save addresse texte
    mov r2,#0
    mov r4,#sin_addr
    mov r6,r0                    @ debut zone
                                 @ recherche . ou fin de chaine
1:
    ldrb r3,[r5,r2]
    cmp r3,#0
    beq 4f                       @ fin de chaine
    cmp r3,#'.'
    addne r2,#1
    bne 1b
    mov r3,#0                    @ remplacement du point par le zero final
    strb r3,[r5,r2]
    mov r0,r6                    @ conversion ascii registre
    bl conversionAtoD
    strb r0,[r1,r4]
    add r4,#1
    add r2,#1
    add r6,r5,r2
    b 1b
4:
    mov r0,r6                    @ conversion finale
    bl conversionAtoD
    strb r0,[r1,r4]
100:                             @ fin standard de la fonction
   	pop {r1-r6,lr}               @ restaur des registres 
    bx lr                        @ retour de la fonction en utilisant lr
    