function y = wkeep(x, longueur, varargin)
%WKEEP Garde la partie centrale d'un vecteur ou d'une image.
%   Y = WKEEP(X,L) garde L éléments au centre.
%   Y = WKEEP(X,L,'l') ou 'r' garde le début ou la fin.
%   Y = WKEEP(X,L,DEBUT) part de l'indice donné.
%
%   Exemple :
%      wkeep([1 2 3 4 5], 3)   % [2 3 4]
    x = double(x);
    if ~isvector(x)
        if numel(longueur) == 1, longueur = [longueur longueur]; end
        debutLigne = floor((size(x, 1) - longueur(1)) / 2) + 1;
        debutColonne = floor((size(x, 2) - longueur(2)) / 2) + 1;
        y = x(debutLigne:debutLigne + longueur(1) - 1, ...
              debutColonne:debutColonne + longueur(2) - 1);
        return
    end
    ligne = isrow(x);
    v = x(:)';
    n = numel(v);
    longueur = min(longueur, n);
    debut = floor((n - longueur) / 2) + 1;
    if ~isempty(varargin)
        option = varargin{1};
        if ischar(option) || isstring(option)
            switch lower(char(option))
                case 'l', debut = 1;
                case 'r', debut = n - longueur + 1;
                case 'c', debut = floor((n - longueur) / 2) + 1;
            end
        else
            debut = option;
        end
    end
    y = v(debut:debut + longueur - 1);
    if ~ligne, y = y'; end
end
