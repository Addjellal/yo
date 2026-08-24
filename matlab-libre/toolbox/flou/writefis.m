function writefis(fis, nomFichier)
%WRITEFIS Écrit un système d'inférence floue dans un fichier .fis.
%   WRITEFIS(FIS,NOMFICHIER) écrit le format texte de MathWorks : une
%   section [System], une section par variable, et une section [Rules].
%   L'extension .fis est ajoutée si elle manque.
%
%   Le format est lisible et se relit par READFIS, ce qui donne un moyen
%   simple de conserver un système entre deux sessions.
%
%   Exemple :
%      writefis(fis, 'pilote.fis');
%      memeFis = readfis('pilote.fis');
%
%   Voir aussi READFIS, NEWFIS.
    nomFichier = char(nomFichier);
    if numel(nomFichier) < 4 || ~strcmpi(nomFichier(end-3:end), '.fis')
        nomFichier = [nomFichier '.fis'];
    end
    fid = fopen(nomFichier, 'w');
    if fid < 0
        error('fuzzy:writefis:CannotOpen', 'Impossible d''écrire %s.', nomFichier);
    end
    fprintf(fid, '[System]\n');
    fprintf(fid, 'Name=''%s''\n', fis.nom);
    fprintf(fid, 'Type=''%s''\n', fis.type);
    fprintf(fid, 'Version=2.0\n');
    fprintf(fid, 'NumInputs=%d\n', numel(fis.entrees));
    fprintf(fid, 'NumOutputs=%d\n', numel(fis.sorties));
    fprintf(fid, 'NumRules=%d\n', size(fis.regles, 1));
    fprintf(fid, 'AndMethod=''%s''\n', fis.et);
    fprintf(fid, 'OrMethod=''%s''\n', fis.ou);
    fprintf(fid, 'ImpMethod=''%s''\n', fis.implication);
    fprintf(fid, 'AggMethod=''%s''\n', fis.agregation);
    fprintf(fid, 'DefuzzMethod=''%s''\n', fis.defuzzification);
    ecrireVariables(fid, fis.entrees, 'Input');
    ecrireVariables(fid, fis.sorties, 'Output');
    fprintf(fid, '\n[Rules]\n');
    nEntrees = numel(fis.entrees);
    nSorties = numel(fis.sorties);
    for r = 1:size(fis.regles, 1)
        regle = fis.regles(r, :);
        poids = 1;
        connecteur = 1;
        if numel(regle) >= nEntrees + nSorties + 1, poids = regle(nEntrees + nSorties + 1); end
        if numel(regle) >= nEntrees + nSorties + 2, connecteur = regle(nEntrees + nSorties + 2); end
        fprintf(fid, '%s, %s (%g) : %d\n', ...
                joindreEntiers(regle(1:nEntrees)), ...
                joindreEntiers(regle(nEntrees + 1:nEntrees + nSorties)), ...
                poids, connecteur);
    end
    fclose(fid);
end

function ecrireVariables(fid, variables, etiquette)
    for k = 1:numel(variables)
        v = variables{k};
        fprintf(fid, '\n[%s%d]\n', etiquette, k);
        fprintf(fid, 'Name=''%s''\n', v.nom);
        fprintf(fid, 'Range=[%s]\n', joindreReels(v.intervalle));
        fprintf(fid, 'NumMFs=%d\n', numel(v.mf));
        for j = 1:numel(v.mf)
            mf = v.mf{j};
            fprintf(fid, 'MF%d=''%s'':''%s'',[%s]\n', ...
                    j, mf.nom, mf.type, joindreReels(mf.parametres));
        end
    end
end

function texte = joindreEntiers(v)
    morceaux = cell(1, numel(v));
    for k = 1:numel(v)
        morceaux{k} = sprintf('%d', round(v(k)));
    end
    texte = strjoin(morceaux, ' ');
end

function texte = joindreReels(v)
    morceaux = cell(1, numel(v));
    for k = 1:numel(v)
        morceaux{k} = sprintf('%g', v(k));
    end
    texte = strjoin(morceaux, ' ');
end
