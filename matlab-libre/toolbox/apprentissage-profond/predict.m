function y = predict(reseau, X)
%PREDICT Sortie d'un réseau appris.
    y = X;
    couches = reseau.couches;
    for k = 1:numel(couches)
        c = couches{k};
        switch c.type
            case 'fc'
                y = c.W * y + repmat(c.b, 1, size(y, 2));
            case 'relu'
                y = max(y, 0);
            case 'sigmoid'
                y = 1 ./ (1 + exp(-y));
            case 'tanh'
                y = tanh(y);
            case 'softmax'
                y = softmax(y);
        end
    end
end
