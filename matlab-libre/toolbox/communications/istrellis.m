function [correct, message] = istrellis(t)
%ISTRELLIS Vérification d'une structure de treillis.
%   OK = ISTRELLIS(T) est vrai quand T porte les cinq champs attendus,
%   des tailles cohérentes, et des états et sorties dans les bornes.
%   [OK,MESSAGE] = ISTRELLIS(T) rend en plus la raison du refus.
%
%   Exemple :
%      istrellis(poly2trellis(3, [7 5]))   % vrai
%
%   Voir aussi POLY2TRELLIS, CONVENC, VITDEC.
    correct = false;
    message = '';
    champs = {'numInputSymbols', 'numOutputSymbols', 'numStates', ...
              'nextStates', 'outputs'};
    if ~isstruct(t)
        message = 'Le treillis doit être une structure.';
        return
    end
    for k = 1:numel(champs)
        if ~isfield(t, champs{k})
            message = sprintf('Champ manquant : %s.', champs{k});
            return
        end
    end
    ni = t.numInputSymbols;
    no = t.numOutputSymbols;
    ns = t.numStates;
    if ni < 1 || no < 1 || ns < 1 || ...
       abs(log2(ni) - round(log2(ni))) > 0 || ...
       abs(log2(no) - round(log2(no))) > 0 || ...
       abs(log2(ns) - round(log2(ns))) > 0
        message = 'Les nombres de symboles et d''états doivent être des puissances de deux.';
        return
    end
    if ~isequal(size(t.nextStates), [ns, ni])
        message = 'nextStates doit être de taille numStates x numInputSymbols.';
        return
    end
    if ~isequal(size(t.outputs), [ns, ni])
        message = 'outputs doit être de taille numStates x numInputSymbols.';
        return
    end
    if any(any(t.nextStates < 0)) || any(any(t.nextStates > ns - 1)) || ...
       any(any(t.nextStates ~= round(t.nextStates)))
        message = 'nextStates doit contenir des états valides.';
        return
    end
    valeurs = oct2dec(t.outputs);
    if any(any(valeurs < 0)) || any(any(valeurs > no - 1))
        message = 'outputs doit contenir des symboles valides.';
        return
    end
    correct = true;
end
