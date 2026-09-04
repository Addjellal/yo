function g = matlibre_dl_gradients_de(variable, gradients)
%MATLIBRE_DL_GRADIENTS_DE Dérivée rendue sous la forme de la variable.
%   G = MATLIBRE_DL_GRADIENTS_DE(VARIABLE,GRADIENTS) va chercher, dans le
%   tableau des dérivées par nœud, celle qui revient à la variable — et
%   rend la même forme qu'elle : un DLARRAY, un tableau de cellules ou
%   une structure. Une variable dont la perte ne dépend pas reçoit une
%   dérivée nulle plutôt qu'un tableau vide, ce qui laisse les solveurs
%   travailler sans cas particulier.
%
%   Exemple :
%      g = matlibre_dl_gradients_de(dlarray(1), {[]});
%
%   Voir aussi DLGRADIENT.
    if isa(variable, 'dlarray')
        if variable.Noeud > 0 && variable.Noeud <= numel(gradients) && ...
           ~isempty(gradients{variable.Noeud})
            valeur = gradients{variable.Noeud};
        else
            valeur = zeros(size(variable.Valeur));
        end
        g = matlibre_dl_construire(valeur, variable.Format, 0);
    elseif isa(variable, 'dlnetwork')
        g = variable.Learnables;
        g.Value = matlibre_dl_gradients_de(variable.Learnables.Value, gradients);
    elseif istable(variable)
        g = variable;
        g.Value = matlibre_dl_gradients_de(variable.Value, gradients);
    elseif iscell(variable)
        g = variable;
        for k = 1:numel(variable)
            g{k} = matlibre_dl_gradients_de(variable{k}, gradients);
        end
    elseif isstruct(variable)
        g = variable;
        noms = fieldnames(variable);
        for e = 1:numel(variable)
            for k = 1:numel(noms)
                g(e).(noms{k}) = matlibre_dl_gradients_de(variable(e).(noms{k}), gradients);
            end
        end
    else
        g = zeros(size(variable));
    end
end
