function r = random(nom, varargin)
%RANDOM Tirages d'une loi nommée.
%   R = RANDOM('name', A, B, C, M, N) : les paramètres d'abord, les
%   dimensions ensuite, comme pour les fonctions ...RND.
%
%   R = RANDOM(GM,N) tire N points d'un mélange gaussien : on tire
%   d'abord la composante, puis le point dans cette composante.
%
%   R = RANDOM(PD,M,N) tire dans une loi ajustée par FITDIST.
%
%   Exemples :
%      random('Poisson', 4, 1, 5)              % cinq tirages
%      pd = fitdist(normrnd(5, 2, 500, 1), 'Normal');
%      size(random(pd, 1, 10))                 % 1 10
    if isstruct(nom) && isfield(nom, 'type') && strcmp(nom.type, 'melange-gaussien')
        r = tirerMelange(nom, varargin{:});
        return
    end
    [ajustee, nomLoi, parametres] = matlibre_stat_loi_ajustee(nom);
    if ajustee
        r = feval([statPrefixeLoi(nomLoi) 'rnd'], parametres{:}, varargin{:});
        return
    end
    r = feval([statPrefixeLoi(nom) 'rnd'], varargin{:});
end
