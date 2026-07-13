import java.util.Optional;

/** Décodeur de trame binaire {0xA5, id, hi, lo} — corrigé TD 05, ex. 3.
 *  LE piège : byte est SIGNÉ en Java ; le masque & 0xFF est obligatoire. */
public class DecodeurTrame {
    public record TrameMesure(int id, int valeur) {}

    static final int TETE = 0xA5;
    static final int LONGUEUR = 4;

    /** Optional : une trame invalide est un cas NORMAL, pas une exception. */
    public static Optional<TrameMesure> decoder(byte[] trame) {
        if (trame == null || trame.length != LONGUEUR)
            return Optional.empty();

        if ((trame[0] & 0xFF) != TETE)       // sans & 0xFF : -91 != 165, tout
            return Optional.empty();         // serait rejeté !

        int id     = trame[1] & 0xFF;
        int valeur = ((trame[2] & 0xFF) << 8) | (trame[3] & 0xFF);
        return Optional.of(new TrameMesure(id, valeur));
    }
}
