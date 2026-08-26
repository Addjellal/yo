function [classes, scores] = classify(reseau, X)
%CLASSIFY Classe de plus forte probabilité pour chaque observation.
    scores = predict(reseau, X);
    [~, classes] = max(scores, [], 1);
    classes = classes(:);
end
