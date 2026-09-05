function texte = matlibre_id_ecrire_polynome(p)
%MATLIBRE_ID_ECRIRE_POLYNOME Écriture lisible d'un polynôme en q moins un.
%   T = MATLIBRE_ID_ECRIRE_POLYNOME(P) rend la formule, les coefficients
%   nuls omis.
%
%   Exemple :
%      matlibre_id_ecrire_polynome([1 -0.8])      % 1 - 0.8 q^-1
%
%   Voir aussi IDPOLY.
    morceaux = {};
    for k = 1:numel(p)
        if p(k) == 0
            continue
        end
        if k == 1
            morceaux{end + 1} = sprintf('%g', p(k));      %#ok<AGROW>
        else
            if p(k) < 0
                signe = '- ';
            else
                signe = '+ ';
            end
            morceaux{end + 1} = sprintf('%s%g q^-%d', signe, abs(p(k)), k - 1);  %#ok<AGROW>
        end
    end
    if isempty(morceaux)
        texte = '0';
    else
        texte = strjoin(morceaux, ' ');
    end
end
