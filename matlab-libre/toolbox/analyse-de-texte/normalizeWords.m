function sortie = normalizeWords(mots, varargin)
%NORMALIZEWORDS Racinisation des mots anglais (Porter), comme MATLAB.
%   SORTIE = NORMALIZEWORDS(MOTS) ramène chaque mot à sa racine par
%   l'algorithme de Porter (1980), celui qu'emploie MATLAB pour l'anglais,
%   après passage en minuscules. MOTS est une cellule de mots (celle de
%   TOKENIZEDDOCUMENT), un tableau de chaînes ou un texte ; SORTIE a la
%   même forme.
%
%   Le but est de reconnaître « connect », « connected », « connecting »
%   et « connection » comme un même terme, pour ne pas les compter
%   séparément. La racine obtenue n'est pas toujours un mot (« poni »
%   pour « ponies ») : c'est une clé de regroupement.
%
%   L'implémentation suit celle de référence de Martin Porter, et
%   reproduit les 23 531 racines du jeu d'essai de l'auteur. Les options
%   'Style','lemma' (lemmatisation, qui demande un dictionnaire) et
%   'Language' autre que 'en' ne sont pas encore là : elles sont refusées
%   en le disant.
%
%   Exemple :
%      normalizeWords({'connected', 'connecting', 'connection', 'connections'})
%      normalizeWords(["caresses" "ponies" "relational" "generalizations"])
%      % caress, poni, relat, gener
%
%   Voir aussi TOKENIZEDDOCUMENT, REMOVESTOPWORDS, BAGOFWORDS.
    if mod(numel(varargin), 2) ~= 0
        error('textanalytics:normalizeWords:Options', 'Options must be name-value pairs.');
    end
    for k = 1:2:numel(varargin)
        nom = lower(char(varargin{k}));
        valeur = lower(char(varargin{k + 1}));
        if strcmp(nom, 'style') && ~strcmp(valeur, 'stem')
            error('textanalytics:normalizeWords:Style', ...
                  ['MatLibre supports only Porter stemming (''stem''), ' ...
                   'not lemmatization.']);
        elseif strcmp(nom, 'language') && ~strcmp(valeur, 'en')
            error('textanalytics:normalizeWords:Langue', ...
                  'Porter stemming applies to English (''en'') only.');
        elseif ~any(strcmp(nom, {'style', 'language'}))
            error('textanalytics:normalizeWords:Option', 'Option inconnue : %s.', nom);
        end
    end
    if ischar(mots)
        sortie = matlibre_porter(mots);
    elseif isstring(mots)
        sortie = mots;
        for k = 1:numel(mots)
            sortie(k) = string(matlibre_porter(char(mots(k))));
        end
    elseif iscell(mots)
        sortie = cell(size(mots));
        for k = 1:numel(mots)
            sortie{k} = matlibre_porter(mots{k});
        end
    else
        error('textanalytics:normalizeWords:Type', ...
              'WORDS must be text, a string array, or a cell array of words.');
    end
end
