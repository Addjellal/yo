function modele = load_system(nom)
%LOAD_SYSTEM Relit un modèle enregistré, et l'ouvre dans la session.
%   MODELE = LOAD_SYSTEM(NOM) exécute le fichier NOM.m — celui qu'écrit
%   SAVE_SYSTEM, ou tout autre programme qui rend un modèle — et rend le
%   modèle obtenu. Le modèle est inscrit au registre de la session :
%   BDISLOADED répond vrai, et GCS le nomme.
%
%   Le chemin peut porter l'extension .m ou non. Un fichier .slx ou .mdl
%   est refusé en disant pourquoi : leur format n'est pas public.
%
%   Exemple :
%      m = new_system('petit');
%      m = add_block(m, 'constant', 'c', 'Value', 7);
%      chemin = save_system(m, [tempname() '.m']);
%      relu = load_system(chemin);
%      get_param(relu, 'c', 'Value')            % 7
%      bdclose('petit');
%      delete(chemin);
%
%   Voir aussi SAVE_SYSTEM, OPEN_SYSTEM, BDISLOADED, GCS, SIM.
    nom = char(nom);
    [dossier, base, extension] = fileparts(nom);
    if strcmpi(extension, '.slx') || strcmpi(extension, '.mdl')
        error('Simulink:Commands:SlxNonLu', ...
              ['MatLibre ne lit pas les fichiers .slx ni .mdl : leur format ' ...
               'n''est pas public. Decrivez le modele en appelant NEW_SYSTEM, ' ...
               'ADD_BLOCK et ADD_LINE, ou enregistrez-le par SAVE_SYSTEM.']);
    end
    chemin = fullfile(dossier, [base '.m']);
    if exist(chemin, 'file') ~= 2
        error('Simulink:Commands:OpenSystemUnknownSystem', ...
              'Invalid Simulink object name: ''%s''.', nom);
    end
    ancien = pwd();
    if ~isempty(dossier)
        % Le fichier est appelé par son nom de base : il doit être
        % atteignable, et le dossier courant est le chemin le plus sûr.
        cd(dossier);
        nettoyage = onCleanup(@() cd(ancien));   %#ok<NASGU>
    end
    modele = feval(base);
    if ~isstruct(modele) || ~isfield(modele, 'blocs')
        error('Simulink:Commands:InvalidModel', ...
              'Le fichier ''%s'' ne rend pas un modele.', chemin);
    end
    matlibre_sl_ouverts('inscrire', modele.nom, modele, 0);
end
