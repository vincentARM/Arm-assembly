/* programme assembleur ARM pour Raspberry */
/* affichage zones mémoire */
/********************************/
/*  Constantes                  */
/********************************/ 
.equ EXIT, 1
.equ WRITE, 4

.equ STDOUT, 1
/********************************/
/*  Données initialisées        */
/********************************/ 
.data
/*  donnees pour vidage mémoire */
szVidregistreMem: .ascii "Vidage mémoire instruction : "
adresseInst: .ascii "            "
sadr1: .ascii " adresse : "
adresseMem : .ascii "            "
suiteMem: .asciz "\n"
debmem: .fill 9, 1, ' '
s1mem: .ascii " "
zone1: .fill 48, 1, ' '
s2mem: .ascii " "
zone2: .fill 16, 1, ' '
s3mem: .asciz "\n"			  

/********************************/
/*  Code section                */
/********************************/
.text    
.global main           /* point d'entrée du programme  */
main:                  /* Programme principal */
   ldr r0,=adresseMem  /* zone mémoire à vider */
   //mov r0,sp         /* pour vider la pile */
   //ldr r0,=main      /* pour vider les instructions !! */
   //sub r0,r0,#100
   mov r1,#10          /* nombre de blocs de 16 octets à vider */
   push {r0,r1}        /* passage des paramètres R0 puis r1 */
   //push {r1}         /* Attention si push individuel */
   //push {r0}         /* il faut inverser les 2 registres */
   bl affmemoire
  
  /* Fin standard du programme */
    mov r0,#0         /* code retour r0 */
    mov r7, #EXIT     /* code pour la fonction systeme EXIT */
    swi 0             /* appel system */
/*******************************************/	
/* affichage zone memoire  */
/*******************************************/	
affmemoire:
    push {fp,lr}
	add fp,sp,#8               /* fp <- adresse début pile */
	push {r0-r8}               /* save des registres utilisés */ 
	sub r0,lr,#4               /* adresse instruction d'appel */
	ldr r1,adresse_adresseInst /*adresse de stockage du resultat */
        bl conversion16
	mov r0,fp                  /* récuperation debut memoire a afficher */ 
	ldr r0, [r0]               /* dans le registre r0 */
	ldr r1,adresse_adresseMem  /*adresse de stockage du resultat */
        bl conversion16
	
	/* affichage entete */
	ldr r0, adresse_chaineMem   /* r0 <- adresse chaine */
        bl affichageMess            /*appel procedure  */
	mov r0,fp                   /* récuperation debut mémoire a afficher */
	ldr r2, [r0]                /* dans le registre r2 */
	add r0,fp,#4                /* recuperation nombre de blocs */
        ldr r6, [r0]                /* dans le registre r6 */
	/*calculer debut du bloc de 16 octets*/
	mov r1, r2, ASR #4          /* r1 <- (r2/16) */
	mov r1, r1, LSL #4          /* r1 <- (r2*16) */
	/* mettre une étoile à la position de l'adresse demandée*/
	mov r8,#3                   /* 3 caractères pour chaque octet affichée */
	sub r0,r2,r1                /* calcul du deplacement dans le bloc de 16 octets */
	mul r5,r0,r8                /* deplacement * par le nombre de caractères */
	ldr r0,adresse_zone1        /*adresse de stockage   */
	add r7,r0,r5                /* calcul de la position */
	sub r7,r7,#1                /* on enleve 1 pour se mettre avant le caractère */
	mov r0,#'*'           
	strb r0,[r7]                /* stockage de l'étoile */
	
1:                                  /* début de boucle d'affichage d'un bloc */ 
	mov r5,r1                   /* preparer l'affichage de l'adresse de chaque debut de bloc */
	mov r0,r1
	ldr r1,adresse_debmem       /* adresse de stockage du resultat */
        bl conversion16             /*conversion hexa */
	
	/*balayer 16 octets de la memoire  */
	mov r2,#0                   /* compteur de boucle */
	mov r1,r5   
2:                                  /* debut de boucle de vidage par bloc de 16 octets */
	ldrb r4,[r1,+r2]	    /* recuperation du byte à l'adresse début + le compteur */
	/* conversion byte pour affichage */
	ldr r0,adresse_zone1        /*adresse de stockage du resultat */
	mul r5,r2,r8                /* calcul position r5 <- r2 * 3 */
	add r0,r5                   /* on l'ajoute au début de la zone */
	mov r3, r4, ASR #4          /* r3 <- (r4/16) */
	cmp r3,#9                   /* inferieur a 10 ? */
	addle r5,r3,#48             /*oui c'est un chiffre */
	addgt r5,r3,#55             /*non c'est une lettre en hexa */
	strb r5,[r0]                /* on le stocke au premier caractéres de la position */ 
	add r0,#1                   /* 2iéme caractere */
	mov r5,r3,LSL #4            /* r5 <- (r4*16)  */
	sub r3,r4,r5                /* pour calculer le reste de la division par 16 */
	cmp r3,#9                   /* inferieur a 10 ? */
	addle r5,r3,#48             /*oui c'est un chiffre */
	addgt r5,r3,#55             /*non c'est une lettre en hexa */
	strb r5,[r0]                /* stockage du deuxieme caracteres */
	add r2,r2,#1                /* +1 dans le compteur */
	cmp r2,#16                  /* fin du bloc de 16 caractéres ? */
	blt 2b
	/* vidage en caractères */
	mov r2,#0                   /* compteur */
	ldr r0,adresse_zone2        /*adresse de debut de stockage du resultat */
