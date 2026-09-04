function indicateur = williamsad(haut, bas, cloture)
%WILLIAMSAD Accumulation et distribution de Williams.
%   A = WILLIAMSAD(HAUT,BAS,CLOTURE) cumule, séance après séance, l'écart
%   entre la clôture et le point extrême de la séance précédente : la
%   hausse ajoute la clôture moins le plus bas des deux clôtures, la
%   baisse retranche le plus haut moins la clôture.
%
%   L'indicateur monte quand les acheteurs l'emportent séance après
%   séance, même si le cours ne progresse pas : c'est une divergence de
%   ce genre que ses utilisateurs guettent.
%
%   Exemple :
%      williamsad(hauts, bas, clotures)
%
%   Voir aussi ADLINE, ADOSC, ONBALVOL.
    if nargin < 2
        series = matlibre_colonnes_marche(haut, {}, {'haut', 'bas', 'cloture'});
    else
        series = matlibre_colonnes_marche(haut, {bas, cloture}, {'haut', 'bas', 'cloture'});
    end
    H = series{1}; B = series{2}; C = series{3};
    n = numel(C);
    indicateur = zeros(n, 1);
    for k = 2:n
        if C(k) > C(k - 1)
            variation = C(k) - min(B(k), C(k - 1));
        elseif C(k) < C(k - 1)
            variation = C(k) - max(H(k), C(k - 1));
        else
            variation = 0;
        end
        indicateur(k) = indicateur(k - 1) + variation;
    end
end
