class Calculadora {
    memoria : Int;
    ultimoResultado : Int <- 0;
    nome : String <- "Calculadora";
    ativa : Bool <- true;

    soma(a : Int, b : Int) : Int {
        a + b
    };

    fatorial(n : Int) : Int {
        if n <= 1 then
            1
        else
            n * fatorial(n - 1)
        fi
    };

    somaAte(n : Int) : Int {
        let i : Int <- 0, total : Int <- 0 in {
            while i <= n loop {
                total <- total + i;
                i <- i + 1;
            } pool;
            total;
        }
    };

    ehPar(n : Int) : Bool {
        n - (n / 2 * 2) = 0
    };

    menor(a : Int, b : Int) : Bool {
        a < b
    };

    negativo(n : Int) : Int {
        ~n
    };

    naoEhPar(n : Int) : Bool {
        not ehPar(n)
    };

    semObjeto() : Bool {
        let objeto : Calculadora in isvoid objeto
    };

    classificar(objeto : Object) : Int {
        case objeto of
            numero : Int => numero;
            texto : String => texto.length();
            outro : Object => 0;
        esac
    };

    identidade() : SELF_TYPE {
        self
    };

    nova() : SELF_TYPE {
        new SELF_TYPE
    };

    precedencia() : Int {
        {
            ultimoResultado <- 1 + 2 * 3;
            memoria <- (1 + 2) * 3;
            8 - 3 - 1;
            8 / 2 / 2;
            1 + let x : Int <- 2 in x * 3 + 1;
        }
    };
};

class Vazia {
};

class Main inherits IO {
    main() : Object {
        let calc : Calculadora <- new Calculadora,
            valor : Int <- 5,
            resultadoFatorial : Int <- calc.fatorial(valor),
            resultadoSoma : Int <- calc.somaAte(valor)
        in {
            out_string("Fatorial de ");
            out_int(valor);
            out_string(" = ");
            out_int(resultadoFatorial);
            out_string("\n");

            out_string("Soma de 0 ate ");
            out_int(valor);
            out_string(" = ");
            out_int(resultadoSoma);
            out_string("\n");

            if calc.ehPar(valor) then
                out_string("O valor e par.\n")
            else
                out_string("O valor e impar.\n")
            fi;

            (* Chamadas com @, em sequencia e sem argumentos. *)
            calc@Calculadora.soma(2, 3);
            calc.identidade().soma(1, 2);
            calc.nova();

            (* Comparacao, operadores unarios e let sem inicializacao. *)
            calc.menor(1, 2);
            calc.negativo(3);
            calc.naoEhPar(valor);
            calc.semObjeto();

            (* Um objeto para cada ramo do case. *)
            calc.classificar(7);
            calc.classificar("abc");
            calc.classificar(new Object);

            (* Precedencia, associatividade e atribuicao encadeada. *)
            calc.precedencia();
            let a : Int, b : Int in a <- b <- 2;
            if true then false else true fi;

            0;
        }
    };
};
