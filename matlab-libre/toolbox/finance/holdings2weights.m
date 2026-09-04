function poids = holdings2weights(quantites, prix, valeur)
%HOLDINGS2WEIGHTS Poids d'un portefeuille à partir des quantités détenues.
%   P = HOLDINGS2WEIGHTS(QUANTITES,PRIX) rend la part de chaque ligne
%   dans la valeur totale. Chaque ligne de QUANTITES est un portefeuille.
%
%   HOLDINGS2WEIGHTS(...,VALEUR) rapporte à une valeur donnée plutôt qu'à
%   la somme des lignes.
%
%   Exemple :
%      holdings2weights([100 200], [10 5])    % [0.5 0.5]
%
%   Voir aussi WEIGHTS2HOLDINGS, PORTSTATS.
    quantites = double(quantites);
    prix = double(prix(:)).';
    if size(quantites, 2) ~= numel(prix)
        error('finance:holdings2weights:Tailles', ...
              'Il faut un prix par actif.');
    end
    montants = quantites .* repmat(prix, size(quantites, 1), 1);
    if nargin < 3 || isempty(valeur)
        valeur = sum(montants, 2);
    else
        valeur = double(valeur(:));
    end
    poids = montants ./ repmat(valeur, 1, size(montants, 2));
end
