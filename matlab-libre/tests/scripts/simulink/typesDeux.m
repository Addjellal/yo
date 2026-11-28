% Un bloc a deux entrees, nourri de deux constantes.
function m = typesDeux(type, valeurA, valeurB, parametres)
    m = new_system('typesDeux');
    m = add_block(m, 'constant', 'a', 'Value', valeurA);
    m = add_block(m, 'constant', 'b', 'Value', valeurB);
    m = add_block(m, type, 'op', parametres{:});
    m = add_block(m, 'outport', 'y');
    m = add_line(m, 'a/1', 'op/1');
    m = add_line(m, 'b/1', 'op/2');
    m = add_line(m, 'op/1', 'y/1');
end
