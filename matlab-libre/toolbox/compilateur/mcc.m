function chemin = mcc(script, sortie)
%MCC Fabrique un lanceur autonome pour un script.
%   CHEMIN = MCC('script.m','programme') écrit un script shell qui appelle
%   l'interpréteur MatLibre sur le script, avec le chemin des toolboxes
%   déjà réglé. C'est l'équivalent libre du « MATLAB Runtime » : le
%   programme produit a besoin de l'interpréteur, comme un programme
%   compilé par mcc a besoin du runtime.
    if nargin < 2
        [~, nom] = fileparts(script);
        sortie = nom;
    end
    racine = matlabroot();
    fid = fopen(sortie, 'w');
    fprintf(fid, '#!/bin/sh\n');
    fprintf(fid, '# Lanceur produit par mcc (MatLibre)\n');
    fprintf(fid, 'MATLIBRE_TOOLBOX="%s"\n', racine);
    fprintf(fid, 'export MATLIBRE_TOOLBOX\n');
    fprintf(fid, 'exec matlibre "%s" "$@"\n', fullfile(pwd(), script));
    fclose(fid);
    system(sprintf('chmod +x %s', sortie));
    chemin = fullfile(pwd(), sortie);
end
