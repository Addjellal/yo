function oscillateur = adosc(ouverture, haut, bas, cloture)
%ADOSC Oscillateur d'accumulation et de distribution.
%   O = ADOSC(OUVERTURE,HAUT,BAS,CLOTURE) rend, pour chaque séance, la
%   part de l'amplitude gagnée par les acheteurs : la hausse depuis
%   l'ouverture plus la hausse depuis le plus bas, rapportées au double
%   de l'amplitude.
%
%   L'indicateur vaut un quand la séance ouvre au plus bas et clôture au
%   plus haut, zéro dans le cas contraire.
%
%   Exemple :
%      adosc(ouvertures, hauts, bas, clotures)
%
%   Voir aussi ADLINE, CHAIKOSC, WILLIAMSAD.
    if nargin < 2
        series = matlibre_colonnes_marche(ouverture, {}, ...
                                          {'ouverture', 'haut', 'bas', 'cloture'});
    else
        series = matlibre_colonnes_marche(ouverture, {haut, bas, cloture}, ...
                                          {'ouverture', 'haut', 'bas', 'cloture'});
    end
    O = series{1}; H = series{2}; B = series{3}; C = series{4};
    amplitude = 2 * (H - B);
    amplitude(amplitude == 0) = eps;
    oscillateur = ((H - O) + (C - B)) ./ amplitude;
end
