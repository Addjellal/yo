// Mini-TP Java — decodeur de trame {0xA5, id, hi, lo} (cours 05, TD 05 ex.3)
// Plateforme : onlinegdb.com (Java) — le fichier doit s'appeler Main.java.
// Complete les 3 trous. Le programme s'auto-verifie.
import java.util.Optional;

public class Main {

    record Mesure(int id, int valeur) {}

    static final int TETE = 0xA5;

    static Optional<Mesure> decoder(byte[] trame) {
        if (trame == null || trame.length != 4)
            return Optional.empty();

        // A COMPLETER (1) : verifier l'octet de tete.
        // PIEGE : byte est SIGNE -> il FAUT le masque & 0xFF
        // if ( ??? != TETE) return Optional.empty();


        // A COMPLETER (2) : extraire l'id (trame[1], toujours avec & 0xFF)
        int id = 0;


        // A COMPLETER (3) : assembler la valeur 16 bits big-endian :
        // (octet haut & 0xFF) decale de 8 a gauche, OU l'octet bas & 0xFF
        int valeur = 0;


        return Optional.of(new Mesure(id, valeur));
    }

    // ---- Banc de test (ne pas modifier) -------------------------------
    public static void main(String[] args) {
        int erreurs = 0;

        byte[] ok = {(byte) 0xA5, 0x07, (byte) 0x01, (byte) 0xF4};   // 500
        Optional<Mesure> r = decoder(ok);
        if (r.isPresent() && r.get().id() == 7 && r.get().valeur() == 500) {
            System.out.println("trame valide     : id=7 valeur=500");
        } else {
            System.out.println("trame valide     : ECHEC " + r
                    + "  <- le masque & 0xFF est-il partout ?");
            erreurs++;
        }

        if (decoder(new byte[]{0x55, 0x07, 0x01, (byte) 0xF4}).isEmpty()) {
            System.out.println("mauvaise tete    : rejetee (OK)");
        } else { System.out.println("mauvaise tete    : ACCEPTEE (bug)"); erreurs++; }

        if (decoder(new byte[]{(byte) 0xA5, 0x07}).isEmpty()) {
            System.out.println("trame trop courte: rejetee (OK)");
        } else { System.out.println("trame trop courte: ACCEPTEE (bug)"); erreurs++; }

        byte piege = (byte) 0xA5;
        System.out.println("piege du byte    : (byte)0xA5 = " + piege
                + ", avec & 0xFF = " + (piege & 0xFF));

        System.out.println(erreurs == 0 ? "TOUS LES TESTS PASSENT"
                                        : erreurs + " test(s) en echec");
    }
}
