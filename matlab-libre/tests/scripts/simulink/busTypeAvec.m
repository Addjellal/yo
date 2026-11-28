function m = busTypeAvec(element, valeur)
    % Le bus de type Capteurs57, l'élément ELEMENT réglé à VALEUR.
    valeurs = struct('a', 'int8(5)', 'b', '2.5', 'jour', 'JourEssai.Lundi');
    valeurs.(element) = valeur;
    m = new_system('busFaux');
    m = add_block(m, 'constant', 'a', 'Value', valeurs.a);
    m = add_block(m, 'constant', 'b', 'Value', valeurs.b);
    m = add_block(m, 'constant', 'j', 'Value', valeurs.jour);
    m = add_block(m, 'buscreator', 'bc', 'Inputs', 'a,b,jour', 'OutDataTypeStr', ...
                  'Bus: Capteurs57');
    m = add_block(m, 'busselector', 'bs', 'OutputSignals', 'b');
    m = add_block(m, 'outport', 'y');
    m = add_line(add_line(add_line(m, 'a/1', 'bc/1'), 'b/1', 'bc/2'), 'j/1', 'bc/3');
    m = add_line(add_line(m, 'bc/1', 'bs/1'), 'bs/1', 'y/1');
end
