% Simuler, et ne tolérer que les erreurs de Simulink.
function id = batterieSimuler(s, solveur, contexte)
    id = 'ok';
    try
        evalc('sim(s, ''Solver'', solveur, ''FixedStep'', 0.1, ''StopTime'', 0.5);');
    catch err
        id = err.identifier;
        assert(strncmp(id, 'Simulink:', 9) || strncmp(id, 'Stateflow:', 10) || ...
               strncmp(id, 'Simscape:', 9), ...
               sprintf('%s (%s) : erreur interne %s : %s', contexte, solveur, id, err.message));
        assert(~isempty(strfind(err.message, [s.nom '/'])), ...
               sprintf('%s (%s) : le message ne nomme pas de bloc : %s', contexte, ...
                       solveur, err.message));
    end
end
