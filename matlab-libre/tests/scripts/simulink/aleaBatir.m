% Un modèle de la batterie au hasard : les blocs en chaîne, leurs entrées
% de plus nourries de constantes, leurs sorties de plus relevées.
function [m, texte] = aleaBatir(nom, types, cat)
    m = new_system(nom);
    texte = '';
    valeurEntree = 1.5;
    typeEntree = {};
    tirage = rand();
    if tirage < 0.3
        valeurEntree = [0.5; 1.5; 2.5];
        texte = ' entrees=vecteur';
    elseif tirage < 0.45
        valeurEntree = 1.5 - 0.5i;   % un complexe, que bien des blocs refusent
        texte = ' entrees=complexe';
    elseif tirage < 0.6
        typeEntree = {'OutDataTypeStr', 'fixdt(1,16,8)'};   % à virgule fixe
        texte = ' entrees=sfix16_En8';
    end
    for q = 1:numel(types)
        e = cat(strcmp({cat.type}, types{q}));
        reglages = {};
        for i = 1:size(e.params, 1)
            nature = e.params{i, 3};
            if iscell(nature) && rand() < 0.4
                valeur = nature{randi(numel(nature))};
                reglages(end + 1:end + 2) = {e.params{i, 1}, valeur}; %#ok<AGROW>
                texte = sprintf('%s %s.%s=%s', texte, types{q}, e.params{i, 1}, valeur);
            elseif strcmp(nature, 'nombre') && isnumeric(e.params{i, 2}) && ...
                   isscalar(e.params{i, 2}) && rand() < 0.15
                genantes = {0, -1, 2, 0.5, [1 2], 1i};
                valeur = genantes{randi(numel(genantes))};
                reglages(end + 1:end + 2) = {e.params{i, 1}, valeur}; %#ok<AGROW>
                texte = sprintf('%s %s.%s=%s', texte, types{q}, e.params{i, 1}, mat2str(valeur));
            end
        end
        m = add_block(m, types{q}, sprintf('b%d', q), reglages{:});
    end
    for q = 1:numel(types)
        [ne, ns] = matlibre_sl_ports(m.blocs{q});
        if isnan(ne), ne = 1; end
        if isnan(ns), ns = 1; end
        for i = 1 + (q > 1):ne
            source = sprintf('c%d_%d', q, i);
            m = add_block(m, 'constant', source, 'Value', valeurEntree, typeEntree{:});
            m = add_line(m, [source '/1'], sprintf('b%d/%d', q, i));
        end
        for j = 1 + (q < numel(types)):ns
            puits = sprintf('o%d_%d', q, j);
            m = add_block(m, 'outport', puits);
            m = add_line(m, sprintf('b%d/%d', q, j), [puits '/1']);
        end
        if q < numel(types)
            [ne2, ~] = matlibre_sl_ports(m.blocs{q + 1});
            [~, nsq] = matlibre_sl_ports(m.blocs{q});
            if (isnan(ne2) || ne2 >= 1) && (isnan(nsq) || nsq >= 1)
                m = add_line(m, sprintf('b%d/1', q), sprintf('b%d/1', q + 1));
            end
        end
    end
end
