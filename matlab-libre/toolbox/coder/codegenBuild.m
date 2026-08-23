function [ok, message, sortie] = codegenBuild(nomFonction, varargin)
%CODEGENBUILD Génère le C puis le compile avec le compilateur du système.
%   [OK,MESSAGE] = CODEGENBUILD('f') écrit f.c et f.h dans un dossier
%   temporaire puis les compile en objet.
%   CODEGENBUILD('f','-args',{...},'-d',DOSSIER) accepte les mêmes options
%   que CODEGEN, plus '-exe' pour produire un exécutable de démonstration.
    dossier = tempdir();
    executable = false;
    options = {};
    k = 1;
    while k <= numel(varargin)
        option = char(varargin{k});
        switch lower(option)
            case '-d'
                dossier = char(varargin{k + 1});
                k = k + 2;
            case '-exe'
                executable = true;
                k = k + 1;
            otherwise
                options{end + 1} = varargin{k}; %#ok<AGROW>
                k = k + 1;
        end
    end
    if executable
        options = [options, {'-config', 'exe'}];
    end
    sortie = codegen(nomFonction, options{:}, '-d', dossier);
    if executable
        cible = fullfile(dossier, nomFonction);
        commande = sprintf('cc -O2 -o %s %s -lm', cible, sortie.fichierSource);
    else
        cible = fullfile(dossier, [nomFonction '.o']);
        commande = sprintf('cc -c -O2 -o %s %s', cible, sortie.fichierSource);
    end
    [code, message] = system(commande);
    ok = (code == 0);
    sortie.cible = cible;
    sortie.commande = commande;
end
