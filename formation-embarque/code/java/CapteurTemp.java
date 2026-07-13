public class CapteurTemp extends Capteur {
    public CapteurTemp() { super("temperature", "C"); }

    @Override
    public double lire() { return 18 + Math.random() * 10; }   // simulé
}
