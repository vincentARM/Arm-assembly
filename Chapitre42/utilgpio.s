/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */
/* fonctions de base pour le GPIO */

/*********************************************/
/*           CONSTANTES                      */
/********************************************/
.include "src/constantes.inc"

/**********************************************/
/* -- Code section                            */
/**********************************************/
.text            
/* les fonctions doivent être déclarées Globales */
.global selectPin, setPin, clearPin     

/***************************************************/
/*   Selection pin GPIO                  */
/***************************************************/
/* r0 adresse GPIO memoire  */
/* r1 N° du pin  code FSEL ou code BCM */
/* r2 code fonction */
/* utilise la fonction division qui se trouve dans util.s  */
selectPin:
   push {r0,lr}    /* save des  2 registres r0 et retour */
   push {r1-r6}   /* save autres registres en nombre pair */
   mov r5,r0      /* save adresse */ 
   mov r6,r2      /* save fonction */
   /* calcul du registre à selectionner (GPFSEL) et du rang du pin par division par 10 */
   mov r0,r1
   mov r1,#10
   bl division
   @r2 contient le N° du registre (GPFSEL) et r3 le rang
   @ le registre 0 sera à l'adresse memoire, le 1 à l'offset +4 et le 2 à l'offset +8
   mov r4,r2   @ save registre GPIO calculé
   ldr r2,[r5,r4,lsl#2]   @ chargement du registre complet de la mémoire
                          @ et du bon offset r5 + (r4*4)
   mov r0,r3             @ rang du pin dans le registre
   add r3,r3,r0,lsl #1   @ calcul de la position dans le registre = rang * 3
   mov r1,#MASKPIN       @ masque des 3 bits à selectionner 
   lsl r1,r1,r3           @ déplacement du masque en fonction de la position
   bic r2,r2,r1           @ raz des 3 bits concernés dans le registre
   lsl r6,r6,r3           @ deplacement du code fonction à la bonne position
   orr r2,r2,r6           @ maj du code fonction à la bonne position
   str r2,[r5,r4,lsl#2]   @ stockage du registre à sa bonne place dans la mémoire
100:   /* fin standard de la fonction  */
   	pop {r1-r6}   /*restaur des autres registres */
   	pop {r0,lr}   /* restaur des  2 registres r0 et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
 
/***************************************************/
/*   allumage (set) pin GPIO                             */
/***************************************************/
/* r0 adresse GPIO memoire  */
/* r1 N° du pin */
setPin:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r0-r3}    /* save autres registres en nombre pair */
   add r0,#GPSET0    @ position du registre d'allumage dans la zone mémoire 
   mov r3,#0             @ registre 0
   cmp r1,#32            @ et si pin > 31 c'est le registre 1
   movge r3,#1          
   subge r1,#32    @ et recalcul de la position dans le registre r1  		  
   mov r2,#1        @ 1 = code selection
   lsl r2,r2,r1     @ deplacement à la position du pin dans le registre 
   str r2,[r0,r3,lsl#2]   @ stockage du registre à sa bonne place dans la mémoire


100:   
   /* fin standard de la fonction  */
   	pop {r0-r3}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	
	
/***************************************************/
/*   extinction (clear) pin GPIO                             */
/***************************************************/
/* r0 adresse GPIO memoire  */
/* r1 N° du pin */
clearPin:
   push {fp,lr}    /* save des  2 registres frame et retour */
   push {r0-r3}   /* save autres registres en nombre pair */
   add r0,#GPCLR0    @ position du registre d'extinction
   mov r3,#0             @ registre 0
   cmp r1,#32            @ et si pin > 31 c'est le registre 1
   movge r3,#1          
   subge r1,#32    @ et recalcul de la position dans le registre r1  	
   mov r2,#1  @ 1 = code selection du pin
   lsl r2,r2,r1   @ deplacement à la position du pin dans le registre 	
   str r2,[r0,r3,lsl#2]   @ stockage du registre à sa bonne place dans la mémoire
	
100:   
   /* fin standard de la fonction  */
   	pop {r0-r3}   /*restaur des autres registres */
   	pop {fp,lr}   /* restaur des  2 registres frame et retour  */
    bx lr                   /* retour de la fonction en utilisant lr  */	