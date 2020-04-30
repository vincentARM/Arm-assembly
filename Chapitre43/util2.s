/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */

/* fonctions utilitaires    */
/* constantes */
.equ LGZONEADR, 60 
/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data

/* donnees pour vidage un registre */
szVidregistre: .ascii "adresse : "
adresse: .ascii "           "
suite: .ascii "valeur du registre : "
registre: .fill 35, 1, ' '
szFin: .asciz "\n\r"
/* donnees pour vidage tout registres */          
szVidregistreReg: .ascii "Vidage registres : "
adresseLib:  .fill LGZONEADR, 1, ' '
suiteReg: .ascii "\n\r r0  : "
reg0: .fill 9, 1, ' '
s1: .ascii " r1  : "
reg1: .fill 9, 1, ' '
s2: .ascii " r2  : "
reg2: .fill 9, 1, ' '
s3: .ascii " r3  : "
reg3: .fill 9, 1, ' '
/*ligne2 */
s4: .ascii "\n\r r4  : "
reg4: .fill 9, 1, ' '
s5: .ascii " r5  : "
reg5: .fill 9, 1, ' '
s6: .ascii " r6  : "
reg6: .fill 9, 1, ' '
s7: .ascii " r7  : "
reg7: .fill 9, 1, ' '
/*ligne 3 */
s8: .ascii "\n\r r8  : "
reg8: .fill 9, 1, ' '
s9: .ascii " r9  : "
reg9: .fill 9, 1, ' '
s10: .ascii " r10 : "
reg10: .fill 9, 1, ' '
s11: .ascii " fp  : "
reg11: .fill 9, 1, ' '
/*ligne4 */
s12: .ascii "\n\r r12 : "
reg12: .fill 9, 1, ' '
s13: .ascii " sp  : "
reg13: .fill 9, 1, ' '
s14: .ascii " lr  : inconnu  "
s15: .ascii " pc  : "
reg15: .fill 9, 1, ' '
fin: .asciz "\n\r"

/*  donnees pour vidage mémoire */
szVidregistreMem: .ascii "Aff mémoire "
sadr1: .ascii " adresse : "
adresseMem : .ascii "          "
suiteMem: .asciz "                                              *\n\r"
debmem: .fill 9, 1, ' '
s1mem: .ascii " "
zone1: .fill 48, 1, ' '
s2mem: .ascii " "
zone2: .fill 16, 1, ' '
s3mem: .asciz "\n\r"

/*******************************************/
/* DONNEES INITIALISEES A ZERO             */
/*******************************************/ 
.bss
itest:   .skip 8

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global memzero, division ,vidregistre,affregistres,affmemoireTit,lectureChaine     /* fonctions doivent �tre  global */

/***************************************************/
/*   raz zone memoire                              */
/***************************************************/
/* r0 contient l'adresse de début   */
/* r1 contient le nombre d'octets (doit être un multiple de 4) */
/* utilise r2    */
/* aucun registre sauvegardé car la pile peut ne pas etre initialisée */
memzero:
	mov r2,#0
1:
    str r2, [r0], #4      @ store r2 et incremente r0 de 4 octets
	subs r1, r1, #4
	bgt 1b
100:   /* fin standard de la fonction  */
    bx lr                   /* retour de la fonction en utilisant lr  */
	
/*=============================================*/
/* division entiere non signée                */
/*============================================*/
division:
    /* r0 contains N */
    /* r1 contains D */
    /* r2 contains Q */
    /* r3 contains R */
    push {r4, lr}
    mov r2, #0                 /* r2 ? 0 */
    mov r3, #0                 /* r3 ? 0 */
    mov r4, #32                /* r4 ? 32 */
    b 2f
1:
    movs r0, r0, LSL #1    /* r0 ? r0 << 1 updating cpsr (sets C if 31st bit of r0 was 1) */
    adc r3, r3, r3         /* r3 ? r3 + r3 + C. This is equivalent to r3 ? (r3 << 1) + C */
 
    cmp r3, r1             /* compute r3 - r1 and update cpsr */
    subhs r3, r3, r1       /* if r3 >= r1 (C=1) then r3 ? r3 - r1 */
    adc r2, r2, r2         /* r2 ? r2 + r2 + C. This is equivalent to r2 ? (r2 << 1) + C */
