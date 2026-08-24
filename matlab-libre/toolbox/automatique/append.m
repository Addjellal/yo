function sys = append(varargin)
%APPEND Mise en parallèle sans connexion : modèle bloc-diagonal.
%   SYS = APPEND(SYS1,SYS2,...) empile les modèles sans les relier :
%   les entrées et les sorties se juxtaposent, et les matrices d'état
%   forment des blocs diagonaux. C'est le produit direct des systèmes,
%   à ne pas confondre avec PARALLEL, qui somme les sorties.
%
%   Un scalaire est accepté et vaut pour un gain statique.
%
%   Exemple :
%      s = append(tf(1, [1 1]), tf(2, [1 2]));
%      size(ssdata(s))   % 2 états
%
%   Voir aussi PARALLEL, SERIES, FEEDBACK.
    if isempty(varargin)
        error('control:append:NoInput', 'Il faut au moins un modèle.');
    end
    A = []; B = []; C = []; D = []; Ts = 0;
    for k = 1:numel(varargin)
        courant = varargin{k};
        if ~isstruct(courant)
            courant = ss(courant);
        else
            courant = ss(courant);
        end
        if courant.Ts ~= 0
            Ts = courant.Ts;
        end
        n = size(A, 1);
        m = size(courant.A, 1);
        ny = size(C, 1);
        nu = size(B, 2);
        nyk = size(courant.C, 1);
        nuk = size(courant.D, 2);
        A = [A, zeros(n, m); zeros(m, n), courant.A];
        B = [B, zeros(n, nuk); zeros(m, nu), courant.B];
        C = [C, zeros(ny, m); zeros(nyk, n), courant.C];
        D = [D, zeros(ny, nuk); zeros(nyk, nu), courant.D];
    end
    sys = ss(A, B, C, D, Ts);
end
