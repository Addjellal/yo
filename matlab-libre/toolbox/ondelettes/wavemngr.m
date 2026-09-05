function varargout = wavemngr(action, varargin)
%WAVEMNGR Gestion des familles d'ondelettes.
%   WAVEMNGR('read') affiche les familles connues.
%   T = WAVEMNGR('read') les rend dans une chaîne.
%   T = WAVEMNGR('read',1) y ajoute le nom de chaque ondelette.
%
%   WAVEMNGR('add',NOM,ABREGE,TYPE,ORDRES,FICHIER) ajoute une famille.
%      NOM       nom complet, par exemple 'MonOndelette'
%      ABREGE    préfixe des noms, par exemple 'mond'
%      TYPE      1 orthogonale, 2 biorthogonale, 3 à fonction d'échelle
%                sans orthogonalité, 4 sans fonction d'échelle,
%                5 complexe sans fonction d'échelle
%      ORDRES    liste des ordres, '1 2 3' ou '**' pour tout entier
%      FICHIER   nom d'une fonction rendant le filtre d'échelle, appelée
%                comme FICHIER(NOM) ; pour un type 2 elle rend deux
%                filtres, décomposition puis reconstruction
%
%   WAVEMNGR('del',ABREGE) retire une famille ajoutée.
%   WAVEMNGR('restore') revient aux seules familles d'origine.
%   T = WAVEMNGR('type',NOM) rend le type de l'ondelette NOM.
%   S = WAVEMNGR('fields',NOM) rend, dans une structure, le nom complet,
%   l'abrégé, le type, les ordres et le fichier de la famille à laquelle
%   NOM appartient ; [F,A,T,O,FI] = WAVEMNGR('fields',NOM) les rend
%   séparément.
%   A = WAVEMNGR('tfsn') rend les abrégés de toutes les familles.
%
%   Les familles d'origine ne sont pas des tables de coefficients : leurs
%   filtres sont construits à la demande, ce qui les rend disponibles à
%   tout ordre. Une famille ajoutée, elle, n'est qu'un nom associé à la
%   fonction qui sait fabriquer son filtre.
%
%   Exemple :
%      wavemngr('read')
%      wavemngr('type', 'db4')                % 1
%      [f, a, t, o] = wavemngr('fields', 'bior2.2');
%
%   Voir aussi WFILTERS, WAVENAMES, WAVEINFO.
    action = lower(strtrim(char(action)));
    registre = registreOndelettes();
    switch action
        case 'read'
            avecNoms = ~isempty(varargin) && isequal(varargin{1}, 1);
            texte = decrireRegistre(registre, avecNoms);
            if nargout > 0
                varargout = {texte};
            else
                fprintf('%s', texte);
            end
        case 'add'
            if numel(varargin) < 5
                error('wavelet:wavemngr:Arguments', ...
                      'AJOUTER demande nom, abrégé, type, ordres et fichier.');
            end
            registreOndelettes(ajouterFamille(registre, varargin));
            varargout = cell(1, nargout);
        case 'del'
            if isempty(varargin)
                error('wavelet:wavemngr:Arguments', ...
                      'SUPPRIMER demande le nom ou l''abrégé d''une famille.');
            end
            registreOndelettes(retirerFamille(registre, char(varargin{1})));
            varargout = cell(1, nargout);
        case 'restore'
            registreOndelettes('reinitialiser');
            varargout = cell(1, nargout);
        case 'type'
            famille = familleDuNom(registre, char(varargin{1}));
            varargout = {famille.type};
        case 'fields'
            famille = familleDuNom(registre, char(varargin{1}));
            if nargout <= 1
                varargout = {rmfield(famille, 'ajoutee')};
            else
                champs = {famille.nom, famille.abrege, famille.type, ...
                          famille.ordres, famille.fichier};
                varargout = champs(1:min(nargout, numel(champs)));
            end
        case {'tfsn', 'tfn'}
            varargout = {{registre.abrege}};
        case 'fichier'
            % Utilisé par WFILTERS pour une famille ajoutée.
            famille = familleDuNom(registre, char(varargin{1}));
            varargout = {famille.fichier};
        otherwise
            error('wavelet:wavemngr:Action', 'Action inconnue : %s.', action);
    end
end

function registre = registreOndelettes(nouveau)
%REGISTREONDELETTES Table des familles, gardée d'un appel à l'autre.
    persistent table
    if isempty(table)
        table = famillesOrigine();
    end
    if nargin > 0
        if ischar(nouveau) && strcmp(nouveau, 'reinitialiser')
            table = famillesOrigine();
        else
            table = nouveau;
        end
    end
    registre = table;
end

