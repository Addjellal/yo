function modele = matlibre_sl_bibliotheque(modele)
%MATLIBRE_SL_BIBLIOTHEQUE Déplie les blocs que Simulink bâtit en sous-systèmes.
%   MODELE = MATLIBRE_SL_BIBLIOTHEQUE(MODELE) remplace chaque bloc de la
%   bibliothèque que Simulink construit comme un sous-système masqué, et
%   que MatLibre ne calcule pas d'un seul tenant, par le sous-système de
%   blocs élémentaires qui fait la même chose. Le bloc garde son nom, ses
%   liens et le relevé de sa sortie ; ses paramètres passent aux blocs du
%   dedans tels qu'on les a écrits, expressions comprises.
%
%   C'est le cas du PID continu dont on borne la sortie, qu'on protège de
%   l'emballement (back-calculation, clamping), qu'on remet à zéro par une
%   entrée, dont les conditions initiales arrivent par des entrées, ou
%   dont la dérivée n'est pas filtrée : il devient gains, intégrateurs,
%   dérivateur, sommes et saturation, comme dans Simulink. Le PID continu
%   ordinaire et le PID discret se calculent d'un seul tenant.
%
%   MATLIBRE_SL_APLATIR l'appelle avant de déplier les sous-systèmes.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = new_system('essai');
%      m = add_block(m, 'pidcontroller', 'k', 'LimitOutput', 'on', ...
%                    'UpperSaturationLimit', 1);
%      m = matlibre_sl_bibliotheque(m);
%      m.blocs{1}.type                              % 'subsystem'
%
%   Voir aussi MATLIBRE_SL_APLATIR, ADD_BLOCK.
    for j = 1:numel(modele.blocs)
        bloc = modele.blocs{j};
        if ~strcmp(bloc.type, 'pidcontroller')
            continue
        end
        p = parametresPID(bloc);
        if ~pidAvance(p)
            continue
        end
        interne = pidContinu(p);
        garde = bloc.parametres;
        bloc.type = 'subsystem';
        bloc.parametres = struct('Model', interne);
        if isfield(garde, 'Position')
            bloc.parametres.Position = garde.Position;
        end
        modele.blocs{j} = bloc;
    end
end

% Les paramètres du PID sous leur nom canonique, avec les défauts.
function p = parametresPID(bloc)
    entree = matlibre_sl_catalogue('type', 'pidcontroller');
    p = struct();
    for i = 1:size(entree.params, 1)
        p.(entree.params{i, 1}) = entree.params{i, 2};
    end
    ecrits = fieldnames(bloc.parametres);
    for i = 1:numel(ecrits)
        canon = matlibre_sl_catalogue('parametre', entree, ecrits{i});
        if ~isempty(canon)
            p.(canon) = bloc.parametres.(ecrits{i});
        end
    end
end

function oui = pidAvance(p)
    choix = @(nom, valeur) strcmpi(char(p.(nom)), valeur);
    oui = choix('TimeDomain', 'Continuous-time') && ...
          (choix('LimitOutput', 'on') || ~choix('ExternalReset', 'none') || ...
           choix('InitialConditionSource', 'external') || choix('UseFilter', 'off'));
end

% Une valeur de paramètre écrite pour un bloc du dedans : telle quelle si
% c'est une expression, en texte sinon, pour pouvoir la composer.
function t = texte(v)
    if ischar(v) || isstring(v)
        t = ['(' char(v) ')'];
    else
        t = mat2str(double(v), 17);
    end
end

