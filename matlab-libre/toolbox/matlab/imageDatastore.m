classdef imageDatastore < handle
%IMAGEDATASTORE Lecture par morceaux d'une collection d'images.
%   DS = IMAGEDATASTORE(CHEMIN) rassemble les images d'un dossier, d'une
%   liste de fichiers ou d'un motif. READ rend l'image suivante, HASDATA
%   dit s'il en reste, RESET revient au début, READALL les lit toutes.
%
%   DS.Labels peut recevoir une étiquette par image — c'est ainsi qu'on
%   décrit un jeu d'apprentissage, et COUNTEACHLABEL en compte les
%   classes.
%
%   Les formats lisibles sont ceux d'IMREAD : PGM et PPM en texte. Les
%   autres demandent une bibliothèque externe, et IMREAD le dit.
%
%   Le magasin se copie par référence : READ le fait avancer sans qu'on
%   ait à le réaffecter.
%
%   Exemple :
%      dossier = tempname;
%      mkdir(dossier);
%      imwrite(uint8(magic(4) * 15), fullfile(dossier, 'a.pgm'));
%      ds = imageDatastore(dossier);
%      numel(ds.Files)                 % 1 image trouvee
%      size(read(ds))                  % 4 par 4
%
%   Voir aussi DATASTORE, TABULARTEXTDATASTORE, IMREAD, READ, READALL.
    properties
        Files = {}
        Labels = []
        ReadSize = 1
    end
    properties (Access = private)
        Position = 1
    end

    methods
        function ds = imageDatastore(chemin, varargin)
            if nargin == 0
                return
            end
            ds.Files = matlibre_datastore_fichiers(chemin, ...
                {'.pgm', '.ppm', '.png', '.jpg', '.jpeg', '.bmp'});
            if isempty(ds.Files)
                error('MATLAB:datastore:FileNotFound', ...
                      'Aucune image a « %s ».', char(string(chemin)));
            end
            options = matlibre_lire_options(varargin, ...
                struct('Labels', [], 'ReadSize', 1));
            ds.Labels = options.Labels;
            ds.ReadSize = options.ReadSize;
        end

        function t = hasdata(ds)
        %HASDATA Reste-t-il une image à lire ?
            t = ds.Position <= numel(ds.Files);
        end

        function [image, infos] = read(ds)
        %READ L'image suivante, et d'où elle vient.
            if ~hasdata(ds)
                error('MATLAB:datastore:NoMoreData', ...
                      'Il n''y a plus d''image. Employez HASDATA ou RESET.');
            end
            nomFichier = ds.Files{ds.Position};
            image = imread(nomFichier);
            infos = struct('Filename', nomFichier);
            if ~isempty(ds.Labels) && ds.Position <= numel(ds.Labels)
                infos.Label = ds.Labels(ds.Position);
            end
            ds.Position = ds.Position + 1;
        end

        function images = readall(ds)
        %READALL Toutes les images, dans une cellule.
            images = cell(numel(ds.Files), 1);
            for k = 1:numel(ds.Files)
                images{k} = imread(ds.Files{k});
            end
        end

        function image = preview(ds)
        %PREVIEW La première image, sans avancer.
            if isempty(ds.Files)
                image = [];
                return
            end
            image = imread(ds.Files{1});
        end

        function reset(ds)
        %RESET Revient à la première image.
            ds.Position = 1;
        end

        function n = numpartitions(ds, varargin)
        %NUMPARTITIONS Nombre d'images.
            n = numel(ds.Files);
        end

        function compte = countEachLabel(ds)
        %COUNTEACHLABEL Combien d'images par étiquette.
        %   C'est ce qui dit si un jeu d'apprentissage est équilibré : une
        %   classe dix fois plus représentée qu'une autre fausse tout ce
        %   qui suit, et cela ne se voit pas autrement.
            if isempty(ds.Labels)
                compte = table();
                return
            end
            etiquettes = categorical(ds.Labels);
            distinctes = categories(etiquettes);
            nombres = zeros(numel(distinctes), 1);
            for k = 1:numel(distinctes)
                nombres(k) = sum(etiquettes == distinctes{k});
            end
            compte = table(distinctes, nombres, ...
                           'VariableNames', {'Label', 'Count'});
        end
    end
end
