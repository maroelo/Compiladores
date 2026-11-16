(* Todos os metodos das classes basicas Object, IO e String,
   com os tipos de retorno corretos (incluindo SELF_TYPE em IO). *)
class Main inherits IO {
   main() : Object {
      let s : String <- "abcdef",
          o : Object <- new Object,
          io : IO <- new IO
      in {
         out_string(s.concat("ghi")).out_string("\n");
         out_string(s.substr(2, 3)).out_string("\n");
         out_int(s.length()).out_string("\n");
         out_string(o.type_name()).out_string("\n");
         out_string(io.type_name()).out_string("\n");
         out_string(s.type_name()).out_string("\n");
         out_string(1.type_name()).out_string("\n");
         out_string(true.type_name()).out_string("\n");
         io.out_string("io separado\n").out_int(10).out_string("\n");
         case o.copy() of x : Object => out_string("copy ok\n"); esac;
         if false then abort() else 0 fi;
         if false then in_string() else "" fi;
         if false then in_int() else 0 fi;
      }
   };
};