2:
    subs r4, r4, #1        /* r4 ? r4 - 1 */
    bpl 1b            /* if r4 >= 0 (N=0) then branch to .Lloop1 */
 
    pop {r4, lr}
    bx lr	
/**************************************************/
/*       vidage d'un registre                     */
/**************************************************/
/* r0 contient la valeur à afficher */
/* r1 contient la base d'affichage 2 binaire ou 10 ou 16 (hexa) */
/* tous les registres sont sauvés */
vidregistre:
 	push {fp,lr}    /* save des  2 registres */
	/*ici save autres registres */
	push {r0,r1,r2,r3}
	mov r4,r0       @ save valeur 
	mov r5,r1       @ save coefficient
	sub r1,lr,#4    /* adresse instruction */
	ldr r0,adresse_adresse /*adresse de stockage du resultat */
    mov r2,#16    /* conversion en base 16 */
    bl conversion
	mov r1,r4  /* récuperation valeur a afficher */
	mov r2,r5  /* récuperation facteur conversion */
	ldr r0,adresse_registre
    bl conversion
	/* affichage resultats */
	ldr r0, adresse_chaine   /* r0 <- adresse chaine */
//	ldr r0,iAdrptAdrUart
//	ldr r0,[r0]
	bl uart_send_string

	/* effacement zone registre */
	ldr r0,adresse_registre   
	mov r1,#32   /* caractère espace */
	mov r2,#0    /* compteur */
1:
    strb r1,[r0,+r2]   /* byte r1 -> adresse r0+r2 */ 
    add r2,r2,#1       /* incremente compteur */
	cmp r2,#34         /* blanc sur 35 caractères */
    ble 1b	
	
	/* retour de la fonction */
   /*pop des autres registres */
   	pop {r0,r1,r2,r3}
	 /*pop des registres frame et retour */
    pop {fp,lr}
    bx lr                            /* return from main using lr */
adresse_chaine : .word szVidregistre
adresse_adresse: .word adresse 
adresse_registre: .word registre 

/**************************************************/
/*       conversion registre en caractères ascii  */
/**************************************************/
/* r0 adresse de stockage du résultat
/* r1 valeur du registre */
/* r2 facteur de conversion */
/* gestion des nombres negatifs si base 10 */
conversion:
 	push {fp,lr}    /* save des  2 registres */
	/*ici save autres registres */
	push {r0-r7}
    mov r5, r0   /* adresse zone stockage dans le registre r5 */
	cmp r2,#2    /*   conversion en binaire */ 
	bne 1f
	mov r4,#32
	b 3f
1:	
	cmp r2,#10    /*   conversion en base 10 */ 
	bne 2f
	mov r4,#10
	@ test si nombre negatif
	cmp r1,#0
	bge 3f   @ non negatif
	mov  r3,#-1   @ negatif on le multiplie par -1 
	mov r6,r1
	mul r1,r6,r3
	mov r3,#'-'  @ et on affiche le signe moins
	strb r3,[r5]
	add r5,r5,#1
	sub r4,r4,#1
	b 3f
2:	
	mov r4,#8  /* et conversion autres */ 
3:	
	mov r0,#0   /* compteur de boucle */
	mov r3,#32  /*  espace */ 
4:    /* raz de la zone de reception */
   strb r3,[r5,+r0] 	
	add r0,#1
	cmp r0,r4
	blt 4b
	add r5,r5,r4  /* on ajoute la longueur de la zone pour commencer par la fin */
	mov r0,r2
	mov r2,r1
	mov r1,r0
5:	/* debut de boucle de conversion */
    mov r0,r2    /* division par le facteur de conversion */
	bl division
	cmp r3,#9    /* inferieur a 10 ? */
	ble 6f
	add r3,#55   /* c'est une lettre au dela de 9 : A B C D E F*/
	b 7f
6:	
	add r3,#48   /* c'est un chiffre */
