function sugeno = convertToSugeno(fis)
%CONVERTTOSUGENO Traduit un système de Mamdani en système de Sugeno.
%   SUG = CONVERTTOSUGENO(FIS) rend un système équivalent dont chaque
%   modalité de sortie devient une constante : celle qu'on obtient en
%   défuzzifiant la modalité seule, par la méthode du système d'origine.
%
%   La traduction est fidèle règle par règle, non point par point : la
%   sortie diffère de celle du Mamdani, l'agrégation des ensembles flous
%   n'étant pas la même chose que la moyenne pondérée de leurs centres.
%   Ce qu'on y gagne est la vitesse, et la possibilité d'employer ANFIS.
%
%   Un système déjà de Sugeno est rendu tel quel.
%
%   Exemple :
%      fis = addInput(mamfis, [0 10], 'Name', 'a', 'NumMFs', 2);
%      fis = addOutput(fis, [0 1], 'Name', 'b', 'NumMFs', 2);
%      fis = addRule(fis, [1 1 1 1; 2 2 1 1]);
%      sug = convertToSugeno(fis);
%      sug.type                       % 'sugeno'
%
%   Voir aussi MAMFIS, SUGFIS, EVALFIS, GENFIS.
    if strcmp(fis.type, 'sugeno')
        sugeno = fis;
        return
    end
    sugeno = fis;
    sugeno.type = 'sugeno';
    sugeno.implication = 'prod';
    sugeno.agregation = 'sum';
    sugeno.defuzzification = 'wtaver';
    for k = 1:numel(sugeno.sorties)
        intervalle = sugeno.sorties{k}.intervalle;
        grille = linspace(intervalle(1), intervalle(2), 201);
        liste = sugeno.sorties{k}.mf;
        for m = 1:numel(liste)
            appartenance = evalmf(grille, liste{m}.type, liste{m}.parametres);
            constante = defuzz(grille, appartenance, fis.defuzzification);
            liste{m}.type = 'constant';
            liste{m}.parametres = constante;
        end
        sugeno.sorties{k}.mf = liste;
    end
end
