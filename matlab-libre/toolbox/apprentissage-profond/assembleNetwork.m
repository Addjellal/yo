function reseau = assembleNetwork(couches)
%ASSEMBLENETWORK Assemble un réseau sans l'entraîner.
%   RESEAU = ASSEMBLENETWORK(COUCHES) construit un réseau prêt à prédire à
%   partir de couches dont les poids sont déjà donnés. C'est ce qu'il faut
%   pour rejouer un réseau appris ailleurs, ou pour en modifier une couche
%   sans recommencer l'apprentissage.
%
%   COUCHES est un tableau de cellules de couches ou un LAYERGRAPH.
%
%   Exemple :
%      net = assembleNetwork({featureInputLayer(3), fullyConnectedLayer(2), ...
%                             softmaxLayer()});
%      Y = predict(net, randn(3, 4));
%
%   Voir aussi DLNETWORK, TRAINNETWORK, LAYERGRAPH.
    reseau = dlnetwork(couches);
    if ~reseau.Initialized
        error('nnet:assembleNetwork:Tailles', ...
              'Les tailles ne se déduisent pas des couches ; donnez une couche d''entrée.');
    end
end
