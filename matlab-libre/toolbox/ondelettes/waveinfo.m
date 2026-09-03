function texte = waveinfo(nom)
%WAVEINFO Renseignements sur une ondelette ou une famille d'ondelettes.
%   WAVEINFO affiche la liste des familles disponibles.
%   WAVEINFO(FAMILLE) décrit la famille : 'haar', 'db', 'sym', 'bior',
%   'rbio', 'meyr', 'mexh', 'morl', 'gaus', 'cgau', 'cmor', 'shan',
%   'fbsp'.
%   WAVEINFO(NOM) décrit une ondelette précise : 'db4', 'sym8',
%   'bior4.4'.
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
        lignes{end+1} = '  bior   biorthogonales splines, bior1.1 à bior4.4';
        lignes{end+1} = '  rbio   les mêmes, analyse et synthèse échangées';
        lignes{end+1} = '  meyr   Meyer (transformée continue)';
        lignes{end+1} = '  mexh   chapeau mexicain, morl Morlet';
        lignes{end+1} = '  gaus   dérivées de la gaussienne, cgau leur';
        lignes{end+1} = '         version complexe';
        lignes{end+1} = '  cmor   Morlet complexe, shan Shannon, fbsp spline';
        lignes{end+1} = '         en fréquence';
        lignes{end+1} = 'waveinfo(''db'') décrit une famille, waveinfo(''db4'')';
        lignes{end+1} = 'une ondelette précise. WAVENAMES en donne la liste.';
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
    elseif strcmp(nom, 'bior')
        lignes{end+1} = 'bior : biorthogonales splines.';
        lignes{end+1} = '  Construction de Cohen, Daubechies et Feauveau : la';
        lignes{end+1} = '  synthèse est le spline d''ordre Nr, l''analyse le';
        lignes{end+1} = '  filtre d''ordre Nd qui complète le demi-bande. Les';
        lignes{end+1} = '  deux filtres sont symétriques, ce qu''aucune';
        lignes{end+1} = '  orthogonale à support compact n''est sauf Haar ;';
        lignes{end+1} = '  en échange, le banc n''est pas orthogonal.';
        lignes{end+1} = '  Noms : bior1.1, 1.3, 1.5, 2.2, 2.4, 2.6, 2.8,';
        lignes{end+1} = '  3.1, 3.3, 3.5, 3.7, 3.9, 4.4 — cette dernière';
        lignes{end+1} = '  étant le couple 9/7 de JPEG 2000.';
    elseif strcmp(nom, 'rbio')
        lignes{end+1} = 'rbio : biorthogonales splines inversées.';
        lignes{end+1} = '  Les mêmes que bior, analyse et synthèse';
        lignes{end+1} = '  échangées : la régularité passe du côté de';
        lignes{end+1} = '  l''analyse. Noms : rbio1.1 à rbio4.4.';
    elseif strcmp(nom, 'meyr') || strcmp(nom, 'meyer')
        lignes{end+1} = 'meyr : ondelette de Meyer.';
        lignes{end+1} = '  Définie par sa transformée de Fourier, à support';
        lignes{end+1} = '  borné et infiniment dérivable. Elle n''est pas à';
        lignes{end+1} = '  support compact mais décroît plus vite que toute';
        lignes{end+1} = '  puissance : le compromis inverse de Daubechies.';
    elseif strcmp(nom, 'cgau')
        lignes{end+1} = 'cgau : gaussiennes complexes.';
        lignes{end+1} = '  Dérivées de exp(-i x) exp(-x^2), ordres 1 à 8. La';
        lignes{end+1} = '  modulation rend la transformée analytique : module';
        lignes{end+1} = '  et phase se lisent séparément.';
    elseif strcmp(nom, 'cmor')
        lignes{end+1} = 'cmor : Morlet complexe.';
        lignes{end+1} = '  Gaussienne modulée, réglée par sa largeur de bande';
        lignes{end+1} = '  et sa fréquence centrale : c''est le compromis';
        lignes{end+1} = '  temps-fréquence qu''on règle directement.';
    elseif strcmp(nom, 'shan')
        lignes{end+1} = 'shan : ondelette de Shannon.';
        lignes{end+1} = '  Sa transformée est une porte : support en fréquence';
        lignes{end+1} = '  exact, décroissance en 1/x en temps.';
    elseif strcmp(nom, 'fbsp')
        lignes{end+1} = 'fbsp : spline en fréquence.';
        lignes{end+1} = '  La porte de Shannon convolée M fois par elle-même :';
        lignes{end+1} = '  support en fréquence borné, bords adoucis.';
    elseif numel(nom) > 4 && (strcmp(nom(1:4), 'bior') || strcmp(nom(1:4), 'rbio'))
        lignes = descriptionBiorthogonale(nom);
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

function lignes = descriptionBiorthogonale(nom)
%DESCRIPTIONBIORTHOGONALE Fiche d'une biorthogonale nommée.
    lignes = {};
    try
        [RF, DF] = wavefiltresNommes(nom);
    catch err
        lignes{end+1} = sprintf('%s : %s', nom, err.message);
        return
    end
    lignes{end+1} = sprintf('%s : biorthogonale spline.', nom);
    lignes{end+1} = sprintf('  Synthèse %d coefficients, analyse %d.', ...
                            nombreUtile(RF), nombreUtile(DF));
    lignes{end+1} = '  Filtres symétriques, reconstruction parfaite, banc';
    lignes{end+1} = '  non orthogonal.';
end

function [RF, DF] = wavefiltresNommes(nom)
    if strcmp(nom(1:4), 'bior')
        [RF, DF] = biorwavf(nom);
    else
        [RF, DF] = rbiowavf(nom);
    end
end

function n = nombreUtile(f)
%NOMBREUTILE Coefficients non nuls, zéros de complètement exclus.
    garde = abs(f) > 1e-12;
    n = find(garde, 1, 'last') - find(garde, 1) + 1;
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
