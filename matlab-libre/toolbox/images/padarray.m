function b = padarray(a, taille, valeur, direction)
%PADARRAY Ajoute une bordure à un tableau.
%   B = PADARRAY(A,[M N]) ajoute M lignes et N colonnes de zéros de chaque
%   côté. PADARRAY(A,T,VALEUR) remplit avec VALEUR ; VALEUR peut aussi
%   valoir 'replicate' (répète le bord), 'symmetric' (miroir) ou
%   'circular' (périodique). PADARRAY(A,T,VALEUR,DIRECTION) où DIRECTION
%   vaut 'both' (défaut), 'pre' ou 'post'.
%
%   Exemple :
%      padarray([1 2; 3 4], [1 1])   % entouré de zéros
    if nargin < 3 || isempty(valeur), valeur = 0; end
    if nargin < 4 || isempty(direction), direction = 'both'; end
    taille = taille(:)';
    if numel(taille) < 2, taille(2) = 0; end
    [m, n] = size(a);
    avantLignes = 0; apresLignes = 0; avantColonnes = 0; apresColonnes = 0;
    switch lower(direction)
        case 'pre'
            avantLignes = taille(1); avantColonnes = taille(2);
        case 'post'
            apresLignes = taille(1); apresColonnes = taille(2);
        otherwise
            avantLignes = taille(1); apresLignes = taille(1);
            avantColonnes = taille(2); apresColonnes = taille(2);
    end
    lignes = indices(m, avantLignes, apresLignes, valeur);
    colonnes = indices(n, avantColonnes, apresColonnes, valeur);
    if ischar(valeur) || isstring(valeur)
        b = a(lignes, colonnes);
    else
        b = valeur * ones(m + avantLignes + apresLignes, ...
                          n + avantColonnes + apresColonnes, class(a));
        b(avantLignes + (1:m), avantColonnes + (1:n)) = a;
    end
end

function idx = indices(n, avant, apres, valeur)
%INDICES Indices source pour un mode de remplissage donné.
    if ~(ischar(valeur) || isstring(valeur))
        idx = 1:n;
        return
    end
    total = avant + n + apres;
    brut = (1:total) - avant;
    switch lower(char(valeur))
        case 'replicate'
            idx = min(max(brut, 1), n);
        case 'symmetric'
            periode = 2 * n;
            k = mod(brut - 1, periode);
            k(k < 0) = k(k < 0) + periode;
            idx = k + 1;
            grand = idx > n;
            idx(grand) = periode - idx(grand) + 1;
        case 'circular'
            idx = mod(brut - 1, n) + 1;
        otherwise
            idx = min(max(brut, 1), n);
    end
end
