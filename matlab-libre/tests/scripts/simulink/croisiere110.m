% Le régulateur de vitesse de Control Tutorials (Cruise Control), PI et
% capteur du premier ordre dans le retour.
function croisiere110(nom)
    new_system(nom);
    espace = get_param(nom, 'ModelWorkspace');
    assignin(espace, 'm', 1000);
    assignin(espace, 'b', 50);
    assignin(espace, 'r', 10);
    add_block('simulink/Sources/Step', [nom '/consigne'], 'Time', '0', 'After', 'r');
    add_block('simulink/Math Operations/Sum', [nom '/erreur'], 'Inputs', '+-');
    add_block('simulink/Math Operations/Gain', [nom '/Kp'], 'Gain', '800');
    add_block('simulink/Continuous/Integrator', [nom '/integrale']);
    add_block('simulink/Math Operations/Gain', [nom '/Ki'], 'Gain', '40');
    add_block('simulink/Math Operations/Sum', [nom '/u'], 'Inputs', '++');
    add_block('simulink/Continuous/Transfer Fcn', [nom '/voiture'], 'Numerator', '1', ...
              'Denominator', '[m b]');
    add_block('simulink/Continuous/Transfer Fcn', [nom '/capteur'], 'Numerator', '1', ...
              'Denominator', '[0.5 1]');
    add_block('simulink/Sinks/Out1', [nom '/vitesse']);
    add_line(nom, {'consigne/1', 'erreur/1', 'erreur/1', 'integrale/1', 'Kp/1', 'Ki/1', ...
                   'u/1', 'voiture/1', 'voiture/1', 'capteur/1'}, ...
                  {'erreur/1', 'Kp/1', 'integrale/1', 'Ki/1', 'u/1', 'u/2', 'voiture/1', ...
                   'vitesse/1', 'capteur/1', 'erreur/2'});
end
