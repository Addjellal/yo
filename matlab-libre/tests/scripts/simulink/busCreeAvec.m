% Un Bus Creator typé TYPE, nourri de constantes aux valeurs VALEURS.
function m = busCreeAvec(type, valeurs)
    m = new_system('mauvais');
    m = add_block(m, 'buscreator', 'bc', 'Inputs', num2str(numel(valeurs)), ...
                  'OutDataTypeStr', type);
    for q = 1:numel(valeurs)
        m = add_block(m, 'constant', sprintf('c%d', q), 'Value', valeurs{q});
        m = add_line(m, sprintf('c%d/1', q), sprintf('bc/%d', q));
    end
    m = add_block(m, 'terminator', 't');
    m = add_line(m, 'bc/1', 't/1');
end
