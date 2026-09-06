# Toolbox `base-de-donnees`

```
% Database Toolbox — tables, requêtes, persistance.
%
% Structure
%   dbTable     - Crée une table, colonnes nommées
%   dbInsert    - Ajoute une ligne
%
% Requêtes
%   dbSelect    - Les lignes qui vérifient un prédicat
%   dbUpdate    - Écrit une colonne, pour les lignes retenues
%   dbDelete    - Retire les lignes retenues
%   dbGroupSum  - Somme d'une colonne, groupée par une autre
%
% Persistance
%   dbSave      - Écrit la table en CSV
%   dbLoad      - La relit, en rétablissant les types
```

## `dbDelete`

```
DBDELETE Supprime les lignes vérifiant le prédicat.
  T = DBDELETE(T,PREDICAT) rend la table privée des lignes que le
  prédicat retient. Un prédicat toujours faux ne supprime rien ; un
  prédicat toujours vrai vide la table sans la détruire.

  Exemple :
     t = dbDelete(t, @(l) l{4} < 4);       % anciennete de moins de 4 ans
     t = dbDelete(t, @(l) true);           % vide la table

  Voir aussi DBSELECT, DBUPDATE, DBTABLE.
```

## `dbGroupSum`

```
DBGROUPSUM Somme d'une colonne, groupée par une autre.
  [CLES,SOMMES] = DBGROUPSUM(T,COLONNECLE,COLONNEVALEUR) rend une clé
  par valeur distincte rencontrée, et la somme correspondante. C'est le
  « GROUP BY » d'un langage de requête.

  Les groupes partitionnent la table : la somme des sommes est le total
  général. C'est la propriété qui valide tout regroupement, et elle se
  vérifie en une ligne.

  Les clés sortent dans l'ordre où elles apparaissent, non triées :
  c'est l'ordre de la table, et il porte souvent une information.

  Exemple :
     [services, masses] = dbGroupSum(t, 'service', 'salaire');
     sum(masses)                     % le total general

  Voir aussi DBSELECT, DBTABLE.
```

## `dbInsert`

```
DBINSERT Ajoute une ligne à la table.
  T = DBINSERT(T,{...}) ajoute une ligne. Le nombre de valeurs doit
  correspondre au nombre de colonnes, sans quoi la fonction refuse :
  c'est le seul contrôle de forme, et il vaut mieux qu'il soit strict —
  une ligne décalée d'une colonne fausse tout ce qui suit.

  Chaque case garde son type : un nom reste une chaîne, un montant un
  nombre. La table ne convertit rien.

  Exemple :
     t = dbTable({'nom', 'service', 'salaire'});
     t = dbInsert(t, {'Dupont', 'etudes', 45000});

  Voir aussi DBTABLE, DBSELECT, DBDELETE.
```

## `dbLoad`

```
DBLOAD Lit une table depuis un fichier CSV.
  T = DBLOAD(FICHIER) lit un fichier écrit par DBSAVE : la première
  ligne donne les noms de colonnes, les suivantes les enregistrements.

  Les champs qui se convertissent en nombre reviennent en nombres, les
  autres restent des chaînes. C'est la seule reconstruction de type
  possible d'un format qui n'en porte pas — et elle se trompe sur un
  identifiant tout en chiffres, qu'elle rendra numérique.

  L'aller-retour DBSAVE puis DBLOAD est la vérification qui compte :
  la table relue doit se comporter comme l'originale, groupements
  compris.

  Exemple :
     dbSave(t, 'personnel.csv');
     relue = dbLoad('personnel.csv');
     isequal(relue.colonnes, t.colonnes)     % true

  Voir aussi DBSAVE, DBTABLE, READTABLE.
```

## `dbSave`

```
DBSAVE Écrit la table dans un fichier CSV.
  DBSAVE(T,FICHIER) écrit la table : une première ligne d'en-tête avec
  les noms de colonnes, puis une ligne par enregistrement, les champs
  séparés par des virgules.

  Le CSV est le seul format qu'à peu près tout sait lire. Il ne porte
  pas les types : c'est DBLOAD qui les rétablit, en reconnaissant ce qui
  se convertit en nombre.

  Exemple :
     dbSave(t, 'personnel.csv');
     relue = dbLoad('personnel.csv');

  Voir aussi DBLOAD, DBTABLE.
```

## `dbSelect`

```
DBSELECT Sélectionne les lignes vérifiant un prédicat.
  LIGNES = DBSELECT(T,PREDICAT) rend les lignes pour lesquelles le
  prédicat est vrai, sous forme d'un tableau de cellules.
  DBSELECT(T) sans prédicat rend toute la table.

  Le prédicat reçoit la ligne entière, et lit ses colonnes par leur
  rang : @(l) l{3} > 40000 porte sur la troisième colonne. Les
  conditions se composent avec && et || comme partout ailleurs, ce qui
  remplace le « WHERE » d'un langage de requête.

  Un prédicat toujours faux rend une liste vide, non une erreur : c'est
  un résultat, et le programme appelant doit pouvoir le traiter comme
  tel.

  Exemple :
     dbSelect(t, @(l) strcmp(l{2}, 'etudes'))
     dbSelect(t, @(l) l{3} > 40000 && l{4} > 4)
     dbSelect(t)                     % toute la table

  Voir aussi DBTABLE, DBUPDATE, DBDELETE, DBGROUPSUM.
```

## `dbTable`

```
DBTABLE Crée une table vide dont les colonnes sont nommées.
  T = DBTABLE({'nom','service','salaire'}) crée une table à trois
  colonnes et aucune ligne.

  La table est une valeur, non une référence : DBINSERT, DBUPDATE et
  DBDELETE rendent une table nouvelle et laissent l'ancienne intacte.
  C'est ce qui rend une requête sans effet de bord, et permet de
  comparer un avant et un après sans avoir rien copié.

  Une table vide reste une table : on peut la sélectionner, la grouper
  et la vider sans cas particulier.

  Exemple :
     t = dbTable({'nom', 'age'});
     t = dbInsert(t, {'Dupont', 42});
     dbSelect(t, @(l) l{2} > 40)

  Voir aussi DBINSERT, DBSELECT, DBUPDATE, DBDELETE, DBGROUPSUM.
```

## `dbUpdate`

```
DBUPDATE Met à jour une colonne pour les lignes retenues.
  T = DBUPDATE(T,PREDICAT,COLONNE,VALEUR) écrit VALEUR dans la colonne
  nommée, pour toutes les lignes que le prédicat retient. Les autres ne
  bougent pas, et la table d'origine non plus.

  La colonne se désigne ici par son nom, alors que le prédicat lit par
  rang : c'est voulu. Le prédicat parcourt une ligne quelconque, la
  colonne écrite est connue à l'avance.

  Exemple :
     t = dbUpdate(t, @(l) strcmp(l{2}, 'ventes'), 'salaire', 45000);

  Voir aussi DBSELECT, DBDELETE, DBINSERT.
```

