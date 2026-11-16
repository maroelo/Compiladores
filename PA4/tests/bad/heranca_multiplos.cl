(* Varios erros de heranca ao mesmo tempo: ciclo A/B, pai indefinido,
   heranca de Int e classe Main duplicada. *)
class A inherits B { };
class B inherits A { };
class C inherits D { };
class E inherits Int { };
class Main { main() : Object { 0 }; };
class Main { };
