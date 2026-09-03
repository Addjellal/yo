function fis = ajouterVariable(fis, entree, intervalle, varargin)
%AJOUTERVARIABLE Rouage commun d'ADDINPUT et d'ADDOUTPUT.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    variables = variablesDe(fis, entree);
    if entree
        nom = sprintf('input%d', numel(variables) + 1);
    else
        nom = sprintf('output%d', numel(variables) + 1);
    end
    nombreMf = 0;
    typeMf = 'trimf';
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'name',   nom = char(varargin{k+1});
            case 'nummfs', nombreMf = round(varargin{k+1});
            case 'mftype', typeMf = lower(char(varargin{k+1}));
            otherwise
                error('fuzzy:addInput:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    intervalle = double(intervalle(:))';
    if numel(intervalle) ~= 2 || intervalle(2) <= intervalle(1)
        error('fuzzy:addInput:Intervalle', ...
              'L''intervalle doit être [min max], avec max plus grand.');
    end
    if entree
        fis = addvar(fis, 'input', nom, intervalle);
        indice = numel(fis.entrees);
        genre = 'input';
    else
        fis = addvar(fis, 'output', nom, intervalle);
        indice = numel(fis.sorties);
        genre = 'output';
    end
    for m = 1:nombreMf
        fis = addmf(fis, genre, indice, sprintf('mf%d', m), typeMf, ...
                    parametresReguliers(typeMf, intervalle, nombreMf, m));
    end
end

function p = parametresReguliers(typeMf, intervalle, nombre, rang)
%PARAMETRESREGULIERS Modalités également réparties sur l'intervalle.
%   Les sommets vont d'un bout à l'autre, et chaque modalité recouvre ses
%   voisines à mi-hauteur : c'est la partition d'usage.
    bas = intervalle(1);
    haut = intervalle(2);
    if nombre == 1
        centres = (bas + haut) / 2;
    else
        centres = bas + (haut - bas) * (rang - 1) / (nombre - 1);
    end
    if nombre > 1
        largeur = (haut - bas) / (nombre - 1);
    else
        largeur = (haut - bas) / 2;
    end
    switch typeMf
        case 'trimf'
            p = [centres - largeur, centres, centres + largeur];
        case 'trapmf'
            p = [centres - largeur, centres - largeur / 2, ...
                 centres + largeur / 2, centres + largeur];
        case 'gaussmf'
            p = [largeur / 2.5, centres];
        case 'gbellmf'
            p = [largeur / 2, 2, centres];
        otherwise
            error('fuzzy:addInput:TypeMf', ...
                  'Type de modalité inconnu pour une partition : %s.', typeMf);
    end
end
