classdef tabularTextDatastore < handle
%TABULARTEXTDATASTORE Lecture par morceaux d'un ou plusieurs fichiers texte.
%   DS = TABULARTEXTDATASTORE(CHEMIN) ouvre un fichier, une liste de
%   fichiers, ou tous les fichiers d'un dossier. La lecture se fait
%   ensuite par morceaux : READ rend le suivant, HASDATA dit s'il en
%   reste, RESET revient au début, READALL lit tout d'un coup.
%
%   L'intérêt d'un magasin de données est de ne pas tout charger : un jeu
%   plus gros que la mémoire se traite morceau par morceau, et le
%   programme qui le parcourt ne change pas quand le jeu grandit. C'est
%   la seule raison d'en employer un ; pour un fichier qui tient en
%   mémoire, READTABLE suffit et va plus vite.
%
%   Réglages : 'ReadSize' (nombre de lignes par morceau, 20000 par
%   défaut), 'Delimiter', 'ReadVariableNames', 'TreatAsMissing'.
%
%   Le magasin se copie par référence : READ le fait avancer, sans qu'on
%   ait à le réaffecter. C'est ce qui permet d'écrire la boucle usuelle —
%   « while hasdata(ds), morceau = read(ds); end » — qui ne se terminerait
%   jamais sur un objet qui se copierait par valeur.
%
%   Exemple :
%      f = [tempname '.csv'];
%      writelines(["a,b"; "1,2"; "3,4"; "5,6"], f);
%      ds = tabularTextDatastore(f, 'ReadSize', 2);
%      premier = read(ds);
%      height(premier)                 % 2 lignes : le morceau demande
%      delete(f);
%
%   Voir aussi DATASTORE, READTABLE, READ, READALL, PRESERVE.
    properties
        Files = {}
        ReadSize = 20000
        Delimiter = ','
        ReadVariableNames = true
        TreatAsMissing = {}
        VariableNames = {}
    end
    properties (Access = private)
        Position = 1
        Cache = []
    end

    methods
        function ds = tabularTextDatastore(chemin, varargin)
            if nargin == 0
                return
            end
            ds.Files = matlibre_datastore_fichiers(chemin, {'.csv', '.txt', '.dat'});
            if isempty(ds.Files)
                error('MATLAB:datastore:FileNotFound', ...
                      'Aucun fichier lisible a « %s ».', char(string(chemin)));
            end
            options = matlibre_lire_options(varargin, ...
                struct('ReadSize', 20000, 'Delimiter', ',', ...
                       'ReadVariableNames', true, 'TreatAsMissing', {{}}));
            ds.ReadSize = options.ReadSize;
            ds.Delimiter = options.Delimiter;
            ds.ReadVariableNames = options.ReadVariableNames;
            ds.TreatAsMissing = options.TreatAsMissing;
            charger(ds);
        end

        function charger(ds)
        %CHARGER Lit tous les fichiers en une table, une fois pour toutes.
        %   La lecture par morceaux qui suit découpe cette table. Un vrai
        %   magasin lirait le fichier au fur et à mesure ; ici la lecture
        %   est faite d'avance, ce qui donne le même résultat mais n'évite
        %   pas la mémoire — l'aide de DATASTORE le dit.
            morceaux = {};
            for k = 1:numel(ds.Files)
                morceaux{end + 1} = readtable(ds.Files{k}, ...
                                              'Delimiter', ds.Delimiter, ...
                                              'ReadVariableNames', ...
                                              ds.ReadVariableNames);   %#ok<AGROW>
            end
            ds.Cache = morceaux{1};
            for k = 2:numel(morceaux)
                ds.Cache = [ds.Cache; morceaux{k}];
            end
            ds.VariableNames = ds.Cache.Properties.VariableNames;
            ds.Position = 1;
        end

        function t = hasdata(ds)
        %HASDATA Reste-t-il quelque chose à lire ?
            t = ds.Position <= height(ds.Cache);
        end

        function donnees = read(ds)
        %READ Le morceau suivant.
        %   Rend au plus READSIZE lignes, et avance. Lire au-delà de la
        %   fin est une erreur : c'est HASDATA qui dit quand s'arrêter.
            if ~hasdata(ds)
                error('MATLAB:datastore:NoMoreData', ...
                      'Il n''y a plus rien a lire. Employez HASDATA ou RESET.');
            end
            dernier = min(ds.Position + ds.ReadSize - 1, height(ds.Cache));
            donnees = ds.Cache(ds.Position:dernier, :);
            ds.Position = dernier + 1;
        end

        function donnees = readall(ds)
        %READALL Tout le contenu, d'un coup.
            donnees = ds.Cache;
        end

        function donnees = preview(ds)
        %PREVIEW Les huit premières lignes, sans avancer.
        %   Sert à voir de quoi le jeu est fait avant de le parcourir.
            dernier = min(8, height(ds.Cache));
            donnees = ds.Cache(1:dernier, :);
        end

        function reset(ds)
        %RESET Revient au début.
            ds.Position = 1;
        end

        function n = numpartitions(ds, varargin)
        %NUMPARTITIONS Nombre de morceaux que la lecture produira.
            n = max(1, ceil(height(ds.Cache) / ds.ReadSize));
        end
    end
end
