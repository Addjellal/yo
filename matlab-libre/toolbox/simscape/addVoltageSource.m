function c = addVoltageSource(c, n1, n2, V)
%ADDVOLTAGESOURCE Source de tension idéale de V volts (n1 au potentiel +).
    c = addComponent(c, 'v', n1, n2, V);
end
