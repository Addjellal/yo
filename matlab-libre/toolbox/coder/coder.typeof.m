function t = coder.typeof(exemple, tailles, variables) %#ok<*STOUT>
%CODER.TYPEOF Décrit le type et la taille d'une entrée pour CODEGEN.
%   T = CODER.TYPEOF(EXEMPLE) prend la classe et les dimensions de EXEMPLE.
%   T = CODER.TYPEOF(EXEMPLE,TAILLES) impose les dimensions.
%
%   MatLibre ne produit que des tableaux de taille fixe : le troisième
%   argument de MATLAB, qui déclare des dimensions variables, est accepté
%   puis ignoré, et un avertissement le signale.
%
%   Exemple :
%      codegen('f', '-args', {coder.typeof(int32(0), [3 3])})
    if nargin >= 3 && any(variables(:))
        warning('coder:typeof:VariableSizeIgnored', ...
                ['MatLibre Coder produces fixed-size arrays: the variable-size ' ...
                 'declaration is ignored.']);
    end
    if nargin < 2 || isempty(tailles)
        t = exemple;
        return
    end
    if isscalar(tailles), tailles = [tailles tailles]; end
    t = zeros(tailles(1), tailles(2), class(exemple));
end
