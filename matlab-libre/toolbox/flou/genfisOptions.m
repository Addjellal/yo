function options = genfisOptions(methode, varargin)
%GENFISOPTIONS Options de construction d'un système à partir de données.
%   O = GENFISOPTIONS(METHODE) où METHODE vaut 'GridPartition' (défaut),
%   'SubtractiveClustering' ou 'FCMClustering'. Les champs dépendent de
%   la méthode :
%     GridPartition          NumMembershipFunctions, InputMembershipFunctionType
%     SubtractiveClustering  ClusterInfluenceRange, SquashFactor,
%                            AcceptRatio, RejectRatio
%     FCMClustering          NumClusters, Exponent, MaxNumIteration,
%                            MinImprovement
%
%   Exemple :
%      o = genfisOptions('FCMClustering', 'NumClusters', 4);
%      fis = genfis(x, y, o);
%
%   Voir aussi GENFIS, ANFISOPTIONS, SUBCLUSTOPTIONS, FCM.
    if nargin < 1 || isempty(methode), methode = 'GridPartition'; end
    methode = char(methode);
    switch lower(methode)
        case {'gridpartition', 'grid'}
            options = struct('Methode', 'gridpartition', ...
                             'NumMembershipFunctions', 2, ...
                             'InputMembershipFunctionType', 'gaussmf');
        case {'subtractiveclustering', 'subclust'}
            options = struct('Methode', 'subtractiveclustering', ...
                             'ClusterInfluenceRange', 0.5, ...
                             'SquashFactor', 1.25, ...
                             'AcceptRatio', 0.5, 'RejectRatio', 0.15);
        case {'fcmclustering', 'fcm'}
            options = struct('Methode', 'fcm', 'NumClusters', 2, ...
                             'Exponent', 2, 'MaxNumIteration', 100, ...
                             'MinImprovement', 1e-5);
        otherwise
            error('fuzzy:genfisOptions:Methode', ...
                  'Méthode inconnue : %s.', methode);
    end
    options = poserOptions(options, 'genfisOptions', varargin{:});
end
