
(*
 *  execute "coolc bad.cl" to see the error messages that the coolc parser
 *  generates
 *
 *  execute "myparser bad.cl" to see the error messages that your parser
 *  generates
 *)class

(* no error *)
class A {
};

(* error:  b is not a type identifier *)
class b inherits A {
};

(* error:  a is not a type identifier *)
class C inherits a {
};

(* error:  keyword inherits is misspelled *)
class D inherts A {
};

(* error:  missing type identifer *)
class E {
    x : ;
};

(* error:  unmached operator *)
class F {
    x : Int;

    test() : Int {
        x <- 5 ++ 2
    };
};

(* error: missing attribute type *)
class G {
    x : ;
    y : Int <- 1;
};

(* error: missing return type; *)
class H {
    test(x : Int) : { x };
};

(* error:  closing brace is missing *)
class I {
;