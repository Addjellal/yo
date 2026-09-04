function tableau = matlibre_reseau_ecrire(tableau, nom, valeurs)
%MATLIBRE_RESEAU_ECRIRE Range les paramètres d'une couche dans la table.
%   T = MATLIBRE_RESEAU_ECRIRE(T,NOM,VALEURS) remplace les lignes de la
%   couche nommée par les champs de la structure VALEURS, ou les ajoute si
%   elles n'y sont pas.
%
%   Exemple :
%      t = matlibre_reseau_ecrire(t, 'bn_1', struct('TrainedMean', 0));
%
%   Voir aussi DLNETWORK, MATLIBRE_RESEAU_LIRE.
    champs = fieldnames(valeurs);
    couches = tableau.Layer;
    parametres = tableau.Parameter;
    contenus = tableau.Value;
    for k = 1:numel(champs)
        ligne = find(strcmp(couches, nom) & strcmp(parametres, champs{k}), 1);
        if isempty(ligne)
            couches{end + 1, 1} = nom;              %#ok<AGROW>
            parametres{end + 1, 1} = champs{k};     %#ok<AGROW>
            contenus{end + 1, 1} = valeurs.(champs{k});   %#ok<AGROW>
        else
            contenus{ligne} = valeurs.(champs{k});
        end
    end
    tableau = table(couches, parametres, contenus, ...
                    'VariableNames', {'Layer', 'Parameter', 'Value'});
end
