function tf = issorted(a, varargin)
%ISSORTED Vrai si le tableau est trié.
%   TF = ISSORTED(A) est vrai si A est trié par ordre croissant.
%   ISSORTED(A,SENS) teste 'ascend', 'descend', 'monotonic',
%   'strictascend', 'strictdescend' ou 'strictmonotonic'.
%   ISSORTED(A,'rows') teste les lignes d'une matrice ; voir ISSORTEDROWS.
%
%   Ce qui s'ordonne se teste, même sans passer par des nombres : dates,
%   durées, catégories ordonnées et textes se comparent directement.
%
%   Exemples :
%      issorted([1 2 2 5])                  % true
%      issorted([1 2 2 5], 'strictascend')  % false
%      issorted([datetime(2024,1,1) datetime(2024,3,1)])   % true
%
%   Voir aussi SORT, ISSORTEDROWS, SORTROWS.
    sens = 'ascend';
    for k = 1:numel(varargin)
        o = lower(char(varargin{k}));
        if strcmp(o, 'rows')
            tf = issortedrows(a);
            return;
        end
        sens = o;
    end
    % Un tableau qu'on ne sait pas convertir en nombres — des dates, des
    % durées, des catégories ordonnées — se trie quand même : c'est la
    % comparaison qui compte, non la conversion. Passer par DOUBLE
    % refusait ces types, alors qu'ils s'ordonnent parfaitement.
    if isnumeric(a) || islogical(a)
        d = diff(double(a(:)));
        croissant = all(d >= 0);
        decroissant = all(d <= 0);
        strictCroissant = all(d > 0);
        strictDecroissant = all(d < 0);
    elseif iscell(a) || ischar(a) || isstring(a)
        % Du texte se compare par l'ordre lexicographique, que « < » ne
        % sait pas faire sur une cellule : on passe par la comparaison
        % deux a deux.
        liste = cellstr(a);
        liste = liste(:);
        croissant = true;
        decroissant = true;
        strictCroissant = true;
        strictDecroissant = true;
        for k = 2:numel(liste)
            comparaison = matlibre_comparer_textes(liste{k - 1}, liste{k});
            croissant = croissant && comparaison <= 0;
            decroissant = decroissant && comparaison >= 0;
            strictCroissant = strictCroissant && comparaison < 0;
            strictDecroissant = strictDecroissant && comparaison > 0;
        end
    else
        colonne = a(:);
        croissant = true;
        decroissant = true;
        strictCroissant = true;
        strictDecroissant = true;
        for k = 2:numel(colonne)
            avant = colonne(k - 1);
            apres = colonne(k);
            croissant = croissant && ~(apres < avant);
            decroissant = decroissant && ~(apres > avant);
            strictCroissant = strictCroissant && (avant < apres);
            strictDecroissant = strictDecroissant && (avant > apres);
        end
    end
    switch sens
        case 'ascend'
            tf = croissant;
        case 'descend'
            tf = decroissant;
        case 'monotonic'
            tf = croissant || decroissant;
        case 'strictascend'
            tf = strictCroissant;
        case 'strictdescend'
            tf = strictDecroissant;
        case 'strictmonotonic'
            tf = issorted(a, 'strictascend') || issorted(a, 'strictdescend');
        otherwise
            error('issorted:Sens', 'Sens de tri inconnu : %s.', sens);
    end
    tf = logical(tf);
end
