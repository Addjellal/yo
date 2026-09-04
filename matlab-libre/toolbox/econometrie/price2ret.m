function [rendements, instants] = price2ret(prix, dates, methode)
%PRICE2RET Rendements tirés d'une série de prix.
%   R = PRICE2RET(P) rend les rendements continus, c'est-à-dire les
%   différences des logarithmes : R(t) = log(P(t+1)) - log(P(t)). Il y a
%   un rendement de moins que de prix.
%
%   R = PRICE2RET(P,DATES) rend aussi les instants correspondants.
%   R = PRICE2RET(P,DATES,'Periodic') calcule les rendements simples,
%   P(t+1)/P(t) - 1, au lieu des rendements continus.
%
%   Le rendement continu s'ajoute d'une période à l'autre, ce que le
%   rendement simple ne fait pas : c'est ce qui le rend commode pour
%   cumuler, et c'est pourquoi les modèles le préfèrent.
%
%   Une matrice est traitée colonne par colonne.
%
%   Exemple :
%      p = [100; 110; 99];
%      price2ret(p)                   % [0.0953; -0.1054]
%      price2ret(p, [], 'Periodic')   % [0.1; -0.1]
%
%   Voir aussi RET2PRICE, TICK2RET, RET2TICK.
    if nargin < 3 || isempty(methode), methode = 'continuous'; end
    prix = double(prix);
    ligne = isrow(prix);
    if isvector(prix)
        prix = prix(:);
    end
    if size(prix, 1) < 2
        error('econ:price2ret:Longueur', 'Il faut au moins deux prix.');
    end
    methode = lower(char(methode));
    switch methode
        case {'continuous', 'continu'}
            if any(prix(:) <= 0)
                error('econ:price2ret:Positifs', ...
                      'Le rendement continu demande des prix strictement positifs.');
            end
            rendements = diff(log(prix), 1, 1);
        case {'periodic', 'simple'}
            rendements = prix(2:end, :) ./ prix(1:end-1, :) - 1;
        otherwise
            error('econ:price2ret:Methode', ...
                  'La méthode doit être ''Continuous'' ou ''Periodic''.');
    end
    if ligne
        rendements = rendements.';
    end
    if nargout > 1
        if nargin < 2 || isempty(dates)
            instants = (2:size(prix, 1)).';
        else
            dates = dates(:);
            instants = dates(2:end);
        end
    end
end
