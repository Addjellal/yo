function texte = matlibre_sl_etiquette(bloc)
%MATLIBRE_SL_ETIQUETTE Ce qui s'écrit dans un bloc.
%   TEXTE = MATLIBRE_SL_ETIQUETTE(BLOC) rend ce que le bloc affiche : sa
%   valeur pour une constante, son gain pour un gain, sa transmittance
%   pour un intégrateur ou un retard.
%
%   C'est le réglage qui s'écrit, non le type : « 1/s » dit plus qu'
%   « integrator », et un gain de 2 se lit d'un coup d'œil là où il
%   faudrait sinon ouvrir le bloc.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_sl_etiquette(struct('type', 'integrator', 'parametres', struct()))
%
%   Voir aussi MATLIBRE_SL_FORME, OPEN_SYSTEM, GET_PARAM.
    p = struct();
    if isfield(bloc, 'parametres')
        p = bloc.parametres;
    end
    switch bloc.type
        case 'constant',   texte = nombre(p, 'Value', 0);
        case 'gain',       texte = nombre(p, 'Gain', 1);
        case 'integrator', texte = '1/s';
        case 'derivative', texte = 'du/dt';
        case 'delay',      texte = '1/z';
        case 'product',    texte = '×';
        case 'abs',        texte = '|u|';
        case 'statespace', texte = 'A B C D';
        case 'transferfcn'
            texte = [vecteur(p, 'Numerator') ' / ' vecteur(p, 'Denominator')];
        case 'math'
            texte = 'f(u)';
            if isfield(p, 'Operator')
                texte = char(p.Operator);
            end
        otherwise
            texte = bloc.type;
    end
end

function t = nombre(p, nom, defaut)
    v = defaut;
    if isfield(p, nom)
        v = p.(nom);
    end
    if isscalar(v) && v == round(v)
        t = sprintf('%d', v);
    elseif isscalar(v)
        t = sprintf('%g', v);
    else
        t = mat2str(v);
    end
end

function t = vecteur(p, nom)
    if isfield(p, nom)
        t = mat2str(p.(nom));
    else
        t = '1';
    end
end
