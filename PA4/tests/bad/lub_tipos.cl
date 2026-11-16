(* O tipo de if e de case e o lub dos ramos; o resultado nao pode ser
   usado onde se espera um tipo mais especifico. *)
class A { };
class B inherits A { };
class C inherits A { };

class Main {
   main() : Object {
      {
         (* lub(B, C) = A, que nao conforma com B *)
         let b : B <- if true then new B else new C fi in b;
         (* lub(Int, String) = Object, que nao conforma com Int *)
         let i : Int <- case 1 of x : Int => 1; y : String => "s"; esac in i;
         (* lub(Int, Bool) = Object: operacao aritmetica invalida *)
         (if true then 1 else false fi) + 1;
      }
   };
};
