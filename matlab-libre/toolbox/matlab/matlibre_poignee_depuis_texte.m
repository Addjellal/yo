function f = matlibre_poignee_depuis_texte(texte)
%MATLIBRE_POIGNEE_DEPUIS_TEXTE Une poignée bâtie sur une expression écrite.
%   Fonction interne : elle n'existe pas dans MATLAB. EZPLOT, EZSURF et
%   EZCONTOUR acceptent leur argument sous forme de chaîne — c'est
%   l'usage de ces fonctions anciennes — et cette fonction en fait une
%   poignée.
%
%   Les variables sont devinées : « x » seul donne une fonction d'une
%   variable, « x » et « y » une fonction de deux. Les opérateurs sont
%   vectorisés au passage, de sorte que « x^2 » travaille sur un tableau.
    texte = strtrim(texte);
    % Vectorisation : ^, * et / deviennent .^, .* et ./ quand ils ne le
    % sont pas deja.
    vectorise = '';
    k = 1;
    while k <= numel(texte)
        c = texte(k);
        if any(c == '^*/') && (k == 1 || texte(k - 1) ~= '.')
            vectorise = [vectorise, '.', c];     %#ok<AGROW>
        else
            vectorise = [vectorise, c];          %#ok<AGROW>
        end
        k = k + 1;
    end
    aY = matlibre_contient_variable(vectorise, 'y');
    if aY
        f = str2func(['@(x, y) ', vectorise]);
    else
        f = str2func(['@(x) ', vectorise]);
    end
end
