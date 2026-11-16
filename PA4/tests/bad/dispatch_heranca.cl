(* Dispatch que depende do tipo estatico: metodos definidos apenas na
   subclasse nao podem ser chamados por uma referencia da superclasse. *)
class Animal {
   som() : String { "..." };
};

class Cachorro inherits Animal {
   som() : String { "au" };
   buscar() : String { "bola" };
};

class Main {
   main() : Object {
      let a : Animal <- new Cachorro in {
         a.som();
         (* erro: buscar nao existe em Animal *)
         a.buscar();
         (* erro: Animal nao conforma com Cachorro *)
         a@Cachorro.buscar();
         (* erro: atribuir Animal a variavel Cachorro *)
         let c : Cachorro <- a in c;
      }
   };
};
