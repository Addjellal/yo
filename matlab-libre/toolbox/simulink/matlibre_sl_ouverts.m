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
%   Elle retient enfin ce que la session sait du modèle sans que ce soit
%   le modèle : le fichier d'où il vient ou vers lequel on l'a enregistré
%   (FileName), et s'il a changé depuis (Dirty). 'info' rend ces deux
%   champs, 'noter' en règle : MATLIBRE_SL_OUVERTS('noter',NOM,S) pose
%   les champs de la structure S.
%
%   Actions : 'inscrire', 'retirer', 'vider', 'lire', 'figure', 'connu',
%   'noms', 'dernier', 'info', 'noter'.
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
    persistent noms modeles figures infos
    if isempty(noms)
        noms = {};
        modeles = {};
        figures = {};
        infos = {};
    end
    sortie = [];
    switch lower(char(action))
        case 'inscrire'
            if nargin < 4
                numeroFigure = [];
            end
            nom = char(nom);
            k = trouver(noms, nom);
            info = struct('Dirty', 'off', 'FileName', '');
            if k > 0
                % Réinscrire remet le modèle au bout : le dernier ouvert
                % est celui que GCS doit rendre. Ce que la session en
                % savait reste.
                info = infos{k};
                noms(k) = [];
                modeles(k) = [];
                figures(k) = [];
                infos(k) = [];
            end
            noms{end + 1} = nom;
            modeles{end + 1} = modele;
            figures{end + 1} = numeroFigure;
            infos{end + 1} = info;
        case 'retirer'
            k = trouver(noms, char(nom));
            if k > 0
                noms(k) = [];
                modeles(k) = [];
                figures(k) = [];
                infos(k) = [];
            end
        case 'vider'
            noms = {};
            modeles = {};
            figures = {};
            infos = {};
        case 'info'
            sortie = infos{exiger(noms, char(nom))};
        case 'noter'
            k = exiger(noms, char(nom));
            champs = fieldnames(modele);
            for i = 1:numel(champs)
                infos{k}.(champs{i}) = modele.(champs{i});
            end
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
            error('Simulink:Commands:InvalidAction', 'Action inconnue : %s.', char(action));
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
