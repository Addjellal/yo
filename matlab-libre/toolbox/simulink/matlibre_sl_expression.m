function valeur = matlibre_sl_expression(texte, nomBloc, nomParametre, classe)
%MATLIBRE_SL_EXPRESSION Évalue un paramètre de bloc donné par une expression.
%   V = MATLIBRE_SL_EXPRESSION(TEXTE,BLOC,PARAMETRE) évalue TEXTE dans
%   l'espace de travail de base et rend sa valeur numérique, en double.
%   V = MATLIBRE_SL_EXPRESSION(TEXTE,BLOC,PARAMETRE,'classe') la rend dans
%   sa classe : 'int8(5)' reste un int8, que la propagation des types lit.
%
%   C'est ainsi qu'un modèle et l'espace de travail partagent leurs
%   variables : un gain réglé à 'K' vaut ce que vaut K au moment où l'on
%   simule, non ce qu'il valait quand on a posé le bloc. Changer K et
%   relancer SIM suffit ; le modèle, lui, ne bouge pas.
%
%   Les variables de l'espace de travail du modèle — celui du modèle dont
%   BLOC est un bloc, « modele/bloc » — passent avant celles de base.
%
%   Une variable qui porte un SIMULINK.PARAMETER y vaut la valeur de
%   l'objet, convertie dans son DataType et vérifiée contre ses bornes
%   Min et Max : '2*K' se calcule avec la valeur de K, comme dans
%   Simulink.
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
%      assignin('base', 'K', 3);
%      matlibre_sl_expression('2 * K', 'gain', 'Gain')      % 6
%
%   Voir aussi SIM, ADD_BLOCK, SET_PARAM, EVALIN, SIMULINK.PARAMETER.
    % Les objets paramètres que nomme l'expression : chacun est remplacé
    % par sa valeur. Sans eux, l'évaluation se fait telle quelle dans
    % l'espace de base.
    [noms, valeurs] = parametresNommes(texte, nomBloc, nomParametre);
    try
        if isempty(noms)
            valeur = evalin('base', texte);
        else
            valeur = evaluerAvec(texte, noms, valeurs);
        end
    catch err
        error('Simulink:Commands:ParametreNonEvalue', ...
              ['Le parametre ''%s'' du bloc ''%s'' vaut ''%s'', et cette ' ...
               'expression ne s''evalue pas dans l''espace de travail de ' ...
               'base : %s'], nomParametre, nomBloc, texte, err.message);
    end
    % un membre d'énumération passe : sa classe dit le type du signal
    membre = isobject(valeur) && isenum(valeur);
    if ~isnumeric(valeur) && ~islogical(valeur) && ~membre
        error('Simulink:Commands:ParametreNonNumerique', ...
              ['Le parametre ''%s'' du bloc ''%s'' vaut ''%s'', qui rend un ' ...
               '%s : il faut un nombre.'], nomParametre, nomBloc, texte, ...
              class(valeur));
    end
    if nargin < 4 || ~strcmp(classe, 'classe')
        try
            valeur = double(valeur);
        catch
            error('Simulink:Commands:ParametreNonNumerique', ...
                  ['Le parametre ''%s'' du bloc ''%s'' vaut ''%s'', un membre de %s qui ' ...
                   'ne porte pas de valeur entiere : il faut un nombre.'], nomParametre, ...
                  nomBloc, texte, class(valeur));
        end
    end
end

% Les variables que nomme le texte : celles de l'espace de travail du
% modèle d'abord, puis celles de l'espace de base. Toutes, avec leur
% valeur, dès que l'une porte un Simulink.Parameter ou vient de l'espace
% du modèle ; aucune sinon.
function [noms, valeurs] = parametresNommes(texte, nomBloc, nomParametre)
    noms = {};
    valeurs = {};
    objets = false;
    [nomsModele, valeursModele] = matlibre_sl_espace('variables', nomBloc);
    for id = unique(regexp(texte, '[A-Za-z]\w*', 'match'))
        nom = id{1};
        j = find(strcmp(nomsModele, nom), 1);
        if ~isempty(j)
            v = valeursModele{j};
            objets = true;
        elseif evalin('base', sprintf('exist(''%s'', ''var'')', nom)) ~= 1
            continue
        else
            v = evalin('base', nom);
        end
        if isa(v, 'Simulink.Parameter')
            v = matlibre_sl_parametre('valeur', v, nom, nomBloc, nomParametre);
            objets = true;
        end
        noms{end + 1} = nom; %#ok<AGROW>
        valeurs{end + 1} = v; %#ok<AGROW>
    end
    if ~objets
        noms = {};
        valeurs = {};
    end
end

% L'évaluation dans un espace à part, où chaque variable nommée vaut ce
% qu'on lui donne. Les noms propres à la fonction commencent par
% matlibre__ : une variable de l'utilisateur ne les heurte pas.
function matlibre__v = evaluerAvec(matlibre__texte, matlibre__noms, matlibre__valeurs)
    for matlibre__k = 1:numel(matlibre__noms)
        eval([matlibre__noms{matlibre__k} ' = matlibre__valeurs{matlibre__k};']);
    end
    matlibre__v = eval(matlibre__texte);
end
