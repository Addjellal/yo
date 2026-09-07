function f = matlibre_decomp_factoriser(A, type)
%MATLIBRE_DECOMP_FACTORISER Calcule et range la factorisation demandée.
%   Le drapeau « malConditionne » retient ce que la factorisation a vu
%   passer : le rapport du plus petit pivot au plus grand. C'est une
%   estimation du conditionnement qui ne coûte rien, et c'est la seule
%   information que la substitution ne peut plus retrouver ensuite.
%
%   Le seuil est la racine de la précision machine, soit 1,5e-8 : un
%   rapport plus petit signifie que plus de la moitié des chiffres
%   significatifs sont perdus, ce qui est le moment de prévenir.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      f = matlibre_decomp_factoriser([4 1; 1 3], 'chol');
%      f.malConditionne                % 0
%      matlibre_decomp_factoriser(hilb(12), 'lu').malConditionne     % 1
%
%   Voir aussi DECOMPOSITION, ISILLCONDITIONED.
    f = struct();
    f.type = type;
    f.malConditionne = false;
    switch type
        case 'chol'
            [R, echec] = chol(A);
            if echec ~= 0
                error('MATLAB:decomposition:NotPositiveDefinite', ...
                      'La matrice n''est pas définie positive.');
            end
            f.R = R;
            f.malConditionne = rapportPivots(diag(R)) < sqrt(eps);
        case 'ldl'
            [L, D, P] = ldl(A);
            f.L = L; f.D = D; f.P = P;
            f.malConditionne = rapportPivots(diag(D)) < sqrt(eps);
        case 'qr'
            [Q, R] = qr(A, 0);
            f.Q = Q; f.R = R;
            f.malConditionne = rapportPivots(diag(R)) < sqrt(eps);
        otherwise
            [L, U, P] = lu(A);
            f.L = L; f.U = U; f.P = P;
            f.malConditionne = rapportPivots(diag(U)) < sqrt(eps);
    end
end

function r = rapportPivots(pivots)
% Le rapport du plus petit pivot au plus grand : une estimation du
% conditionnement que la factorisation donne sans travail supplementaire.
    pivots = abs(pivots(:));
    if isempty(pivots) || max(pivots) == 0
        r = 0;
    else
        r = min(pivots) / max(pivots);
    end
end
