% L'oscillateur de Van der Pol : x1' = x2, x2' = mu (1 - x1^2) x2 - x1.
function vdp110(nom)
    new_system(nom);
    assignin(get_param(nom, 'ModelWorkspace'), 'mu', 1);
    add_block('simulink/Continuous/Integrator', [nom '/x2'], 'InitialCondition', '0');
    add_block('simulink/Continuous/Integrator', [nom '/x1'], 'InitialCondition', '2');
    add_block('simulink/Math Operations/Product', [nom '/carre']);
    add_block('simulink/Sources/Constant', [nom '/un'], 'Value', '1');
    add_block('simulink/Math Operations/Sum', [nom '/s1'], 'Inputs', '+-');
    add_block('simulink/Math Operations/Product', [nom '/p']);
    add_block('simulink/Math Operations/Gain', [nom '/mu'], 'Gain', 'mu');
    add_block('simulink/Math Operations/Sum', [nom '/s2'], 'Inputs', '+-');
    add_block('simulink/Sinks/Out1', [nom '/y1']);
    add_block('simulink/Sinks/Out1', [nom '/y2']);
    add_line(nom, {'x2/1', 'x1/1', 'x1/1', 'un/1', 'carre/1', 's1/1', 'x2/1', 'p/1', 'mu/1', ...
                   'x1/1', 's2/1', 'x1/1', 'x2/1'}, ...
                  {'x1/1', 'carre/1', 'carre/2', 's1/1', 's1/2', 'p/1', 'p/2', 'mu/1', 's2/1', ...
                   's2/2', 'x2/1', 'y1/1', 'y2/1'});
end
