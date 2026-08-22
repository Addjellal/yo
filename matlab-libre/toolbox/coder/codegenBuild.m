function [ok, message] = codegenBuild(nomFonction, dossier)
%CODEGENBUILD Génère le C puis le compile avec le compilateur du système.
    if nargin < 2
        dossier = tempdir();
    end
    fichierC = fullfile(dossier, [nomFonction '.c']);
    codegen(nomFonction, fichierC);
    objet = fullfile(dossier, [nomFonction '.o']);
    [code, message] = system(sprintf('cc -c -O2 -o %s %s', objet, fichierC));
    ok = (code == 0);
end
