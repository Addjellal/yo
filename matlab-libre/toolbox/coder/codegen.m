function code = codegen(nomFonction, fichierSortie)
%CODEGEN Traduit une fonction MATLAB scalaire en C.
%   CODE = CODEGEN('nom') rend le texte du fichier C.
%   CODEGEN('nom','sortie.c') l'écrit sur disque.
    chemin = which(nomFonction);
    if isempty(chemin) || ~isempty(strfind(chemin, 'not found'))
        error('coder:codegen:notFound', 'Function ''%s'' not found.', nomFonction);
    end
    source = fileread(chemin);
    lignes = strsplit(source, sprintf('\n'));
    entete = '';
    corps = {};
    entrees = {};
    sortie = '';
    for k = 1:numel(lignes)
        ligne = strtrim(lignes{k});
        if isempty(ligne) || ligne(1) == '%'
            continue;
        end
        if isempty(entete) && strncmp(ligne, 'function', 8)
            entete = ligne;
            [sortie, entrees] = analyserEntete(ligne);
            continue;
        end
        if strcmp(ligne, 'end')
            continue;
        end
        corps{end+1} = ligne;
    end
    code = sprintf('/* Genere par MatLibre Coder a partir de %s */\n', chemin);
    code = [code sprintf('#include <math.h>\n\n')];
    signature = sprintf('double %s(', nomFonction);
    for k = 1:numel(entrees)
        if k > 1
            signature = [signature ', '];
        end
        signature = [signature sprintf('double %s', entrees{k})];
    end
    signature = [signature ')'];
    code = [code signature sprintf('\n{\n')];
    declarees = entrees;
    corpsC = '';
    profondeur = 1;
    for k = 1:numel(corps)
        [texte, declarees, profondeur] = traduire(corps{k}, declarees, profondeur, sortie);
        corpsC = [corpsC texte];
    end
    code = [code corpsC];
    code = [code sprintf('    return %s;\n}\n', sortie)];
    if nargin > 1
        fid = fopen(fichierSortie, 'w');
        fprintf(fid, '%s', code);
        fclose(fid);
    end
end

function [sortie, entrees] = analyserEntete(ligne)
    reste = strtrim(ligne(9:end));
    egal = strfind(reste, '=');
    if isempty(egal)
        sortie = 'resultat';
        appel = reste;
    else
        sortie = strtrim(reste(1:egal(1)-1));
        sortie = strrep(strrep(sortie, '[', ''), ']', '');
        appel = strtrim(reste(egal(1)+1:end));
    end
    ouvrante = strfind(appel, '(');
    entrees = {};
    if ~isempty(ouvrante)
        fermante = strfind(appel, ')');
        listeArguments = appel(ouvrante(1)+1:fermante(end)-1);
        morceaux = strsplit(listeArguments, ',');
        for k = 1:numel(morceaux)
            m = strtrim(morceaux{k});
            if ~isempty(m)
                entrees{end+1} = m;
            end
        end
    end
end

function [texte, declarees, profondeur] = traduire(ligne, declarees, profondeur, sortie)
    indentation = repmat('    ', 1, profondeur);
    ligne = regexprep(ligne, '%.*$', '');
    ligne = strtrim(ligne);
    if isempty(ligne)
        texte = '';
        return;
    end
    if ~isempty(ligne) && ligne(end) == ';'
        ligne = ligne(1:end-1);
    end
    if strncmp(ligne, 'if ', 3)
        texte = sprintf('%sif (%s) {\n', indentation, expression(ligne(4:end)));
        profondeur = profondeur + 1;
        return;
    end
    if strcmp(ligne, 'else')
        texte = sprintf('%s} else {\n', repmat('    ', 1, profondeur - 1));
        return;
    end
    if strncmp(ligne, 'elseif ', 7)
        texte = sprintf('%s} else if (%s) {\n', repmat('    ', 1, profondeur - 1), ...
                        expression(ligne(8:end)));
        return;
    end
    if strncmp(ligne, 'while ', 6)
        texte = sprintf('%swhile (%s) {\n', indentation, expression(ligne(7:end)));
        profondeur = profondeur + 1;
        return;
    end
    if strncmp(ligne, 'for ', 4)
        reste = ligne(5:end);
        egal = strfind(reste, '=');
        variable = strtrim(reste(1:egal(1)-1));
        plage = strtrim(reste(egal(1)+1:end));
        bornes = strsplit(plage, ':');
        if numel(bornes) == 2
            texte = sprintf('%sfor (int %s = %s; %s <= %s; %s++) {\n', indentation, ...
                            variable, strtrim(bornes{1}), variable, strtrim(bornes{2}), variable);
        else
            texte = sprintf('%sfor (int %s = %s; %s <= %s; %s += %s) {\n', indentation, ...
                            variable, strtrim(bornes{1}), variable, strtrim(bornes{3}), ...
                            variable, strtrim(bornes{2}));
        end
        profondeur = profondeur + 1;
        return;
    end
    if strcmp(ligne, 'end')
        profondeur = max(1, profondeur - 1);
        texte = sprintf('%s}\n', repmat('    ', 1, profondeur));
        return;
    end
    egal = strfind(ligne, '=');
    if ~isempty(egal) && (numel(ligne) <= egal(1) || ligne(egal(1)+1) ~= '=')
        cible = strtrim(ligne(1:egal(1)-1));
        valeur = expression(strtrim(ligne(egal(1)+1:end)));
        if any(strcmp(declarees, cible))
            texte = sprintf('%s%s = %s;\n', indentation, cible, valeur);
        else
            declarees{end+1} = cible;
            texte = sprintf('%sdouble %s = %s;\n', indentation, cible, valeur);
        end
        return;
    end
    texte = sprintf('%s/* non traduit : %s */\n', indentation, ligne);
end

function e = expression(texte)
    e = strtrim(texte);
    e = strrep(e, '.^', '^');
    e = regexprep(e, '(\w+|\([^()]*\))\s*\^\s*(\w+|\([^()]*\))', 'pow($1, $2)');
    e = strrep(e, '.*', '*');
    e = strrep(e, './', '/');
    e = strrep(e, '~=', '!=');
    e = strrep(e, '&&', '&&');
    e = strrep(e, '||', '||');
end
