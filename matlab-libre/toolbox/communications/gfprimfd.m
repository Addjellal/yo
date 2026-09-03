function polynomes = gfprimfd(m, option, p)
%GFPRIMFD Recherche de polynômes primitifs.
%   POL = GFPRIMFD(M) rend le premier polynôme primitif de degré M sur
%   GF(2), coefficients par puissances croissantes.
%   POL = GFPRIMFD(M,OPT,P) cherche sur GF(P). OPT vaut :
%     'min'  le premier trouvé, dans l'ordre des codes croissants (défaut)
%     'max'  le dernier
%     'all'  tous, une ligne par polynôme
%     un entier N : le N-ième
%
%   La recherche est exhaustive : on parcourt les polynômes unitaires de
%   degré M et l'on garde ceux que GFPRIMCK déclare primitifs. Le nombre
%   de primitifs de degré M sur GF(P) vaut phi(P^M - 1) / M.
%
%   Exemple :
%      gfprimfd(4)                    % [1 1 0 0 1]
%      size(gfprimfd(5, 'all'), 1)    % 6
%
%   Voir aussi GFPRIMDF, GFPRIMCK, GFCOSETS, GFROOTS.
    if nargin < 2 || isempty(option), option = 'min'; end
    if nargin < 3 || isempty(p), p = 2; end
    exigerPremier(p, 'gfprimfd');
    m = round(m);
    if m < 1
        error('comm:gfprimfd:Degre', 'Le degré doit valoir au moins un.');
    end
    trouves = zeros(0, m + 1);
    cherchePremier = ischar(option) || isstring(option);
    if cherchePremier
        mot = lower(char(option));
    else
        mot = '';
    end
    for code = 0:(p ^ m - 1)
        candidat = [chiffresBase(code, p, m), 1];
        if candidat(1) == 0
            continue                 % x diviserait le polynôme
        end
        if gfprimck(candidat, p) == 1
            trouves(end + 1, :) = candidat;   %#ok<AGROW>
            if strcmp(mot, 'min')
                polynomes = candidat;
                return
            end
        end
    end
    if isempty(trouves)
        polynomes = zeros(0, m + 1);
        return
    end
    if cherchePremier
        switch mot
            case 'min',  polynomes = trouves(1, :);
            case 'max',  polynomes = trouves(end, :);
            case 'all',  polynomes = trouves;
            otherwise
                error('comm:gfprimfd:Option', 'Option inconnue : %s.', mot);
        end
    else
        rang = round(option);
        if rang < 1 || rang > size(trouves, 1)
            error('comm:gfprimfd:Rang', ...
                  'Il n''y a que %d polynômes primitifs de ce degré.', ...
                  size(trouves, 1));
        end
        polynomes = trouves(rang, :);
    end
end

function v = chiffresBase(code, p, n)
    v = zeros(1, n);
    for k = 1:n
        v(k) = mod(code, p);
        code = floor(code / p);
    end
end
