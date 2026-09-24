function [module, phase, w] = bode(varargin)
%BODE Diagramme de Bode : module et phase de la réponse fréquentielle.
%   BODE(SYS) trace le gain en décibels et la phase en degrés du modèle
%   SYS en fonction de la pulsation, l'abscisse en échelle logarithmique.
%   Le gain occupe la moitié haute de la case courante, la phase la
%   moitié basse.
%
%   BODE(SYS,W) impose la grille de pulsations, en radians par seconde :
%   un vecteur, ou {WMIN,WMAX} pour n'en donner que les bornes.
%
%   BODE(SYS1,SYS2,...) superpose plusieurs modèles. Une chaîne de style
%   peut suivre chacun d'eux, comme dans PLOT :
%   BODE(SYS1,'b',SYS2,'r--',W).
%
%   [MODULE,PHASE] = BODE(SYS) ne trace rien et rend le module — linéaire,
%   pas en décibels — et la phase en degrés. [MODULE,PHASE,W] = BODE(SYS)
%   rend en plus la grille employée. Avec des sorties, un seul modèle est
%   accepté, comme dans MATLAB.
%
%   Pour un modèle échantillonné, la réponse est évaluée sur le cercle
%   unité, en exp(j*W*Ts) ; pour un modèle continu, en j*W.
%
%   Un modèle à plusieurs entrées et sorties répond sur chaque couple :
%   MODULE et PHASE sont alors de taille NY x NU x NW, comme dans MATLAB,
%   et le tracé en fait une grille — pour chaque sortie, une ligne de
%   modules au-dessus d'une ligne de phases. Un modèle à une voie rend
%   des colonnes, comme avant.
%
%   BODE(...,OPTIONS) où OPTIONS vient de BODEOPTIONS règle le tracé :
%   FreqUnits, MagUnits, PhaseUnits, Grid, XLim, YLim, Title, XLabel et
%   YLabel sont suivis.
%
%   Exemples :
%      bode(tf(1, [1 2 1]))
%      bode(tf(1, [1 1]), tf(1, [1 0.2 1]), logspace(-2, 2, 500))
%      [m, p] = bode(tf(1, [1 1]), 1);   % m = 0.7071, p = -45
%
%   Voir aussi BODEMAG, NICHOLS, NYQUIST, SIGMA, MARGIN, FREQRESP,
%   BODEOPTIONS.
    [modeles, styles, w, options] = matlibre_arguments_lti(varargin);
    if isempty(modeles)
        error('MATLAB:minrhs', 'Not enough input arguments.');
    end
    if nargout > 0
        if numel(modeles) > 1
            error('Control:analysis:MultipleModels', ...
                  ['The command BODE(SYS1,SYS2,...) with output arguments ' ...
                   'is not supported.']);
        end
        [module, phase, w] = reponseBode(modeles{1}, w);
        return;
    end

    reglage = matlibre_reglages_bode(options);
    if ~estMonovoie(modeles{1})
        tracerGrille(modeles, styles, w, reglage);
        return;
    end
    gain = {};
    dephasage = {};
    for k = 1:numel(modeles)
        [m, p, wk] = reponseBode(modeles{k}, w);
        gain{end+1} = wk / reglage.diviseurW;   %#ok<AGROW>
        if reglage.enDecibels
            gain{end+1} = 20 * log10(m);        %#ok<AGROW>
        else
            gain{end+1} = m;                    %#ok<AGROW>
        end
        dephasage{end+1} = wk / reglage.diviseurW;  %#ok<AGROW>
        dephasage{end+1} = p * reglage.facteurPhase; %#ok<AGROW>
        if ~isempty(styles{k})
            gain{end+1} = styles{k};        %#ok<AGROW>
            dephasage{end+1} = styles{k};   %#ok<AGROW>
        end
    end

    [haut, bas] = matlibre_cases_bode();
    axes(haut);
    semilogx(gain{:});
    grid(reglage.grille);
    ylabel(reglage.nomGain);
    title(reglage.titre);
    if ~isempty(reglage.xlim), xlim(reglage.xlim / reglage.diviseurW); end
    if ~isempty(reglage.ylim), ylim(reglage.ylim); end
    axes(bas);
    semilogx(dephasage{:});
    grid(reglage.grille);
    xlabel(reglage.nomPulsation);
    ylabel(reglage.nomPhase);
    if ~isempty(reglage.xlim), xlim(reglage.xlim / reglage.diviseurW); end
    axes(bas);
