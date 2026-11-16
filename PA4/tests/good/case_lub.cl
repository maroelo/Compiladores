(* case escolhe o ramo do ancestral mais proximo; tipo do case e do if
   e o lub dos ramos. *)
class A inherits IO { nome() : String { "A" }; };
class B inherits A { nome() : String { "B" }; };
class C inherits B { nome() : String { "C" }; };
class D inherits A { nome() : String { "D" }; };

class Main inherits IO {
   qual(o : Object) : String {
      case o of
         b : B => "ramo B com ".concat(b.nome());
         a : A => "ramo A com ".concat(a.nome());
         o : Object => "ramo Object";
      esac
   };

   main() : Object {
      {
         out_string(qual(new A).concat("\n"));
         out_string(qual(new B).concat("\n"));
         out_string(qual(new C).concat("\n"));
         out_string(qual(new D).concat("\n"));
         out_string(qual(self).concat("\n"));
         (* lub(C, D) = A, entao nome() e valido *)
         out_string((if true then new C else new D fi).nome().concat("\n"));
         (* lub de case com ramos B e D tambem e A *)
         out_string((case 0 of i : Int => new C; s : String => new D; esac).nome().concat("\n"));
      }
   };
};
