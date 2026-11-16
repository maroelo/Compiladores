(* Classes, metodos e atributos usados antes de serem declarados.
   A analise precisa coletar todas as declaracoes antes de verificar
   os corpos. Main aparece primeiro e herda de uma classe declarada depois. *)
class Main inherits Base {
   main() : Object { out_string(mensagem().concat("\n")) };
};

class Base inherits IO {
   mensagem() : String { prefixo.concat(sufixo()) };
   sufixo() : String { (new Auxiliar).texto() };
   prefixo : String <- "referencia ";
};

class Auxiliar {
   texto() : String { valor };
   valor : String <- "adiante";
};
