function forme = statForme(defaut, args)
%STATFORME Taille demandée à un générateur aléatoire.
%   Les fonctions ...RND de MATLAB acceptent des dimensions après les
%   paramètres : RND(A,M), RND(A,M,N), RND(A,[M N]). Sans dimension, le
%   résultat prend la taille des paramètres.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isempty(args)
        forme = defaut;
    elseif numel(args) == 1
        n = args{1};
        if numel(n) == 1
            forme = [n n];
        else
            forme = double(n(:))';
        end
    else
        forme = zeros(1, numel(args));
        for k = 1:numel(args)
            forme(k) = double(args{k});
        end
    end
end
