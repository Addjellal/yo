function tf = isIllConditioned(d)
%ISILLCONDITIONED La factorisation a-t-elle rencontré un pivot minuscule.
%   TF = ISILLCONDITIONED(D) dit si la factorisation gardée par D a
%   rencontré un pivot négligeable devant la norme de la matrice.
%
%   C'est la seule information que la substitution ne peut plus retrouver :
%   une fois la factorisation faite, le mauvais conditionnement ne se voit
%   plus dans le résultat, il se voit dans les pivots. La retenir est
%   l'intérêt de l'objet.
%
%   Exemple :
%      isIllConditioned(decomposition([4 1; 1 3]))       % 0
%      isIllConditioned(decomposition(hilb(12), 'lu'))   % 1
%
%   Voir aussi DECOMPOSITION, COND, CONDEST, RCOND.
    if ~isa(d, 'decomposition')
        error('MATLAB:isIllConditioned:NotDecomposition', ...
              'ISILLCONDITIONED attend un objet DECOMPOSITION.');
    end
    tf = d.Facteurs.malConditionne;
end
