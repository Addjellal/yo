function aire = integrerParMorceaux(f, a, b, coupures)
    % L'intégrale d'une fonction qui casse en des instants connus : un
    % morceau lisse après l'autre.
    bornes = unique([a, coupures(coupures > a & coupures < b), b]);
    aire = 0;
    for k = 1:numel(bornes) - 1
        aire = aire + integral(f, bornes(k), bornes(k + 1), 'AbsTol', 1e-13, 'RelTol', 1e-12);
    end
end
