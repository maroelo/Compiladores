class Calculadora {
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

            0;
        }
    };
};