7:	
    strb r3,[r5]
	sub r5,r5,#1   /* position précedente */
	cmp r2,#0      /* arret si quotient est égale à zero */
	bne 5b	
	
	
	/* retour de la fonction */
   /*pop des autres registres */
   	pop {r0-r7}
	 /*pop des registres frame et retour */
    pop {fp,lr}
    bx lr                            /* return from main using lr */
	
/**************************************************/
/*     vidage de tous les registres               */
/**************************************************/
/* argument pile : adresse du libelle a afficher */
affregistres:
	push {fp,lr}    /* save des  2 registres */
	add fp,sp,#8    /* fp <- adresse début */
	push {r0,r1,r2,r3} /* save des registres pour restaur finale en fin */ 
	push {r0,r1,r2,r3} /* save des registres avant leur vidage */ 
	ldr r1,[fp]
	mov r2,#0
	ldr r0,adresse_adresseLib /*adresse de stockage du resultat */
1: @ boucle copie
    ldrb r3,[r1,r2]
    cmp r3,#0
    strneb r3,[r0,r2]
    addne r2,#1
    bne 1b		
	mov r3,#' '
2:
    strb r3,[r0,r2]	
	add r2,#1
	cmp r2,#LGZONEADR
	blt 2b
	/* contenu registre */
	ldr r0,adresse_reg0 /*adresse de stockage du resultat */
	pop {r1}
	mov r2,#16
    bl conversion
	ldr r0,adresse_reg1 /*adresse de stockage du resultat */
	pop {r1}
	mov r2,#16
    bl conversion
	ldr r0,adresse_reg2 /*adresse de stockage du resultat */
	pop {r1}
	mov r2,#16
    bl conversion
	ldr r0,adresse_reg3 /*adresse de stockage du resultat */
	pop {r1}
	mov r2,#16
    bl conversion
	ldr r0,adresse_reg4 /*adresse de stockage du resultat */
	mov r1,r4
	mov r2,#16
    bl conversion
	ldr r0,adresse_reg5 /*adresse de stockage du resultat */
	mov r1,r5
	mov r2,#16
    bl conversion
	ldr r0,adresse_reg6 /*adresse de stockage du resultat */
	mov r1,r6
	mov r2,#16
    bl conversion
	ldr r0,adresse_reg7 /*adresse de stockage du resultat */
	mov r1,r7
	mov r2,#16
    bl conversion
	ldr r0,adresse_reg8 /*adresse de stockage du resultat */
	mov r1,r8
	mov r2,#16
    bl conversion
	ldr r0,adresse_reg9 /*adresse de stockage du resultat */
	mov r1,r9
	mov r2,#16
    bl conversion
	ldr r0,adresse_reg10 /*adresse de stockage du resultat */
	mov r1,r10
	mov r2,#16
    bl conversion
	/* r11 = fr  frame register sauvegarde en debut de fonction */
	ldr r0,adresse_reg11 /*adresse de stockage du resultat */
	sub r1,fp,#8
	ldr r1,[r1]
	mov r2,#16
    bl conversion
	ldr r0,adresse_reg12 /*adresse de stockage du resultat */
	mov r1,r12
	mov r2,#16
    bl conversion
	/* r13 = sp   et est egale au fp actuel  + 3 push dans la macro */
	ldr r0,adresse_reg13 /*adresse de stockage du resultat */
	mov r1,fp
	add r1,#12
	mov r2,#16
    bl conversion
	/* r14 = lr   adresse du retour  sauvegardé au début */
	/* mais c'est l'adresse de retour du programme appelant  */
	/* et donc qui est ecrase par l'appel de cette procedure */
	/* pour connaitre la valeur exacte il faur utiliser vidregistre */
	/* en vidant le contenu de lr */

	/* r15 = pc  donc contenu = adresse de retour (lr) - 4 */
	ldr r0,adresse_reg15 /*adresse de stockage du resultat */
	sub r1,fp,#4
	ldr r1,[r1]
	sub r1,#4
	mov r2,#16
    bl conversion
    /* affichage resultats */
	ldr r0, adresse_chaineReg   @ r0 <- adresse chaine 
    bl uart_send_string  @ envoi chaine par mini uart

	/* fin fonction */
	pop {r0,r1,r2,r3}
	pop {fp,lr}   /* restaur des  2 registres */
	add sp,#4     /* pour liberer la pile du push 1 argument */
	bx lr                            /* return from main using lr */

