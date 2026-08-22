function [y, fs] = audioread(nomFichier)
%AUDIOREAD Lit un fichier WAV PCM 16 bits monophonique.
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
