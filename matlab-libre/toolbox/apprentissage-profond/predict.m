function y = predict(reseau, X)
%PREDICT Sortie d'un réseau appris.
%   Les couches qui se comportent autrement à l'apprentissage — abandon,
%   normalisation par lot — sont ici en mode prédiction.
%
%   Pour un réseau à couches spatiales, X est un tableau H x L x P x N ;
%   la sortie reste une matrice, une colonne par observation.
    y = X;
    couches = reseau.couches;
    for k = 1:numel(couches)
        c = couches{k};
        switch c.type
            case 'fc'
                y = c.W * y + repmat(c.b, 1, size(y, 2));
            case {'conv2d', 'maxpool', 'avgpool', 'flatten'}
                y = couchesConvolution('avant', c, y);
            case 'relu'
                y = max(y, 0);
            case 'leakyrelu'
                y = max(y, 0) + c.pente * min(y, 0);
            case 'elu'
                y = max(y, 0) + c.alpha * (exp(min(y, 0)) - 1);
            case 'sigmoid'
                y = 1 ./ (1 + exp(-y));
            case 'tanh'
                y = tanh(y);
            case 'softmax'
                y = softmax(y);
            case 'batchnorm'
                if ~isempty(c.gamma)
                    n = size(y, 2);
                    y = repmat(c.gamma, 1, n) .* ...
                        (y - repmat(c.moyenne, 1, n)) ./ ...
                        repmat(sqrt(c.variance + c.epsilon), 1, n) + repmat(c.beta, 1, n);
                end
            otherwise
                % 'dropout', 'input', 'imageinput', 'classification',
                % 'regression' : transparentes à la prédiction.
        end
    end
end
