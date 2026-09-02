function [pire, valeurs] = matlibre_pire_pole_sur_pave(parametres, evaluer, rayon, options)
%MATLIBRE_PIRE_POLE_SUR_PAVE Le pire pôle sur le pavé dilaté d'un rayon donné.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   ROBSTAB s'en sert à chaque essai de sa dichotomie.
    if nargin < 4
        options = struct();
    end
    options.Rayon = rayon;
    cout = @(v) matlibre_pire_pole(evaluer(v));
    [pire, valeurs] = matlibre_balayer_incertitude(parametres, cout, options);
end
