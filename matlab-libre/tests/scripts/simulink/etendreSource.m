function p = etendreSource(type, p)
    % La même source sur trois voies : chacune décalée de la précédente.
    switch type
        case 'sine'
            p = [p, {'Bias', [0; 0.2; -0.3]}];
        case 'ramp'
            p{2} = [0.7; 0.35; -0.2];
        case 'step'
            p{6} = [-0.6; 0.1; 1.2];
    end
end
