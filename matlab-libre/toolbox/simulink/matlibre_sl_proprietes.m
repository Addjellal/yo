function matlibre_sl_proprietes(objet, noms)
%MATLIBRE_SL_PROPRIETES Affiche un objet de Simulink comme MATLAB le fait.
%   MATLIBRE_SL_PROPRIETES(OBJET,NOMS) écrit « Classe with properties: »
%   puis, alignées à droite, les propriétés NOMS de l'objet avec leur
%   valeur résumée : le texte entre apostrophes, un petit tableau en
%   entier, les autres par leur taille et leur classe. Pour un tableau
%   d'objets, seulement les noms. Les méthodes DISP de SIMULINK.PARAMETER,
%   SIMULINK.SIGNAL et SIMULINK.SIMULATIONINPUT s'en servent.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      K = Simulink.Parameter(2);
%      matlibre_sl_proprietes(K, {'Value', 'DataType'})
%
%   Voir aussi SIMULINK.PARAMETER, DISP.
    classe = class(objet);
    court = classe(find(classe == '.', 1, 'last') + 1:end);
    if numel(objet) ~= 1
        fprintf('  %s %s array with properties:\n\n', dimensionsTexte(size(objet)), court);
        for k = 1:numel(noms)
            fprintf('    %s\n', noms{k});
        end
        return
    end
    fprintf('  %s with properties:\n\n', court);
    largeur = max(cellfun(@numel, noms));
    for k = 1:numel(noms)
        fprintf('%s%s: %s\n', blanks(4 + largeur - numel(noms{k})), noms{k}, ...
                resume(objet.(noms{k})));
    end
end

function t = resume(v)
    if ischar(v) && (isrow(v) || isempty(v)) && numel(v) <= 60
        t = ['''' v ''''];
    elseif isstring(v) && isscalar(v)
        t = ['"' char(v) '"'];
    elseif isa(v, 'function_handle')
        t = func2str(v);
        if t(1) ~= '@'
            t = ['@' t];
        end
    elseif isempty(v) && isa(v, 'double')
        t = '[]';
    elseif (isnumeric(v) || islogical(v)) && isscalar(v)
        t = strtrim(evalc('disp(v)'));
    elseif (isnumeric(v) || islogical(v)) && isrow(v) && numel(v) <= 10 && isreal(v)
        t = mat2str(double(v), 5);
    elseif iscell(v)
        t = sprintf('{%s cell}', dimensionsTexte(size(v)));
    else
        t = sprintf('[%s %s]', dimensionsTexte(size(v)), class(v));
    end
end

function t = dimensionsTexte(d)
    t = strjoin(arrayfun(@num2str, d, 'UniformOutput', false), 'x');
end
