/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* modèle B 512MO   */
/*  */
/* Recherche IP d'un site web (cas de https) acces et extraction données */
/* voir chapitre 61 du blog  http://assembleurarmpi.blogspot.com/ */ 

/* test openssl : package libssl-dev */

/************************************/
/* Constantes                       */
/************************************/
.equ DUP2,   0x3F      @ Linux syscall
.equ WAIT4,  0x72      @ Linux syscall

.equ WUNTRACED,   2
.equ TAILLEBUFFER,  500

.equ INVALID_SOCKET,   -1
.equ AF_INET,           2        @ Internet IP Protocol

.equ SOCK_STREAM,       1        @ stream (connection) socket
.equ SOCK_DGRAM,        2        @ datagram (conn.less) socket
.equ SOCK_RAW,          3        @ raw socket
.equ SOCK_RDM,          4        @ reliably-delivered message
.equ SOCK_SEQPACKET,    5        @ sequential packet socket
.equ SOCK_PACKET,      10        @ linux specific way of

.equ LGBUFFERREQ,       128001
/*******************************************/
/* Structures                             */
/********************************************/
/* définition structure de type sockaddr_in */
    .struct  0
sin_family:              @ famille : AF_INET
    .struct  sin_family + 2 
sin_port:                @ le numéro de port
   .struct  sin_port + 2 
sin_addr:                @ l'adresse internet
    .struct  sin_addr + 4 
sin_zero:                @ un champ de 8 zéros
	.struct  sin_zero + 8
sin_fin:
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"
/*********************************/
/* DONNEES INITIALISEES          */
/*********************************/
.data
szMessDebutPgm:       .asciz "Début du programme. \n"
szRetourLigne:        .asciz "\n"
szMessFinOK:          .asciz "Fin normale du programme. \n"
szMessErreur:         .asciz "Erreur  !!!"
szMessValeurCours:    .asciz "Cours du bitcoin = "
szMessValeurFin:      .asciz " Euros. \n"
szCommand:            .asciz "/usr/bin/host"     @ commande linux host
szNomSite :           .asciz "bitcoin.fr"        @ nom du site à rechercher
szLibAdrIP:           .asciz "has address"

.align 4
szLibEur:             .asciz "<b>EUR</b>"
stArg1:               .int szCommand             @ adresse de la commande
                      .int szNomSite             @ adresse de l'argument
                      .int 0,0                   @ zeros
szRequete1:           .asciz "GET /le-cours-du-bitcoin/ HTTP/1.1 \r\nHost:  bitcoin.fr\r\n\r\n"

/*********************************/
/* DONNEES NON INITIALISEES      */
/*********************************/
.bss  
sIP:                  .skip 20
.align 4
iStatusThread:        .skip 4
pipefd:               .skip 8
stSocket1:            .skip sin_fin
sBuffer:              .skip TAILLEBUFFER
stRusage:             .skip TAILLEBUFFER
sBufferreq:           .skip LGBUFFERREQ
szCours:              .skip TAILLEBUFFER
/*********************************/
/*  code section                 */
/*********************************/
.text
.global main 
main:                                           @ programme principal 
    ldr r0,iAdrszMessDebutPgm                   @ r0 <- adresse message debut 
    bl affichageMess                            @ affichage message dans console  
    /* création pipe  */
    ldr r0,iAdrpipefd                           @  adresse FDs
    mov r7, #PIPE                               @ creation pipe
    svc 0                                       @ call system Linux
    cmp r0,#0                                   @ erreur  ?
    blt 99f

    /* création thread fils */
    mov r0,#0
    mov r7, #FORK                               @ call system
    svc #0 
    cmp r0,#0                                   @ erreur ?
    blt 99f
    bne parent                                  @ if <> zero r0 contient le pid du parent
                                                @ sinon c'est le fils
