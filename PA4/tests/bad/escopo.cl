(* Erros de escopo: nomes usados fora do bloco onde foram declarados. *)
class A {
   f(p : Int) : Int { p };
   (* p so existe dentro de f *)
   g() : Int { p };
   h() : Int {
      {
         let x : Int <- 1 in x;
         (* x ja saiu de escopo *)
         x;
      }
   };
   k() : Int {
      {
         case 1 of y : Int => y; esac;
         (* y so existe dentro do ramo *)
         y;
      }
   };
};

class Main { main() : Int { 0 }; };
