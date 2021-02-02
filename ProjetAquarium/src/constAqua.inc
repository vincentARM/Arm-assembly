/*********************************************/
/*           CONSTANTES                      */
/********************************************/
.equ TAILLETAS,      1000000
.global TAILLETAS                @ utilisé par le linker pour définir le tas
.equ TAILLEBUF,      65280
.equ PVDEPART,       10
.equ NBPVALGUEMANGE, 2
.equ PVALGUETOUR,    1
.equ PVPOISSONTOUR,  1
.equ PVREPASPOISSON, 5
.equ PVREPASALGUE,   3
.equ PVFAIMPOISSON,  5
.equ AGEMAXI,        20
.equ AGEREPRODUCTION, 10
.equ AGEREPROHERMA,  10

.equ CREATE,     8

/*constantes Linux syscall */
.equ EXIT,   1
.equ FORK,   2
.equ READ,   3
.equ WRITE,  4
.equ OPEN,   5
.equ CLOSE,  6
.equ EXECVE, 0xB
.equ PIPE,   0x2A
.equ IOCTL,  0x36

/* console */
.equ STDIN,  0
.equ STDOUT, 1
.equ STDERR, 2  

/*  fichier */
.equ O_RDONLY, 0
.equ O_WRONLY, 0x0001    
.equ O_RDWR,   0x0002          @ open for reading and writing

.equ O_CREAT,  0x0200          @ create if nonexistant
.equ O_TRUNC,  0x0400          @ truncate to zero length
.equ O_EXCL,   0x0800          @ error if already exists 
