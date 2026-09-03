function [valeurs, m, prim] = matlibre_gf_concat(morceaux, dimension)
%MATLIBRE_GF_CONCAT Concatène des tableaux de corps de Galois.
%   Tous doivent appartenir au même corps ; un tableau ordinaire est
%   admis et pris dans le corps des autres.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    m = [];
    prim = [];
    for k = 1:numel(morceaux)
        if isa(morceaux{k}, 'gf')
            if isempty(m)
                m = morceaux{k}.m;
                prim = morceaux{k}.prim_poly;
            elseif morceaux{k}.m ~= m || morceaux{k}.prim_poly ~= prim
                error('comm:gf:Corps', ...
                      'Les morceaux ne sont pas du même corps de Galois.');
            end
        end
    end
    if isempty(m)
        m = 1;
        prim = 3;
    end
    valeurs = [];
    for k = 1:numel(morceaux)
        bloc = matlibre_gf_valeurs(morceaux{k});
        if isempty(valeurs)
            valeurs = bloc;
        elseif dimension == 1
            valeurs = [valeurs; bloc];   %#ok<AGROW>
        else
            valeurs = [valeurs, bloc];   %#ok<AGROW>
        end
    end
end
