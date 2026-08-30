function [X, ok] = matlibre_riccati(A, S, Q)
%MATLIBRE_RICCATI Solution stabilisante d'une équation de Riccati.
%   [X,OK] = MATLIBRE_RICCATI(A,S,Q) résout
%
%      A'*X + X*A + X*S*X + Q = 0
%
%   et rend la solution stabilisante : celle qui rend A + S*X stable. OK
%   est faux quand elle n'existe pas — c'est ainsi que la synthèse
%   H-infini apprend qu'un GAMMA est trop petit.
%
%   La solution vient du sous-espace invariant stable de la matrice
%   hamiltonienne
%
%      H = [ A   S ; -Q  -A' ]
%
%   dont une base [U1; U2] donne X = U2/U1. Ce sous-espace est cherché de
%   deux façons, parce qu'aucune ne suffit seule :
%
%     - par les vecteurs propres, exacte quand les valeurs propres sont
%       distinctes, mise en défaut dès que deux pôles se confondent — un
%       modèle avec un pôle double en donne aussitôt ;
%     - par la fonction signe, dont l'itération de Newton
%       Z <- (Z + inv(Z))/2 converge vers une matrice dont (I - Z)/2
%       projette sur le sous-espace stable, pôles doubles ou non, mais qui
%       perd en précision sur une matrice mal conditionnée.
%
%   On garde celle des deux qui laisse le plus petit résidu, et l'on
%   vérifie qu'elle stabilise vraiment. Une solution qui ne passe ni l'un
%   ni l'autre contrôle est refusée : c'est le cas sans solution.
%
%   Cette fonction est un utilitaire interne de la boîte à outils
%   Automatique : elle n'existe pas dans MATLAB.
%
%   Voir aussi CARE, DARE, HINFSYN.
    n = size(A, 1);
    X = zeros(n);
    ok = false;
    if n == 0
        ok = true;
        return
    end
    H = [A, S; -Q, -A'];
    bases = {};
    [base, trouve] = parVecteursPropres(H);
    if trouve
        bases{end+1} = base;    %#ok<AGROW>
    end
    [base, trouve] = parFonctionSigne(H);
    if trouve
        bases{end+1} = base;    %#ok<AGROW>
    end

    echelle = max(1, norm(A, 'fro') + norm(S, 'fro') + norm(Q, 'fro'));
    meilleur = inf;
    for k = 1:numel(bases)
        U = bases{k};
        U1 = U(1:n, :);
        U2 = U(n+1:end, :);
        if rcond(U1' * U1) < 1e-14
            continue
        end
        candidat = real(U2 / U1);
        candidat = (candidat + candidat') / 2;
        if ~all(all(isfinite(candidat)))
            continue
        end
        % La solution doit stabiliser : c'est ce qui distingue la bonne des
        % autres solutions de la même équation.
        if max(real(eig(A + S * candidat))) > -1e-9 * echelle
            continue
        end
        residu = norm(A' * candidat + candidat * A + candidat * S * candidat + Q, 'fro');
        residu = residu / (echelle * max(1, norm(candidat, 'fro')));
        if residu < meilleur
            meilleur = residu;
            X = candidat;
            ok = true;
        end
    end
    if ok && meilleur > 1e-7
        ok = false;             % aucune des deux n'a vraiment résolu
        X = zeros(n);
    end
end

function [base, ok] = parVecteursPropres(H)
%PARVECTEURSPROPRES Sous-espace stable, par les vecteurs propres.
    m = size(H, 1);
    n = m / 2;
    base = zeros(m, n);
    [V, D] = eig(H);
    valeurs = diag(D);
    echelle = max(1, max(abs(valeurs)));
    ok = false;
    if any(abs(real(valeurs)) < 1e-9 * echelle)
        return                  % des valeurs propres sur l'axe imaginaire
    end
    choix = find(real(valeurs) < 0);
    if numel(choix) ~= n
        return
    end
    base = V(:, choix);
    ok = true;
end

function [base, ok] = parFonctionSigne(H)
%PARFONCTIONSIGNE Sous-espace stable, par la fonction signe.
    m = size(H, 1);
    n = m / 2;
    base = zeros(m, n);
    ok = false;
    Z = H;
    converge = false;
    precedent = inf;
    supplementaires = 0;
    for tour = 1:100
        Zi = inv(Z);
        if ~all(all(isfinite(Zi)))
            return              % une valeur propre nulle : pas de signe
        end
        % Mise à l'échelle par les normes : elle divise par deux le nombre
        % de tours et garde l'itération loin des débordements. Le
        % déterminant, lui, déborde dès que la matrice est grande.
        c = sqrt(norm(Zi, 'fro') / max(norm(Z, 'fro'), realmin));
        if ~isfinite(c) || c <= 0
            c = 1;
        end
        suivant = (c * Z + Zi / c) / 2;
        if ~all(all(isfinite(suivant)))
            return
        end
        ecart = norm(suivant - Z, 'fro');
        Z = suivant;
        if converge
            supplementaires = supplementaires + 1;
            if supplementaires >= 2
                break           % deux tours de plus, pour la précision
            end
        elseif ecart <= 1e-8 * norm(Z, 'fro') || ecart >= precedent
            % Convergée, ou stagnante : au-delà, l'arrondi domine.
            converge = true;
        end
        precedent = ecart;
    end
    if ~converge
        return
    end
    % Le signe d'une matrice sans valeur propre sur l'axe imaginaire
    % vérifie signe^2 = I. Sinon, l'équation n'a pas de solution.
    if norm(Z * Z - eye(m), 'fro') > 1e-4 * m * max(1, norm(Z, 'fro'))
        return
    end
    projecteur = (eye(m) - Z) / 2;
    [U, valeurs, ~] = svd(projecteur);
    d = diag(valeurs);
    if numel(d) < n || d(n) < 1e-10 * max(d(1), realmin)
        return                  % le sous-espace n'a pas la dimension voulue
    end
    if numel(d) > n && d(n+1) > 1e-6 * d(1)
        return                  % il en a trop : des pôles sur l'axe
    end
    base = U(:, 1:n);
    ok = true;
end
