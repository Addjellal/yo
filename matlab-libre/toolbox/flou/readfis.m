function fis = readfis(nomFichier)
%READFIS Lit un système d'inférence floue depuis un fichier .fis.
%   FIS = READFIS(NOMFICHIER) relit le format texte de MathWorks. Les
%   sections inconnues sont ignorées, ce qui rend la lecture tolérante aux
%   fichiers écrits par des versions plus récentes.
%
%   Exemple :
%      fis = readfis('pilote.fis');
%
%   Voir aussi WRITEFIS, NEWFIS.
    nomFichier = char(nomFichier);
    if numel(nomFichier) < 4 || ~strcmpi(nomFichier(end-3:end), '.fis')
        nomFichier = [nomFichier '.fis'];
    end
    fid = fopen(nomFichier, 'r');
    if fid < 0
        error('fuzzy:readfis:CannotOpen', 'Impossible de lire %s.', nomFichier);
    end
    fis = newfis('fis');
    section = '';
    indiceVariable = 0;
    entreeCourante = true;
    entrees = {};
    sorties = {};
    regles = [];
    while true
        ligne = fgetl(fid);
        if ~ischar(ligne), break, end
        ligne = strtrim(ligne);
        if isempty(ligne) || ligne(1) == '%'
            continue
        end
        if ligne(1) == '['
            section = lower(ligne(2:end-1));
            [entreeCourante, indiceVariable] = analyserSection(section, entrees, sorties);
            if strncmp(section, 'input', 5)
                entrees{indiceVariable} = variableVide();      %#ok<AGROW>
            elseif strncmp(section, 'output', 6)
                sorties{indiceVariable} = variableVide();      %#ok<AGROW>
            end
            continue
        end
        if strcmp(section, 'rules')
            regles = [regles; analyserRegle(ligne)];           %#ok<AGROW>
            continue
        end
        [cle, valeur] = separerCle(ligne);
        if isempty(cle), continue, end
        if strcmp(section, 'system')
            fis = appliquerSysteme(fis, cle, valeur);
        elseif entreeCourante && indiceVariable > 0
            entrees{indiceVariable} = appliquerVariable(entrees{indiceVariable}, cle, valeur);
        elseif indiceVariable > 0
            sorties{indiceVariable} = appliquerVariable(sorties{indiceVariable}, cle, valeur);
        end
    end
    fclose(fid);
    fis.entrees = entrees;
    fis.sorties = sorties;
    fis.regles = regles;
end

function v = variableVide()
    v = struct('nom', '', 'intervalle', [0 1], 'mf', {{}});
end

function [entree, indice] = analyserSection(section, entrees, sorties)
    entree = true;
    indice = 0;
    if strncmp(section, 'input', 5)
        indice = str2double(section(6:end));
        if isnan(indice), indice = numel(entrees) + 1; end
    elseif strncmp(section, 'output', 6)
        entree = false;
        indice = str2double(section(7:end));
        if isnan(indice), indice = numel(sorties) + 1; end
    end
end

function [cle, valeur] = separerCle(ligne)
    position = find(ligne == '=', 1);
    if isempty(position)
        cle = '';
        valeur = '';
        return
    end
    cle = lower(strtrim(ligne(1:position-1)));
    valeur = strtrim(ligne(position+1:end));
end

function fis = appliquerSysteme(fis, cle, valeur)
    texte = retirerApostrophes(valeur);
    switch cle
        case 'name',         fis.nom = texte;
        case 'type',         fis.type = lower(texte);
        case 'andmethod',    fis.et = lower(texte);
        case 'ormethod',     fis.ou = lower(texte);
        case 'impmethod',    fis.implication = lower(texte);
        case 'aggmethod',    fis.agregation = lower(texte);
        case 'defuzzmethod', fis.defuzzification = lower(texte);
    end
end

function v = appliquerVariable(v, cle, valeur)
    if strcmp(cle, 'name')
        v.nom = retirerApostrophes(valeur);
    elseif strcmp(cle, 'range')
        v.intervalle = lireVecteur(valeur);
    elseif numel(cle) > 2 && strcmp(cle(1:2), 'mf')
        v.mf{end+1} = analyserMf(valeur);
    end
end

function mf = analyserMf(valeur)
%ANALYSERMF Décode « 'nom':'type',[p1 p2 ...] ».
    virgule = find(valeur == ',', 1);
    tete = valeur(1:virgule-1);
    queue = valeur(virgule+1:end);
    separateur = find(tete == ':', 1);
    mf = struct('nom', retirerApostrophes(tete(1:separateur-1)), ...
                'type', lower(retirerApostrophes(tete(separateur+1:end))), ...
                'parametres', lireVecteur(queue));
end

function regle = analyserRegle(ligne)
%ANALYSERREGLE Décode « 1 1, 1 (1) : 1 ».
    ligne = strrep(ligne, ',', ' ');
    poids = 1;
    debutPoids = find(ligne == '(', 1);
    finPoids = find(ligne == ')', 1);
    if ~isempty(debutPoids) && ~isempty(finPoids)
        poids = str2double(ligne(debutPoids+1:finPoids-1));
        ligne = [ligne(1:debutPoids-1), ' ', ligne(finPoids+1:end)];
    end
    connecteur = 1;
    deuxPoints = find(ligne == ':', 1);
    if ~isempty(deuxPoints)
        connecteur = str2double(strtrim(ligne(deuxPoints+1:end)));
        ligne = ligne(1:deuxPoints-1);
    end
    indices = sscanf(ligne, '%f')';
    regle = [indices, poids, connecteur];
end

function texte = retirerApostrophes(texte)
    texte = strtrim(char(texte));
    if numel(texte) >= 2 && texte(1) == '''' && texte(end) == ''''
        texte = texte(2:end-1);
    end
end

function v = lireVecteur(texte)
    texte = strrep(strrep(char(texte), '[', ' '), ']', ' ');
    v = sscanf(texte, '%f')';
end
