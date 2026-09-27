function modele = delete_line(modele, source, destination, entree, sortie)
%DELETE_LINE Supprime le lien qui va d'un bloc à un autre.
%   MODELE = DELETE_LINE(MODELE,SOURCE,DESTINATION) supprime le lien
%   allant d'une sortie du premier bloc à une entrée du second.
%   DELETE_LINE(MODELE,SOURCE,DESTINATION,E) précise l'entrée, quand
%   plusieurs liens joignent les deux mêmes blocs ;
%   DELETE_LINE(MODELE,SOURCE,DESTINATION,E,S) précise aussi la sortie.
%   La syntaxe de Simulink, « 'demux/2' », désigne un port comme dans
%   ADD_LINE.
%
%   Un lien qui n'existe pas lève une erreur qui nomme les deux blocs,
%   plutôt que de laisser croire à une suppression qui n'a pas eu lieu.
%
%   Exemple :
%      m = new_system('essai');
%      m = add_block(m, 'constant', 'c', 'Value', 1);
%      m = add_block(m, 'gain', 'g', 'Gain', 2);
%      m = add_line(m, 'c', 'g');
%      m = delete_line(m, 'c', 'g');
%      isempty(m.liens)                 % vrai
%
%   Voir aussi ADD_LINE, DELETE_BLOCK, NEW_SYSTEM.
    physique = @(t) (ischar(t) || isstring(t)) && ...
                    ~isempty(regexp(char(t), '/(LConn|RConn)\d+$', 'once', 'ignorecase'));
    if physique(source) && physique(destination) && isfield(modele, 'connexions')
        % une connexion physique : dans un sens ou dans l'autre
        [a, pa] = portPhysique(modele, source);
        [b, pb] = portPhysique(modele, destination);
        c = modele.connexions;
        trouve = (c(:, 1) == a & c(:, 2) == pa & c(:, 3) == b & c(:, 4) == pb) | ...
                 (c(:, 1) == b & c(:, 2) == pb & c(:, 3) == a & c(:, 4) == pa);
        if ~any(trouve)
            error('Simulink:Commands:DeleteLineNoLine', ...
                  'Aucune connexion ne relie ''%s'' a ''%s''.', char(source), char(destination));
        end
        modele.connexions(trouve, :) = [];
        return
    end
    [a, portSortie, sortieDite] = designer(modele, source);
    [b, portEntree, entreeDite] = designer(modele, destination);
    if nargin >= 4 && ~isempty(entree)
        portEntree = entree;
        entreeDite = true;
    end
    if nargin >= 5 && ~isempty(sortie)
        portSortie = sortie;
        sortieDite = true;
    end
    liens = matlibre_sl_liens(modele);
    candidats = find(liens(:, 1) == a & liens(:, 2) == b);
    if entreeDite
        candidats = candidats(liens(candidats, 3) == portEntree);
    end
    if sortieDite
        candidats = candidats(liens(candidats, 4) == portSortie);
    end
    if isempty(candidats)
        error('Simulink:Commands:DeleteLineNoLine', ...
              'Aucun lien ne va de ''%s'' a ''%s''.', char(source), char(destination));
    end
    liens(candidats, :) = [];
    modele.liens = liens;
end

function [k, port] = portPhysique(modele, texte)
    jetons = regexp(char(texte), '^(.*)/(LConn|RConn)(\d+)$', 'tokens', 'once', 'ignorecase');
    k = chercher(modele, jetons{1});
    if k == 0
        error('Simulink:Commands:InvSimulinkObjectName', ['Nom d''objet Simulink invalide : ' ...
              'aucun bloc ne s''appelle ''%s''.'], jetons{1});
    end
    port = str2double(jetons{3});
    if strcmpi(jetons{2}, 'RConn')
        port = -port;
    end
end

% « nom » ou « nom/port », comme dans ADD_LINE. Le troisième résultat dit
% si un port a été nommé : sans lui, tous les ports conviennent.
function [k, port, dit] = designer(modele, texte)
    texte = char(texte);
    port = 1;
    dit = false;
    k = chercher(modele, texte);
    if k > 0
        return
    end
    jetons = regexp(texte, '^(.*)/(\d+)$', 'tokens', 'once');
    if ~isempty(jetons)
        k = chercher(modele, jetons{1});
        if k > 0
            port = str2double(jetons{2});
            dit = true;
            return
        end
    end
    k = matlibre_sl_indice(modele, texte);   % l'erreur qui nomme le bloc
end

function k = chercher(modele, nom)
    k = 0;
    for i = 1:numel(modele.blocs)
        if strcmp(modele.blocs{i}.nom, nom)
            k = i;
            return
        end
    end
end
