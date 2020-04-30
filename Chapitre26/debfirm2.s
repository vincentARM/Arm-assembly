/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* modèle B 512MO   */
/* test acces firmware */
/* lecture N° serie et température du SOC */
/*********************************************/
/*constantes particulière au programme*/
/********************************************/
.equ CODESERIE,   0x00010004     @ code requête pour N° serie
.equ CODEMEM,     0x00010005     @ code requête  pour taille memoire
.equ CODETEMP,   0x00030006      @ code requete pour temperature
/*******************************************/
/* Structures                          **/
/*******************************************/
/* structure de type msg mailbox  */
    .struct  0
mbox_msg_size:	          /* taille du message */
    .struct mbox_msg_size + 4
mbox_msg_code:	          /* code retour requete message */
    .struct mbox_msg_code + 4
mbox_tag_id:	              /* identifiant du tag   */
	.struct mbox_tag_id + 4
mbox_tag_size:	              /* taille du buffer souvent 8 octets   */
	.struct mbox_tag_size + 4
mbox_data_size:	              /* taille des données reçues et code retour   */
	.struct mbox_data_size + 4
mbox_data_id:	              /* identification de certaines données reçues    */
	.struct mbox_data_id + 4
mbox_data_val:	              /* valeur    */
	.struct mbox_data_val + 4 
mbox_data_val1:	              /* valeur    */
	.struct mbox_data_val1 + 4 
mbox_data_val2:	              /* valeur    */
	.struct mbox_data_val2 + 4 	
mbox_data_end:	              /* doit être zéro    */
	.struct mbox_data_end + 4 	
mbox_fin:
	
/*******************************************/
/* Fichier des macros                       */
/********************************************/
.include "../ficmacros.s"

/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data
szMessDebutPgm: .asciz "Début du programme. \n"
szMessFinOK: .asciz "Fin normale du programme. \n"
szMessErreur: .asciz "Erreur ouverture fichier.\n"
szMessErreur1: .asciz "Erreur fermeture fichier.\n"
szMessErreur2: .asciz "Erreur accès données.\n"
szRetourligne: .asciz  "\n"
szMessValeur:  .ascii "Valeur trouvée : "
iValeur:       .fill 12, 1, ' '
                   .asciz "\n"

szPeriphNom: .asciz "/dev/vcio"
.align 4


/*******************************************/
/* DONNEES NON INITIALISEES                    */
/*******************************************/ 
.bss
.align 4
@ place mémoire pour le message en fonction de la structure 
message_MBOX:  .skip mbox_fin

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global main      /* 'main' point d'entrée doit être  global */

