function verifierFrequences(Fc, Fs)
%VERIFIERFREQUENCES Contrôle du critère de Shannon pour la porteuse.
%   La porteuse doit tenir sous la moitié de la fréquence
%   d'échantillonnage, sinon elle se replie et la modulation n'a plus de
%   sens.
    if Fs <= 2 * Fc
        error('comm:modulation:BadFs', ...
              'FS doit dépasser deux fois FC (FS = %g, FC = %g).', Fs, Fc);
    end
end
