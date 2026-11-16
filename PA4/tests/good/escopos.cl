(* Escopo e ocultamento de nomes: parametros escondem atributos, let
   aninhados escondem lets externos, ramos de case criam escopo novo. *)
class Main inherits IO {
   x : Int <- 1;

   mostra(n : Int) : SELF_TYPE { out_int(n).out_string(" ") };

   parametro(x : Int) : Int { x };

   main() : Object {
      {
         mostra(x);
         mostra(parametro(2));
         let x : Int <- 3 in {
            mostra(x);
            let x : Int <- x + 1 in mostra(x);
            mostra(x);
         };
         case "s" of
            x : String => mostra(x.length() + 4);
            o : Object => mostra(0);
         esac;
         mostra(x);
         let a : Int <- 6, b : Int <- a + 1, c : Int <- b + 1 in
            mostra(a).mostra(b).mostra(c);
         out_string("\n");
      }
   };
};
