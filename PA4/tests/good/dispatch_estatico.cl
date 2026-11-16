(* Despacho dinamico x estatico com redefinicao de metodos em tres niveis. *)
class Avo inherits IO {
   fala() : String { "avo" };
   apresenta() : SELF_TYPE { out_string(fala().concat("\n")) };
};
class Pai inherits Avo { fala() : String { "pai" }; };
class Filho inherits Pai { fala() : String { "filho" }; };

class Main {
   main() : Object {
      let f : Filho <- new Filho, a : Avo <- f in {
         a.apresenta();
         f@Pai.apresenta();
         (new IO).out_string(f@Pai.fala().concat("\n"));
         (new IO).out_string(f@Avo.fala().concat("\n"));
         (new IO).out_string(a@Avo.fala().concat("\n"));
      }
   };
};
