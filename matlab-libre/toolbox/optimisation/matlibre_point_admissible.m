function ok = matlibre_point_admissible(x, A, b, Aeq, beq, bas, haut)
%MATLIBRE_POINT_ADMISSIBLE Le point respecte-t-il toutes les contraintes ?
%   OK = MATLIBRE_POINT_ADMISSIBLE(X,A,B,AEQ,BEQ,BAS,HAUT) rend vrai si X
%   satisfait A*X <= B, AEQ*X = BEQ et les bornes, à la tolérance près.
%
%   La tolérance se mesure contrainte par contrainte, rapportée à son
%   propre second membre. Rapportée au plus grand d'entre eux, une borne
%   de substitution à 1e9 rendrait acceptable une violation de mille sur
%   toutes les autres — et c'est ainsi qu'un point hors du domaine passe
%   pour une solution.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_point_admissible([1; 1], [1 1], 3, [], [], [0; 0], [])   % 1
%      matlibre_point_admissible([2; 2], [1 1], 3, [], [], [0; 0], [])   % 0
%
%   Voir aussi LINPROG, QUADPROG, FMINCON.
    ok = true;
    x = x(:);
    tolerance = 1e-6;
    if ~isempty(A)
        marge = A * x - b(:);
        if any(marge > tolerance * max(1, abs(b(:))))
            ok = false;
            return;
        end
    end
    if ~isempty(Aeq)
        ecart = abs(Aeq * x - beq(:));
        if any(ecart > tolerance * max(1, abs(beq(:))))
            ok = false;
            return;
        end
    end
    if ~isempty(bas)
        borne = bas(:);
        if isscalar(borne), borne = repmat(borne, numel(x), 1); end
        finies = isfinite(borne);
        if any(borne(finies) - x(finies) > tolerance * max(1, abs(borne(finies))))
            ok = false;
            return;
        end
    end
    if ~isempty(haut)
        borne = haut(:);
        if isscalar(borne), borne = repmat(borne, numel(x), 1); end
        finies = isfinite(borne);
        if any(x(finies) - borne(finies) > tolerance * max(1, abs(borne(finies))))
            ok = false;
            return;
        end
    end
end
