function r = ecrireDansSaCopie(x, i)
%ECRIREDANSSACOPIE Ecrit aux deux bouts de son parametre et rend
%   x(1) + x(2) + x(end) : i + x(2) - i. Sert a test_parallele, ou des
%   travailleurs l'appellent en meme temps sur un tableau diffuse.
    x(1) = i;
    x(end) = -i;
    r = x(1) + x(2) + x(end);
end
