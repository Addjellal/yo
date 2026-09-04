function sortie = vectorize(expression)
%VECTORIZE Rend une expression applicable terme à terme.
%   S = VECTORIZE(EXPRESSION) insère un point devant les opérateurs de
%   multiplication, de division et de puissance : l'expression s'applique
%   alors à des tableaux entiers plutôt qu'à des scalaires.
%
%   Un point déjà présent n'est pas redoublé.
%
%   EXPRESSION peut être une chaîne, un tableau de cellules de chaînes ou
%   une poignée de fonction anonyme ; le résultat est du même genre, sauf
%   pour une poignée, rendue sous forme de chaîne comme dans MATLAB.
%
%   Exemple :
%      vectorize('a*x^2 + b/c')      % a.*x.^2 + b./c
%
%   Voir aussi STR2FUNC, FUNC2STR, INLINE.
    if iscell(expression)
        sortie = cell(size(expression));
        for k = 1:numel(expression)
            sortie{k} = vectorize(expression{k});
        end
        return
    end
    if isa(expression, 'function_handle')
        expression = func2str(expression);
    end
    texte = char(expression);
    sortie = '';
    for k = 1:numel(texte)
        c = texte(k);
        if any(c == '*/^') && (k == 1 || texte(k - 1) ~= '.')
            sortie(end + 1) = '.';      %#ok<AGROW>
        end
        sortie(end + 1) = c;            %#ok<AGROW>
    end
end
