function [estAjustee, nom, parametres] = matlibre_stat_loi_ajustee(valeur)
%MATLIBRE_STAT_LOI_AJUSTEE Reconnaît une loi ajustée par FITDIST.
%   [OUI,NOM,PARAMETRES] = MATLIBRE_STAT_LOI_AJUSTEE(V) dit si V est la
%   structure que rend FITDIST, et en tire le nom de la loi et la liste de
%   ses paramètres, dans l'ordre qu'attendent les fonctions ...PDF.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   C'est ce qui permet à PDF, CDF, ICDF et RANDOM de prendre une loi
%   ajustée au lieu d'un nom suivi de ses paramètres : l'objet porte déjà
%   les deux, et les répéter serait une occasion de se tromper.
    estAjustee = isstruct(valeur) && isscalar(valeur) ...
                 && isfield(valeur, 'DistributionName') ...
                 && isfield(valeur, 'ParameterValues');
    nom = '';
    parametres = {};
    if ~estAjustee
        return
    end
    nom = char(valeur.DistributionName);
    valeurs = valeur.ParameterValues;
    if iscell(valeurs)
        parametres = valeurs(:)';
    else
        parametres = num2cell(double(valeurs(:)'));
    end
end