main:             /* programme principal */
    push {fp,lr}    /* save des  2 registres */
	add fp,sp,#8    /* fp <- adresse début */
	ldr r0,iAdrszMessDebutPgm   /* r0 ← adresse message */
	bl affichageMess  /* affichage message dans console   */

	/* ouverture du peripherique */
	ldr r0,iAdrszPeriphNom   /* nom du peripherique à ouvrir */
	ldr r1,#iFlags  /*  flags    */
	mov r2,#0        /* mode */
	mov r7, #OPEN /* appel fonction systeme pour ouvrir */
    swi #0 
	cmp r0,#0    /* si erreur retourne -1 */
	ble erreur
	mov r8,r0    /* save du Fd */ 
	
	/* préparation du message */
	ldr r0,iAdrmessage_MBOX
	mov r1,#mbox_fin
	str r1,[r0,#mbox_msg_size]
	ldr r1,iTagSerie
	str r1,[r0,#mbox_tag_id]
	mov r1,#8
	str r1,[r0,#mbox_tag_size]
	/* lecture code serie */
	mov r0,r8
	ldr r1,=IOWR
	ldr r1,[r1]
	ldr r2,iAdrmessage_MBOX
	mov r7, #IOCTL     @ appel systeme 
    swi 0 
	@ verif code retour
	ldr r1,iAdrmessage_MBOX
	ldr r0,[r1,#mbox_msg_code]
	cmp r0,#0x80000000
	bne erreur2
	@ pas d'erreur d'acces
	//ldr r0,iAdrmessage_MBOX
	//mov r1,#4  /* nombre de bloc a afficher */
    //push {r0} /* adresse memoire */	
	//push {r1}
    bl affmemoire
	ldr r0,[r0,#mbox_data_id]
	ldr r1,iAdriValeur
	bl conversion10S
	ldr r0,iAdrszMessValeur
	bl affichageMess  /* affichage message dans console   */

	@lecture de la température
	ldr r0,iAdrmessage_MBOX
	mov r1,#0
	str r1,[r0,#mbox_msg_code]   @ raz du code requete
    ldr r1,iTagTemp
	str r1,[r0,#mbox_tag_id]    @ tag requete
	mov r1,#8
	str r1,[r0,#mbox_tag_size]   @ longueur
	mov r1,#0
	str r1,[r0,#mbox_data_id]   @ id temperature
	mov r1,#0
	str r1,[r0,#mbox_data_size]   @ longeur réponse
	
	mov r0,r8    /* recup du Fd */ 
	ldr r1,=IOWR
	ldr r1,[r1]
	ldr r2,iAdrmessage_MBOX
	mov r7, #IOCTL    @ appel systeme 
    swi 0 
	@ verif code retour
	ldr r1,iAdrmessage_MBOX
	ldr r0,[r1,#mbox_msg_code]
	cmp r0,#0x80000000
	bne erreur2
	//ldr r0,iAdrmessage_MBOX
	//mov r1,#4  /* nombre de bloc a afficher */
    //push {r0} /* adresse memoire */	
	//push {r1}
    //bl affmemoire
	ldr r0,[r0,#mbox_data_val]
	ldr r1,iAdriValeur
	bl conversion10S
	ldr r0,iAdrszMessValeur
	bl affichageMess  /* affichage message dans console   */

	/* fermeture fichier vcio */
	mov r0,r8   /* Fd  fichier */
	mov r7, #CLOSE /* appel fonction systeme pour fermer */
    swi #0 
	cmp r0,#0
	blt erreur1	
    /* fin OK */
finnormale:	
    ldr r0,iAdrszMessFinOK   /* r0 ← adresse chaine */
	bl affichageMess  /* affichage message dans console   */	
	mov r0,#0     /* code retour OK */
	b 100f
erreur:		/* erreur d'ouverture du fichier */
	ldr r1,iAdrszMessErreur   /* r0 <- code erreur r1 <- adresse chaine */
    bl   afficheerreur   /*appel procedure  */		
	mov r0,#1       /* erreur */
	b 100f	
erreur1:	/* erreur fermeture du fichier */
	ldr r1,iAdrszMessErreur1   /* r1 <- adresse chaine */
	bl   afficheerreur   /*appel procedure  */		
	mov r0,#1       /* erreur */
	b 100f	
erreur2:	/* erreur  acces aux données */
	ldr r1,iAdrszMessErreur2   /* r1 <- adresse chaine */
	bl   afficheerreur   /*appel procedure  */		
	mov r0,#1       /* erreur */
	b 100f		
100:		/* fin de programme standard  */
	pop {fp,lr}   /* restaur des  2 registres */
	mov r0,#0     /* code retour  */
	mov r7, #EXIT /* appel fonction systeme pour terminer */
    swi  #0

iAdrszPeriphNom:		.int szPeriphNom
iFlags:     				.int O_RDONLY 
iAdrmessage_MBOX:		.int message_MBOX
iAdriValeur:  			.int iValeur
iAdrszMessDebutPgm: 	.int szMessDebutPgm
iAdrszMessFinOK: 		.int szMessFinOK
iAdrszMessErreur:		.int szMessErreur
iAdrszMessErreur1:		.int szMessErreur1  
iAdrszMessErreur2:		.int szMessErreur2
iAdrszMessValeur: 		.int szMessValeur
iTagTemp: 				.int CODETEMP
iTagSerie: 				.int CODESERIE
iTagMem: 					.int CODEMEM 
IOWR: 						.int 0xc0046400
/***************************************************/
/*   conversion registre en décimal   signé  */
/***************************************************/
/* r0 contient le registre   */
/* r1 contient l'adresse de la zone de conversion */
conversion10S:
    push {fp,lr}    /* save des  2 registres frame et retour */
    push {r0-r5}   /* save autres registres  */
    mov r2,r1       /* debut zone stockage */
    mov r5,#'+'     /* par defaut le signe est + */
    cmp r0,#0       /* nombre négatif ? */
    movlt r5,#'-'     /* oui le signe est - */
    mvnlt r0,r0       /* et inversion en valeur positive */
    addlt r0,#1

    mov r4,#10   /* longueur de la zone */
1: /* debut de boucle de conversion */
    bl divisionpar10 /* division  */
    add r1,#48        /* ajout de 48 au reste pour conversion ascii */	
    strb r1,[r2,r4]  /* stockage du byte en début de zone r5 + la position r4 */
    sub r4,r4,#1      /* position précedente */
    cmp r0,#0     
    bne 1b	       /* boucle si quotient different de zéro */
    strb r5,[r2,r4]  /* stockage du signe à la position courante */
    subs r4,r4,#1   /* position précedente */
    blt  100f         /* si r4 < 0  fin  */
    /* sinon il faut completer le debut de la zone avec des blancs */
    mov r3,#' '   /* caractere espace */	
2:
    strb r3,[r2,r4]  /* stockage du byte  */
    subs r4,r4,#1   /* position précedente */
    bge 2b        /* boucle si r4 plus grand ou egal a zero */
100:  /* fin standard de la fonction  */
    pop {r0-r5}   /*restaur des autres registres */
    pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr   

/***************************************************/
/*   division par 10   signé                       */
/* Thanks to http://thinkingeek.com/arm-assembler-raspberry-pi/*  
/* and   http://www.hackersdelight.org/            */
/***************************************************/
/* r0 contient le dividende   */
/* r0 retourne le quotient */	
/* r1 retourne le reste  */
divisionpar10:	
  /* r0 contains the argument to be divided by 10 */
   push {r2-r4}   /* save autres registres  */
   mov r4,r0 
   ldr r3, .Ls_magic_number_10 /* r1 <- magic_number */
   smull r1, r2, r3, r0   /* r1 <- Lower32Bits(r1*r0). r2 <- Upper32Bits(r1*r0) */
   mov r2, r2, ASR #2     /* r2 <- r2 >> 2 */
   mov r1, r0, LSR #31    /* r1 <- r0 >> 31 */
   add r0, r2, r1         /* r0 <- r2 + r1 */
   add r2,r0,r0, lsl #2   /* r2 <- r0 * 5 */
   sub r1,r4,r2, lsl #1   /* r1 <- r4 - (r2 * 2)  = r4 - (r0 * 10) */
   pop {r2-r4}
   bx lr                  /* leave function */
   .align 4
.Ls_magic_number_10: .word 0x66666667
 /*********************************************/
/*constantes */
/********************************************/
.include "../constantesARM.inc"
