(*
 *  CS164 Fall 94
 *
 *  Programming Assignment 1
 *    Implementation of a simple stack machine.
 *
 *  Skeleton file
 *)

class StackCommand inherits IO {
    next : StackCommand;
    init_next(n : StackCommand) : SELF_TYPE {
        {
            next <- n;
            self;
        }
    };
    get_next() : StackCommand {
        next
    };
    get_int() : Int {
        {
            abort();
            0;
        }
    };
    display() : Object {
        abort()
    };
    evaluate() : StackCommand {
        self
    };
};
class IntCommand inherits StackCommand {
    val : Int;
    init(i : Int) : SELF_TYPE {
        {
            val <- i;
            self;
        }
    };
    get_int() : Int {
        val
    };
    display() : Object {
        out_int(val)
    };
};
class PlusCommand inherits StackCommand {
    display() : Object {
        out_string("+")
    };
    evaluate() : StackCommand {
        let a : StackCommand <- next,
            b : StackCommand <- next.get_next(),
            soma : Int <- a.get_int() + b.get_int(),
            resultado : StackCommand <- (new IntCommand).init(soma)
        in
        {
            resultado.init_next(b.get_next());
            resultado;
        }
    };
};
class SCommand inherits StackCommand {
    display() : Object {
        out_string("s")
    };
    evaluate() : StackCommand {
        let a : StackCommand <- next,
            b : StackCommand <- next.get_next()
        in
        {
            a.init_next(b.get_next());
            b.init_next(a);
            b;
        }
    };
};
class Main inherits IO {
    top : StackCommand;  
    push(cmd : StackCommand) : Object {
        {
            cmd.init_next(top);
            top <- cmd;
        }
    };
    display_stack() : Object {
        let cur : StackCommand <- top in
        while not isvoid cur loop
            {
                cur.display();
                out_string("\n");
                cur <- cur.get_next();
            }
        pool
    };
    do_eval() : Object {
        if isvoid top then
            self
        else
            {
                top <- top.evaluate();
            }
        fi
    };
    digit_value(c : String) : Int {
        if c = "0" then 0 else
        if c = "1" then 1 else
        if c = "2" then 2 else
        if c = "3" then 3 else
        if c = "4" then 4 else
        if c = "5" then 5 else
        if c = "6" then 6 else
        if c = "7" then 7 else
        if c = "8" then 8 else
        if c = "9" then 9 else
        0
        fi fi fi fi fi fi fi fi fi fi
    };
    str2int(s : String) : Int {
        let len : Int <- s.length(),
            i : Int <- 0,
            resultado : Int <- 0
        in
        {
            while i < len loop
                {
                    resultado <- resultado * 10 + digit_value(s.substr(i, 1));
                    i <- i + 1;
                }
            pool;
            resultado;
        }
    };
    main() : Object {
        let cmd : String <- "",
            executando : Bool <- true
        in
        while executando loop
            {
                out_string(">");
                cmd <- in_string();
                if cmd = "x" then
                    executando <- false
                else if cmd = "+" then
                    {
                        push(new PlusCommand);
                        true;
                    }
                else if cmd = "s" then
                    {
                        push(new SCommand);
                        true;
                    }
                else if cmd = "d" then
                    {
                        display_stack();
                        true;
                    }
                else if cmd = "e" then
                    {
                        do_eval();
                        true;
                    }
                else
                    {
                        push((new IntCommand).init(str2int(cmd)));
                        true;
                    }
                fi fi fi fi fi;
            }
        pool
    };
};
