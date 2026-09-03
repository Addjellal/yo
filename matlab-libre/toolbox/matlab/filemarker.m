function m = filemarker()
%FILEMARKER Le caractère qui sépare un fichier de sa sous-fonction.
%   M = FILEMARKER rend le caractère employé dans les noms qualifiés du
%   genre « monfichier>masousfonction », que rendent WHICH et les piles
%   d'erreurs.
%
%   Exemple :
%      ['essai' filemarker() 'aide']     % 'essai>aide'
%
%   Voir aussi WHICH, PATHSEP, FILESEP, DBSTACK.
    m = '>';
end
