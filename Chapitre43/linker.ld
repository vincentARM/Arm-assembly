SECTIONS
{
	. = 0x8000; /* adresse de chargement */ 
	.text.boot : { *(.text.boot) }
	.text : { *(.text) }
	. = ALIGN(4096);   /* alignement sur une page */ 
	.rodata : { *(.rodata) }
	.data : { *(.data) }
	. = ALIGN(4096);   /* alignement sur une page */ 
	bss_begin = .;
	.bss : { *(.bss*) } 
	. = ALIGN(4096);   /* alignement sur une page */ 
	bss_end = .;
}