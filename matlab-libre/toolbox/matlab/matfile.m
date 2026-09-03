classdef matfile
%MATFILE Accès à un fichier .mat sans tout charger.
%   M = MATFILE(F) ouvre le fichier F et rend un objet dont chaque
%   propriété est une variable du fichier : M.x lit la variable x, et
%   M.x = 3 l'écrit sans toucher aux autres.
%
%   M = MATFILE(F,'Writable',true) autorise l'écriture ; par défaut,
%   comme dans MATLAB, un fichier existant s'ouvre en lecture seule et
%   un fichier absent s'ouvre en écriture.
%
%   MatLibre relit le fichier à chaque accès plutôt que d'en indexer le
%   contenu : la syntaxe est celle de MATLAB, la lecture partielle
%   d'une grande matrice — M.x(1:10,:) — coûte la lecture entière.
%
%   Exemple :
%      f = fullfile(tempdir, 'essai.mat');
%      m = matfile(f, 'Writable', true);
%      m.x = magic(4);
%      m.x(1,:)
%
%   Voir aussi LOAD, SAVE, WHOS, WHO.
    properties
        Properties = struct('Source', '', 'Writable', false);
    end
    methods
        function m = matfile(nomFichier, varargin)
            if nargin < 1
                error('MATLAB:matfile:NoFile', 'matfile attend un nom de fichier.');
            end
            nom = char(nomFichier);
            [~, ~, ext] = fileparts(nom);
            if isempty(ext)
                nom = [nom '.mat'];
            end
            inscriptible = ~isfile(nom);
            for k = 1:2:numel(varargin)
                if k + 1 <= numel(varargin) && strcmpi(char(varargin{k}), 'Writable')
                    inscriptible = logical(varargin{k+1});
                end
            end
            m.Properties = struct('Source', nom, 'Writable', inscriptible);
        end

        function varargout = subsref(m, s)
            if strcmp(s(1).type, '.') && strcmp(s(1).subs, 'Properties')
                r = m.Properties;
                if numel(s) > 1
                    r = subsref(r, s(2:end));
                end
                varargout{1} = r;
                return;
            end
            if ~strcmp(s(1).type, '.')
                error('MATLAB:matfile:BadSubscript', ...
                      'Un objet matfile s''indexe par le nom d''une variable.');
            end
            nom = s(1).subs;
            fichier = m.Properties.Source;
            if ~isfile(fichier)
                error('MATLAB:matfile:NoFile', 'Fichier introuvable : %s.', fichier);
            end
            contenu = load(fichier, nom);
            if ~isfield(contenu, nom)
                error('MATLAB:matfile:NoVariable', ...
                      'La variable « %s » n''est pas dans %s.', nom, fichier);
            end
            r = contenu.(nom);
            if numel(s) > 1
                r = subsref(r, s(2:end));
            end
            varargout{1} = r;
        end

        function m = subsasgn(m, s, valeur)
            if ~strcmp(s(1).type, '.')
                error('MATLAB:matfile:BadSubscript', ...
                      'Un objet matfile s''indexe par le nom d''une variable.');
            end
            if strcmp(s(1).subs, 'Properties')
                m.Properties = subsasgn(m.Properties, s(2:end), valeur);
                return;
            end
            if ~m.Properties.Writable
                error('MATLAB:matfile:NotWritable', ...
                      'Le fichier est ouvert en lecture seule ; ouvrez-le avec ''Writable'',true.');
            end
            nom = s(1).subs;
            fichier = m.Properties.Source;
            if numel(s) > 1
                % « m.x(2,:) = v » : on relit la variable, on la modifie,
                % on la réécrit. Sans cela l'affectation partielle
                % détruirait le reste de la matrice.
                if isfile(fichier)
                    contenu = load(fichier);
                else
                    contenu = struct();
                end
                if isfield(contenu, nom)
                    ancien = contenu.(nom);
                else
                    ancien = [];
                end
                valeur = subsasgn(ancien, s(2:end), valeur);
            end
            ecrire(fichier, nom, valeur);
        end

        function n = who(m)
            fichier = m.Properties.Source;
            if ~isfile(fichier)
                n = {};
                return;
            end
            n = fieldnames(load(fichier));
        end

        function afficher(m)
            disp(m);
        end
    end
end

function ecrire(fichier, nom, valeur)
% Écrire une variable sans perdre les autres : on ajoute au fichier
% quand il existe déjà.
    depot = struct();
    depot.(nom) = valeur;   %#ok<STRNU>
    variables = depot;      %#ok<NASGU>
    ancienNom = nom;
    eval([ancienNom ' = variables.(ancienNom);']);
    if isfile(fichier)
        save(fichier, ancienNom, '-append');
    else
        save(fichier, ancienNom);
    end
end
