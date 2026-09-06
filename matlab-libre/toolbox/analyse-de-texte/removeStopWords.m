function sortie = removeStopWords(mots, liste)
%REMOVESTOPWORDS Retire les mots vides d'une liste de mots.
%   SORTIE = REMOVESTOPWORDS(MOTS) retire les articles, prépositions et
%   auxiliaires les plus courants, en français et en anglais.
%   REMOVESTOPWORDS(MOTS,LISTE) emploie une autre liste.
%
%   Les mots vides sont ceux qui apparaissent partout et ne distinguent
%   donc rien : les garder gonfle le vocabulaire et noie le signal. Les
%   retirer n'est pourtant pas toujours bon — « ne » et « pas » sont des
%   mots vides et portent la négation, ce qui compte beaucoup pour une
%   analyse de sentiment.
%
%   La pondération TF-IDF fait un travail voisin, en donnant de fait un
%   poids nul à ce qui apparaît dans tous les documents. Elle a
%   l'avantage de le faire d'après le corpus, non d'après une liste
%   décidée à l'avance.
%
%   Exemple :
%      removeStopWords({'le','chat','et','le','chien'})   % {'chat','chien'}
%
%   Voir aussi TOKENIZEDDOCUMENT, TFIDF, WORDFREQUENCY.
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
