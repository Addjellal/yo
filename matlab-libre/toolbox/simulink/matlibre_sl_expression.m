function valeur = matlibre_sl_expression(texte, nomBloc, nomParametre)
%MATLIBRE_SL_EXPRESSION Évalue un paramètre de bloc donné par une expression.
%   V = MATLIBRE_SL_EXPRESSION(TEXTE,BLOC,PARAMETRE) évalue TEXTE dans
%   l'espace de travail de base et rend sa valeur numérique.
%
%   C'est ainsi qu'un modèle et l'espace de travail partagent leurs
%   variables : un gain réglé à 'K' vaut ce que vaut K au moment où l'on
%   simule, non ce qu'il valait quand on a posé le bloc. Changer K et
%   relancer SIM suffit ; le modèle, lui, ne bouge pas.
%
%   L'espace consulté est celui de base, comme dans Simulink : un modèle
%   ne voit pas les variables locales de la fonction qui le simule.
%
%   Une expression qui ne s'évalue pas, ou qui ne rend pas un nombre, est
%   refusée en nommant le bloc et le paramètre — sans quoi on chercherait
%   longtemps d'où vient un résultat faux.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      K = 3;
%      matlibre_sl_expression('2 * K', 'gain', 'Gain')      % 6
%
%   Voir aussi SIM, ADD_BLOCK, SET_PARAM, EVALIN.
    try
        valeur = evalin('base', texte);
    catch err
        error('Simulink:Commands:ParametreNonEvalue', ...
              ['Le parametre ''%s'' du bloc ''%s'' vaut ''%s'', et cette ' ...
               'expression ne s''evalue pas dans l''espace de travail de ' ...
               'base : %s'], nomParametre, nomBloc, texte, err.message);
    end
    if ~isnumeric(valeur) && ~islogical(valeur)
        error('Simulink:Commands:ParametreNonNumerique', ...
              ['Le parametre ''%s'' du bloc ''%s'' vaut ''%s'', qui rend un ' ...
               '%s : il faut un nombre.'], nomParametre, nomBloc, texte, ...
              class(valeur));
    end
    valeur = double(valeur);
end
