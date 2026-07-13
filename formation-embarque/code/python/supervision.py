#!/usr/bin/env python3
"""supervision.py — client Modbus TCP de supervision de cuve (corrigé TP 4).

Lit la table d'échange du TD 08/TP 4 :
    %MW100  état (bits : b0=P1, b1=P2, b2=vanne, b3=nivTH, b4=nivTB, b5=defCapteur)
    %MW101  niveau en pour-mille
    %MW102  heures P1 (h x10)      %MW103  heures P2 (h x10)
    %MW104  mot de vie (+1/s)
Écrit :
    %MW110  commande (b0=autoriser remplissage, b1=acquit)
    %MW111  consigne haute en pour-mille (bornée côté automate 500..800)

Usage :
    pip install pymodbus
    python3 supervision.py [ip_automate]        # défaut : 192.168.1.50
Commandes en cours d'exécution : taper `consigne 650`, `stop`, `marche`, `quitter`.
"""
import csv
import sys
import threading
import time
from datetime import datetime

try:
    from pymodbus.client import ModbusTcpClient
except ImportError:
    sys.exit("pymodbus manquant : pip install pymodbus")

IP_DEFAUT = "192.168.1.50"
PERIODE_S = 1.0
FICHIER_CSV = "journal_cuve.csv"

commandes = []           # file de commandes tapées par l'opérateur
verrou = threading.Lock()


def lecteur_clavier():
    """Thread clavier : ne bloque jamais la boucle de scrutation."""
    for ligne in sys.stdin:
        with verrou:
            commandes.append(ligne.strip().lower())


def barre(pourcent, largeur=20):
    plein = int(pourcent / 100 * largeur)
    return "#" * plein + "." * (largeur - plein)


def main():
    ip = sys.argv[1] if len(sys.argv) > 1 else IP_DEFAUT
    client = ModbusTcpClient(ip, port=502)
    if not client.connect():
        sys.exit(f"connexion impossible a {ip}:502")

    threading.Thread(target=lecteur_clavier, daemon=True).start()

    vie_prec = None
    vie_figee = 0

    with open(FICHIER_CSV, "a", newline="") as f:
        journal = csv.writer(f, delimiter=";")
        journal.writerow(["horodatage", "niveau_pct", "p1", "p2",
                          "vanne", "defauts", "vie"])

        while True:
            # ---- 1. Lecture de la zone API -> PC
            rr = client.read_holding_registers(address=100, count=5)
            if rr.isError():
                print("erreur Modbus :", rr)
                time.sleep(PERIODE_S)
                continue

            etat, niveau, h_p1, h_p2, vie = rr.registers
            p1 = bool(etat & 0x01)
            p2 = bool(etat & 0x02)
            vanne = bool(etat & 0x04)
            defauts = []
            if etat & 0x08:
                defauts.append("NIVEAU TRES HAUT")
            if etat & 0x10:
                defauts.append("NIVEAU TRES BAS")
            if etat & 0x20:
                defauts.append("CAPTEUR HS")

            # ---- 2. Surveillance du mot de vie : liaison ouverte != automate vivant
            if vie_prec is not None and vie == vie_prec:
                vie_figee += 1
            else:
                vie_figee = 0
            vie_prec = vie
            if vie_figee >= 3:
                defauts.append("MOT DE VIE FIGE (automate en panne ?)")

            # ---- 3. Affichage
            pct = niveau / 10.0
            print(f"\n--- CUVE {datetime.now():%H:%M:%S} " + "-" * 30)
            print(f" niveau : {pct:5.1f} %  [{barre(pct)}]")
            print(f" P1 : {'MARCHE' if p1 else 'arret '} ({h_p1/10:.1f} h)"
                  f"   P2 : {'MARCHE' if p2 else 'arret '} ({h_p2/10:.1f} h)")
            print(f" vanne  : {'ouverte' if vanne else 'fermee'}   vie : {vie}")
            print(f" defauts: {', '.join(defauts) if defauts else 'aucun'}")

            # ---- 4. Journalisation
            journal.writerow([datetime.now().isoformat(timespec="seconds"),
                              pct, p1, p2, vanne, "|".join(defauts), vie])
            f.flush()

            # ---- 5. Commandes opérateur -> zone PC -> API (des DEMANDES :
            #         l'automate valide et borne, jamais l'inverse)
            with verrou:
                en_attente, commandes[:] = commandes[:], []
            for cmd in en_attente:
                if cmd.startswith("consigne "):
                    try:
                        valeur = int(float(cmd.split()[1]) * 10)   # % -> pour-mille
                        client.write_register(address=111, value=valeur)
                        print(f">> consigne {valeur/10:.1f} % envoyee "
                              "(l'automate borne 50..80 %)")
                    except (ValueError, IndexError):
                        print(">> usage : consigne <pourcent>")
                elif cmd == "marche":
                    client.write_register(address=110, value=0x0001)
                    print(">> demande de marche envoyee")
                elif cmd == "stop":
                    client.write_register(address=110, value=0x0000)
                    print(">> demande d'arret envoyee")
                elif cmd in ("quitter", "q"):
                    client.close()
                    print("journal :", FICHIER_CSV)
                    return
                elif cmd:
                    print(">> commandes : consigne <pct> | marche | stop | quitter")

            time.sleep(PERIODE_S)


if __name__ == "__main__":
    main()
