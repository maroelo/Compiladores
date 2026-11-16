(*
 *  good.cl
 *  Programa correto que exercita o maior numero possivel de regras
 *  semanticas legais. Deve passar pelo mysemant sem nenhum erro e,
 *  compilado com mycoolc, executar no spim imprimindo resultados.
 *)

(* Hierarquia: Forma <- Retangulo <- Quadrado, Forma <- Circulo.
   Testa heranca, redefinicao de metodo com a mesma assinatura,
   atributos herdados e uso de atributos antes da declaracao. *)
class Forma inherits IO {
   nome : String <- "forma";
   area() : Int { 0 };
   descricao() : String { nome.concat(" de area ").concat(i2s(area())) };

   (* metodo usado antes de ser declarado na classe Forma *)
   i2s(n : Int) : String { (new Conversor).para_string(n) };

   (* retorno SELF_TYPE: subclasses recebem o proprio tipo *)
   renomear(n : String) : SELF_TYPE { { nome <- n; self; } };
};

class Retangulo inherits Forma {
   largura : Int <- 2;
   altura : Int <- 3;
   area() : Int { largura * altura };
   dimensoes(l : Int, a : Int) : SELF_TYPE {
      { largura <- l; altura <- a; self; }
   };
};

class Quadrado inherits Retangulo {
   lado(l : Int) : SELF_TYPE { dimensoes(l, l) };
};

class Circulo inherits Forma {
   raio : Int <- 1;
   area() : Int { 3 * raio * raio };
};

(* Conversao de inteiro para string com recursao, if, divisao e
   comparacoes. Classe declarada depois de ser usada em Forma. *)
class Conversor {
   digito(d : Int) : String {
      if d = 0 then "0" else
      if d = 1 then "1" else
      if d = 2 then "2" else
      if d = 3 then "3" else
      if d = 4 then "4" else
      if d = 5 then "5" else
      if d = 6 then "6" else
      if d = 7 then "7" else
      if d = 8 then "8" else "9"
      fi fi fi fi fi fi fi fi fi
   };

   para_string(n : Int) : String {
      if n < 0 then "-".concat(para_string(~n)) else
      if n < 10 then digito(n) else
         para_string(n / 10).concat(digito(n - (n / 10) * 10))
      fi fi
   };
};

(* Lista encadeada com atributo do tipo SELF_TYPE e isvoid. *)
class No {
   valor : Int;
   prox : No;
   init(v : Int, p : No) : SELF_TYPE { { valor <- v; prox <- p; self; } };
   valor() : Int { valor };
   prox() : No { prox };
   copia_de_mim : SELF_TYPE;
};

class Main inherits IO {
   r : Retangulo <- new Retangulo;
   contador : Int;
   flag : Bool;
   texto : String;
   objeto : Object;

   imprime(s : String) : SELF_TYPE { out_string(s.concat("\n")) };

   (* case com lub entre ramos e tipo dinamico *)
   classifica(o : Object) : String {
      case o of
         q : Quadrado => "quadrado";
         r : Retangulo => "retangulo";
         c : Circulo => "circulo";
         f : Forma => "forma";
         s : String => "string ".concat(s);
         i : Int => "inteiro";
         b : Bool => "booleano";
         x : Object => "objeto";
      esac
   };

   (* if cujo tipo e o lub de Quadrado e Circulo, isto e, Forma *)
   escolhe(b : Bool) : Forma {
      if b then (new Quadrado).lado(4) else new Circulo fi
   };

   soma_lista(n : No) : Int {
      let total : Int <- 0, atual : No <- n in {
         while not isvoid atual loop {
            total <- total + atual.valor();
            atual <- atual.prox();
         } pool;
         total;
      }
   };

   main() : Object {
      let q : Quadrado <- (new Quadrado).lado(5),
          f : Forma <- q,
          c : Circulo <- new Circulo,
          lista : No <- (new No).init(1, (new No).init(2, (new No).init(3, new No))),
          conv : Conversor <- new Conversor
      in {
         imprime(f.descricao());
         imprime(c.descricao());
         imprime(r.dimensoes(4, 5).descricao());

         (* dispatch estatico chama a versao de Forma *)
         imprime(conv.para_string(q@Forma.area()));
         imprime(conv.para_string(q@Retangulo.area()));

         (* SELF_TYPE preserva o tipo Quadrado depois de renomear *)
         imprime(q.renomear("quadrado").lado(2).descricao());

         imprime(classifica(q));
         imprime(classifica(c));
         imprime(classifica(new Forma));
         imprime(classifica("abc"));
         imprime(classifica(42));
         imprime(classifica(true));
         imprime(classifica(new Main));

         imprime(escolhe(true).descricao());
         imprime(escolhe(false).descricao());

         imprime(conv.para_string(soma_lista(lista)));

         (* atributos sem inicializacao recebem o valor padrao *)
         if contador = 0 then imprime("contador inicia em 0") else abort() fi;
         if not flag then imprime("flag inicia em false") else abort() fi;
         if texto.length() = 0 then imprime("texto inicia vazio") else abort() fi;
         if isvoid objeto then imprime("objeto inicia void") else abort() fi;

         (* let aninhado escondendo um nome externo *)
         let contador : Int <- 10 in
            let contador : Int <- contador + 5 in
               imprime(conv.para_string(contador));
         imprime(conv.para_string(contador));

         (* aritmetica, precedencia, negacao e comparacoes *)
         imprime(conv.para_string(1 + 2 * 3 - 8 / 4));
         imprime(conv.para_string(~(3 - 10)));
         if 2 <= 2 then imprime("2 <= 2") else abort() fi;
         if not (3 < 2) then imprime("not 3 < 2") else abort() fi;

         (* igualdade entre objetos e entre tipos basicos iguais *)
         if q = f then imprime("q = f mesma referencia") else abort() fi;
         if "abc" = "abc" then imprime("strings iguais") else abort() fi;
         if true = not false then imprime("bools iguais") else abort() fi;

         (* metodos das classes basicas *)
         imprime("compilador".substr(0, 7));
         imprime(type_name());
         imprime(q.type_name());
         imprime(q.copy().descricao());
         out_int("cool".length()).out_string("\n");

         (* atribuicao retorna o valor atribuido *)
         contador <- contador <- 7;
         imprime(conv.para_string(contador));

         (* while devolve Object, isvoid devolve Bool *)
         objeto <- while false loop 0 pool;
         if isvoid objeto then imprime("while devolve void") else abort() fi;

         self;
      }
   };
};
