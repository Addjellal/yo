function cours = ret2tick(rendements, depart)
%RET2TICK Reconstruit une série de cours à partir des rendements.
%   COURS = RET2TICK(RENDEMENTS) reconstruit la série des cours à partir
%   des rendements simples, en partant de 1.
%   COURS = RET2TICK(RENDEMENTS,DEPART) part de DEPART.
%
%   Le cumul est multiplicatif : COURS(k+1) = COURS(k)*(1+R(k)). La série
%   rendue a un point de plus que celle des rendements, le cours initial
%   n'étant le rendement de rien.
%
%   C'est l'inverse de TICK2RET, et c'est là que se voit pourquoi les
%   rendements ne se moyennent pas arithmétiquement : +50 % puis -50 %
%   ramènent à 0,75, non à 1. La moyenne qui a un sens sur des rendements
%   composés est géométrique, et elle est toujours inférieure à
%   l'arithmétique dès que la série varie.
%
%   Exemple :
%      ret2tick([0.5 -0.5])
%
%   Voir aussi TICK2RET, MAXDRAWDOWN, SHARPE.
    if nargin < 2
        depart = 1;
    end
    cours = zeros(numel(rendements) + 1, 1);
    cours(1) = depart;
    for k = 1:numel(rendements)
        cours(k + 1) = cours(k) * (1 + rendements(k));
    end
end
