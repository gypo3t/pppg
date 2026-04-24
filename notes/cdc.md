# cdc


mettre à jour cette appli boggle en tenant compte des requetes suivantes :

1#

- un bouton pour afficher les résultats
- pouvoir choisir la taille de la grille (par défaut=4)
- le bouton shuffle efface les résultats et relance avec la taille de la grille demandée
- les résultats s'affichent avec le score du mot
- proposer tri alpha ou score ou nombre de lettres
- pouvoir importer une grille depuis fichier texte (la grille se remplit avec les lettres de la chaine de caractères chargée)
- proposer un mode jeu (le joueur propose des mots dans une zone de texte)
- la liste des résultats indique si trouvé par le joueur
- afficher le temps de recherche totale des résultats


2#

bugs:
-  bouton export non efficient

Requetes:
- fichier dédié pour widget appbar avec boutons shuffle/jeu et selecteur de size
- selecteur de size avec "+" et "-"
- jeu : refuser mot si non présent dans la grille ou non présent dans dictionnaire
- jeu : afficher le score du mot trouvé
- jeu : intégrer un timer
- grille : pouvoir exporter grille

#3 
ce qui ne va pas :
- boutons importer et exporter ne marchent pas
- lancer le jeu affiche les résultats

requetes :
- saisir une valeur dans chanp texte pour la taille de la grille (à placer ailleur que dans appbar, peut-etre en haut de la grille ou peut-être dans un écran "paramètres" dans lequel on renseignerait également le temps de jeu)
- les mots refusés s'ajoutent en rouge dans la liste du joueur
- faire un fichier .dart dédié au jeu

#4
- ne pas afficher le changement de taille au dessus de la grille
                                                                            - masquer "temps écoulé" et champ de saisie une fois le temps écoulé et la partie terminée

#5 evolution
l'appli propose 3 modes :solver/game/edition
l'écran d'accueil affiche des statistiques sur les parties déjà jouées, les solutions trouvées et les mots du dictionnaire en place
Chaque écran à une appbar propre mais toujours avec le bouton home. et le bouton paramètres

1.edition
- active la saisie des dés
- bouton exporter => écran exporter
- bouton importer => écran importer

2.game
- active la saisie des mots par champ texte
- active la saisie des mots par dessin sur grille
- affiche score joueur
- pas de liste affichée
- pop les points marqués ou statut du mot joué ("refusé","déjà joué")
- bouton nouvelle partie
- affiche timer
- bouton solutions => renvoie à écran solver

3.solver
- grille : active mode affichage mots trouvés
- affiche liste mots trouvés indiquant mots trouvés par joueur
- affiche statistique courtes : temps de résolution et nombre de mots joueur/total, score joueur/total (1 ligne)
- bouton affiche statistiques complètes (score joueur)


#4 correctif
1.écran de jeu :
- Les boutons "nouvelle partie" et "solutions" doivent être des icones dans AppBar du même stytle que les autres boutons noirs de la appBar
- timer et score s'affichent au-dessus de la grille
- un mot trouvé pop en vert avec son score
- un mot refusé pop en rouge
- la grille ne doit pas être grisée au moment du dessin d'un mot
- rétablir la liste des mots trouvés en dessou d champ de saisie

2.écran des solutions :
- bug d'affichage de la grille quand l'écran est vertical

3. Ecran édition :
- boutons "jouer avec cette grille" et "analyser" toujours sous la grille
- grille centrée sur l'écran


4. global :
- Le bouton paramètres doit être affiché sur tous les écrans
- Le widget statistique a son propre fichier

5. settings :
- mettre affichage du champ texte en option (sur mobile c'est mieux de s'en passer)


#5 
1. Ecran d'accueil :
- le chargement de dictionnaire reste en busy et les stats ne s'affichent pas
- dans appbar, mettre icone de jeu et icone d'édition

2. Ecran solutions :
- trouver une icone pour "stats" dans appbar
- bouton jouer dans appbar
- bouton éditer dans appbar
- bouton exporter dans appbar

3. Settings
- curseur horizontal pour taille de la grille
- curseur horizontal pour durée de jeu

4. Ecran de jeu
- dessin du mot : la flèche recule avec le doigt

#6
1. Ecran édition
- ajouter icone de "jeu" et icone de "solutions" dans appbar

2. Ecran jeu :
- saisie texte forceé en lettres majuscules


#7
1. Listes de mot :
- La largeur de la colonne affichant le mot ne doit pas excéder 20 caractères

2. Accueil :
- Les stats parties et solutins ne se mettent pas à jour

3. Settings :
- temps max = 5 min, palier curseur 10 sec.

#8
1. settings
- mémoriser settings entre 2 sessions
- par défaut champ texte non activé

2. stats accueil
- infos session ne se met pas à jour
- ajouter stats sessions globales

#8
ecran game : 
- probleme de mise à jour de la grille sur relance de nouvelle partie en cours de partie
- confirmation si lancement nouvelle partie alors que partie en cours
- confirmation si demande solutions alors que partie en cours
- fin de partie passe en mode solutions
- améliorer expérience dessin du mot (en particulier les diagonales)


sauvegarde :
- propose sauvegarde grille
- sauvegarde les résultats

solutions :
affiche grille et liste dans les mêmes proportions que les autres écrans (même remarque que précédemment pour édition )

#9
ecran game :
- dessin de la fèche plus élégant

accueil :
- afficher numéro de version
- afficher numéro de compilation si debug

#10
evolution de appbar
- Placer les icones et leur intitulé dans menu déroulant à droite (trois barres horizontales)
- ça donne plus de place pour afficher le titre de l'écran avec son icone associée

Menu déroulant :
- resserrer lignes menu

bug : 
- liste des résultats active mode edition

Ecran resultats :
- ne pas afficher la synhese au dessus de la liste mais reprendre la même information que ecran game au dessus de la grille (timer, points et mot), remplacer juste timer par "nouvelle partie".

Ecran game :
- Si partie non commencée, lancer directement partie à l'affichage de l'écran
- si partie en pause, griser la grille avec la mention "Pause" (clic sur pause relance la partie)
- attention, si partie en cours, toujours demandé confirmation avant lancement nouvelle partie

#10 
je veux que le solver affiche le score playerScore/maxScore . playerNbWords/wordsCoutMax
Si partie en cours maxScore et wordsCoutMax sont affichés en options (settings)
si solver playerScore et playerNbWords s'affichent si partie jouée