function familles = famillesOrigine()
    familles = struct('nom', {}, 'abrege', {}, 'type', {}, 'ordres', {}, ...
                      'fichier', {}, 'ajoutee', {});
    familles(end + 1) = poser('Haar', 'haar', 1, '', 'dbwavf', false);
    familles(end + 1) = poser('Daubechies', 'db', 1, '**', 'dbwavf', false);
    familles(end + 1) = poser('Symlets', 'sym', 1, '**', 'symwavf', false);
    familles(end + 1) = poser('Coiflets', 'coif', 1, '1 2 3 4 5', 'coifwavf', false);
    familles(end + 1) = poser('BiorSplines', 'bior', 2, ...
        '1.1 1.3 1.5 2.2 2.4 2.6 2.8 3.1 3.3 3.5 3.7 3.9 4.4', 'biorwavf', false);
    familles(end + 1) = poser('ReverseBior', 'rbio', 2, ...
        '1.1 1.3 1.5 2.2 2.4 2.6 2.8 3.1 3.3 3.5 3.7 3.9 4.4', 'rbiowavf', false);
    familles(end + 1) = poser('Meyer', 'meyr', 3, '', 'meyer', false);
    familles(end + 1) = poser('Gaussian', 'gaus', 4, '1 2 3 4 5 6 7 8', 'gauswavf', false);
    familles(end + 1) = poser('Mexican hat', 'mexh', 4, '', 'mexihat', false);
    familles(end + 1) = poser('Morlet', 'morl', 4, '', 'morlet', false);
    familles(end + 1) = poser('Complex Gaussian', 'cgau', 5, '1 2 3 4 5', 'cgauwavf', false);
    familles(end + 1) = poser('Complex Morlet', 'cmor', 5, '', 'cmorwavf', false);
    familles(end + 1) = poser('Shannon', 'shan', 5, '', 'shanwavf', false);
    familles(end + 1) = poser('Frequency B-Spline', 'fbsp', 5, '', 'fbspwavf', false);
end

function f = poser(nom, abrege, type, ordres, fichier, ajoutee)
    f = struct('nom', nom, 'abrege', abrege, 'type', type, 'ordres', ordres, ...
               'fichier', fichier, 'ajoutee', ajoutee);
end

function registre = ajouterFamille(registre, arguments)
    nom = char(arguments{1});
    abrege = lower(char(arguments{2}));
    type = double(arguments{3});
    ordres = char(arguments{4});
    fichier = char(arguments{5});
    if ~any(type == 1:5)
        error('wavelet:wavemngr:Type', 'Le type va de un à cinq.');
    end
    for k = 1:numel(registre)
        if strcmp(registre(k).abrege, abrege)
            error('wavelet:wavemngr:Doublon', ...
                  'L''abrégé ''%s'' est déjà pris.', abrege);
        end
    end
    registre(end + 1) = poser(nom, abrege, type, ordres, fichier, true);
end

function registre = retirerFamille(registre, nom)
    nom = lower(strtrim(nom));
    garde = true(1, numel(registre));
    trouve = false;
    for k = 1:numel(registre)
        if strcmpi(registre(k).abrege, nom) || strcmpi(registre(k).nom, nom)
            if ~registre(k).ajoutee
                error('wavelet:wavemngr:Origine', ...
                      'La famille ''%s'' est d''origine : elle ne se retire pas.', nom);
            end
            garde(k) = false;
            trouve = true;
        end
    end
    if ~trouve
        error('wavelet:wavemngr:Absente', 'Famille inconnue : %s.', nom);
    end
    registre = registre(garde);
end

function famille = familleDuNom(registre, nom)
    nom = lower(strtrim(nom));
    meilleur = 0;
    famille = [];
    for k = 1:numel(registre)
        abrege = registre(k).abrege;
        if numel(nom) >= numel(abrege) && strncmp(nom, abrege, numel(abrege)) ...
                && numel(abrege) > meilleur
            meilleur = numel(abrege);
            famille = registre(k);
        end
    end
    if isempty(famille)
        error('wavelet:wavemngr:Inconnue', 'Ondelette inconnue : %s.', nom);
    end
end

function texte = decrireRegistre(registre, avecNoms)
    genres = {'orthogonale', 'biorthogonale', 'à fonction d''échelle', ...
              'sans fonction d''échelle', 'complexe'};
    lignes = {sprintf('%-22s %-8s %s\n', 'Famille', 'Abrégé', 'Genre')};
    for k = 1:numel(registre)
        lignes{end + 1} = sprintf('%-22s %-8s %s\n', registre(k).nom, ...
            registre(k).abrege, genres{registre(k).type});   %#ok<AGROW>
        if avecNoms && ~isempty(registre(k).ordres)
            lignes{end + 1} = sprintf('    ordres : %s\n', registre(k).ordres);   %#ok<AGROW>
        end
    end
    texte = [lignes{:}];
end
