function session = writeData(session, donnees)
%WRITEDATA Écrit un bloc sur les voies de sortie (mémorisé).
    session.ecrit = [session.ecrit; donnees(:)];
end
