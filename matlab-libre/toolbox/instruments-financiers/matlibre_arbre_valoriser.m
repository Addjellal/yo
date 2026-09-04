function [prix, valeurs] = matlibre_arbre_valoriser(arbre, typeOption, exercice, americain)
%MATLIBRE_ARBRE_VALORISER Récurrence arrière sur un arbre binomial.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    n = arbre.TimeSpec.NumPeriods;
    p = arbre.UpProbs(1);
    escompte = exp(-arbre.Rate * arbre.Step);
    if strcmpi(typeOption, 'put')
        gain = @(s) max(exercice - s, 0);
    else
        gain = @(s) max(s - exercice, 0);
    end
    valeurs = cell(1, n + 1);
    valeurs{n + 1} = gain(arbre.STree{n + 1});
    for k = n:-1:1
        suivant = valeurs{k + 1};
        attente = escompte * (p * suivant(1:end-1) + (1 - p) * suivant(2:end));
        if americain
            attente = max(attente, gain(arbre.STree{k}));
        end
        valeurs{k} = attente;
    end
    prix = valeurs{1}(1);
end
