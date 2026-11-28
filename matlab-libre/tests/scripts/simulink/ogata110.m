% Ogata : G(s) = K/(s(s+1)(s+2)) en boucle fermée unitaire.
function ogata110(nom)
    new_system(nom);
    assignin(get_param(nom, 'ModelWorkspace'), 'K', 1);
    add_block('simulink/Sources/Step', [nom '/r'], 'Time', '0');
    add_block('simulink/Math Operations/Sum', [nom '/e'], 'Inputs', '+-');
    add_block('simulink/Math Operations/Gain', [nom '/K'], 'Gain', 'K');
    add_block('simulink/Continuous/Transfer Fcn', [nom '/G'], 'Numerator', '1', ...
              'Denominator', '[1 3 2 0]');
    add_block('simulink/Sinks/Out1', [nom '/y']);
    add_line(nom, {'r/1', 'e/1', 'K/1', 'G/1', 'G/1'}, {'e/1', 'K/1', 'G/1', 'y/1', 'e/2'});
end
