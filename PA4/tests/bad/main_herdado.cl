(* O metodo main precisa ser declarado na propria classe Main.
   Um main herdado de uma superclasse nao e aceito (mesmo comportamento
   do coolc de referencia). *)
class Programa inherits IO {
   main() : Object { out_string("main herdado\n") };
};

class Main inherits Programa { };
