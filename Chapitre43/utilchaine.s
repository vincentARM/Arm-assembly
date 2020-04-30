/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */

/* fonctions manipulations de chaines    */
/* rappel: une chaine se termine par un 0 binaire */
/* constantes */

/*******************************************/
/* DONNEES INITIALISEES                    */
/*******************************************/ 
.data


/*******************************************/
/* DONNEES INITIALISEES A ZERO             */
/*******************************************/ 
.bss

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
.global comparaison     /* fonctions doivent être  globales */

/************************************/	   
/* comparaison de chaines           */
/************************************/	  
/* r0 et r1 contiennent les adresses des chaines */
/* retour 0 dans r0 si egalite */
/* retour -1 si chaine r0 < chaine r1 */
/* retour 1  si chaine r0> chaine r1 */
comparaison:
	//push {fp,lr}    /* save des  2 registres */
	push {r1-r4}  /* save des registres */
	mov r2,#0   /* indice */
1:	
	ldrb r3,[r0,r2]   /* octet chaine 1 */
    ldrb r4,[r1,r2]   /* octet chaine 2 */
    cmp r3,r4
	movlt r0,#-1	 /* plus petite */ 	
	movgt r0,#1	 /* plus grande */ 	
    bne 100f     /* pas egaux */
	cmp r3,#0   /* 0 final */
	moveq r0,#0    /* egalite */ 	
	beq 100f     /* c'est la fin */
	add r2,r2,#1 /* sinon plus 1 dans indice */
	b 1b         /* et boucle */
100:
    pop {r1-r4}
	//pop {fp,lr}   /* fin procedure */
    bx lr   	
	