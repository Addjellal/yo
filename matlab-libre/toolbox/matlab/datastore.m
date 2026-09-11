function ds = datastore(chemin, varargin)
%DATASTORE Magasin de données, choisi d'après ce qu'on lui donne.
%   DS = DATASTORE(CHEMIN) construit le magasin qui convient : texte
%   tabulaire pour un .csv, .txt ou .dat, images pour un dossier
%   d'images. DATASTORE(...,'Type',TYPE) l'impose : 'tabulartext' ou
%   'image'.
%
%   Un magasin se parcourt par morceaux : READ rend le suivant, HASDATA
%   dit s'il en reste, RESET revient au début, READALL lit tout d'un coup
%   et PREVIEW montre les premières lignes sans avancer.
%
%   Ce qui n'est pas fait : la lecture réellement paresseuse. Le fichier
%   est lu une fois pour toutes à la construction, puis découpé. Le
%   programme qui parcourt le magasin est donc le même que sous MATLAB,
%   mais la mémoire n'est pas économisée — et c'est la seule raison
%   d'employer un magasin. L'annoncer vaut mieux que de le laisser
%   découvrir sur un jeu qui ne tient pas.
%
%   Exemple :
%      f = [tempname '.csv'];
%      writelines(["a,b"; "1,2"; "3,4"], f);
%      ds = datastore(f);
%      height(readall(ds))             % 2 lignes de donnees
%      delete(f);
%
%   Voir aussi TABULARTEXTDATASTORE, IMAGEDATASTORE, READ, READALL, PREVIEW.
    options = matlibre_lire_options(varargin(matlibre_datastore_typeSeul(varargin)), ...
                                    struct('Type', ''));
    reste = varargin(~matlibre_datastore_typeSeul(varargin));
    type = lower(char(options.Type));
    if isempty(type)
        type = matlibre_datastore_deviner(chemin);
    end
    switch type
        case {'tabulartext', 'tabular', 'text'}
            ds = tabularTextDatastore(chemin, reste{:});
        case 'image'
            ds = imageDatastore(chemin, reste{:});
        otherwise
            error('MATLAB:datastore:UnknownType', ...
                  'Type de magasin inconnu : ''%s''.', type);
    end
end
