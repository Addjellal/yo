function y = matlibre_dl_tracer(x)
%MATLIBRE_DL_TRACER Fait de chaque DLARRAY une feuille de la bande.
%   Y = MATLIBRE_DL_TRACER(X) recrée les DLARRAY que X contient en les
%   rattachant à la bande qui vient d'être ouverte. X peut être un
%   DLARRAY, un tableau de cellules, une structure ou un tableau de
%   structures : les paramètres d'un réseau se rangent ainsi, et il faut
%   que chacun soit dérivable.
%
%   Exemple :
%      matlibre_bande('ouvrir');
%      p = matlibre_dl_tracer(struct('W', dlarray(1)));
%      matlibre_bande('fermer');
%
%   Voir aussi DLFEVAL, DLGRADIENT.
    if isa(x, 'dlarray')
        y = matlibre_dl_construire(x.Valeur, x.Format, ...
                                   matlibre_bande('ajouter', 'feuille', [], {}));
    elseif isa(x, 'dlnetwork')
        % Les poids d'un réseau se dérivent comme n'importe quel
        % paramètre : c'est sa table qu'il faut rattacher à la bande.
        y = x;
        y.Learnables = matlibre_dl_tracer(x.Learnables);
    elseif istable(x)
        y = x;
        y.Value = matlibre_dl_tracer(x.Value);
    elseif iscell(x)
        y = x;
        for k = 1:numel(x)
            y{k} = matlibre_dl_tracer(x{k});
        end
    elseif isstruct(x)
        y = x;
        noms = fieldnames(x);
        for e = 1:numel(x)
            for k = 1:numel(noms)
                y(e).(noms{k}) = matlibre_dl_tracer(x(e).(noms{k}));
            end
        end
    else
        y = x;
    end
end
