function m = batterieSinus(type)
    % Le bloc TYPE, ses entrées nourries de sinus continus, ses sorties vers
    % des Outport. Le retard que reçoit un Variable Transport Delay varie
    % moins vite que le temps, sans quoi ses échantillons se doubleraient.
    m = new_system('bv');
    m = add_block(m, type, 'b');
    [ne, ns] = matlibre_sl_ports(m.blocs{end});
    if isnan(ne), ne = 1; end
    if isnan(ns), ns = 1; end
    for i = 1:ne
        m = add_block(m, 'sine', sprintf('c%d', i), 'Amplitude', 0.8, 'Bias', 0.3 * i, ...
                      'Frequency', 2 * i);
        if strcmp(type, 'variabletransportdelay') && i == 2
            m = set_param(m, 'c2', 'Amplitude', 0.2, 'Bias', 0.5, 'Frequency', 2);
        end
        m = add_line(m, sprintf('c%d/1', i), sprintf('b/%d', i));
    end
    for j = 1:ns
        m = add_block(m, 'outport', sprintf('o%d', j));
        m = add_line(m, sprintf('b/%d', j), sprintf('o%d/1', j));
    end
end
