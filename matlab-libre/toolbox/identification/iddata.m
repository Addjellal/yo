function donnees = iddata(y, u, Ts)
%IDDATA Jeu de données entrée/sortie.
    if nargin < 3
        Ts = 1;
    end
    donnees = struct();
    donnees.y = y(:);
    donnees.u = u(:);
    donnees.Ts = Ts;
    donnees.N = numel(y);
end