/****************************************/
/*  Thread  du fils                     */
/****************************************/
    /* redirection sysout -> pipe */ 
    ldr r0,iAdrpipefd
    ldr r0,[r0,#4]
    mov r7, #DUP2                                @ call system linux 
    mov r1, #STDOUT                              @
    svc #0
    cmp r0,#0                                    @ erreur ?
    blt 99f

    /* run commande linux host      */
    ldr r0, iAdrszCommand                        @ r0 = adresse de "/usr/bin/host"
    ldr r1,iAdrstArg1                            @ adresse argument 1
    mov r2,#0
    mov r7, #EXECVE                              @ call system linux (execve)
    svc #0                                       @ si ok -> fin du thread sans retour !!!
    b 100f                                       @ cette instruction n'est jamais executée
/****************************************/
/*  Thread parent                       */
/****************************************/
parent:
    mov r4,r0                                     @ save pid du fils
1:                                                @ boucle attente signal du fils
    mov r0,r4
    ldr r1,iAdriStatusThread                      @ status du thread
    mov r2,#WUNTRACED                             @ flags 
    ldr r3,iAdrstRusage                           @ structure retour du thread
    mov r7, #WAIT4                                @ Call System Attente signal
    svc #0 
    cmp r0,#0                                     @ erreur 
    blt 99f
    @ recup status 
    ldr r0,iAdriStatusThread                      @ analyse status
    ldrb r0,[r0]                                  @ premier byte
    cmp r0,#0                                     @ fin normale du thread ?
    bne 1b                                        @ non alors boucle

    /* fermeture pipe */ 
    ldr r0,iAdrpipefd
    mov r7,#CLOSE                                 @ call system
    svc #0 

    /* lecture des données pipe */ 
    ldr r0,iAdrpipefd
    ldr r0,[r0]
    ldr r1,iAdrsBuffer                            @ adresse du buffer
    mov r2,#TAILLEBUFFER                          @ taille du buffer 
    mov r7, #READ                                 @ call system
    svc #0 
    ldr r0,iAdrsBuffer                            @ affichage buffer
    bl affichageMess
    ldr r0,iAdrsBuffer 

    /* extraction de l'IP    */
    ldr r0,iAdrsBuffer 
    ldr r1,iAdrszLibAdrIP
    mov r2,#1
    mov r3,#2
    ldr r4,iAdrsIP
    bl extChaine
    cmp r0,#-1
    beq 99f
    //ldr r0,iAdrsIP                               @ pour affichage chaine IP
    //bl affichageMess
   /* conversion IP  */
    ldr r0,iAdrsIP
    ldr r1,iAdrstSocket1
    bl convIP
    /* connexion site sur port 443 et lancement requete */ 
    bl envoiRequete
    cmp r0,#-1
    beq 99f
    bl analyseReponse

    ldr r0,iAdrszMessFinOK                        @ affichage message Ok
    bl affichageMess
    mov r0, #0                                    @ code retour OK
    b 100f
99:
    ldr r0,iAdrszMessErreur                       @ erreur
    bl affichageMess
    mov r0, #1                                    @ code retour erreur
    b 100f
100: 
    mov r7, #EXIT                                 @ fin du programme
    svc #0                                        @ system call
iAdrszMessDebutPgm:          .int szMessDebutPgm
iAdrszMessFinOK:             .int szMessFinOK
iAdrszMessErreur:            .int szMessErreur
iAdrsBuffer:                 .int sBuffer
iAdrpipefd:                  .int pipefd
iAdrszCommand:               .int szCommand
iAdrstArg1:                  .int stArg1
iAdriStatusThread:           .int iStatusThread
iAdrstRusage:                .int stRusage
iAdrszLibAdrIP:              .int szLibAdrIP
iAdrsIP:                     .int sIP
iAdrstSocket1:               .int stSocket1

/*********************************************************/
/*   connexion au site et envoi de la requete            */
/*********************************************************/
envoiRequete:
    push {r2-r8,lr}                 @ save des registres
    ldr r5,iAdrstSocket1
    mov r0,#0xBB01                  @ port 443 stocké 01BB pour l'accès https
    strh r0,[r5,#sin_port]
    mov r0,#AF_INET                 @ Internet IP Protocol
    strh r0,[r5,#sin_family]
    mov r0,r5

    @création socket
    mov r0,#AF_INET                 @ Internet IP Protocol
    mov r1,#SOCK_STREAM
    mov r2,#0                       @ null
    mov r7,#280                     @ linux call system (socket 281)
    add r7,#1
    svc #0
    cmp r0,#INVALID_SOCKET
    beq erreur

    @ connection 
    mov r4, r0                      @ save host_sockid in r4
    mov r1,r5                       @ adresse structure socket
    mov r2,#16                      @ longueur de la structure
    mov r7,#280                     @ linux call system 283 (connect)
    add r7,#3
    svc #0
    cmp r0,#INVALID_SOCKET
    ble erreur

    @*************************************
    @ Utilisation des fonction d'Openssl *
    @*************************************
    @init ssl
    bl OPENSSL_init_crypto
    bl ERR_load_BIO_strings
    mov r2, #0
    mov r1, #0
    mov r0, #2
    bl OPENSSL_init_crypto
    mov r2, #0
    mov r1, #0
    mov r0, #0
    bl OPENSSL_init_ssl
    cmp r0,#0
    blt erreur
    bl TLS_client_method
    bl SSL_CTX_new
    cmp r0,#0
    ble erreur
    mov r6,r0                       @ save ctx
    mov r1,#0
    bl SSL_CTX_set_options
    mov r0,r6
    bl  SSL_new
    mov r5,r0                       @ save ssl
    mov r1, r4                      @ socket
    bl SSL_set_fd
    mov r0, r5        
    bl SSL_connect
    cmp r0, #1
    bne erreur
                                    @ calcul longueur de la requete
    mov r2,#0
    ldr r1,iAdrszRequete1           @ requete
1:
    ldrb r0,[r1,r2]
    cmp r0,#0
    addne r2,#1
    bne 1b
    mov r0,r5                       @ ssl
                                    @ ici r1 contient l'adresse de la requête et r2 sa longueur
    mov r3,#0
    bl SSL_write                    @ envoi requête
    cmp r0,#0
    blt erreur
    ldr r7,iAdrsBufferreq
2:                                  @début de boucle de lecture des résultats
    mov r0,r5     @ ssl
    mov r1,r7
    mov r2,#LGBUFFERREQ - 1
    mov r3,#0
    bl SSL_read
    cmp r0,#0
    ble 4f                          @ erreur ou pb serveur
    add r7,r0
    //add r2,r0,r1
    ldrb r2,[r7,#-1]                @ réutilisation de r2
    mov r1,#0xFFFFFF                @ boucle d'attente pour la prochaine lecture
3:
    subs r1,#1
    bgt 3b
    cmp r2,#0xA                     @ fin des données ?
    bne 2b                          @ non boucle

4:                                  @ fin résultats
    //ldr r0,iAdrsBufferreq           @ pour afficher le contenu de la page
    //bl affichageMess
    
    mov r0,r4                       @ socket
    mov r7, #6                      @ code pour la fonction systeme CLOSE
    svc 0                           @ appel system 
    mov r0, r5                      @ fermeture SSL
    bl  SSL_free
    mov r0, r6
    bl SSL_CTX_free
    mov r0,#0
    b 100f
erreur:                             @ affichage erreur 
    ldr r1,iAdrszMessErreur         @ r0 <- code erreur, r1 <- adresse chaine
    bl   afficheerreur              @ appel affichage message
    mov r0,#-1                      @ code erreur
    b 100f
100:                                @ fin standard de la fonction
    pop {r2-r8,lr}                  @ restaur des registres 
    bx lr                           @ retour de la fonction en utilisant lr
iAdrszRequete1:             .int szRequete1
iAdrsBufferreq:             .int sBufferreq

/*********************************************************/
/*   analyse de la réponse du site                       */
/*********************************************************/
analyseReponse:
    push {r1-r4,lr}                           @ save des registres
    ldr r0,iAdrsBufferreq
    ldr r1,iAdrszLibEur                       @ recherche mot cle
    mov r2,#1                                 @ occurence mot clé
    mov r3,#31                                @ déplacement
    ldr r4,iAdrszCours                        @ zone de reception du cours
    bl extChaine
    cmp r0,#-1
    beq 99f
    ldr r0,iAdrszMessValeurCours
    bl affichageMess
    ldr r0,iAdrszCours                        @ affichage du résultat
    bl affichageMess
    ldr r0,iAdrszMessValeurFin
    bl affichageMess
    b 100f
99:
    affichelib erreur_analyseReponse
    ldr r0,iAdrszMessErreur                   @ erreur
    bl affichageMess
    mov r0, #-1                               @ code retour erreur
    b 100f
100:                                          @ fin standard de la fonction
    pop {r1-r4,lr}                            @ restaur des registres 
    bx lr                                     @ retour de la fonction en utilisant lr
iAdrszLibEur:                 .int szLibEur
iAdrszCours:                  .int szCours
iAdrszMessValeurCours:        .int szMessValeurCours
iAdrszMessValeurFin:          .int szMessValeurFin
/*********************************************************/
/*   Extraction d 'un mot d'un texte suivant un mot cle  */
/*********************************************************/
/* r0  adresse du texte   */
/* r1  adresse mot clé a rechercher */
/* r2  nombre occurence mot cle */
/* r3  déplacement mot */
/* r4  adresse de stockage du mot */
extChaine:
    push {r2-r8,lr}    @ save des registres
    mov r5,r0    @ save addresse texte
    mov r6,r1    @ save mot clé
    @ il faut calculer la longueur du texte
    mov r7,#0
1:                       @ calcul longueur texte
    ldrb r0,[r5,r7]      @ pour des textes longs, et nombreuses recherches 
    cmp r0,#0            @ il serait préférable de passer la longueur du texte en parametre
    addne r7,#1          @ pour éviter cette boucle
    bne 1b
    add r7,r5            @ calcul adresse fin du texte

    @ il faut aussi la longueur du mot clé
    mov r8,#0
2:                       @ calcul longueur mot clé
    ldrb r0,[r6,r8]
    cmp r0,#0
    addne r8,#1
    bne 2b

3:  @ boucle de recherche du nième(r2)  mot clé 
    mov r0,r5
    mov r1,r6
    bl rechercheSousChaine
    cmp r0,#0
    blt 100f
    subs r2,#1
    addgt r5,r0       
    addgt r5,r8
    bgt 3b
    add r0,r5           @ ajout adresse texte précédent à l'index trouvé
    add r3,r0           @ ajout du déplacement à r0
    sub r3,#1
    @ et il faut ajouter la longueur du mot cle 
    add r3,r8           @ ajout longueur 
    cmp r3,r7           @ verification si pas superieur à la fin du texte
    movge r0,#-1        @ sinon erreur
    bge 100f
    mov r0,#0
4:   @ boucle de copie des caractères 
    ldrb r2,[r3,r0]
    strb r2,[r4,r0]
    cmp r2,#0           @ fin du texte ?
    moveq r0,#0         @ dans ce cas r0 retourne 0
    beq 100f
    cmp r2,#' '         @ fin du mot ?
    beq 5f              @ alors fin
    cmp r2,#'<'         @ fin du mot ?
    beq 5f              @ alors fin
    cmp r2,#10          @ fin de ligne = fin du mot ?
    beq 5f              @ alors fin
    @ ici il faut ajouter d'autres fin de mot comme > : . etc 
    add r0,#1
    b 4b                @ boucle
5:
    mov r2,#0           @ forçage 0 final
    strb r2,[r4,r0]
    add r0,#1
    add r0,r3           @ r0 retourne la position suivant la fin du mot
                        @ peut servir à continuer une recherche 
100:                    @ fin standard de la fonction
   	pop {r2-r8,lr}      @ restaur des registres 
    bx lr               @ retour de la fonction en utilisant lr

/******************************************************************/
/*   recherche d'une sous chaine dans une chaine                  */ 
/******************************************************************/
/* r0 contient l'adresse de la chaine */
/* r1 contient l'adresse de la sous-chaine */
/* r0 retourne l'index du début de la sous chaine dans la chaine ou -1 si non trouvée */
rechercheSousChaine:
    push {r1-r6,lr}                       @ save registres 
    mov r2,#0                             @ index position chaine
    mov r3,#0                             @ index position sous chaine
    mov r6,#-1                            @ index recherche
    ldrb r4,[r1,r3]                       @ chargement premier octet sous chaine
    cmp r4,#0                             @ zero final ?
    moveq r0,#-1                          @ erreur 
    beq 100f
1:
    ldrb r5,[r0,r2]                       @ chargement octet chaine
    cmp r5,#0                             @ zero final ?
    moveq r0,#-1                          @ oui non trouvée
    beq 100f
    cmp r5,r4                             @ compare caractère des 2 chaines 
    beq 2f
    mov r6,#-1                            @ différent - > raz index 
    mov r3,#0                             @ et raz compteur byte
    ldrb r4,[r1,r3]                       @ et chargement octet
    add r2,#1                             @ et increment compteur byte
    b 1b                                  @ et boucle
2:                                        @ caracteres egaux
    cmp r6,#-1                            @ est-ce le premier caractère egal ?
    moveq r6,r2                           @ oui -> index de debut est mis dans r6
    add r3,#1                             @ increment compteur souschaine
    ldrb r4,[r1,r3]                       @ et chargement octet suivant
    cmp r4,#0                             @ zero final ?
    beq 3f                                @ oui -> fin de la recherche 
    add r2,#1                             @ sinon increment index de la chaine
    b 1b                                  @ et boucle
3:
    mov r0,r6
100:
    pop {r1-r6,lr}                        @ restaur registres
    bx lr   
/*********************************************************/
/*   Conversion chaine adresse IP  en octet structure sockaddr_in */
/*********************************************************/
/* r0  adresse de la chaine   */
/* r1  adresse de la structure de type sockaddr_in */
convIP:
    push {r1-r6,lr}    @ save des registres
    mov r5,r0          @ save addresse texte
    mov r2,#0
    mov r4,#sin_addr
    mov r6,r0          @ debut zone
                       @ recherche . ou fin de chaine
1:
    ldrb r3,[r5,r2]
    cmp r3,#0
    beq 4f             @ fin de chaine
    cmp r3,#'.'
    addne r2,#1
    bne 1b
    mov r3,#0          @ remplacement du point par le zero final
    strb r3,[r5,r2]
    @ conversion
    mov r0,r6
    bl conversionAtoD
    strb r0,[r1,r4]
    add r4,#1
    add r2,#1
    add r6,r5,r2
    b 1b
4:
    @ conversion finale 
    mov r0,r6
    bl conversionAtoD
    strb r0,[r1,r4]
100:                    @ fin standard de la fonction
    pop {r1-r6,lr}      @ restaur des registres 
    bx lr               @ retour de la fonction en utilisant lr
/*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
