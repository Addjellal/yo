function h = subtitle(varargin)
%SUBTITLE Sous-titre d'un axe, sous son titre.
%   SUBTITLE(TXT) pose TXT sous le titre de l'axe courant.
%   H = SUBTITLE(...) rend la poignée du texte.
%
%   Le rendu n'ayant qu'une ligne de titre par axe, le sous-titre est
%   joint au titre, séparé par un retour à la ligne. Le texte est donc
%   bien là, mais sur la même poignée que le titre : le modifier ensuite
%   modifie les deux. C'est dit ici plutôt que laissé à découvrir.
%
%   Exemple :
%      figure; plot(1:10);
%      title('Signal');
%      subtitle('mesure du 3 mars');
%      close all;
%
%   Voir aussi TITLE, SGTITLE, XLABEL.
    texte = '';
    if ~isempty(varargin)
        texte = char(varargin{1});
    end
    titreActuel = get(get(gca, 'Title'), 'String');
    % On ne recolle pas un sous-titre deja pose : le retour a la ligne le
    % separe, et tout ce qui le suit est l'ancien sous-titre.
    coupure = strfind(titreActuel, sprintf('\n'));
    if ~isempty(coupure)
        titreActuel = titreActuel(1:coupure(1) - 1);
    end
    if isempty(titreActuel)
        poignee = title(texte);
    else
        poignee = title([titreActuel sprintf('\n') texte]);
    end
    if nargout > 0
        h = poignee;
    end
end
