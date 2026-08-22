# Toolbox `base-de-donnees`

```
% Database Toolbox — stockage tabulaire.
%
% Le magasin est un fichier CSV ; les requêtes portent sur des structures
% en mémoire. C'est assez pour les usages courants d'un script : lire,
% filtrer, agréger, écrire.
%
%   dbTable      - Crée une table
%   dbInsert     - Ajoute une ligne
%   dbSelect     - Sélection avec prédicat
%   dbUpdate     - Mise à jour conditionnelle
%   dbDelete     - Suppression conditionnelle
%   dbSave, dbLoad - Persistance en CSV
%   dbGroupSum   - Agrégation par colonne
```

## `dbDelete`

```
DBDELETE Supprime les lignes vérifiant le prédicat.
```

## `dbGroupSum`

```
DBGROUPSUM Somme d'une colonne, groupée par une autre.
```

## `dbInsert`

```
DBINSERT Ajoute une ligne à la table.
```

## `dbLoad`

```
DBLOAD Lit une table depuis un fichier CSV.
```

## `dbSave`

```
DBSAVE Écrit la table dans un fichier CSV.
```

## `dbSelect`

```
DBSELECT Sélectionne les lignes vérifiant un prédicat.
  LIGNES = DBSELECT(T,@(ligne) ...) ; sans prédicat, rend toute la table.
```

## `dbTable`

```
DBTABLE Crée une table vide dont les colonnes sont nommées.
```

## `dbUpdate`

```
DBUPDATE Met à jour une colonne pour les lignes retenues.
```

