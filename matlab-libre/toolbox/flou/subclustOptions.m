function options = subclustOptions(varargin)
%SUBCLUSTOPTIONS Options de la classification soustractive.
%   O = SUBCLUSTOPTIONS rend les réglages par défaut de SUBCLUST :
%     ClusterInfluenceRange  rayon d'influence, 0,5
%     DataScale              bornes de normalisation, 'auto'
%     SquashFactor           écrasement du potentiel autour d'un centre,
%                            1,25
%     AcceptRatio            au-dessus de ce rapport, un point devient
%                            centre sans discussion, 0,5
%     RejectRatio            en dessous, il est écarté, 0,15
%     Verbose                affichage, 0
%
%   Exemple :
%      o = subclustOptions('ClusterInfluenceRange', 0.3);
%      c = subclust(donnees, o);
%
%   Voir aussi SUBCLUST, GENFISOPTIONS, FCM.
    options = struct('ClusterInfluenceRange', 0.5, 'DataScale', 'auto', ...
                     'SquashFactor', 1.25, 'AcceptRatio', 0.5, ...
                     'RejectRatio', 0.15, 'Verbose', 0);
    options = poserOptions(options, 'subclustOptions', varargin{:});
end
