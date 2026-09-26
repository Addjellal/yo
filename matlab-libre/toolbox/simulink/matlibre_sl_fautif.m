function ex = matlibre_sl_fautif(err, type, parametres, chemin)
%MATLIBRE_SL_FAUTIF L'erreur de Simulink qui nomme un bloc et son paramètre fautif.
%   EX = MATLIBRE_SL_FAUTIF(ERR,TYPE,PARAMETRES,CHEMIN) rend l'exception
%   Simulink:Parameters:InvParamSetting pour ERR, une erreur imprévue
%   tombée pendant que le bloc CHEMIN — de type TYPE, de paramètres
%   PARAMETRES — se compilait ou se calculait. C'est presque toujours la
%   valeur d'un paramètre que le bloc ne sait pas employer : l'exception
%   nomme le bloc par son chemin, et, parmi ses paramètres, ceux dont la
%   valeur s'écarte de la forme de leur valeur par défaut — vide, NaN,
%   complexe, une matrice là où il faut un scalaire, un nombre négatif là
%   où il faut un compte. Le message d'origine suit, en détail.
%
%   MATLIBRE_SL_COMPILER et SIM s'en servent : l'un sait quel bloc il
%   compile, l'autre rejoue la simulation pour savoir lequel calculait.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      err = MException('MATLAB:badsubscript', 'Index exceeds...');
%      ex = matlibre_sl_fautif(err, 'gain', struct('Gain', []), 'm/g');
%      ex.identifier                 % 'Simulink:Parameters:InvParamSetting'
%
%   Voir aussi SIM, MATLIBRE_SL_COMPILER, MATLIBRE_SL_CATALOGUE.
    suspects = {};
    donnes = {};
    try
        entree = matlibre_sl_catalogue('type', type);
        champs = fieldnames(parametres);
        for i = 1:numel(champs)
            canon = matlibre_sl_catalogue('parametre', entree, champs{i});
            j = find(strcmp(entree.params(:, 1), canon), 1);
            if isempty(j)
                continue
            end
            v = parametres.(champs{i});
            defaut = entree.params{j, 2};
            donnes{end + 1} = canon; %#ok<AGROW>
            if ecarte(v, defaut)
                suspects{end + 1} = sprintf('''%s'' (%s)', canon, apercu(v)); %#ok<AGROW>
            end
        end
    catch
    end
    if ~isempty(suspects)
        quoi = sprintf('la valeur de %s', strjoin(suspects, ', '));
    elseif ~isempty(donnes)
        quoi = sprintf('l''un de ses parametres (%s)', strjoin(unique(donnes), ', '));
    else
        quoi = 'ses parametres';
    end
    ex = MException('Simulink:Parameters:InvParamSetting', ...
                    'Parametre invalide dans ''%s'' : le bloc ne sait pas employer %s. Detail : %s', ...
                    chemin, quoi, err.message);
end

% Une valeur qui n'a pas la forme de la valeur par défaut.
function oui = ecarte(v, defaut)
    oui = false;
    if ~isnumeric(defaut) || ~(isnumeric(v) || islogical(v))
        return
    end
    v = double(v);
    oui = (isempty(v) && ~isempty(defaut)) || any(isnan(v(:))) || ~isreal(v) || ...
          (numel(v) > 1 && numel(defaut) <= 1) || ...
          (isscalar(defaut) && isscalar(v) && defaut >= 1 && v < 0);
end

function t = apercu(v)
    if isempty(v)
        t = '[]';
    elseif isnumeric(v) || islogical(v)
        t = mat2str(v, 6);
        if numel(t) > 40
            t = sprintf('une matrice %dx%d', size(v, 1), size(v, 2));
        end
    else
        t = ['''' char(v) ''''];
    end
end
