function varargout = fetchOutputs(futur)
%FETCHOUTPUTS Résultats d'une tâche lancée par PARFEVAL.
    for k = 1:numel(futur.resultats)
        varargout{k} = futur.resultats{k};
    end
end
