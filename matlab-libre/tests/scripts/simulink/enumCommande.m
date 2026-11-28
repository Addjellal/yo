function r = enumCommande(ordre, indices)
    % Un Multiport Switch commandé par JourEssai.Mardi.
    m = new_system('multi');
    m = add_block(m, 'constant', 'j', 'Value', 'JourEssai.Mardi');
    m = add_block(m, 'constant', 'a', 'Value', 10);
    m = add_block(m, 'constant', 'b', 'Value', 20);
    m = add_block(m, 'multiportswitch', 'ms', 'Inputs', 2, 'DataPortOrder', ordre, ...
                  'DataPortIndices', indices);
    m = add_block(m, 'outport', 'y');
    m = add_line(m, 'j/1', 'ms/1');
    m = add_line(m, 'a/1', 'ms/2');
    m = add_line(m, 'b/1', 'ms/3');
    m = add_line(m, 'ms/1', 'y/1');
    r = sim(m, 'StopTime', 0.02);
end
