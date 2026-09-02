function [pire, valeurs] = matlibre_pire_gain_sur_pave(parametres, evaluer, rayon, options)
%MATLIBRE_PIRE_GAIN_SUR_PAVE Le pire gain sur le pavé dilaté d'un rayon donné.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   ROBGAIN s'en sert à chaque essai de sa dichotomie.
    if nargin < 4
        options = struct();
    end
    options.Rayon = rayon;
    cout = @(v) matlibre_gain_ou_zero(evaluer(v));
    [pire, valeurs] = matlibre_balayer_incertitude(parametres, cout, options);
end
