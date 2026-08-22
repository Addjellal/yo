function sortie = removeStopWords(mots, liste)
%REMOVESTOPWORDS Retire les mots vides d'une liste de mots.
    if nargin < 2
        liste = {'le','la','les','de','des','du','un','une','et','ou','a', ...
                 'the','of','and','to','in','is','it','that','for','on', ...
                 'with','as','was','at','by','an','be','this','are','from'};
    end
    sortie = {};
    for k = 1:numel(mots)
        if ~any(strcmp(liste, mots{k}))
            sortie{end+1} = mots{k};
        end
    end
end
