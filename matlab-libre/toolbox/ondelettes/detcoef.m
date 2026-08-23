function d = detcoef(c, l, niveau)
%DETCOEF Coefficients de détail d'un niveau donné.
%   D = DETCOEF(C,L,N) extrait le bloc du niveau N dans le vecteur rendu
%   par WAVEDEC. Le niveau 1 est le plus fin.
%
%   Exemple :
%      [c, l] = wavedec(1:8, 2, 'db1');
%      numel(detcoef(c, l, 1))   % 4
    maximum = numel(l) - 2;
    if nargin < 3 || isempty(niveau), niveau = maximum; end
    if niveau < 1 || niveau > maximum
        error('wavelet:detcoef:BadLevel', 'The level must be between 1 and %d.', maximum);
    end
    debut = l(1) + 1;
    for k = maximum:-1:niveau + 1
        debut = debut + l(maximum - k + 2);
    end
    longueur = l(maximum - niveau + 2);
    d = c(debut:debut + longueur - 1);
end
