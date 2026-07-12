# make test     : compile et exécute les tests
# make prodcons : démonstration producteur/consommateur (~3 s)
all:
	javac *.java

test: all
	java TestTout

prodcons: all
	java ProdCons

clean:
	rm -f *.class

.PHONY: all test prodcons clean
