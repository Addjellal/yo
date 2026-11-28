% Un modèle où le bloc T est seul dans un sous-système : activé,
% déclenché, itéré, masqué, ou sous une période discrète.
function m = batterieContexte(type, contexte)
    interne = new_system('dedans');
    interne = add_block(interne, type, 'b');
    [ne, ns] = matlibre_sl_ports(interne.blocs{end});
    if isnan(ne), ne = 1; end
    if isnan(ns), ns = 1; end
    for i = 1:ne
        interne = add_block(interne, 'inport', sprintf('in%d', i));
        interne = add_line(interne, sprintf('in%d/1', i), sprintf('b/%d', i));
    end
    for j = 1:ns
        interne = add_block(interne, 'outport', sprintf('out%d', j));
        interne = add_line(interne, sprintf('b/%d', j), sprintf('out%d/1', j));
    end
    switch contexte
        case 'enable'
            interne = add_block(interne, 'enableport', 'Enable');
        case 'trigger'
            interne = add_block(interne, 'triggerport', 'Trigger');
        case 'for'
            interne = add_block(interne, 'foriterator', 'iteration', 'IterationLimit', 3);
    end
    m = new_system('ctx');
    if strcmp(contexte, 'masque')
        m = add_block(m, 'subsystem', 'sous', 'Model', interne, 'Mask', 'on', ...
                      'MaskVariables', 'k=@1;', 'MaskValueString', '2');
    else
        m = add_block(m, 'subsystem', 'sous', 'Model', interne);
    end
    periode = 0;
    if strcmp(contexte, 'discret'), periode = 0.1; end
    for i = 1:ne
        m = add_block(m, 'sine', sprintf('u%d', i), 'Amplitude', 0.5, 'Bias', 1.5, ...
                      'SampleTime', periode);
        m = add_line(m, sprintf('u%d/1', i), sprintf('sous/%d', i));
    end
    switch contexte
        case 'enable'
            m = add_block(m, 'pulsegenerator', 'porte', 'Period', 0.4, 'PulseWidth', 50);
            m = add_line(m, 'porte/1', 'sous/Enable');
        case 'trigger'
            m = add_block(m, 'pulsegenerator', 'porte', 'Period', 0.2, 'PulseWidth', 50);
            m = add_line(m, 'porte/1', 'sous/Trigger');
    end
    for j = 1:ns
        m = add_block(m, 'outport', sprintf('o%d', j));
        m = add_line(m, sprintf('sous/%d', j), sprintf('o%d/1', j));
    end
end
