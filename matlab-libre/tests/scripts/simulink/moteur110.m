% --- section 110 : les modèles de la littérature, bâtis sous la forme de MATLAB

% Le moteur à courant continu de Control Tutorials for MATLAB and Simulink
% (DC Motor Speed: Simulink Modeling) : J dw/dt = K i - b w,
% L di/dt = V - R i - K w.
function moteur110(nom)
    new_system(nom);
    espace = get_param(nom, 'ModelWorkspace');
    assignin(espace, 'J', 0.01);
    assignin(espace, 'b', 0.1);
    assignin(espace, 'K', 0.01);
    assignin(espace, 'R', 1);
    assignin(espace, 'L', 0.5);
    add_block('simulink/Sources/Step', [nom '/V'], 'Time', '0', 'After', '1');
    add_block('simulink/Math Operations/Sum', [nom '/somme_e'], 'Inputs', '+--');
    add_block('simulink/Math Operations/Gain', [nom '/1_L'], 'Gain', '1/L');
    add_block('simulink/Continuous/Integrator', [nom '/i']);
    add_block('simulink/Math Operations/Gain', [nom '/R'], 'Gain', 'R');
    add_block('simulink/Math Operations/Gain', [nom '/Kt'], 'Gain', 'K');
    add_block('simulink/Math Operations/Sum', [nom '/somme_m'], 'Inputs', '+-');
    add_block('simulink/Math Operations/Gain', [nom '/1_J'], 'Gain', '1/J');
    add_block('simulink/Continuous/Integrator', [nom '/w']);
    add_block('simulink/Math Operations/Gain', [nom '/b'], 'Gain', 'b');
    add_block('simulink/Math Operations/Gain', [nom '/Ke'], 'Gain', 'K');
    add_block('simulink/Sinks/Out1', [nom '/vitesse']);
    add_line(nom, {'V/1', 'somme_e/1', '1_L/1', 'i/1', 'i/1', 'R/1', 'Kt/1', 'somme_m/1', ...
                   '1_J/1', 'w/1', 'w/1', 'b/1', 'w/1', 'Ke/1'}, ...
                  {'somme_e/1', '1_L/1', 'i/1', 'R/1', 'Kt/1', 'somme_e/2', 'somme_m/1', ...
                   '1_J/1', 'w/1', 'b/1', 'vitesse/1', 'somme_m/2', 'Ke/1', 'somme_e/3'});
end
