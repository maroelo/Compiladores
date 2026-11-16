(*
 *  bad.cl
 *  Programa com o maior numero possivel de erros semanticos que NAO
 *  interrompem a analise. O grafo de heranca aqui e valido, entao o
 *  analisador deve reportar todos os erros abaixo em uma unica execucao.
 *  Erros de heranca (ciclos, pai indefinido, etc.) interrompem a
 *  compilacao e por isso ficam em arquivos separados em tests/bad/.
 *  Cada comentario indica o erro esperado na linha seguinte.
 *)

class A {
   x : Int <- 0;
   f(a : Int, b : Bool) : Int { a };
   g() : SELF_TYPE { self };
   h() : A { self };
};

class B inherits A {
   (* atributo redefinido de classe herdada *)
   x : Int;
   (* atributo com tipo indefinido *)
   y : Inexistente;
   (* atributo chamado self *)
   self : Int;
   (* atributo duplicado na mesma classe *)
   z : Int;
   z : Bool;
   (* inicializacao que nao conforma com o tipo declarado *)
   w : Int <- "texto";

   (* redefinicao com numero diferente de parametros *)
   f(a : Int) : Int { a };
   (* redefinicao com tipo de retorno diferente *)
   g() : B { self };
   (* metodo duplicado na mesma classe *)
   k() : Int { 1 };
   k() : Int { 2 };
};

class C inherits A {
   (* redefinicao com tipo de parametro diferente *)
   f(a : Int, b : Int) : Int { a };
   (* tipo de retorno indefinido *)
   m() : Nada { 0 };
   (* parametro chamado self, parametro SELF_TYPE, parametro duplicado
      e parametro de tipo indefinido *)
   n(self : Int, p : SELF_TYPE, q : Int, q : Bool, r : Fantasma) : Int { 0 };
   (* corpo nao conforma com o tipo de retorno *)
   o() : Int { true };
   (* SELF_TYPE no retorno exige self ou expressao SELF_TYPE *)
   s() : SELF_TYPE { new C };
};

class Main {
   a : A <- new A;

   main() : Object { 0 };

   expressoes() : Object {
      {
         (* identificador nao declarado *)
         nao_existe;
         (* atribuicao a variavel nao declarada *)
         fantasma <- 1;
         (* atribuicao a self *)
         self <- new Main;
         (* atribuicao com tipo incompativel *)
         a <- 5;

         (* aritmetica com operandos nao Int *)
         1 + true;
         "a" - 2;
         a * 3;
         4 / "b";
         (* negacao e comparacoes com tipos errados *)
         ~true;
         1 < "dois";
         false <= 2;
         (* not aplicado a nao Bool *)
         not 3;
         (* comparacao ilegal com tipo basico *)
         1 = "um";
         true = 0;
         a = 2;

         (* predicados que nao sao Bool *)
         if 1 then 2 else 3 fi;
         while "sim" loop 0 pool;

         (* new com classe indefinida *)
         new Desconhecida;

         (* dispatch para metodo inexistente *)
         a.inexistente();
         (* numero errado de argumentos *)
         a.f(1);
         (* argumento com tipo errado *)
         a.f(1, 2);
         (* dispatch estatico para classe indefinida *)
         a@Sumida.h();
         (* tipo da expressao nao conforma com o tipo do dispatch estatico *)
         a@B.h();
         (* dispatch estatico para metodo inexistente *)
         (new B)@A.k();
         (* chamada em self de metodo inexistente *)
         metodo_fantasma(1);
      }
   };

   lets_e_cases() : Object {
      {
         (* let com tipo indefinido *)
         let v : Vazio in 0;
         (* let ligando self *)
         let self : Int <- 1 in 0;
         (* inicializacao do let nao conforma *)
         let n : Int <- "nao" in n;
         (* o nome do let nao e visivel na propria inicializacao *)
         let w : Int <- w + 1 in w;

         case a of
            (* ramos com tipo duplicado *)
            x : Int => 0;
            y : Int => 1;
            (* ramo com tipo indefinido *)
            z : Fantasma => 2;
            (* ramo com SELF_TYPE *)
            t : SELF_TYPE => 3;
            (* ramo ligando self *)
            self : A => 4;
         esac;

         (* variavel do ramo nao existe fora do case *)
         case 1 of i : Int => i; esac + i;
      }
   };
};
