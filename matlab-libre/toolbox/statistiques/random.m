function r = random(nom, varargin)
%RANDOM Tirages d'une loi nommée.
%   R = RANDOM('name', A, B, C, M, N) : les paramètres d'abord, les
%   dimensions ensuite, comme pour les fonctions ...RND.
%
%   R = RANDOM(GM,N) tire N points d'un mélange gaussien : on tire
%   d'abord la composante, puis le point dans cette composante.
%
%   Exemple :  random('Poisson', 4, 1, 5)   % cinq tirages
    if isstruct(nom) && isfield(nom, 'type') && strcmp(nom.type, 'melange-gaussien')
        r = tirerMelange(nom, varargin{:});
        return
    end
    r = feval([statPrefixeLoi(nom) 'rnd'], varargin{:});
end
