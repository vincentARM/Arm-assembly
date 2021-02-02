Exemple d'une simulation d'aquarium en assembleur arm 32 bits.<br>
Il tourne sur un raspberry pi 3 b+ . Pour des raspberry de versions inférieures il faut réecrire l'opération de division. <br> 
Voir les régles sur le forum programmation de zeste de savoir. Cet exercice était prévu à l'origine pour le langage JAVA <br>
Mais je me suis amusé à le programmer en assembleur. Il peut être amélioré mais il reprend toutes les étapes de l'exercice.<br>
Pour le compiler, modifier les outils de compilation et de link dans le Makefile.<br>
Pour l'exécuter, il suffit de le lancer par build/aqua et l'aquarium sera initialisé avec 2 algues et 2 poissons.<br>
L'aquarium peut être initialisé à l'aide d'un fichier de type texte voir l'exemple init1.txt et l'execution s'effectuera par : <br>
build/aqua -i init1.txt <br>
La restauration d'une sauvegarde s'effectue par : <br>
build/aqua -r nomSauvegarde <br>
Le log de la session peut être effectué par : <br>
build/aqua -l nomduLog  <br>
les 2 paramètres -i et -r sont incompatibles (soit on initialise soit on restaure !!). <br>
Mais il est possible d'initialiser et d'avoir le log sur fichier par : <br>
build/aqua -i fichierinit.txt  -l nomduLog <br>
