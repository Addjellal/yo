function r = matlibre_reglages_bode(options)
%MATLIBRE_REGLAGES_BODE Ce qu'un tracé retient d'une structure d'options.
%   R = MATLIBRE_REGLAGES_BODE(OPTIONS) lit la structure que rend
%   BODEOPTIONS et en tire ce dont BODE et BODEMAG ont besoin : le
%   diviseur qui porte la pulsation dans l'unité demandée, le choix des
%   décibels, le facteur de phase, la grille, les bornes et les libellés.
%   OPTIONS vide rend les valeurs par défaut.
%
%   Cette fonction est un utilitaire interne de la boîte à outils
%   Automatique : elle n'existe pas dans MATLAB.
%
%   Voir aussi BODE, BODEMAG, BODEOPTIONS.
    r = struct('diviseurW', 1, 'enDecibels', true, 'facteurPhase', 1, ...
               'grille', 'on', 'nomPulsation', 'Pulsation (rad/s)', ...
               'nomGain', 'Gain (dB)', 'nomPhase', 'Phase (deg)', ...
               'titre', 'Diagramme de Bode', 'xlim', [], 'ylim', []);
    if isempty(options) || ~isstruct(options)
        return;
    end
    if champRempli(options, 'FreqUnits')
        switch lower(char(options.FreqUnits))
            case {'hz', 'cycles/timeunit'}
                r.diviseurW = 2 * pi;
                r.nomPulsation = 'Fréquence (Hz)';
            case 'khz'
                r.diviseurW = 2 * pi * 1e3;
                r.nomPulsation = 'Fréquence (kHz)';
            case 'mhz'
                r.diviseurW = 2 * pi * 1e6;
                r.nomPulsation = 'Fréquence (MHz)';
            case 'rpm'
                r.diviseurW = 2 * pi / 60;
                r.nomPulsation = 'Vitesse (tr/min)';
            otherwise
                % 'rad/s' et 'rad/TimeUnit' : rien à changer.
        end
    end
    if champRempli(options, 'MagUnits') && strcmpi(char(options.MagUnits), 'abs')
        r.enDecibels = false;
        r.nomGain = 'Gain';
    end
    if champRempli(options, 'PhaseUnits') && strncmpi(char(options.PhaseUnits), 'rad', 3)
        r.facteurPhase = pi / 180;
        r.nomPhase = 'Phase (rad)';
    end
    if champRempli(options, 'Grid')
        r.grille = lower(char(options.Grid));
    end
    r.xlim = borne(options, 'XLim');
    r.ylim = borne(options, 'YLim');
    r.titre = etiquette(options, 'Title', r.titre);
    r.nomPulsation = etiquette(options, 'XLabel', r.nomPulsation);
    r.nomGain = etiquette(options, 'YLabel', r.nomGain);
end

function tf_ = champRempli(s, nom)
    tf_ = isfield(s, nom) && ~isempty(s.(nom));
end

function v = borne(options, nom)
%BORNE Les deux bornes d'un axe, que BODEOPTIONS range dans une cellule.
    v = [];
    if ~champRempli(options, nom)
        return;
    end
    valeur = options.(nom);
    if iscell(valeur)
        if isempty(valeur), return; end
        valeur = valeur{1};
    end
    if numel(valeur) == 2
        v = double(valeur(:)).';
    end
end

function texte = etiquette(options, nom, defaut)
%ETIQUETTE Le texte d'un libellé, que BODEOPTIONS range dans une
%   structure à champ « String ».
    texte = defaut;
    if ~isfield(options, nom)
        return;
    end
    valeur = options.(nom);
    if isstruct(valeur) && isfield(valeur, 'String')
        valeur = valeur.String;
    end
    if (ischar(valeur) || isstring(valeur)) && ~isempty(char(valeur))
        texte = char(valeur);
    end
end
