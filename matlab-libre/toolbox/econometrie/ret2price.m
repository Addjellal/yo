function prix = ret2price(rendements, prixInitial, methode)
%RET2PRICE Prix reconstruits à partir de rendements.
%   P = RET2PRICE(R) recompose la série de prix, en partant de un.
%   P = RET2PRICE(R,P0) part du prix donné.
%   P = RET2PRICE(R,P0,'Periodic') traite R comme des rendements simples
%   au lieu de rendements continus.
%
%   C'est l'inverse de PRICE2RET : les deux se défont exactement.
%
%   Exemple :
%      p = [100; 110; 99];
%      max(abs(ret2price(price2ret(p), 100) - p))   % nul
%
%   Voir aussi PRICE2RET, RET2TICK, TICK2RET.
    if nargin < 2 || isempty(prixInitial), prixInitial = 1; end
    if nargin < 3 || isempty(methode), methode = 'continuous'; end
    rendements = double(rendements);
    ligne = isrow(rendements);
    if isvector(rendements)
        rendements = rendements(:);
    end
    colonnes = size(rendements, 2);
    prixInitial = double(prixInitial(:)).';
    if numel(prixInitial) == 1
        prixInitial = repmat(prixInitial, 1, colonnes);
    end
    methode = lower(char(methode));
    switch methode
        case {'continuous', 'continu'}
            cumul = [zeros(1, colonnes); cumsum(rendements, 1)];
            prix = repmat(prixInitial, size(cumul, 1), 1) .* exp(cumul);
        case {'periodic', 'simple'}
            facteurs = [ones(1, colonnes); cumprod(1 + rendements, 1)];
            prix = repmat(prixInitial, size(facteurs, 1), 1) .* facteurs;
        otherwise
            error('econ:ret2price:Methode', ...
                  'La méthode doit être ''Continuous'' ou ''Periodic''.');
    end
    if ligne
        prix = prix.';
    end
end
