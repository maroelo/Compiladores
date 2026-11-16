(* Regras de SELF_TYPE: retorno, atributos, new SELF_TYPE, let com
   SELF_TYPE e dispatch que preserva o tipo do receptor. *)
class Contador inherits IO {
   n : Int;
   proprio : SELF_TYPE;

   incrementa() : SELF_TYPE { { n <- n + 1; self; } };
   clone() : SELF_TYPE { new SELF_TYPE };
   guarda() : SELF_TYPE { { proprio <- self; proprio; } };
   valor() : Int { n };
   mostra() : SELF_TYPE { out_int(n).out_string("\n") };
   mesmo() : SELF_TYPE { let x : SELF_TYPE <- self in x };
};

class ContadorDuplo inherits Contador {
   incrementa() : SELF_TYPE { { n <- n + 2; self; } };
   so_aqui() : String { "ContadorDuplo" };
};

class Main inherits IO {
   main() : Object {
      let d : ContadorDuplo <- new ContadorDuplo in {
         (* incrementa devolve SELF_TYPE: o tipo continua ContadorDuplo *)
         d.incrementa().incrementa().mostra();
         out_string(d.guarda().mesmo().so_aqui().concat("\n"));
         out_string(d.clone().type_name().concat("\n"));
         (* copy de Object tambem devolve SELF_TYPE *)
         out_string(d.copy().so_aqui().concat("\n"));
         (* dispatch estatico em Contador ainda devolve ContadorDuplo *)
         d@Contador.incrementa().mostra();
      }
   };
};