adresse_chaineReg : .word szVidregistreReg
adresse_adresseLib: .word adresseLib 
adresse_reg0: .word reg0
adresse_reg1: .word reg1
adresse_reg2: .word reg2
adresse_reg3: .word reg3
adresse_reg4: .word reg4
adresse_reg5: .word reg5
adresse_reg6: .word reg6
adresse_reg7: .word reg7
adresse_reg8: .word reg8
adresse_reg9: .word reg9
adresse_reg10: .word reg10
adresse_reg11: .word reg11
adresse_reg12: .word reg12
adresse_reg13: .word reg13
//adresse_reg14: .word reg14
adresse_reg15: .word reg15
/*******************************************/	
/* affichage zone memoire                  */
/*******************************************/	
/*  new   r0  adresse memoire  r1 nombre de bloc r2 titre */
affmemoireTit:
    push {fp,lr}
	add fp,sp,#8    /* fp <- adresse début pile */
	push {r0-r8} /* save des registres utilisés */ 
	mov r4,r0
	mov r6,r1
	mov r5,r2
	ldr r0,adresse_adresseMem /*adresse de stockage du resultat */
	mov r1,r4
    mov r2,#16    /* conversion en base 16 */
    //push {r3,r4,r5}	
    bl conversion
/* recup libelle dans r2 */
	mov r2,r5
	mov r0,r4
	mov r4,#0
	ldr r5,adresse_suiteMem /*adrsse de stockage du resultat */
0: @ boucle copie
    ldrb r3,[r2,r4]
    cmp r3,#0
    strneb r3,[r5,r4]
    addne r4,#1
    bne 0b		
	mov r3,#' '
	
	//mov r6,r1 /* récuperation nombre de blocs dans r6*/
	mov r2,r0 /* récuperation debut memoire a afficher */
	/* affichage entete */
	ldr r0, adresse_chaineMem   /* r0 ? adresse chaine */
	bl uart_send_string  @ envoi chaine par mini uart

	/*calculer debut du bloc de 16 octets*/
	mov r1, r2, ASR #4      /* r1 <- (r2/16) */
	mov r1, r1, LSL #4      /* r1 <- (r2*16) */
	/* mettre une étoile à la position de l'adresse demandée*/
	mov r8,#3            /* 3 caractères pour chaque octet affiché */
	sub r0,r2,r1         /* calcul du deplacement dans le bloc de 16 octets */
	mul r5,r0,r8         /* deplacement * par le nombre de caractères */
	ldr r0,adresse_zone1  /*adresse de stockage   */
	add r7,r0,r5          /* calcul de la position */
	sub r7,r7,#1          /* on enleve 1 pour se mettre avant le caractère */
	mov r0,#'*'           
	strb r0,[r7]         /* stockage de l'étoile */
1:
	/*afficher le debut  soit r1  */
	ldr r0,adresse_debmem /*adresse de stockage du resultat */
    mov r2,#16    /* conversion en base 16 */
    //push {r0,r1,r2}	
    bl conversion
	/*balayer 16 octets de la memoire  */
	mov r8,#3
	mov r2,#0
2:  /* debut de boucle de vidage par bloc de 16 octets */
	ldrb r4,[r1,+r2]	/* recuperation du byte à l'adresse début + le compteur */
	/* conversion byte pour affichage */
	ldr r0,adresse_zone1 /*adresse de stockage du resultat */
	mul r5,r2,r8   /* calcul position r5 <- r2 * 3 */
	add r0,r5
	mov r3, r4, ASR #4      /* r3 ? (r4/16) */
	cmp r3,#9    /* inferieur a 10 ? */
	addle r5,r3,#48  /*oui  */
	addgt r5,r3,#55  /* c'est une lettre en hexa */
	strb r5,[r0]    /* on le stocke au premier caractères de la position */ 
	add r0,#1        /* 2iéme caractere */
	mov r5,r3,LSL #4  /* r5 <- (r4*16)  */
	sub r3,r4,r5     /* pour calculer le reste de la division par 16 */
	cmp r3,#9    /* inferieur a 10 ? */
	addle r5,r3,#48
	addgt r5,r3,#55
	strb r5,[r0]  /* stockage du deuxieme caracteres */
	add r2,r2,#1   /* +1 dans le compteur */
	cmp r2,#16     /* fin du bloc de 16 caractères ? */
	blt 2b
	/* vidage en caractères */
	mov r2,#0   /* compteur */
