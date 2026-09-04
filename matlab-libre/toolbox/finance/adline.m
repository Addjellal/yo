function ligne = adline(haut, bas, cloture, volume)
%ADLINE Ligne d'accumulation et de distribution.
%   A = ADLINE(HAUT,BAS,CLOTURE,VOLUME) cumule, séance après séance, le
%   volume affecté d'un signe : positif si la clôture est près du plus
%   haut, négatif si elle est près du plus bas.
%
%   L'idée est que la place de la clôture dans l'amplitude du jour dit
%   qui, des acheteurs ou des vendeurs, a eu le dernier mot ; le volume
%   dit avec quelle force.
%
%   Exemple :
%      adline(hauts, bas, clotures, volumes)
%
%   Voir aussi ADOSC, CHAIKOSC, ONBALVOL, WILLIAMSAD.
    if nargin < 2
        series = matlibre_colonnes_marche(haut, {}, {'haut', 'bas', 'cloture', 'volume'});
    else
        series = matlibre_colonnes_marche(haut, {bas, cloture, volume}, ...
                                          {'haut', 'bas', 'cloture', 'volume'});
    end
    H = series{1}; B = series{2}; C = series{3}; V = series{4};
    amplitude = H - B;
    amplitude(amplitude == 0) = eps;
    flux = ((C - B) - (H - C)) ./ amplitude .* V;
    ligne = cumsum(flux);
end
