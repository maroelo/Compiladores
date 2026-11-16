(* Ciclo de heranca envolvendo tres classes: A -> B -> C -> A.
   Esperado: um erro para cada classe do ciclo e a compilacao interrompida. *)
class A inherits C { };
class B inherits A { };
class C inherits B { };

class Main { main() : Int { 0 }; };
