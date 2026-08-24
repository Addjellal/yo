function texte = waveinfo(nom)
%WAVEINFO Renseignements sur une ondelette ou une famille d'ondelettes.
%   WAVEINFO affiche la liste des familles disponibles.
%   WAVEINFO(FAMILLE) décrit la famille : 'haar', 'db', 'sym'.
%   WAVEINFO(NOM) décrit une ondelette précise : 'db4', 'sym8'.
%   T = WAVEINFO(...) rend le texte au lieu de l'afficher.
%
%   Exemples :
%      waveinfo
%      waveinfo('db')
%      waveinfo('db4')
%
%   Voir aussi WFILTERS, WAVEFUN, CENTFRQ.
    if nargin < 1 || isempty(nom), nom = ''; end
    nom = lower(strtrim(char(nom)));
    lignes = {};
    if isempty(nom)
        lignes{end+1} = 'Familles d''ondelettes disponibles :';
        lignes{end+1} = '  haar   ondelette de Haar (= db1)';
        lignes{end+1} = '  db     Daubechies, db1 à db45';
        lignes{end+1} = '  sym    symlets, sym1 à sym45';
        lignes{end+1} = 'waveinfo(''db'') décrit une famille, waveinfo(''db4'')';
        lignes{end+1} = 'une ondelette précise.';
    elseif strcmp(nom, 'haar') || strcmp(nom, 'db1')
        lignes{end+1} = 'haar : ondelette de Haar, la plus ancienne (1909).';
        lignes{end+1} = '  Support 1, un moment nul, symétrique, orthogonale.';
        lignes{end+1} = '  C''est la db1 : deux coefficients, [1 1]/sqrt(2).';
    elseif strcmp(nom, 'db')
        lignes{end+1} = 'db : ondelettes de Daubechies.';
        lignes{end+1} = '  Famille orthogonale à support compact, indexée par';
        lignes{end+1} = '  l''ordre N : dbN a 2N coefficients, un support de';
        lignes{end+1} = '  longueur 2N-1 et N moments nuls. C''est la solution';
        lignes{end+1} = '  à phase minimale de la factorisation spectrale du';
        lignes{end+1} = '  polynôme de Daubechies. db1 est la seule symétrique.';
        lignes{end+1} = '  Noms : db1 (= haar), db2, db3, ...';
    elseif strcmp(nom, 'sym')
        lignes{end+1} = 'sym : symlets.';
        lignes{end+1} = '  Même construction que les Daubechies, mais on choisit';
        lignes{end+1} = '  parmi les factorisations spectrales celle dont la';
        lignes{end+1} = '  phase s''écarte le moins de la linéarité : le filtre';
        lignes{end+1} = '  est presque symétrique. Support et moments nuls sont';
        lignes{end+1} = '  ceux de dbN. Noms : sym1, sym2, sym3, ...';
    elseif numel(nom) > 2 && strcmp(nom(1:2), 'db') && ~isnan(str2double(nom(3:end)))
        ordre = str2double(nom(3:end));
        lignes = descriptionOndelette(nom, ordre, ...
            '  Orthogonale, à phase minimale, non symétrique sauf db1.');
    elseif numel(nom) > 3 && strcmp(nom(1:3), 'sym') && ~isnan(str2double(nom(4:end)))
        ordre = str2double(nom(4:end));
        lignes = descriptionOndelette(nom, ordre, ...
            '  Orthogonale, presque symétrique : la moins asymétrique des');
        lignes{end+1} = '  factorisations spectrales de même support.';
    else
        lignes{end+1} = sprintf('%s : famille inconnue.', nom);
    end
    resultat = strjoin(lignes, sprintf('\n'));
    if nargout > 0
        texte = resultat;
    else
        disp(resultat);
    end
end

function lignes = descriptionOndelette(nom, ordre, remarque)
    if strncmp(nom, 'sym', 3)
        famille = 'symlet';
    else
        famille = 'ondelette de Daubechies';
    end
    lignes = {};
    lignes{end+1} = sprintf('%s : %s d''ordre %d.', nom, famille, ordre);
    lignes{end+1} = sprintf('  Support [0, %d], %d moments nuls, %d coefficients.', ...
                            2 * ordre - 1, ordre, 2 * ordre);
    lignes{end+1} = sprintf('  Fréquence centrale %.4f Hz par unité de support.', centfrq(nom));
    lignes{end+1} = remarque;
end
