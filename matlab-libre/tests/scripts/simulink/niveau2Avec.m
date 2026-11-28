% Un modele ou une S-fonction de niveau 2, NOM, recoit PARAMETRES.
function m = niveau2Avec(nom, parametres)
    m = new_system('mauvais');
    m = add_block(m, 'constant', 'u', 'Value', 1);
    m = add_block(m, 'msfunction', 's', 'FunctionName', nom, 'Parameters', parametres);
    m = add_block(m, 'terminator', 't');
    m = add_line(m, 'u/1', 's/1');
    m = add_line(m, 's/1', 't/1');
end