end

function [module, phase, w] = reponseBode(sys, w)
%REPONSEBODE Module et phase d'un modèle sur une grille de pulsations.
    if ~estMonovoie(sys)
        % A plusieurs voies, FREQRESP rend deja la matrice de transfert en
        % chaque pulsation, retards compris : le module et la phase se
        % lisent couple par couple, la phase deroulee le long des
        % pulsations.
        if isempty(w)
            w = matlibre_pulsations(sys);
        end
        w = w(:);
        H = freqresp(sys, w);
        module = abs(H);
        phase = zeros(size(H));
        for i = 1:size(H, 1)
            for j = 1:size(H, 2)
                phase(i, j, :) = reshape(unwrap(angle(reshape(H(i, j, :), [], 1))), ...
                                         1, 1, []) * 180 / pi;
            end
        end
        return
    end
    g = tf(sys);
    if isempty(w)
        w = matlibre_pulsations(g);
    end
    w = w(:);
    if g.Ts > 0
        s = exp(1i * w * g.Ts);
    else
        s = 1i * w;
    end
    h = polyval(g.num, s) ./ polyval(g.den, s);
    % Le retard tourne la phase de w*D, sans toucher au module : c'est
    % ainsi qu'il mange la marge de phase, et MARGIN, NYQUIST et NICHOLS
    % le voient parce qu'ils passent tous par ici.
    d = matlibre_retard_scalaire(sys, 'BODE');
    if d ~= 0
        h = h(:) .* exp(-1i * w(:) * d);
    end
    module = abs(h);
    phase = unwrap(angle(h)) * 180 / pi;
end

function oui = estMonovoie(sys)
    modele = ss(sys);
    oui = size(modele.D, 1) == 1 && size(modele.D, 2) == 1;
end

% Pour chaque sortie, deux lignes de cases : les modules au-dessus, les
% phases dessous ; une colonne par entree. Chaque modele se superpose.
function tracerGrille(modeles, styles, w, reglage)
    reference = ss(modeles{1});
    [cases, entrees, sorties] = matlibre_grille_voies(modeles{1}, 2);
    modules = cell(1, numel(modeles));
    phases = cell(1, numel(modeles));
    grilles = cell(1, numel(modeles));
    for k = 1:numel(modeles)
        autre = ss(modeles{k});
        if ~isequal(size(autre.D), size(reference.D))
            error('Control:analysis:MultipleModels', ...
                  'Les modeles superposes doivent avoir les memes entrees et sorties.');
        end
        [modules{k}, phases{k}, grilles{k}] = reponseBode(modeles{k}, w);
    end
    ny = size(reference.D, 1);
    nu = size(reference.D, 2);
    for i = 1:ny
        for j = 1:nu
            courbesModule = {};
            courbesPhase = {};
            for k = 1:numel(modeles)
                pulsations = grilles{k} / reglage.diviseurW;
                m = reshape(modules{k}(i, j, :), [], 1);
                if reglage.enDecibels
                    m = 20 * log10(m);
                end
                courbesModule = [courbesModule, {pulsations, m}];              %#ok<AGROW>
                courbesPhase = [courbesPhase, {pulsations, ...
                    reshape(phases{k}(i, j, :), [], 1) * reglage.facteurPhase}]; %#ok<AGROW>
                if ~isempty(styles{k})
                    courbesModule{end + 1} = styles{k};                        %#ok<AGROW>
                    courbesPhase{end + 1} = styles{k};                         %#ok<AGROW>
                end
            end
            axes(cases{2 * i - 1, j});
            semilogx(courbesModule{:});
            grid(reglage.grille);
            title(sprintf('De %s vers %s', entrees{j}, sorties{i}));
            if j == 1, ylabel(reglage.nomGain); end
            axes(cases{2 * i, j});
            semilogx(courbesPhase{:});
            grid(reglage.grille);
            if j == 1, ylabel(reglage.nomPhase); end
            if i == ny, xlabel(reglage.nomPulsation); end
        end
    end
end
