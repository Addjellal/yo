function fis = genfis(X, Y, options)
%GENFIS Construction d'un système flou à partir de données.
%   FIS = GENFIS(X,Y) partitionne régulièrement l'espace d'entrée, comme
%   GENFIS1, et rend un système de Sugeno prêt pour ANFIS.
%   FIS = GENFIS(X,Y,OPTIONS) où OPTIONS est une structure aux champs
%     Methode          'gridpartition', 'subtractiveclustering' ou 'fcm'
%     NumMembershipFunctions   pour la partition régulière
%     ClusterInfluenceRange    pour la classification soustractive
%     NumClusters              pour les c-moyennes floues
%
%   Exemple :
%      x = (0:0.1:10)';
%      fis = genfis(x, sin(x), struct('Methode', 'fcm', 'NumClusters', 6));
%
%   Voir aussi GENFIS1, GENFIS2, GENFIS3, ANFIS.
    if nargin < 3 || isempty(options), options = struct(); end
    methode = 'gridpartition';
    if isfield(options, 'Methode'), methode = lower(char(options.Methode)); end
    if isfield(options, 'Method'), methode = lower(char(options.Method)); end
    switch methode
        case {'subtractiveclustering', 'subclust'}
            rayon = 0.5;
            if isfield(options, 'ClusterInfluenceRange')
                rayon = options.ClusterInfluenceRange;
            end
            fis = genfis2(X, Y, rayon);
        case 'fcm'
            nClusters = 2;
            if isfield(options, 'NumClusters'), nClusters = options.NumClusters; end
            fis = genfis3(X, Y, 'sugeno', nClusters);
        otherwise
            nombreMf = 2;
            if isfield(options, 'NumMembershipFunctions')
                nombreMf = options.NumMembershipFunctions;
            end
            fis = genfis1([X, Y], nombreMf);
    end
end
