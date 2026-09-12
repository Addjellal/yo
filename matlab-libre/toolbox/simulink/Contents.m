% Simulink — simulation de schémas-blocs.
%
% Un modèle est une structure : une liste de blocs, une liste de liens et
% quelques réglages. La simulation est à pas fixe et l'ordre d'exécution
% vient d'un tri topologique, si bien qu'une entrée est toujours calculée
% avant la sortie qui l'emploie. Les blocs sans transmission directe —
% intégrateur, retard, mémoire, retard pur — fournissent la mémoire, et
% cassent donc les boucles algébriques.
%
% Un modèle est une valeur, non une référence : chaque fonction en rend
% une nouvelle et laisse l'ancienne intacte.
%
% L'espace de travail est partagé, comme dans Simulink : un paramètre
% numérique écrit entre apostrophes est une expression, évaluée à la
% simulation — un gain réglé sur 'K' vaut ce que vaut K. Dans l'autre
% sens, le bloc « toworkspace » y dépose son signal et « fromworkspace »
% y lit le sien. Les fichiers .slx de
% MathWorks, dont le format n'est pas public, ne se lisent pas ;
% save_system écrit à leur place un programme .m qui rebâtit le modèle.
%
% Modèle
%   new_system    - Crée un modèle vide
%   open_system   - Dessine le schéma-bloc, et ouvre le modèle
%   close_system  - Ferme un modèle, et sa figure
%   bdclose       - Ferme un modèle, ou tous
%   bdroot        - Le nom du modèle
%   bdIsLoaded    - Dit si un modèle est ouvert
%   gcs           - Le nom du dernier modèle ouvert
%   getfullname   - Le chemin « modele/bloc » d'un bloc
%   save_system   - Écrit un .m qui rebâtit le modèle
%   load_system   - Relit ce .m
%
% Du schéma au programme
%   Deux chemins, qu'il ne faut pas confondre. SAVE_SYSTEM écrit le
%   programme qui rebâtit le modèle, et LOAD_SYSTEM le relit : c'est
%   l'aller-retour du schéma. MATLIBRE_SL_PROGRAMME, lui, écrit le
%   programme qui fait ce que le schéma fait — des variables, une boucle,
%   de l'arithmétique, aucun appel à Simulink — et il n'y a pas de
%   retour : on ne remonte pas d'un calcul quelconque au schéma qui
%   l'aurait produit. MATLIBRE_SL_ECRIRE le dépose dans un fichier.
%
% Un schéma dans un bloc
%   Un bloc de type « subsystem » porte tout un modèle, bâti comme les
%   autres. Ses blocs INPORT sont ses entrées, son premier OUTPORT sa
%   sortie ; SIM le déplie avant de simuler, si bien qu'il rend
%   exactement ce que rendrait le schéma écrit à plat. Le relevé porte
%   ses blocs sous le nom « sousSysteme/bloc », et le sous-système
%   lui-même porte la valeur de sa sortie. Ils s'emboîtent.
%
% Blocs et liens
%   add_block     - Ajoute un bloc, avec ses paramètres
%   delete_block  - Retire un bloc, et les liens qui y touchent
%   replace_block - Change le type de tous les blocs d'un type
%   add_line      - Relie une sortie à une entrée
%   delete_line   - Supprime un lien
%   find_system   - Les blocs, éventuellement filtrés
%
% Réglages
%   get_param     - Lit un paramètre de bloc, ou du modèle
%   set_param     - Change les paramètres d'un bloc, ou du modèle
%   add_param     - Pose un réglage sur le modèle
%   delete_param  - Retire un réglage du modèle
%
% Simulation
%   sim           - Simule à pas fixe ; rend temps et signaux
%   simset        - Rassemble les options d'une simulation
%   simget        - Lit une option
%   simplot       - Trace les signaux relevés
%
% Linéarisation
%   linmod        - Linéarise autour d'un point de fonctionnement
%   dlinmod       - Linéarise et échantillonne
%   trim          - Cherche un point d'équilibre
