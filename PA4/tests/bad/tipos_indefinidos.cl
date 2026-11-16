(* Tipos indefinidos em varios pontos e erros de redefinicao de metodos.
   O analisador deve reportar cada problema sem abortar e sem parar no
   primeiro erro. *)
class A {
  f() : SELF_TYPE { self };
  g(x : Int) : Int { x };
};

class B inherits A {
  (* retorno diferente do original SELF_TYPE *)
  f() : A { self };
  (* parametro e retorno diferentes do original *)
  g(x : String) : String { x };
  (* atribuicao a variavel inexistente *)
  h() : Object { x <- 3 };
  (* atributo e new de classe indefinida *)
  t : Undef <- new Undef;
  (* dispatch sobre um objeto de classe indefinida *)
  u() : Object { t.foo() };
  (* retorno de tipo indefinido *)
  v() : Undef2 { 1 };
  (* let com tipo indefinido e dispatch sobre ele *)
  w() : Object { let q : Undef3 <- 3 in q.bar(4) };
  (* case com tipo indefinido e dispatch sobre ele *)
  y() : Object { case 3 of a : Undef4 => a.baz(); esac };
  (* argumento Bool para parametro Int *)
  z() : Int { self.f().g(true) };
  (* A nao conforma com B no dispatch estatico *)
  zz() : Object { (new A)@B.f() };
  (* predicado nao Bool e soma com String *)
  zzz() : Object { if new A then 1 else 2 fi + "a" };
  (* comparacao de Int com objeto *)
  q() : Object { 1 = new A };
  (* comparacao entre objetos quaisquer e permitida *)
  r() : Object { new A = new B };
  (* < so aceita Int *)
  s() : Object { "a" < "b" };
};

class Main {
  main() : Object { 0 };
  (* identificador nao declarado na inicializacao de atributo *)
  x : Int <- y;
};
