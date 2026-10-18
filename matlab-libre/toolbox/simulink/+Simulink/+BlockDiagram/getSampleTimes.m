function periodes = getSampleTimes(modele)
%SIMULINK.BLOCKDIAGRAM.GETSAMPLETIMES Les périodes d'un modèle compilé.
%   T = SIMULINK.BLOCKDIAGRAM.GETSAMPLETIMES(MODELE) compile le modèle et
%   rend ses périodes d'échantillonnage, des SIMULINK.SAMPLETIME : les
%   discrètes de la plus rapide à la plus lente — D1, D2... —, puis la
%   continue, la continue fixée aux pas mineurs et la constante qu'il
%   porte, comme la légende des périodes de Simulink.
%
%   Exemple :
%      m = new_system('periodes');
%      m = add_block(m, 'constant', 'c', 'Value', 1);
%      m = add_block(m, 'unitdelay', 'd', 'SampleTime', 0.5);
%      m = add_block(m, 'outport', 'y');
%      m = add_line(add_line(m, 'c', 'd'), 'd', 'y');
%      t = Simulink.BlockDiagram.getSampleTimes(m);
%      t(1).Value                                  % [0.5 0]
%      t(1).Annotation                             % 'D1'
%
%   Voir aussi SIMULINK.SAMPLETIME, GET_PARAM.
    c = matlibre_sl_compiler(matlibre_sl_modele(modele), struct('silencieux', true, 'tFinal', 0));
    discretes = zeros(0, 2);
    continu = false;
    mineur = false;
    constante = false;
    for k = 1:c.n
        if strcmp(c.types{k}, 'signalconversion') && c.nOut(k) == 0
            continue
        end
        t = c.cadence(k);
        if t > 0 && isfinite(t)
            discretes(end + 1, :) = [t c.decalage(k)]; %#ok<AGROW>
        elseif t == 0
            if c.majeurSeul(k)
                mineur = true;
            else
                continu = true;
            end
        elseif isinf(t)
            constante = true;
        end
    end
    discretes = unique(round(discretes * 1e12) / 1e12, 'rows');
    periodes = Simulink.SampleTime.empty();
    for i = 1:size(discretes, 1)
        periodes(end + 1) = Simulink.SampleTime(discretes(i, :), sprintf('Discrete %d', i), ...
                                                sprintf('D%d', i)); %#ok<AGROW>
    end
    if continu
        periodes(end + 1) = Simulink.SampleTime([0 0], 'Continuous', 'Cont');
    end
    if mineur
        periodes(end + 1) = Simulink.SampleTime([0 1], 'Fixed in Minor Step', 'FiM');
    end
    if constante
        periodes(end + 1) = Simulink.SampleTime([Inf 0], 'Constant', 'Inf');
    end
end
