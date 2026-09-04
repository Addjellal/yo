function varargout = matlibre_dl_combiner(fonction, varargin)
%MATLIBRE_DL_COMBINER Applique une règle à tous les paramètres à la fois.
%   [...] = MATLIBRE_DL_COMBINER(FONCTION,A,B,...) parcourt en parallèle
%   des conteneurs de même forme — DLARRAY, tableaux de cellules,
%   structures, tables de paramètres — et appelle FONCTION sur chaque
%   feuille numérique. Les sorties ont la forme du premier conteneur.
%
%   Ce que la fonction ne sait pas traiter — un nom de couche, par
%   exemple — est recopié tel quel : une table de paramètres se met ainsi
%   à jour sans qu'on ait à en extraire la colonne des valeurs.
%
%   C'est ce parcours qui permet aux solveurs de mettre à jour d'un seul
%   appel tous les poids d'un réseau, quelle que soit la façon dont
%   l'utilisateur les a rangés.
%
%   Exemple :
%      s = matlibre_dl_combiner(@(a, b) a + b, {1, 2}, {10, 20});
%      s{2}      % 22
%
%   Voir aussi ADAMUPDATE, SGDMUPDATE, RMSPROPUPDATE.
    premier = varargin{1};
    sorties = max(nargout, 1);
    if isa(premier, 'dlnetwork')
        % Un solveur peut recevoir le réseau lui-même : ce sont ses poids
        % qu'il met à jour, et c'est le réseau qu'il rend.
        conteneurs = cell(1, numel(varargin));
        for j = 1:numel(varargin)
            conteneurs{j} = matlibre_dl_apprises(varargin{j});
        end
        resultats = cell(1, sorties);
        [resultats{:}] = matlibre_dl_combiner(fonction, conteneurs{:});
        varargout = repmat({premier}, 1, sorties);
        varargout{1}.Learnables = resultats{1};
        for j = 2:sorties
            varargout{j} = resultats{j};
        end
        return
    end
    if iscell(premier)
        varargout = repmat({premier}, 1, sorties);
        for k = 1:numel(premier)
            elements = cell(1, numel(varargin));
            for j = 1:numel(varargin)
                elements{j} = varargin{j}{k};
            end
            resultats = cell(1, sorties);
            [resultats{:}] = matlibre_dl_combiner(fonction, elements{:});
            for j = 1:sorties
                varargout{j}{k} = resultats{j};
            end
        end
    elseif istable(premier)
        colonnes = cell(1, numel(varargin));
        for j = 1:numel(varargin)
            colonnes{j} = matlibre_dl_colonne_valeurs(varargin{j});
        end
        resultats = cell(1, sorties);
        [resultats{:}] = matlibre_dl_combiner(fonction, colonnes{:});
        varargout = repmat({premier}, 1, sorties);
        for j = 1:sorties
            varargout{j}.Value = resultats{j};
        end
    elseif isstruct(premier)
        varargout = repmat({premier}, 1, sorties);
        noms = fieldnames(premier);
        for e = 1:numel(premier)
            for k = 1:numel(noms)
                elements = cell(1, numel(varargin));
                for j = 1:numel(varargin)
                    elements{j} = varargin{j}(e).(noms{k});
                end
                resultats = cell(1, sorties);
                [resultats{:}] = matlibre_dl_combiner(fonction, elements{:});
                for j = 1:sorties
                    varargout{j}(e).(noms{k}) = resultats{j};
                end
            end
        end
    elseif isa(premier, 'dlarray') || (isnumeric(premier) && ~isempty(premier))
        varargout = cell(1, sorties);
        [varargout{:}] = fonction(varargin{:});
    else
        % Un nom, une chaîne, un tableau vide : rien à mettre à jour.
        varargout = repmat({premier}, 1, sorties);
    end
end

function apprises = matlibre_dl_apprises(conteneur)
    if isa(conteneur, 'dlnetwork')
        apprises = conteneur.Learnables;
    else
        apprises = conteneur;
    end
end

function valeurs = matlibre_dl_colonne_valeurs(conteneur)
    if istable(conteneur)
        valeurs = conteneur.Value;
    else
        valeurs = conteneur;
    end
end
