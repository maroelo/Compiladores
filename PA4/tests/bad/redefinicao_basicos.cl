(* Redefinicao dos metodos das classes basicas com assinatura errada
   e metodo main duplicado. *)
class Main inherits IO {
  main() : Object { 0 };
  main() : Int { 1 };
  out_string(s : String) : SELF_TYPE { self };
  out_int(s : String) : SELF_TYPE { self };
  in_int() : String { "" };
  abort() : Object { 0 };
  copy(x : Int) : SELF_TYPE { self };
};
