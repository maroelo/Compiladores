(* Usos invalidos de SELF_TYPE e de self. *)
class A {
   (* retorno SELF_TYPE com corpo de tipo A: A nao conforma com SELF_TYPE *)
   f() : SELF_TYPE { new A };
   (* atributo SELF_TYPE inicializado com A *)
   a : SELF_TYPE <- new A;
   (* dispatch estatico para SELF_TYPE *)
   g() : Object { self@SELF_TYPE.f() };
   (* parametro formal SELF_TYPE *)
   h(x : SELF_TYPE) : Int { 0 };
};

class Main { main() : Int { 0 }; };
