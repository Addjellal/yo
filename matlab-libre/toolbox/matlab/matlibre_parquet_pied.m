function [metadonnees, octets] = matlibre_parquet_pied(nomFichier)
%MATLIBRE_PARQUET_PIED Lit le fichier et en extrait les métadonnées.
%   [M,OCTETS] = MATLIBRE_PARQUET_PIED(FICHIER) rend la structure des
%   métadonnées, telle que le protocole compact la transporte — champs
%   nommés c1, c2, ... d'après leurs identifiants — et tous les octets du
%   fichier.
%
%   Un fichier Parquet se lit par la fin : « PAR1 » ferme le fichier,
%   précédé de la longueur du pied sur quatre octets, elle-même précédée
%   du pied. C'est ce qui permet d'écrire les données avant de savoir où
%   elles finiront.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      f = fullfile(tempdir, 'matlibre_pied.parquet');
%      parquetwrite(f, table([1; 2]));
%      m = matlibre_parquet_pied(f);
%      m.c3                            % 2 lignes
%
%   Voir aussi PARQUETREAD, PARQUETINFO.
    identifiant = fopen(nomFichier, 'r');
    if identifiant < 0
        error('MATLAB:parquet:FichierIntrouvable', ...
              'Unable to open file ''%s''.', nomFichier);
    end
    octets = uint8(fread(identifiant))';
    fclose(identifiant);
    n = numel(octets);
    if n < 12
        error('MATLAB:parquet:FichierInvalide', ...
              '''%s'' is too short to be a Parquet file.', nomFichier);
    end
    magiqueDebut = char(octets(1:4));
    magiqueFin = char(octets(end-3:end));
    if ~strcmp(magiqueDebut, 'PAR1') || ~strcmp(magiqueFin, 'PAR1')
        error('MATLAB:parquet:FichierInvalide', ...
              '''%s'' is not a Parquet file: the PAR1 marker is missing.', nomFichier);
    end
    longueur = double(typecast(octets(end-7:end-4), 'uint32'));
    debut = n - 8 - longueur + 1;
    if debut < 5
        error('MATLAB:parquet:FichierInvalide', ...
              'The footer overruns file ''%s''.', nomFichier);
    end
    metadonnees = matlibre_thrift_lire(octets(debut:end-8), 1);
end
