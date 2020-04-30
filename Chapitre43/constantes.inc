/* Programme assembleur ARM Raspberry */
/* Assembleur ARM Raspberry  : Vincent Leboulou */
/* Blog : http://assembleurarmpi.blogspot.fr/  */
/* modèle B 512MO   */

/**********************************************/
/* -- Constances pour utilisation sans OS     */
/**********************************************/
.equ  ST_BASE_GPIO,  0x20200000   @  adresse base GPIO pour le raspberry pi 1 B
.equ  ST_BASE_UART,  0x20215000   @  adresse base mini uart pour le raspberry pi 1 B

/* constances pour le GPIO */
.equ    INPUT,0           @  pin utilisé en entrée
.equ    OUTPUT,1          @  pin utilisé en sortie
.equ    GPSET0,0x1c      @ offset du début des registres d'allumage	
.equ    GPCLR0,0x28      @ offset du debut des registres d'extinction
.equ    GPPUD,  0x94     @ ?
.equ    GPPUDCLK0, 0x98  @ ?
.equ    MASKPIN,0b111    @ masque pour 3 bits

	