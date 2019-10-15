Mesure de performances du Cortex M53 sur un raspberry pi3+ <br>
Le premier programme (intSpec.s) sert à tester l'appel à PERF_EVENT_OPEN. <br>
Le deuxième(intSpecgr.s) sert à tester le regroupement de plusieurs compteurs.<br>
Le troisième (intSpecgrM1.s) effectue les mesures sur 3 routines de conversion d'un nombre de 64 bits pour vérifier les optimisations. <br>
Le programme affiche aussi le compteur de temps total (paramètre PERF_FORMAT_TOTAL_TIME_RUNNING).
