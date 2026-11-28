function r = enumDeux(operateur, a, b)
    % Deux constantes comparées par un opérateur relationnel.
    m = new_system('deux');
    m = add_block(m, 'constant', 'a', 'Value', a);
    m = add_block(m, 'constant', 'b', 'Value', b);
    m = add_block(m, 'relational', 'op', 'Operator', operateur);
    m = add_block(m, 'outport', 'y');
    m = add_line(m, 'a/1', 'op/1');
    m = add_line(m, 'b/1', 'op/2');
    m = add_line(m, 'op/1', 'y/1');
    r = sim(m, 'StopTime', 0.02);
end
