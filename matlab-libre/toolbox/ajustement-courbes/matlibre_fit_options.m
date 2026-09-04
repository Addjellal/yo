function [options, imposees] = matlibre_fit_options(modele, arguments)
%MATLIBRE_FIT_OPTIONS Réglages et paramètres imposés d'un appel à FIT.
%   [OPT,IMP] = MATLIBRE_FIT_OPTIONS(MODELE,ARGUMENTS) lit les arguments
%   qui suivent le modèle : une structure de réglages, des couples nom et
%   valeur, ou 'problem' suivi de la valeur des paramètres imposés.
%
%   Exemple :
%      [o, p] = matlibre_fit_options(fittype('poly1'), {'Robust', 'Bisquare'});
%
%   Voir aussi FIT, FITOPTIONS.
    options = fitoptions(modele);
    imposees = {};
    k = 1;
    while k <= numel(arguments)
        courant = arguments{k};
        if isstruct(courant)
            options = courant;
            k = k + 1;
        elseif ischar(courant) && strcmpi(courant, 'problem')
            valeurs = arguments{k + 1};
            if ~iscell(valeurs)
                valeurs = {valeurs};
            end
            imposees = valeurs;
            k = k + 2;
        elseif ischar(courant) && k + 1 <= numel(arguments)
            options.(matlibre_option_canonique(courant)) = arguments{k + 1};
            k = k + 2;
        else
            error('curvefit:fit:Arguments', 'Argument inattendu en position %d.', k);
        end
    end
end
