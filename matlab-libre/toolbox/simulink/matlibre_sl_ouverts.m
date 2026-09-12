function sortie = matlibre_sl_ouverts(action, nom, modele, numeroFigure)
%MATLIBRE_SL_OUVERTS Registre des modèles ouverts dans la session.
%   Un modèle est ici une valeur, non une fenêtre. « Ouvert » veut donc
%   dire « connu de la session » : OPEN_SYSTEM et LOAD_SYSTEM y
%   inscrivent le modèle, CLOSE_SYSTEM et BDCLOSE l'en retirent, GCS rend
%   le dernier inscrit, et BDISLOADED répond sur un nom.
%
%   L'inscription retient aussi le numéro de la figure où le schéma est
%   tracé, quand il y en a une, pour que CLOSE_SYSTEM sache laquelle
%   fermer.
%
%   Actions : 'inscrire', 'retirer', 'vider', 'lire', 'figure', 'connu',
%   'noms', 'dernier'.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_sl_ouverts('vider');
%      matlibre_sl_ouverts('inscrire', 'essai', new_system('essai'));
%      matlibre_sl_ouverts('dernier')          % 'essai'
%      matlibre_sl_ouverts('vider');
%
%   Voir aussi OPEN_SYSTEM, CLOSE_SYSTEM, GCS, BDISLOADED, LOAD_SYSTEM.
    persistent noms modeles figures
    if isempty(noms)
        noms = {};
        modeles = {};
        figures = {};
    end
    sortie = [];
    switch lower(char(action))
        case 'inscrire'
            if nargin < 4
                numeroFigure = [];
            end
            nom = char(nom);
            k = trouver(noms, nom);
            if k > 0
                % Réinscrire remet le modèle au bout : le dernier ouvert
                % est celui que GCS doit rendre.
                noms(k) = [];
                modeles(k) = [];
                figures(k) = [];
            end
            noms{end + 1} = nom;
            modeles{end + 1} = modele;
            figures{end + 1} = numeroFigure;
        case 'retirer'
            k = trouver(noms, char(nom));
            if k > 0
                noms(k) = [];
                modeles(k) = [];
                figures(k) = [];
            end
        case 'vider'
            noms = {};
            modeles = {};
            figures = {};
        case 'lire'
            sortie = modeles{exiger(noms, char(nom))};
        case 'figure'
            sortie = figures{exiger(noms, char(nom))};
        case 'connu'
            sortie = trouver(noms, char(nom)) > 0;
        case 'noms'
            sortie = noms;
        case 'dernier'
            if isempty(noms)
                sortie = '';
            else
                sortie = noms{end};
            end
        otherwise
            error('simulink:ouverts:action', 'Action inconnue : %s.', char(action));
    end
end

function k = trouver(noms, nom)
    k = 0;
    for i = 1:numel(noms)
        if strcmp(noms{i}, nom)
            k = i;
            return
        end
    end
end

function k = exiger(noms, nom)
    k = trouver(noms, nom);
    if k == 0
        error('Simulink:Commands:OpenSystemUnknownSystem', ...
              'Invalid Simulink object name: ''%s''.', nom);
    end
end
