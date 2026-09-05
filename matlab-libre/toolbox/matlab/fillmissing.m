function [b, marque] = fillmissing(a, methode, varargin)
%FILLMISSING Comble les valeurs manquantes.
%   B = FILLMISSING(A,METHODE) remplace les valeurs manquantes de A —
%   NaN pour un tableau numérique, la chaîne vide pour du texte, la
%   catégorie indéfinie pour une catégorielle.
%
%   METHODE vaut :
%      'constant'   remplace par la valeur donnée en troisième argument
%      'previous'   reprend la dernière valeur connue
%      'next'       prend la prochaine valeur connue
%      'nearest'    prend la plus proche des deux
%      'linear'     interpole entre les deux voisines connues
%      'spline'     interpole par une spline cubique
%      'pchip'      interpole en préservant la monotonie
%      'movmean'    moyenne mobile de la fenêtre donnée
%      'movmedian'  médiane mobile de la fenêtre donnée
%
%   B = FILLMISSING(A,'constant',V) donne la constante ; V peut porter
%   une valeur par colonne.
%   B = FILLMISSING(A,'movmean',K) donne la largeur de fenêtre.
%   B = FILLMISSING(...,'EndValues',E) dit quoi faire des trous en bout,
%   là où l'interpolation n'a pas de voisin des deux côtés : 'extrap'
%   (défaut) prolonge, 'none' les laisse, ou une constante les comble.
%
%   [B,MARQUE] = FILLMISSING(...) rend aussi les positions comblées.
%
%   Un trou en bout n'est pas un trou comme un autre : il n'est pas
%   encadré. C'est pourquoi il a son option à lui — et pourquoi la
%   prolongation qu'on en fait est toujours une extrapolation, c'est-à-dire
%   une hypothèse, non une mesure.
%
%   Exemple :
%      fillmissing([1 NaN 3], 'linear')        % [1 2 3]
%      fillmissing([1 NaN 3], 'constant', 0)   % [1 0 3]
%      fillmissing([NaN 2 3], 'previous')      % [NaN 2 3] : rien avant
%
%   Voir aussi ISMISSING, RMMISSING, STANDARDIZEMISSING, INTERP1.
    if nargin < 2
        error('MATLAB:fillmissing:Methode', 'FILLMISSING demande une méthode.');
    end
    methode = lower(char(methode));
    parametre = [];
    k = 1;
    if ~isempty(varargin) && ~(ischar(varargin{1}) || isstring(varargin{1}))
        parametre = varargin{1};
        k = 2;
    elseif ~isempty(varargin) && (ischar(varargin{1}) || isstring(varargin{1})) ...
            && ~any(strcmpi(char(varargin{1}), {'EndValues', 'DataVariables'}))
        parametre = varargin{1};
        k = 2;
    end
    bouts = 'extrap';
    variables = [];
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'endvalues'
                bouts = varargin{k + 1};
            case 'datavariables'
                variables = varargin{k + 1};
            otherwise
                error('MATLAB:fillmissing:Option', 'Option inconnue : %s.', ...
                      char(varargin{k}));
        end
        k = k + 2;
    end
    if isa(a, 'table') || isa(a, 'timetable')
        [b, marque] = comblerTable(a, methode, parametre, bouts, variables);
        return
    end
    [b, marque] = comblerTableau(a, methode, parametre, bouts);
end

function [b, marque] = comblerTable(a, methode, parametre, bouts, variables)
    b = a;
    noms = a.Properties.VariableNames;
    if isempty(variables)
        choisies = noms;
    else
        choisies = cellstr(variables);
    end
    marque = false(height(a), numel(noms));
    for k = 1:numel(noms)
        if ~any(strcmp(noms{k}, choisies))
            continue
        end
        colonne = a.(noms{k});
        if ~isnumeric(colonne)
            continue
        end
        [rempli, ou] = comblerTableau(colonne, methode, parametre, bouts);
        b.(noms{k}) = rempli;
        marque(:, k) = ou(:);
    end
end

function [b, marque] = comblerTableau(a, methode, parametre, bouts)
    b = a;
    if isnumeric(a) || islogical(a)
        b = double(b);
        marque = isnan(b);
    else
        marque = ismissing(a);
    end
    if ~any(marque(:))
        return
    end
    % Une matrice se comble colonne par colonne : c'est la première
    % dimension non singleton, comme pour toutes les réductions.
    if isvector(b)
        b = comblerVecteur(b, methode, parametre, bouts);
    else
        for c = 1:size(b, 2)
            b(:, c) = comblerVecteur(b(:, c), methode, ...
                                     valeurColonne(parametre, c), bouts);
        end
    end
end

function v = valeurColonne(parametre, c)
    if isnumeric(parametre) && ~isscalar(parametre) && numel(parametre) >= c
        v = parametre(c);
    else
        v = parametre;
    end
end

function v = comblerVecteur(v, methode, parametre, bouts)
    forme = size(v);
    v = v(:);
    manquants = isnan(v);
    if ~any(manquants)
        v = reshape(v, forme);
        return
    end
    connus = find(~manquants);
    if isempty(connus)
        v = reshape(v, forme);
        return
    end
    indices = (1:numel(v))';
    switch methode
        case 'constant'
            if isempty(parametre)
                error('MATLAB:fillmissing:Constante', ...
                      'La méthode ''constant'' demande une valeur.');
            end
            v(manquants) = parametre;
            v = reshape(v, forme);
            return
        case {'previous', 'next', 'nearest', 'linear', 'spline', 'pchip'}
            if numel(connus) == 1 && any(strcmp(methode, {'linear', 'spline', 'pchip'}))
                % Une seule valeur connue : aucune pente n'est définie, on
                % la répète plutôt que de rendre des NaN.
                v(manquants) = v(connus);
                v = reshape(v, forme);
                return
            end
            v(manquants) = interp1(connus, v(connus), indices(manquants), methode, NaN);
        case {'movmean', 'movmedian'}
            if isempty(parametre)
                error('MATLAB:fillmissing:Fenetre', ...
                      'Les méthodes mobiles demandent une largeur de fenêtre.');
            end
            largeur = round(double(parametre));
            demi = floor(largeur / 2);
            for k = find(manquants)'
                debut = max(1, k - demi);
                fin = min(numel(v), k + demi);
                voisinage = v(debut:fin);
                voisinage = voisinage(~isnan(voisinage));
                if isempty(voisinage)
                    continue
                end
                if strcmp(methode, 'movmean')
                    v(k) = mean(voisinage);
                else
                    v(k) = median(voisinage);
                end
            end
            v = reshape(v, forme);
            return
        otherwise
            error('MATLAB:fillmissing:Methode', 'Méthode inconnue : %s.', methode);
    end
    % Les bouts : ce que l'interpolation n'a pas pu encadrer.
    restants = isnan(v);
    if any(restants)
        if ischar(bouts) || isstring(bouts)
            switch lower(char(bouts))
                case 'extrap'
                    v(restants) = interp1(connus, v(connus), indices(restants), ...
                                          'nearest', 'extrap');
                case 'none'
                    % Laissés tels quels : c'est ce qu'on demande.
                otherwise
                    error('MATLAB:fillmissing:Bouts', ...
                          'EndValues vaut ''extrap'', ''none'' ou une constante.');
            end
        else
            v(restants) = bouts;
        end
    end
    v = reshape(v, forme);
end
