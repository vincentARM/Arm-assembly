/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* programme pour test fonctions socket */
/*  lancer par testServeur &   en arrière plan */ 

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
.equ BASECALL,               250
.equ SETSOCKOPT,             44
.equ SOCKET,                 31
.equ BIND,                   32
.equ LISTEN,                 34
.equ ACCEPT,                 35
.equ RECV,                   41
.equ SEND,                   39

.equ SOCK_STREAM,            1        @ stream (connection) socket
.equ SOCK_DGRAM,             2        @ datagram (conn.less) socket
.equ SOL_SOCKET,             6        @ N° protocole TCP


.equ SO_REUSEADDR, 0x0004
.equ SO_REUSEPORT, 0014
.equ LGBUFFER,             100
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
szMessFinPgm:     .asciz "Arret du serveur. \n"
szMessErreur:     .asciz "Une erreur est arrivée. \n"   

szReponse1:       .ascii "Reponse du serveur cmd 1"
                  .byte 0xA,0

szReponse2:       .ascii "Reponse du serveur cmd 2"
                  .byte 0xA,0

szCmd1:           .asciz "cmd1"
szCmd2:           .asciz "cmd2"
szCmd3:           .asciz "stop"

szIP:             .ascii "192.168.1.14"           @ adresse IP du serveur

.align 4
hPort:            .hword 4444                     @ port
iOptVal:          .int 1
/*******************************************/
/* données non initialisées                */
/********************************************/
.bss
stSocketServeur:    .skip sin_fin
stSocketClient:     .skip sin_fin
iLgStrClient:       .skip 4
sBuffer:            .skip LGBUFFER
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
    ble erreur
    
    mov r8, r0                          @ save ident socket serveur dans r4
    vidregtit retour_socket
    
                                        @ maj des options de la socket
    mov r1,#SOL_SOCKET                  @ adresse de la structure
    mov r2,#SO_REUSEADDR | SO_REUSEPORT @ option
    ldr r3,iAdriOptVal
    mov r4,#4
    mov r7, #BASECALL                   @ call system linux  (setsockopt) 294
    add r7, #SETSOCKOPT
    svc #0
    cmp r0,#0
    blt erreur
    vidregtit retour_option

                                        @ fonction bind
    mov r0,r8                           @ socket 
    ldr r1,iAdrstSocketServeur          @ adresse de la structure
    mov r2, #16                         @ longueur de la structure
    mov r7, #BASECALL                   @ call system linux  (bind) 282
    add r7, #BIND
    svc #0
    cmp r0,#0
    blt erreur
    vidregtit retour_bind
0:
                                        @ fonction listen 
    mov r0, r8                          @ ident socket
    mov r1, #5                          @ nombre de connexions pouvant être mises en attente
    mov r7, #BASECALL                   @ call system linux (listen 284) 
    add r7, #LISTEN
    svc #0 
    cmp r0,#0
    blt erreur
    vidregtit retour_listen
    
                                        @ fonction accept 
    mov r0, r8                          @ ident socket
    ldr r1, iAdrstSocketClient
    ldr r2, iAdriLgStrClient
    mov r7, #BASECALL                   @ call system linux (accept 285)
    add r7, #ACCEPT
    svc #0
    mov r4, r0                          @ save ident socket client dans r4
    vidregtit retour_accept
    ldr r0,iAdrstSocketClient
    vidmemtit retour_accept  r0 3
1:                                      @ debut de boucle de lecture des commandes
    ldr r6,iAdrsBuffer
    vidregtit lecture
                                        @ fonction lecture
    mov r0,r4
    mov r1,r6                           @ adresse du buffer
    mov r2,#LGBUFFER - 1
    mov r3,#0
    mov r7,#BASECALL                         @ linux call system (recv 291)
    add r7,#RECV
    svc #0
    vidregtit retourlect
    cmp r0,#0
    blt erreur
    beq 0b
    sub r0,r0,#1
    mov r1,#0
    strb r1,[r6,r0]
    mov r0,r6                       @ adresse du buffer de reception
    ldr r1,iAdrszCmd1
    bl comparaison
    bne 4f
                                    @ envoi de la réponse commande 1
     mov r2,#0
    ldr r1,iAdrszReponse1           @ adresse requete 
2:                                  @ calcul de la longueur de la reponse
    ldrb r0,[r1,r2]
    cmp r0,#0
    addne r2,#1
    bne 2b
                                    @ envoi reponse
    mov r0,r4                       @ socket
                                    @ ici r1 contient l'adresse de la requète et r2 sa longueur
    mov r3,#0
    mov r7,#BASECALL                @ linux call system (send  289)
    add r7,#SEND
    svc #0
    cmp r0,#0
    blt erreur
    b 5f
4:
    mov r0,r6
    ldr r1,iAdrszCmd2               @ commande 2 ?
    bl comparaison
    bne 42f
                                    @ envoi de la réponse.
     mov r2,#0
    ldr r1,iAdrszReponse2           @ adresse reponse
41:                                 @ calcul de la longueur de la reponse
    ldrb r0,[r1,r2]
    cmp r0,#0
    addne r2,#1
    bne 41b
                                    @ envoi requète
    mov r0,r4                       @ socket
                                    @ ici r1 contient l'adresse de la requète et r2 sa longueur
    mov r3,#0
    mov r7,#BASECALL                @ linux call system (send  289)
    add r7,#SEND
    svc #0
    cmp r0,#0
    blt erreur
    b 5f
42:
    mov r0,r6
    ldr r1,iAdrszCmd3              @ arret du serveur
    bl comparaison
    beq 10f
    
5:
    b 1b                            @ boucle
    
10:
    mov r0,r4                       @ socket
    mov r7,#CLOSE                   @ fermeture socket client
    svc 0
                                    @ fin serveur
    mov r0,r8                       @ socket
    mov r7,#CLOSE                   @ fermeture socket
    svc 0
    ldr r0,iAdrszMessFinPgm
    bl affichageMess
    mov r0,#0
    b 100f
erreur:                                 @ affichage erreur 
    ldr r1,iAdrszMessErreur             @ r0 <- code erreur, r1 <- adresse chaine 
    bl   afficheerreur                  @ appel affichage message 
    mov r0,r8                           @ socket
    mov r7,#CLOSE                       @ fermeture socket
    svc 0
    mov r0,#-1                          @ code erreur 
    b 100f
100:
    mov r7, #EXIT
    svc #0                              @appel system 

iAdrstSocketServeur:      .int stSocketServeur
iAdrhPort:                .int hPort
iAdrszIP:                 .int szIP
iAdrszMessDebutPgm:       .int szMessDebutPgm    
iAdrszMessErreur:         .int szMessErreur
iAdrsBuffer:              .int sBuffer
iAdrszCmd1:               .int szCmd1
iAdrszCmd2:               .int szCmd2
iAdrszCmd3:               .int szCmd3
iAdrszReponse1:           .int szReponse1
iAdrszReponse2:           .int szReponse2
iAdrstSocketClient:       .int stSocketClient
iAdriLgStrClient:         .int iLgStrClient
iAdriOptVal:              .int iOptVal
iAdrszMessFinPgm:         .int szMessFinPgm
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
    