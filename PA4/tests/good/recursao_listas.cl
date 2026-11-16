(* Lista encadeada polimorfica (Nil/Cons), recursao, isvoid,
   while e atribuicoes encadeadas. *)
class Lista {
   vazia() : Bool { true };
   cabeca() : Int { { abort(); 0; } };
   cauda() : Lista { { abort(); self; } };
   insere(i : Int) : Lista { (new Cons).init(i, self) };
};

class Cons inherits Lista {
   car : Int;
   cdr : Lista;
   vazia() : Bool { false };
   cabeca() : Int { car };
   cauda() : Lista { cdr };
   init(i : Int, resto : Lista) : Lista { { car <- i; cdr <- resto; self; } };
};

class Main inherits IO {
   soma(l : Lista) : Int { if l.vazia() then 0 else l.cabeca() + soma(l.cauda()) fi };

   fatorial(n : Int) : Int { if n <= 1 then 1 else n * fatorial(n - 1) fi };

   main() : Object {
      let l : Lista <- new Lista, i : Int, j : Int in {
         while i < 5 loop { i <- i + 1; l <- l.insere(i); } pool;
         out_int(soma(l)).out_string("\n");
         out_int(fatorial(6)).out_string("\n");
         i <- j <- 3;
         out_int(i + j).out_string("\n");
         if isvoid l then out_string("void\n") else out_string("nao void\n") fi;
      }
   };
};
