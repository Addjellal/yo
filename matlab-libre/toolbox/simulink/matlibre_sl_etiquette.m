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
        case 'bias',       texte = ['u + ' nombre(p, 'Bias', 0)];
        case 'memory',     texte = 'u(k-1)';
        case 'unitdelay',  texte = '1/z';
        case 'inport',     texte = ['in ' nombre(p, 'Port', 1)];
        case 'outport',    texte = ['out ' nombre(p, 'Port', 1)];
        case 'minmax'
            texte = 'min';
            if isfield(p, 'Function')
                texte = lower(char(p.Function));
            end
        case {'logic', 'relational'}
            texte = 'op';
            if isfield(p, 'Operator')
                texte = char(p.Operator);
            end
        case 'trigonometry'
            texte = 'sin';
            if isfield(p, 'Operator')
                texte = lower(char(p.Operator));
            end
        case 'switch',     texte = 'u1 / u3';
        case 'pidcontroller', texte = 'PID';
        case 'discreteintegrator', texte = 'T/(z-1)';
        case 'discretestatespace', texte = 'A B C D (z)';
        case 'discretetransferfcn'
            texte = [vecteur(p, 'Numerator') ' / ' vecteur(p, 'Denominator') '  (z)'];
        otherwise
            texte = bloc.type;
    end
end

function t = nombre(p, nom, defaut)
    v = defaut;
    if isfield(p, nom)
        v = p.(nom);
    end
    % Un paramètre donné par une expression s'écrit tel quel : « K » dit
    % d'où vient la valeur, là où le nombre qu'elle vaut aujourd'hui ne le
    % dirait pas. C'est ce que Simulink affiche dans le bloc.
    if ischar(v) || isstring(v)
        t = char(v);
        return
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
        if ischar(p.(nom)) || isstring(p.(nom))
            t = char(p.(nom));
            return
        end
        t = mat2str(p.(nom));
    else
        t = '1';
    end
end
