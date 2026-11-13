function o = matlibre_sdi_options(args, nomFonction)
%MATLIBRE_SDI_OPTIONS Les options d'une comparaison du Simulation Data Inspector.
%   O = MATLIBRE_SDI_OPTIONS(ARGS,FONCTION) lit les paires 'AbsTol',
%   'RelTol', 'TimeTol' (des nombres positifs ou nuls), 'InterpMethod'
%   ('linear', 'zoh') et 'SyncMethod' ('union', 'intersection') ; une
%   option inconnue est refusée.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      o = matlibre_sdi_options({'AbsTol', 0.1}, 'compareRuns');
%      o.AbsTol                           % 0.1
%
%   Voir aussi SIMULINK.SDI.COMPARERUNS, SIMULINK.SDI.COMPARESIGNALS.
    o = struct();
    if mod(numel(args), 2) ~= 0
        error('SDI:sdi:InvalidOption', ...
              '%s(...,''Option'',VALEUR) : les options vont par paires.', nomFonction);
    end
    for k = 1:2:numel(args)
        nom = args{k};
        v = args{k + 1};
        if ~(ischar(nom) || (isstring(nom) && isscalar(nom)))
            error('SDI:sdi:InvalidOption', 'Une option de %s se nomme par un texte.', nomFonction);
        end
        switch lower(char(nom))
            case {'abstol', 'reltol', 'timetol'}
                if ~isnumeric(v) || ~isscalar(v) || ~isreal(v) || ~(v >= 0) || ~isfinite(v)
                    error('SDI:sdi:InvalidTolerance', ...
                          '%s est un nombre reel positif ou nul, fini.', char(nom));
                end
                canon = struct('abstol', 'AbsTol', 'reltol', 'RelTol', 'timetol', 'TimeTol');
                o.(canon.(lower(char(nom)))) = double(v);
            case 'interpmethod'
                o.InterpMethod = choix('InterpMethod', v, {'linear', 'zoh'});
            case 'syncmethod'
                o.SyncMethod = choix('SyncMethod', v, {'union', 'intersection'});
            otherwise
                error('SDI:sdi:InvalidOption', ...
                      ['%s ne connait pas l''option ''%s'' : AbsTol, RelTol, TimeTol, ' ...
                       'InterpMethod, SyncMethod.'], nomFonction, char(nom));
        end
    end
end

function v = choix(nom, v, admis)
    k = [];
    if ischar(v) || (isstring(v) && isscalar(v))
        k = find(strcmpi(char(v), admis), 1);
    end
    if isempty(k)
        error('SDI:sdi:InvalidValue', '%s vaut %s.', nom, strjoin(admis, ' ou '));
    end
    v = admis{k};
end
