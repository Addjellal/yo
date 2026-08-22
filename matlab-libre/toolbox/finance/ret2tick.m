function cours = ret2tick(rendements, depart)
%RET2TICK Reconstruit une série de cours à partir des rendements.
    if nargin < 2
        depart = 1;
    end
    cours = zeros(numel(rendements) + 1, 1);
    cours(1) = depart;
    for k = 1:numel(rendements)
        cours(k + 1) = cours(k) * (1 + rendements(k));
    end
end
