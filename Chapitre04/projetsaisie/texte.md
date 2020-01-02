Exemple de chaine de compilation sur un PC.<br>
Il faut avoir installer le compilateur et le linker ARM avec la version désirée pour windows 10 <br>
Recopier tout le répertoire projetsaisie sur le PC <br>
Creer le répertoire build dans ce repertoire <br>
Modifier les chemins pour appeler votre compilateur et linker
Lancer le script appelmake.bat pour creer l'executable sur le PC. <br>
Si pas d'erreur, transferer l'executable (dont le nom est donné par la variable PGM du script) sur le raspberry pi (avec par exemple l'utilitaire Filezilla).<br>
Modifier les droits d'execution par chmod 777 nomduprogramme<br>
Et lancer l'execution.<br>
