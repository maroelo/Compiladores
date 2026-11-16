(* Heranca de classes basicas que nao podem ser estendidas
   (Int, Bool, String) e de SELF_TYPE. *)
class A inherits Int { };
class B inherits Bool { };
class C inherits String { };
class D inherits SELF_TYPE { };

class Main { main() : Int { 0 }; };
