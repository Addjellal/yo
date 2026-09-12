function modele = matlibre_sl_modele(entree)
%MATLIBRE_SL_MODELE Rend un modèle, qu'on l'ait donné par valeur ou par nom.
%   MODELE = MATLIBRE_SL_MODELE(ENTREE) accepte un modèle bâti par
%   NEW_SYSTEM, ou le nom d'un modèle ouvert dans la session, ou le nom
%   d'un fichier .m qui le rend.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = new_system('essai');
%      nom = matlibre_sl_modele(m).nom;      % 'essai'
%
%   Voir aussi LINMOD, TRIM, OPEN_SYSTEM, LOAD_SYSTEM, SIM.
    if isstruct(entree) && isfield(entree, 'blocs')
        modele = entree;
        return
    end
    if ischar(entree) || isstring(entree)
        nom = char(entree);
        if matlibre_sl_ouverts('connu', nom)
            modele = matlibre_sl_ouverts('lire', nom);
            return
        end
        if exist(nom, 'file') == 2 || exist(nom, 'file') == 6
            modele = feval(nom);
            if isstruct(modele) && isfield(modele, 'blocs')
                return
            end
        end
        error('Simulink:Commands:OpenSystemUnknownSystem', ...
              'Invalid Simulink object name: ''%s''.', nom);
    end
    error('Simulink:Commands:InvalidModel', ...
          'Un modele se batit par NEW_SYSTEM, ou se designe par son nom.');
end
