function [r, id, message] = aleaSimuler(m, solveur)
    r = [];
    id = '';
    message = '';
    try
        evalc('r = sim(m, ''Solver'', solveur, ''FixedStep'', 0.1, ''StopTime'', 1);');
    catch err
        id = err.identifier;
        message = err.message;
    end
end
