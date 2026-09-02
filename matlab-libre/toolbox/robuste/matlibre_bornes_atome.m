function [nominal, bas, haut] = matlibre_bornes_atome(atome)
%MATLIBRE_BORNES_ATOME La valeur nominale et les deux bornes d'un paramètre.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   Elle accepte un UREAL, la structure interne d'un paramètre d'UMAT, ou
%   un UMAT qui n'a qu'un paramètre — ce que rend une expression comme
%   « k » passée telle quelle.
    if isa(atome, 'ureal')
        nominal = atome.NominalValue;
        bas = atome.Range(1);
        haut = atome.Range(2);
        return
    end
    if isstruct(atome) && isfield(atome, 'Nominal')
        nominal = atome.Nominal;
        bas = atome.Range(1);
        haut = atome.Range(2);
        return
    end
    if isa(atome, 'umat')
        p = atome.Uncertainty;
        if numel(p) ~= 1
            error('Robust:bornes:NotAnAtom', ...
                  'This function needs a single uncertain parameter.');
        end
        nominal = p{1}.Nominal;
        bas = p{1}.Range(1);
        haut = p{1}.Range(2);
        return
    end
    error('Robust:bornes:NotAnAtom', ...
          'This function needs an uncertain parameter.');
end
