function y = cgSwitch(m)
%CGSWITCH Choix multiple traduit en chaine de tests.
    switch m
        case 1
            y = 10;
        case 2
            y = 20;
        otherwise
            y = 0;
    end
end
