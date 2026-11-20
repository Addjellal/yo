function ok = partageImbrique()
%PARTAGEIMBRIQUE Une fonction imbriquee recoit en parametre une variable de
%   son parent, puis ecrit cette variable du parent : le parametre garde
%   la valeur recue, le parent voit l'ecriture. Sert a test_langage.
    partagee = [1 2 3];
    recu = interne(partagee);
    ok = isequal(recu, [1 2 3]) && isequal(partagee, [0 2 3]);
    function p = interne(p)
        partagee(1) = 0;
    end
end
