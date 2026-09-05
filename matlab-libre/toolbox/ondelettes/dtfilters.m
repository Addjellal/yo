function [df, dfSuivant] = dtfilters(nom)
%DTFILTERS Filtres de l'arbre double.
%   DF = DTFILTERS(NOM) rend une cellule de deux éléments, un par arbre.
%   Chaque élément est une matrice à quatre colonnes : Lo_D, Hi_D, Lo_R,
%   Hi_R.
%
%   [DF1,DF2] = DTFILTERS('dtfN') rend d'un coup les filtres du premier
%   étage et ceux des étages suivants, dans la même forme.
%
%   NOM vaut :
%      'farras', 'fsfarras'  premier étage : les deux arbres sont le même
%                            filtre décalé d'un échantillon
%      'qshift1'..'qshift4'  étages suivants, longueurs 10, 14, 16, 18 :
%                            le second arbre est le premier renversé
%      'dtf1', 'dtf2', 'dtf3' les deux étages ensemble
%
%   L'arbre double doit sa raison d'être à un défaut de la transformée
%   discrète ordinaire : décimer rend ses coefficients dépendants du
%   décalage du signal, si bien qu'une même forme, translatée d'un
%   échantillon, ne donne pas les mêmes coefficients. Deux arbres décalés
%   d'un demi-échantillon donnent deux ondelettes conjuguées de Hilbert,
%   dont la somme complexe est analytique : son module ne dépend plus du
%   décalage, comme celui d'une transformée de Fourier.
%
%   Le décalage demandé n'est pas le même aux deux étages. Au premier, le
%   signal n'a pas encore été décimé : il faut un échantillon entier. Aux
%   suivants, la décimation a déjà divisé la cadence par deux : un demi
%   suffit, et c'est ce que le quart de retard de QSHIFTFILTRE procure.
%
%   Exemple :
%      df = dtfilters('qshift2');
%      size(df{1})                    % 14 4
%      isequal(df{2}(:, 1), flipud(df{1}(:, 1)))   % 1
%
%   Voir aussi DUALTREE, QSHIFTFILTRE, WFILTERS.
    nom = lower(strtrim(char(nom)));
    switch nom
        case {'dtf1', 'dtf2', 'dtf3'}
            df = dtfilters('fsfarras');
            dfSuivant = dtfilters(sprintf('qshift%d', str2double(nom(4))));
            if nargout < 2
                error('wavelet:dtfilters:Sorties', ...
                      '''%s'' rend deux étages : demandez deux sorties.', nom);
            end
        case {'farras', 'fsfarras'}
            df = filtresPremierEtage();
        case {'qshift1', 'qshift2', 'qshift3', 'qshift4'}
            longueurs = [10 14 16 18];
            df = filtresQshift(longueurs(str2double(nom(7))));
        otherwise
            error('wavelet:dtfilters:Nom', 'Jeu de filtres inconnu : %s.', nom);
    end
end

function df = filtresPremierEtage()
%FILTRESPREMIERETAGE Deux bancs décalés d'un échantillon exactement.
%   Le décalage est obtenu en bordant le même filtre d'un zéro d'un côté
%   puis de l'autre : les deux bancs restent orthonormaux, et l'écart
%   entre eux vaut un échantillon, sans approximation.
    base = wfilters('sym5');
    h = [base(:); 0];
    g = [0; base(:)];
    df = {bancDepuisEchelle(h), bancDepuisEchelle(g)};
end

function df = filtresQshift(L)
    h = qshiftFiltre(L);
    df = {bancDepuisEchelle(h(:)), bancDepuisEchelle(h(end:-1:1)')};
end

function banc = bancDepuisEchelle(Lo_D)
%BANCDEPUISECHELLE Les quatre filtres d'un banc orthonormal.
%   Le passe-haut est le miroir en quadrature du passe-bas :
%   Hi_D[n] = (-1)^n Lo_D[L-1-n], indices comptés depuis zéro. C'est la
%   relation qui rend les deux bandes orthogonales entre elles, quelle
%   que soit la parité de la longueur.
    Lo_D = Lo_D(:);
    n = numel(Lo_D);
    Hi_D = Lo_D(end:-1:1) .* ((-1) .^ (0:(n - 1))');
    Lo_R = Lo_D(end:-1:1);
    Hi_R = Hi_D(end:-1:1);
    banc = [Lo_D, Hi_D, Lo_R, Hi_R];
end
