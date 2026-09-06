function [y, fs] = audioread(nomFichier)
%AUDIOREAD Lit un fichier WAV PCM 16 bits monophonique.
%   [Y,FS] = AUDIOREAD(FICHIER) rend les échantillons, ramenés entre -1 et
%   1, et la fréquence d'échantillonnage.
%
%   Seul le WAV PCM 16 bits mono est lu : ni compression, ni stéréo, ni
%   flottant. Les formats compressés — MP3, AAC, Ogg — demandent un codec,
%   et les intégrer signifierait une dépendance externe.
%
%   La normalisation entre -1 et 1 est la convention de MATLAB : elle rend
%   le traitement indépendant du nombre de bits, et c'est AUDIOWRITE qui
%   refait la conversion en sens inverse.
%
%   Exemple :
%      audiowrite('essai.wav', sin(2*pi*440*(0:8000)/8000), 8000);
%      [y, fs] = audioread('essai.wav');
%      max(abs(y))                     % proche de 1
%
%   Voir aussi AUDIOWRITE, DBFS, SPECTRALCENTROID.
    fid = fopen(nomFichier, 'r');
    if fid < 0
        error('audio:audioread:cannotOpen', 'Cannot open ''%s''.', nomFichier);
    end
    octets = fread(fid);
    fclose(fid);
    fs = lireEntier(octets, 25, 4);
    tailleDonnees = lireEntier(octets, 41, 4);
    n = tailleDonnees / 2;
    y = zeros(n, 1);
    for k = 1:n
        v = lireEntier(octets, 45 + 2*(k-1), 2);
        if v >= 32768
            v = v - 65536;
        end
        y(k) = v / 32767;
    end
end

function v = lireEntier(octets, debut, nombre)
    v = 0;
    for k = nombre:-1:1
        v = v * 256 + octets(debut + k - 1);
    end
end
