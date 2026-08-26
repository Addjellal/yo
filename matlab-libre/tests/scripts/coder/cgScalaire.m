function y = cgScalaire(x)
%CGSCALAIRE Fonction scalaire : arithmetique, if, while.
    y = x * x + 2 * x - 1;
    if y > 100
        y = 100;
    elseif y < -100
        y = -100;
    end
    while y > 50
        y = y - 10;
    end
end
