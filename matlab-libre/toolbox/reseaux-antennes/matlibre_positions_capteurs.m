function P = matlibre_positions_capteurs(pos)
%MATLIBRE_POSITIONS_CAPTEURS Positions de capteurs ramenées à trois lignes (x ; y ; z).
%   P = MATLIBRE_POSITIONS_CAPTEURS(POS) : une ligne de POS donne y, deux
%   lignes donnent (y ; z), trois lignes (x ; y ; z), comme STEERVEC.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      P = matlibre_positions_capteurs(0:0.5:1.5)     % 3 x 4
%
%   Voir aussi STEERVEC, SENSORCOV.
    n = size(pos, 2);
    switch size(pos, 1)
        case 1
            P = [zeros(1, n); pos; zeros(1, n)];
        case 2
            P = [zeros(1, n); pos];
        case 3
            P = pos;
        otherwise
            error('phased:positions:Taille', ...
                  'POS est 1 x N (y), 2 x N (y ; z) ou 3 x N (x ; y ; z), en longueurs d''onde.');
    end
end
