function m = batterieCadence(type, periode)
    % Le bloc TYPE, ses entrées nourries de sinus échantillonnés à PERIODE,
    % ses sorties vers des Outport.
    m = new_system('bc');
    m = add_block(m, type, 'b');
    [ne, ns] = matlibre_sl_ports(m.blocs{end});
    if isnan(ne), ne = 1; end
    if isnan(ns), ns = 1; end
    for i = 1:ne
        m = add_block(m, 'sine', sprintf('c%d', i), 'Amplitude', 0.5, 'Bias', 1.5, ...
                      'Frequency', 2 * i, 'SampleTime', periode);
        m = add_line(m, sprintf('c%d/1', i), sprintf('b/%d', i));
    end
    for j = 1:ns
        m = add_block(m, 'outport', sprintf('o%d', j));
        m = add_line(m, sprintf('b/%d', j), sprintf('o%d/1', j));
    end
end
