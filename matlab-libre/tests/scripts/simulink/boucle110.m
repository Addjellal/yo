% Le moteur en boucle PI de vitesse, Kp = 100, Ki = 200.
function boucle110(nom)
    moteur110(nom);
    delete_block([nom '/V']);
    add_block('simulink/Sources/Step', [nom '/consigne'], 'Time', '0', 'After', '1');
    add_block('simulink/Math Operations/Sum', [nom '/erreur'], 'Inputs', '+-');
    add_block('simulink/Math Operations/Gain', [nom '/Kp'], 'Gain', '100');
    add_block('simulink/Continuous/Integrator', [nom '/integrale']);
    add_block('simulink/Math Operations/Gain', [nom '/Ki'], 'Gain', '200');
    add_block('simulink/Math Operations/Sum', [nom '/u'], 'Inputs', '++');
    add_line(nom, {'consigne/1', 'erreur/1', 'erreur/1', 'integrale/1', 'Kp/1', 'Ki/1', ...
                   'u/1', 'w/1'}, ...
                  {'erreur/1', 'Kp/1', 'integrale/1', 'Ki/1', 'u/1', 'u/2', 'somme_e/1', ...
                   'erreur/2'});
end
