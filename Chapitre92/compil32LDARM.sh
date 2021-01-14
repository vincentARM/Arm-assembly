#compilation assembleur
#echo $0,$1
echo "Compilation 32 bits de "$1".s"
as -o $1".o"   $1".s" 
#gcc -o $1 $1".o"  -e main
ld -o $1 $1".o" ~/asm32/routinesARM.o -T ~/scripts/linkerldarm.ld -e main -s  -nostdlib --print-map >map1.txt
ls -l $1*  
echo "Fin de compilation."
