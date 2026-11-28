function m = busEmboiteAvec(a)
    % Des bus emboîtés dont l'élément interne.a vaut A (un double).
    m = new_system('emboiteFaux');
    m = add_block(m, 'constant', 'a', 'Value', a);
    m = add_block(m, 'constant', 'b', 'Value', 2.5);
    m = add_block(m, 'constant', 'j', 'Value', 'JourEssai.Lundi');
    m = add_block(m, 'constant', 'c', 'Value', 7);
    m = add_block(m, 'buscreator', 'dedans', 'Inputs', 'a,b,jour');
    m = add_block(m, 'buscreator', 'dehors', 'Inputs', 'interne,c');
    m = add_block(m, 'busselector', 'bs', 'OutputSignals', 'c');
    m = add_block(m, 'outport', 'y');
    m = add_line(add_line(add_line(m, 'a/1', 'dedans/1'), 'b/1', 'dedans/2'), 'j/1', 'dedans/3');
    m = add_line(add_line(m, 'dedans/1', 'dehors/1'), 'c/1', 'dehors/2');
    m = add_line(add_line(m, 'dehors/1', 'bs/1'), 'bs/1', 'y/1');
end
