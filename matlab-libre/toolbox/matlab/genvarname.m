function noms = genvarname(candidats, exclus)
%GENVARNAME Fabrique des noms de variables valides.
%   N = GENVARNAME(C) transforme C — une chaîne ou un tableau de
%   cellules de chaînes — en noms de variables acceptables : les
%   caractères interdits deviennent leur code, un nom vide ou commençant
%   par un chiffre reçoit un préfixe, un mot réservé reçoit un suffixe.
%
%   N = GENVARNAME(C,EXCLUS) évite en outre les noms de la liste EXCLUS
%   en ajoutant un numéro.
%
%   Exemple :
%      genvarname({'a b', 'end', 'a b'})   % {'a_0x20_b', 'end1', 'a_0x20_b1'}
%
%   Voir aussi ISVARNAME, MATLAB.LANG.MAKEVALIDNAME, ISKEYWORD.
    if nargin < 2
        exclus = {};
    end
    if ischar(exclus) || isstring(exclus)
        exclus = {char(exclus)};
    end
    exclus = cellfun(@char, exclus(:)', 'UniformOutput', false);
    seul = ischar(candidats) || isstring(candidats);
    if seul
        candidats = {char(candidats)};
    end
    noms = cell(size(candidats));
    for k = 1:numel(candidats)
        n = nettoyer(char(candidats{k}));
        n = unique_parmi(n, exclus);
        noms{k} = n;
        exclus{end+1} = n;   %#ok<AGROW>
    end
    if seul
        noms = noms{1};
    end
end

function n = nettoyer(n)
% Un nom valide : lettres, chiffres et soulignés, une lettre en tête, et
% pas un mot réservé du langage.
    if isempty(n)
        n = 'x';
    end
    sortie = '';
    for k = 1:numel(n)
        c = n(k);
        if isletter(c) || c == '_' || (c >= '0' && c <= '9')
            sortie(end+1) = c;   %#ok<AGROW>
        else
            sortie = [sortie, sprintf('_0x%X_', double(c))];   %#ok<AGROW>
        end
    end
    n = sortie;
    if isempty(n) || ~isletter(n(1))
        n = ['x' n];
    end
    if numel(n) > namelengthmax()
        n = n(1:namelengthmax());
    end
    if iskeyword(n)
        n = [n '1'];
    end
end

function n = unique_parmi(n, exclus)
% Tant que le nom est pris, on lui accroche un numéro.
    base = n;
    k = 0;
    while any(strcmp(n, exclus))
        k = k + 1;
        n = sprintf('%s%d', base, k);
    end
end
