function modele = arrangeSystem(systeme, varargin)
%SIMULINK.BLOCKDIAGRAM.ARRANGESYSTEM Range les blocs d'un système.
%   SIMULINK.BLOCKDIAGRAM.ARRANGESYSTEM(SYSTEME) range les blocs du
%   système — un modèle de la session, ou un de ses sous-systèmes, par
%   son nom, son chemin ou sa poignée — par la mise en place automatique :
%   de la source vers la sortie, par couches, comme OPEN_SYSTEM range un
%   modèle dont les blocs n'ont pas de Position. La Position de chaque
%   bloc du système est donc retirée, et GET_PARAM la rend ensuite telle
%   que la mise en place la calcule. Les sous-systèmes qu'il contient ne
%   sont pas touchés : on les range chacun par son chemin, comme dans
%   Simulink.
%
%   SIMULINK.BLOCKDIAGRAM.ARRANGESYSTEM(SYSTEME,'FullLayout',TF) : la mise
%   en place s'applique ici toujours, qu'elle améliore ou non celle qui
%   était là — ce que Simulink ne fait qu'avec FullLayout 'true'. TF vaut
%   'true' ou 'false' ; 'Animation' est accepté de même, sans effet.
%
%   MODELE = SIMULINK.BLOCKDIAGRAM.ARRANGESYSTEM(MODELE) range un modèle
%   par valeur, et le rend.
%
%   Exemple :
%      bdclose('all');
%      new_system('essai');
%      add_block('built-in/Constant', 'essai/c', 'Position', [300 300 330 330]);
%      add_block('built-in/Gain', 'essai/g', 'Position', [20 20 50 50]);
%      add_line('essai', 'c/1', 'g/1');
%      Simulink.BlockDiagram.arrangeSystem('essai');
%      p = get_param('essai/c', 'Position');
%      q = get_param('essai/g', 'Position');
%      p(3) < q(1)                              % vrai : la source a gauche
%      bdclose('all');
%
%   Voir aussi OPEN_SYSTEM, SET_PARAM, SIMULINK.BLOCKDIAGRAM.CREATESUBSYSTEM.
    if mod(numel(varargin), 2) ~= 0
        error('Simulink:BlockDiagram:ArrangeSystemArguments', ...
              'Les options d''arrangeSystem vont par paires : un nom, une valeur.');
    end
    for k = 1:2:numel(varargin)
        nom = char(varargin{k});
        if ~any(strcmpi(nom, {'FullLayout', 'Animation'}))
            error('Simulink:BlockDiagram:ArrangeSystemArguments', ...
                  'arrangeSystem n''a pas d''option ''%s'' : ses options sont FullLayout et Animation.', ...
                  nom);
        end
        v = varargin{k + 1};
        if ~(islogical(v) && isscalar(v)) && ...
           ~((ischar(v) || (isstring(v) && isscalar(v))) && any(strcmpi(char(v), {'true', 'false'})))
            error('Simulink:BlockDiagram:ArrangeSystemArguments', ...
                  '%s vaut ''true'' ou ''false''.', nom);
        end
    end
    if isstruct(systeme)
        modele = matlibre_sl_restructurer('arranger', matlibre_sl_modele(systeme));
        return
    end
    [racine, chemin, genre] = matlibre_sl_nomme('systeme', systeme);
    if ~any(strcmp(genre, {'modele', 'bloc'}))
        error('Simulink:BlockDiagram:ArrangeSystemArguments', ...
              'arrangeSystem range un modele ou un sous-systeme, non un port ou une ligne.');
    end
    if isempty(chemin)
        ctx = matlibre_sl_restructurer('ouvrir', racine, '');
        matlibre_sl_restructurer('fermer', ctx, matlibre_sl_restructurer('arranger', ctx.systeme));
    else
        % le contenu du sous-système, rangé, puis remis dans son bloc
        [parent, feuille] = couper(chemin);
        ctx = matlibre_sl_restructurer('ouvrir', racine, parent);
        ou = joindre(racine, parent);
        c = matlibre_sl_restructurer('contenu', ctx.systeme, feuille, ou);
        if ~isempty(c.blocs)
            ctx2 = matlibre_sl_restructurer('ouvrir', racine, chemin);
            matlibre_sl_restructurer('fermer', ctx2, ...
                                     matlibre_sl_restructurer('arranger', ctx2.systeme));
        end
    end
    clear modele
end

function [parent, feuille] = couper(chemin)
    barre = find(chemin == '/', 1, 'last');
    if isempty(barre)
        parent = '';
        feuille = chemin;
    else
        parent = chemin(1:barre - 1);
        feuille = chemin(barre + 1:end);
    end
end

function texte = joindre(racine, chemin)
    texte = racine;
    if ~isempty(chemin)
        texte = [racine '/' chemin];
    end
end
