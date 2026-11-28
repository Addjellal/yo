function m = batterieType(type, valeur)
    % Le bloc TYPE, chacune de ses entrées nourrie d'une constante VALEUR,
    % chacune de ses sorties vers un Outport.
    m = new_system('bt');
    m = add_block(m, type, 'b');
    [ne, ns] = matlibre_sl_ports(m.blocs{end});
    if isnan(ne), ne = 1; end
    if isnan(ns), ns = 1; end
    for i = 1:ne
        m = add_block(m, 'constant', sprintf('c%d', i), 'Value', valeur);
        m = add_line(m, sprintf('c%d/1', i), sprintf('b/%d', i));
    end
    for j = 1:ns
        m = add_block(m, 'outport', sprintf('o%d', j));
        m = add_line(m, sprintf('b/%d', j), sprintf('o%d/1', j));
    end
end
