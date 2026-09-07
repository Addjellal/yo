function [P, v, methode, prolongement] = matlibre_interp_arguments(arguments)
%MATLIBRE_INTERP_ARGUMENTS Démêle les arguments d'un interpolant dispersé.
%   Les points peuvent venir en une matrice ou en coordonnées séparées, et
%   les deux dernières places peuvent porter la méthode et le mode de
%   prolongement. On reconnaît ces derniers à ce qu'ils sont du texte.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [P, v] = matlibre_interp_arguments({[0 0; 1 1], [3; 4]});
%      isequal(v, [3; 4])
%
%   Voir aussi SCATTEREDINTERPOLANT, GRIDDEDINTERPOLANT.
    methode = 'linear';
    prolongement = 'none';
    textes = {};
    while ~isempty(arguments) && (ischar(arguments{end}) || isstring(arguments{end}))
        textes = [{char(arguments{end})}, textes];   %#ok<AGROW>
        arguments(end) = [];
    end
    if ~isempty(textes), methode = lower(textes{1}); end
    if numel(textes) > 1, prolongement = lower(textes{2}); end

    if numel(arguments) == 2
        P = double(arguments{1});
        v = double(arguments{2});
    elseif numel(arguments) == 3
        P = [double(arguments{1}(:)), double(arguments{2}(:))];
        v = double(arguments{3});
    else
        error('MATLAB:scatteredInterpolant:Arguments', ...
              'Il faut les points et leurs valeurs.');
    end
    v = v(:);
    if size(P, 1) ~= numel(v)
        error('MATLAB:scatteredInterpolant:Tailles', ...
              'Il faut autant de valeurs que de points.');
    end
end
