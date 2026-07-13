/** Classe de base abstraite — corrigé TD 05, exercice 1. */
public abstract class Capteur {
    private final String nom;
    private final String unite;

    protected Capteur(String nom, String unite) {
        this.nom = nom;
        this.unite = unite;
    }

    public String getNom()   { return nom; }
    public String getUnite() { return unite; }

    /** Chaque capteur concret fournit SA façon de mesurer. */
    public abstract double lire();
}
