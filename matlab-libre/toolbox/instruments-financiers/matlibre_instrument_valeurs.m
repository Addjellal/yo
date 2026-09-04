function valeurs = matlibre_instrument_valeurs(jeu, type, rang)
%MATLIBRE_INSTRUMENT_VALEURS Champs d'un instrument, rangés en structure.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    valeurs = struct();
    noms = jeu.FieldName{type};
    for c = 1:numel(noms)
        donnee = jeu.FieldData{type}{c};
        if iscell(donnee)
            valeurs.(noms{c}) = donnee{rang};
        else
            ligne = donnee(rang, :);
            ligne = ligne(~isnan(ligne) | true);
            valeurs.(noms{c}) = ligne;
        end
    end
end