3:  /* debut de boucle */
	ldrb r4,[r1,+r2]  /* recuperation du byte à l'adresse début + le compteur */
	cmp r4,#31       /* compris dans la zone des caractères imprimables ? */
	ble 4f   /* non */
	cmp r4,#125
	bgt 4f
	b 5f
4:
    mov r4,#46  /* on force le caractere . */
5:
	ldr r0,adresse_zone2 /*adresse de stockage du resultat */
	add r0,r2
	strb r4,[r0]
	add r2,r2,#1
	cmp r2,#16    /* fin de bloc ? */
	blt 3b	

    /* affichage resultats */
	ldr r0, adresse_debmem   /* r0 ? adresse chaine */
	bl uart_send_string  @ envoi chaine par mini uart

	mov r0,#' '
	strb r0,[r7]   /* on enleve l'étoile pour les autres lignes */
	add r1,r1,#16   /* adresse du bloc suivant de 16 caractères */
	subs r6,#1    /* moins 1 au compteur de blocs */
	bgt 1b   /* boucle si reste des bloc à afficher */
	
	/* fin de la fonction */
	pop {r0-r8}
	pop {fp,lr}   /* restaur des  2 registres */
	bx lr
adresse_chaineMem : .word szVidregistreMem
adresse_adresseMem: .word adresseMem
//adresse_adresseInst: .word adresseInst 
adresse_debmem: .word debmem
adresse_suiteMem: .int suiteMem
adresse_zone1: .word zone1
adresse_zone2: .word zone2

/**************************************************/
/*       lecture chaine de caractère depuis la mini uart  */
/**************************************************/
/* r0 adresse du buffer de lecture */
/* r0 retourne le nombre de caractères saisis */
lectureChaine:
 	push {fp,lr}    @ save des  2 registres 
	push {r1,r2}    @ ici save autres registres 
	mov r2,r0
	mov r1,#0    @ pointeur caractere
1:  @ début de boucle de lecture des caractères
	bl uart_recv
	//vidregtit recep
	cmp r0,#0xA      @ touche ENTER ?
	beq 2f
	@ test touche DEL
	cmp r0,#0x7f      @ DEL ?
	beq 3f
	@ test autres touches
	cmp r0,#0x1b      @ fleches de direction
	beq 4f
	@ sinon stockage du caractère s'il est valide 
	cmp r0,#0x20
	blt 2f      @ termine la chaine
	
	strb r0,[r2,r1]    @ stockage caractère dans le buffer
	add r1,#1           @ position suivante
	bl uart_send  @ envoi du caractère saisi
	b 1b     @ boucle
2:
	mov r0,#0       @ zero final
	strb r0,[r2,r1] @ pour fin du chaine du buffer
	mov r0,#'\n'
	bl uart_send  @ et on force la passage en début de ligne suivante
	mov r0,#'\r'
	bl uart_send
	mov r0,r1      @ retourne le nombre de caractères saisis
	b 100f
	
3:  @ touche DEL retour arrière d'un caractère
	bl uart_send @ envoi du caractère DEL pour retour arrière un caractère
	subs r1,#1     @ position précedente
	b 1b           @ et boucle
	
4: 
	bl uart_recv
	cmp r0,#0x5b     @ fleches de direction ?
	bne 1b
	bl uart_recv
	cmp r0,#0x44    @ fleche gauche ?
	bne 1b
	mov r0,#0x7f    @ envoi du caractère DEL pour retour arrière un caractère
	bl uart_send 
	subs r1,#1      @ position précedente
	b 1b	  @ boucle 

100: @ fin standard de la fonction 
   	pop {r1,r2} @restaur des autres registres 
    pop {fp,lr} @ restaur des registres frame et retour
    bx lr        @ retour fonction

