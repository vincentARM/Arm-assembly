Exemple d'une simulation d'aquarium en assembleur arm 32 bits.<br>
Voir les régles sur le forum programmation de zeste de savoir. Cet exercice était prévu à l'origine pour le langage JAVA <br>
Mais je me suis amusé à le programmer en assembleur. Il peut être amélioré mais il reprend toutes les étapes de l'exercice.<br>
Pour le compiler, modifier les outils de compilation et de link dans le Makefile.
Pour l'exécuter, il suffit de le lancer par build/aqua et l'aquarium sera initialisé avec 2 algues et 2 poissons.
L'aquarium peut être initialisé à l'aide d'un fichier de type texte voir l'exemple init1.txt et l'execution s'effectuera par :
build/aqua -i init1.txt
La restauration d'une sauvegarde s'effectue par :
build/aqua -r <nomSauvegarde>
Le log de la session peut être effectué par :
build/aqua -l <nomduLog>  <br>
