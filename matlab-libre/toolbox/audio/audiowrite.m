function audiowrite(nomFichier, y, fs)
%AUDIOWRITE Écrit un fichier WAV PCM 16 bits monophonique.
    y = y(:);
    y = max(min(y, 1), -1);
    n = numel(y);
    fid = fopen(nomFichier, 'w');
    if fid < 0
        error('audio:audiowrite:cannotOpen', 'Cannot open ''%s''.', nomFichier);
    end
    tailleDonnees = 2 * n;
    ecrireTexte(fid, 'RIFF');
    ecrireEntier(fid, 36 + tailleDonnees, 4);
    ecrireTexte(fid, 'WAVE');
    ecrireTexte(fid, 'fmt ');
    ecrireEntier(fid, 16, 4);
    ecrireEntier(fid, 1, 2);
    ecrireEntier(fid, 1, 2);
    ecrireEntier(fid, fs, 4);
    ecrireEntier(fid, fs * 2, 4);
    ecrireEntier(fid, 2, 2);
    ecrireEntier(fid, 16, 2);
    ecrireTexte(fid, 'data');
    ecrireEntier(fid, tailleDonnees, 4);
    for k = 1:n
        v = round(y(k) * 32767);
        if v < 0
            v = v + 65536;
        end
        ecrireEntier(fid, v, 2);
    end
    fclose(fid);
end

function ecrireTexte(fid, s)
    fwrite(fid, s);
end

function ecrireEntier(fid, valeur, octets)
    v = round(valeur);
    o = zeros(1, octets);
    for k = 1:octets
        o(k) = mod(v, 256);
        v = floor(v / 256);
    end
    fwrite(fid, o);
end
