function [xd, Cd, Ld, perf0, perfl2] = wdencmp(option, varargin)
%WDENCMP Débruitage ou compression par seuillage des coefficients.
%   [XD,CXD,LXD,PERF0,PERFL2] = WDENCMP('gbl',X,NOM,N,THR,SORH,KEEPAPP)
%   décompose X sur N niveaux, seuille, puis reconstruit. PERF0 est le
%   pourcentage de coefficients annulés, PERFL2 la part d'énergie gardée.
%
%   WDENCMP('gbl',C,L,NOM,N,THR,SORH,KEEPAPP) part d'une décomposition
%   déjà faite.
%
%   Exemple :
%      x = wnoise(3, 10, 7);
%      xd = wdencmp('gbl', x, 'db4', 3, 2, 's', 1);
    if numel(varargin) >= 7 && isnumeric(varargin{2})
        % Forme avec décomposition fournie.
        C = varargin{1};
        L = varargin{2};
        nom = varargin{3};
        niveaux = varargin{4};
        seuil = varargin{5};
        sorh = varargin{6};
        garder = varargin{7};
    else
        x = varargin{1};
        nom = varargin{2};
        niveaux = varargin{3};
        seuil = varargin{4};
        sorh = varargin{5};
        garder = varargin{6};
        [C, L] = wavedec(x, niveaux, nom);
    end
    Cd = C;
    debut = 1;
    if garder
        debut = L(1) + 1;
    end
    Cd(debut:end) = wthresh(C(debut:end), sorh, seuil);
    Ld = L;
    xd = waverec(Cd, Ld, nom);
    nuls = sum(Cd == 0);
    perf0 = 100 * nuls / numel(Cd);
    energie = sum(C .^ 2);
    if energie == 0
        perfl2 = 100;
    else
        perfl2 = 100 * sum(Cd .^ 2) / energie;
    end
    option = option;                                 %#ok<ASGSL>
end
