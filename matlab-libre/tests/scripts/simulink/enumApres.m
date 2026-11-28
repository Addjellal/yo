function r = enumApres(type, parametres)
    % Un membre de JourEssai qui entre dans un bloc de ce type.
    m = new_system('apres');
    m = add_block(m, 'constant', 'a', 'Value', 'JourEssai.Mardi');
    m = add_block(m, type, 'b', parametres{:});
    m = add_line(m, 'a/1', 'b/1');
    [~, nSorties] = matlibre_sl_ports(struct('type', type, 'nom', 'b', ...
                                             'parametres', struct(parametres{:})));
    if nSorties > 0 && ~strcmp(type, 'switchcase')
        m = add_block(m, 'outport', 'y');
        m = add_line(m, 'b/1', 'y/1');
    end
    r = sim(m, 'StopTime', 0.2);
end
