function [sysm, T] = modreal(sys, coupure)
%MODREAL Réalisation modale.
%   SYSM = MODREAL(SYS) met SYS sous forme modale : la matrice d'état
%   devient bloc-diagonale, un bloc de taille un par pôle réel et un bloc
%   de taille deux par paire de pôles complexes conjugués. Chaque bloc
%   est alors un mode, qu'on peut lire, garder ou retirer isolément.
%
%   [SYSM,T] = MODREAL(SYS) rend en outre la matrice de passage : les
%   états de SYSM sont T fois ceux de SYS.
%
%   SYSM = MODREAL(SYS,N) range les modes de sorte que les N premiers
%   soient les plus lents — les pôles les plus proches de l'axe
%   imaginaire.
%
%   La forme modale est celle qui sert à retirer des modes par leur
%   fréquence plutôt que par leur poids : c'est ce que font SLOWFAST et
%   STABPROJ.
%
%   Exemples :
%      G = ss([-1 2; -2 -1], [1; 0], [1 1], 0);   % une paire complexe
%      Gm = modreal(G);
%      Gm.A                          % bloc [a b; -b a]
%
%   Voir aussi SLOWFAST, STABPROJ, STRANS, CANON, BALREAL.
    G = ss(sys);
    A = G.A;
    n = size(A, 1);
    if n == 0
        sysm = G;
        T = [];
        return;
    end
    [V, D] = eig(A);
    valeurs = diag(D);
    % Les modes ranges par partie reelle decroissante : les plus lents
    % d'abord, qui sont ceux qu'on garde.
    [~, ordre] = sort(real(valeurs), 'descend');
    if nargin >= 2 && ~isempty(coupure)
        [~, ordre] = sort(abs(real(valeurs)), 'ascend');
    end
    valeurs = valeurs(ordre);
    V = V(:, ordre);
    % La base reelle : une colonne par pole reel, deux par paire.
    base = zeros(n, n);
    colonne = 1;
    k = 1;
    while k <= n
        if abs(imag(valeurs(k))) < 1e-12 * max(1, abs(valeurs(k)))
            base(:, colonne) = real(V(:, k));
            colonne = colonne + 1;
            k = k + 1;
        else
            base(:, colonne) = real(V(:, k));
            base(:, colonne + 1) = imag(V(:, k));
            colonne = colonne + 2;
            % On saute le conjugue, qui suit dans la liste.
            saut = k + 1;
            while saut <= n && abs(valeurs(saut) - conj(valeurs(k))) > ...
                               1e-9 * max(1, abs(valeurs(k)))
                saut = saut + 1;
            end
            if saut <= n
                valeurs([k + 1, saut]) = valeurs([saut, k + 1]);
                V(:, [k + 1, saut]) = V(:, [saut, k + 1]);
            end
            k = k + 2;
        end
    end
    if rcond(base) < eps
        % Modes defectifs : la base propre n'existe pas, on garde SYS.
        sysm = G;
        T = eye(n);
        return;
    end
    T = inv(base);
    sysm = ss(T * A * base, T * G.B, G.C * base, G.D, G.Ts);
end