% Le PID continu en blocs élémentaires : u, puis Reset, I0 et D0 ; la
% somme des parties proportionnelle, intégrale et dérivée ; la saturation,
% et le retour qui empêche l'intégrale de s'emballer.
function m = pidContinu(p)
    type = upper(char(p.Controller));
    aP = any(type == 'P');
    aI = any(type == 'I');
    aD = any(type == 'D');
    filtre = strcmpi(char(p.UseFilter), 'on');
    ideal = strcmpi(char(p.Form), 'Ideal') && aP;
    borne = strcmpi(char(p.LimitOutput), 'on');
    anti = 'none';
    if borne
        anti = char(p.AntiWindupMode);
    end
    remise = char(p.ExternalReset);
    externe = strcmpi(char(p.InitialConditionSource), 'external');
    gainI = texte(p.I);
    gainD = texte(p.D);
    if ideal
        gainI = [texte(p.P) '*' gainI];
        gainD = [texte(p.P) '*' gainD];
    end
    m = new_system('PID');
    m = add_block(m, 'inport', 'u', 'Port', 1);
    rang = 1;
    if ~strcmpi(remise, 'none')
        rang = rang + 1;
        m = add_block(m, 'inport', 'Reset', 'Port', rang);
    end
    if externe && aI
        rang = rang + 1;
        m = add_block(m, 'inport', 'I0', 'Port', rang);
    end
    if externe && aD && filtre
        rang = rang + 1;
        m = add_block(m, 'inport', 'D0', 'Port', rang);
    end
    parties = {};
    if aP
        m = add_block(m, 'gain', 'Gain P', 'Gain', p.P);
        m = add_line(m, 'u', 'Gain P');
        parties{end + 1} = 'Gain P';
    end
    reglagesIntegrateur = {'ExternalReset', remise};
    if aI
        m = add_block(m, 'gain', 'Gain I', 'Gain', gainI);
        m = add_line(m, 'u', 'Gain I');
        ci = {'InitialCondition', p.InitialConditionForIntegrator};
        if externe
            ci = {'InitialConditionSource', 'external'};
        end
        m = add_block(m, 'integrator', 'Integrateur', reglagesIntegrateur{:}, ci{:});
        entreeI = 'Gain I';
        switch anti
            case 'back-calculation'
                m = add_block(m, 'sum', 'Somme I', 'Signs', '++');
                m = add_line(m, 'Gain I', 'Somme I', 1);
                entreeI = 'Somme I';
            case 'clamping'
                m = add_block(m, 'matlabfunction', 'Blocage', 'Script', ...
                              sprintf(['function x = fcn(iu, y, yb)\nx = iu;\n' ...
                                       'x((y ~= yb) & (sign(iu) == sign(y - yb))) = 0;\n']));
                m = add_line(m, 'Gain I', 'Blocage', 1);
                entreeI = 'Blocage';
        end
        m = add_line(m, entreeI, 'Integrateur', 1);
        port = 2;
        if ~strcmpi(remise, 'none')
            m = add_line(m, 'Reset', 'Integrateur', port);
            port = port + 1;
        end
        if externe
            m = add_line(m, 'I0', 'Integrateur', port);
        end
        parties{end + 1} = 'Integrateur';
    end
    if aD && filtre
        % f' = N (D u - f) : le filtre est un intégrateur bouclé
        m = add_block(m, 'gain', 'Gain D', 'Gain', gainD);
        m = add_block(m, 'sum', 'Somme D', 'Signs', '+-');
        m = add_block(m, 'gain', 'Coefficient N', 'Gain', p.N);
        ci = {'InitialCondition', p.InitialConditionForFilter};
        if externe
            ci = {'InitialConditionSource', 'external'};
        end
        m = add_block(m, 'integrator', 'Filtre', reglagesIntegrateur{:}, ci{:});
        m = add_line(add_line(m, 'u', 'Gain D'), 'Gain D', 'Somme D', 1);
        m = add_line(add_line(m, 'Filtre', 'Somme D', 2), 'Somme D', 'Coefficient N');
        m = add_line(m, 'Coefficient N', 'Filtre', 1);
        port = 2;
        if ~strcmpi(remise, 'none')
            m = add_line(m, 'Reset', 'Filtre', port);
            port = port + 1;
        end
        if externe
            m = add_line(m, 'D0', 'Filtre', port);
        end
        parties{end + 1} = 'Coefficient N';
    elseif aD
        m = add_block(m, 'gain', 'Gain D', 'Gain', gainD);
        m = add_block(m, 'derivative', 'Derivee');
        m = add_line(add_line(m, 'u', 'Gain D'), 'Gain D', 'Derivee');
        parties{end + 1} = 'Derivee';
    end
    % la somme des parties ; une seule partie passe telle quelle, car une
    % somme à une entrée additionnerait les éléments d'un vecteur
    if numel(parties) > 1
        m = add_block(m, 'sum', 'Somme', 'Signs', repmat('+', 1, numel(parties)));
        for q = 1:numel(parties)
            m = add_line(m, parties{q}, 'Somme', q);
        end
        brut = 'Somme';
    else
        brut = parties{1};
    end
    m = add_block(m, 'outport', 'y', 'Port', 1);
    if borne
        m = add_block(m, 'saturation', 'Saturation', 'UpperLimit', ...
                      p.UpperSaturationLimit, 'LowerLimit', p.LowerSaturationLimit);
        m = add_line(add_line(m, brut, 'Saturation'), 'Saturation', 'y');
        switch anti
            case 'back-calculation'
                m = add_block(m, 'sum', 'Ecart', 'Signs', '+-');
                m = add_block(m, 'gain', 'Kb', 'Gain', p.Kb);
                m = add_line(add_line(m, 'Saturation', 'Ecart', 1), brut, 'Ecart', 2);
                m = add_line(add_line(m, 'Ecart', 'Kb'), 'Kb', 'Somme I', 2);
            case 'clamping'
                if aI
                    m = add_line(add_line(m, brut, 'Blocage', 2), 'Saturation', 'Blocage', 3);
                end
        end
    else
        m = add_line(m, brut, 'y');
    end
end
