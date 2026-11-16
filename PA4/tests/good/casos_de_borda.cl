(* Casos de borda corretos: atributo usado antes de declarado na
   inicializacao, self e SELF_TYPE em atributos, let e case, lub de
   self com new SELF_TYPE, dispatch estatico em self, isvoid self e
   parametros/lets escondendo nomes externos. *)
class A {
  a : SELF_TYPE;
  b : Int <- c + 1;
  c : Int <- 2;
  d : A <- self;
  e : Object <- self;
  me() : SELF_TYPE { self };
  f(x : A) : SELF_TYPE { if true then self else new SELF_TYPE fi };
  g() : A { if true then self else new A fi };
  h() : Object { case self of x : A => x; y : Object => y; esac };
  i() : SELF_TYPE { let z : SELF_TYPE in z };
  j() : Bool { isvoid self };
  k() : Bool { self = new A };
  l() : Object { f(self) };
  m() : A { let s : SELF_TYPE <- self in s.me() };
  n() : SELF_TYPE { me().me() };
  o() : Object { while isvoid a loop a <- self pool };
  p() : Object { { a <- me(); a <- copy(); } };
};
class B inherits A {
  me() : SELF_TYPE { self@A.me() };
  q() : A { case me() of b : B => b; a : A => a; esac };
  r() : Object { let a : Int <- 5 in a <- a + 1 };
  s(b : Int) : Int { let b : String <- "x" in b.length() };
};
class Main { main() : Object { (new B).q() }; };
