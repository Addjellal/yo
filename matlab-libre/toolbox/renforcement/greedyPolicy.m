function politique = greedyPolicy(Q)
%GREEDYPOLICY Action de valeur maximale dans chaque état.
    [~, politique] = max(Q, [], 2);
end
