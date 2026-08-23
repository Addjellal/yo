function r = random(nom, varargin)
%RANDOM Tirages d'une loi nommée.
%   R = RANDOM('name', A, B, C, M, N) : les paramètres d'abord, les
%   dimensions ensuite, comme pour les fonctions ...RND.
%
%   Exemple :  random('Poisson', 4, 1, 5)   % cinq tirages
    r = feval([statPrefixeLoi(nom) 'rnd'], varargin{:});
end
