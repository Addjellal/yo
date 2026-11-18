function [matrice, info] = matlibre_info_matrice(nom, arguments, fonction)
%MATLIBRE_INFO_MATRICE Matrice de substitution et sa fiche, comme BLOSUM la rend.
%   [M,INFO] = MATLIBRE_INFO_MATRICE(NOM,ARGUMENTS,FONCTION) lit les options
%   'Extended' (true : 24 symboles, B Z X * compris ; false : les 20 acides
%   aminés) et 'Order' (un ordre de symboles imposé), et rend la fiche :
%   Name, Scale, Entropy, ExpectedScore, HighestScore, LowestScore, Order.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [M, info] = matlibre_info_matrice('BLOSUM62', {}, 'blosum');
%      info.Scale                 % 1/2
%
%   Voir aussi BLOSUM, PAM, NUC44.
    [matrice, ordre, echelle] = matlibre_matrice_substitution(nom);
    etendu = true;
    ordreVoulu = '';
    if mod(numel(arguments), 2) ~= 0
        error(['bioinfo:' fonction ':Options'], 'Les options vont par paires nom-valeur.');
    end
    for k = 1:2:numel(arguments)
        switch lower(char(arguments{k}))
            case 'extended'
                etendu = logical(arguments{k + 1});
            case 'order'
                ordreVoulu = upper(char(arguments{k + 1}));
            otherwise
                error(['bioinfo:' fonction ':Options'], 'Option inconnue : %s.', ...
                      char(arguments{k}));
        end
    end
    if ~isempty(ordreVoulu)
        [present, rang] = ismember(ordreVoulu, ordre);
        if ~all(present)
            error(['bioinfo:' fonction ':Order'], ...
                  'L''ordre contient des symboles hors de la matrice.');
        end
        matrice = matrice(rang, rang);
        ordre = ordreVoulu;
    elseif ~etendu && numel(ordre) == 24
        matrice = matrice(1:20, 1:20);
        ordre = ordre(1:20);
    end
    % Entropie relative et score attendu, tels que les fichiers du NCBI
    % les donnent.
    fiches = struct('BLOSUM45', [0.3795 -0.2789], 'BLOSUM50', [0.4808 -0.3573], ...
                    'BLOSUM62', [0.6979 -0.5209], 'BLOSUM80', [0.9868 -0.7442], ...
                    'BLOSUM90', [1.1806 -0.8887], 'PAM250', [0.354 -0.844], ...
                    'NUC44', [0.5164710 -1.7495024]);
    valeurs = fiches.(upper(nom));
    info = struct('Name', upper(nom), 'Scale', echelle, 'Entropy', valeurs(1), ...
                  'ExpectedScore', valeurs(2), 'HighestScore', max(matrice(:)), ...
                  'LowestScore', min(matrice(:)), 'Order', ordre);
end
