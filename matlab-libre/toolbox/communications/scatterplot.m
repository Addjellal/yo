function scatterplot(y, n, decalage)
%SCATTERPLOT Tracé de la constellation reçue.
%   SCATTERPLOT(Y) place chaque échantillon complexe dans le plan, partie
%   réelle en abscisse et imaginaire en ordonnée. C'est le diagramme qui
%   montre d'un coup le bruit, la rotation de phase et le déséquilibre
%   des voies.
%
%   SCATTERPLOT(Y,N) ne garde qu'un échantillon sur N, ce qu'il faut
%   quand le signal est suréchantillonné : seuls les instants de décision
%   ont un sens.
%   SCATTERPLOT(Y,N,DECALAGE) choisit lequel des N échantillons garder.
%
%   Exemple :
%      scatterplot(awgn(qammod(randi([0 15], 1, 500), 16), 20))
%
%   Voir aussi EYEDIAGRAM, QAMMOD.
    if nargin < 2 || isempty(n), n = 1; end
    if nargin < 3 || isempty(decalage), decalage = 0; end
    v = double(y(:));
    v = v(decalage + 1:n:end);
    plot(real(v), imag(v), 'o');
    grid on;
    axis equal;
    xlabel('En phase');
    ylabel('En quadrature');
    title('Constellation');
end