3:                                  /* debut de boucle */
	ldrb r4,[r1,+r2]            /* recuperation du byte à l'adresse début + le compteur */
	cmp r4,#31                  /* compris dans la zone des caractères imprimables ? */
	movle   r4,#46              /* sinon on force le caractere . */
	strb r4,[r0,+r2]            /* stockage au début plus l'indice de boucle */  
	add r2,r2,#1
	cmp r2,#16                  /* fin de bloc ? */
	blt 3b	                    /* sinon on boucle */

    /* affichage resultats */
	ldr r0, adresse_debmem      /* r0 <- adresse chaine */
        bl affichageMess            /*appel procedure  */
	mov r0,#' '
	strb r0,[r7]                /* on enleve l'étoile pour les autres lignes */
	add r1,r1,#16               /* adresse du bloc suivant de 16 caractères */
	sub r6,#1                   /* moins 1 au compteur de blocs */
	cmp r6,#0                   /* nombre de blocs demandés atteint ? */ 
	bgt 1b                      /* boucle */
	
	/* fin de la fonction */
	pop {r0-r8}                 /* restaur des   registres */
	pop {fp,lr}                 /* restaur des  2 registres */
	add sp, sp, #8              /* sp <-sp + 8 octets pour les 2 parametres passés à la fonction */
	bx lr
adresse_chaineMem :  .word szVidregistreMem
adresse_adresseMem:  .word adresseMem
adresse_adresseInst: .word adresseInst 
adresse_debmem:      .word debmem
adresse_zone1:       .word zone1
adresse_zone2:       .word zone2	
/******************************************************************/
/*     affichage des messages   avec calcul longueur                           */ 
/******************************************************************/
/* r0 contient l'adresse du message */
affichageMess:
	push {fp,lr}          /* save des  2 registres */ 
	push {r0,r1,r2,r7}    /* save des autres registres */
	mov r2,#0             /* compteur longueur */
1:	                      /*calcul de la longueur */
        ldrb r1,[r0,r2]       /* recup octet position debut + indice */
	cmp r1,#0             /* si 0 c'est fini */
	beq 1f
	add r2,r2,#1          /* sinon on ajoute 1 */
	b 1b
1:	                      /* donc ici r2 conient la longueur du message */
	mov r1,r0             /* adresse du message en r1 */
	mov r0,#STDOUT        /* code pour écrire sur la sortie standard Linux */
        mov r7, #WRITE        /* code de l'appel systeme 'write' */
        swi #0                /* appel systeme */
	pop {r0,r1,r2,r7}     /* restaur des autres registres */
	pop {fp,lr}           /* restaur des  2 registres */ 
        bx lr	              /* retour procedure */
/***************************************************/
/*   Conversion d'un registre en hexadecimal  */
/***************************************************/
/* r0 contient le registre   */
/* r1 l'adresse de la zone à alimenter */ 
conversion16:
    push {fp,lr}               /* save des  2 registres frame et retour */
    push {r0,r1,r2,r3,r4,r5}   /* save autres registres  */	
    mov r2,r0                  /* save du registre */
    ldr r3,=Masque
    ldr r3,[r3]                /* chargement de 0F soit 1111 dans r3 */
    mov r4,#7                  /* dernière position du résultat */
1: 
    and r0,r0,r3               /* application du masque sur le nombre */
    cmp r0,#9                  /* comparaison par rapport à 9 */
    addle r0,r0,#48            /*inferieur ou egal c'est un chiffre  */
    addgt r0,r0,#55            /* sinon c'est une lettre en hexa */
    strb r0,[r1,r4]            /* on le stocke dans le caractère de la position */ 
    subs r4,#1                 /* on enleve 1 au compteur */
    blt 1f                     /* inferieur à 0 fin de la conversion */
    mov r2,r2,lsr #4           /* sinon on deplace 4 bits du nombre sur la droite */
    mov r0,r2                  /* et copie dans r0 */ 
    b 1b                       /* puis boucle */
1:	
   	pop {r0,r1,r2,r3,r4,r5}   /*restaur des autres registres */
   	pop {fp,lr}               /* restaur des  2 registres frame et retour  */
    bx lr 
Masque: .word 0x0F 	
	
