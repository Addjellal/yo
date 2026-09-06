function proteine = nt2aa(sequence)
%NT2AA Traduction d'une séquence de nucléotides en acides aminés.
%   Le code génétique standard est utilisé ; « * » marque un codon stop.
%
%   PROTEINE = NT2AA(SEQUENCE) lit la séquence par groupes de trois — les
%   codons — depuis le début, et rend la chaîne d'acides aminés à une
%   lettre.
%
%   Le code est dégénéré : soixante-quatre codons pour vingt acides aminés
%   et un signal d'arrêt. La plupart des synonymes ne diffèrent que par la
%   troisième base, ce qui rend les mutations à cette position souvent
%   silencieuses.
%
%   Le cadre de lecture décide de tout : décaler d'une base donne une
%   protéine sans rapport. C'est pourquoi une insertion d'une seule base
%   dans une région codante est bien plus grave qu'une substitution.
%
%   Exemple :
%      nt2aa('ATGGCCTAA')              % 'MA*' : depart, alanine, arret
%      nt2aa('TGGCCTAA')               % tout autre chose : cadre decale
%
%   Voir aussi SEQCOMPLEMENT, RANDSEQ.
    codons = {'TTT','F','TTC','F','TTA','L','TTG','L','CTT','L','CTC','L', ...
              'CTA','L','CTG','L','ATT','I','ATC','I','ATA','I','ATG','M', ...
              'GTT','V','GTC','V','GTA','V','GTG','V','TCT','S','TCC','S', ...
              'TCA','S','TCG','S','CCT','P','CCC','P','CCA','P','CCG','P', ...
              'ACT','T','ACC','T','ACA','T','ACG','T','GCT','A','GCC','A', ...
              'GCA','A','GCG','A','TAT','Y','TAC','Y','TAA','*','TAG','*', ...
              'CAT','H','CAC','H','CAA','Q','CAG','Q','AAT','N','AAC','N', ...
              'AAA','K','AAG','K','GAT','D','GAC','D','GAA','E','GAG','E', ...
              'TGT','C','TGC','C','TGA','*','TGG','W','CGT','R','CGC','R', ...
              'CGA','R','CGG','R','AGT','S','AGC','S','AGA','R','AGG','R', ...
              'GGT','G','GGC','G','GGA','G','GGG','G'};
    sequence = upper(strrep(char(sequence), 'U', 'T'));
    proteine = '';
    for k = 1:3:numel(sequence)-2
        codon = sequence(k:k+2);
        trouve = '?';
        for j = 1:2:numel(codons)
            if strcmp(codons{j}, codon)
                trouve = codons{j+1};
                break;
            end
        end
        proteine(end+1) = trouve;
    end
end
