#!/bin/bash
# Executa a bateria de testes do analisador semantico.
# Uso (dentro do diretorio PA4, depois de "make semant"):
#   bash tests/run_tests.sh
#
# Para cada programa correto (good.cl e tests/good/*.cl):
#   - o semant deve terminar com codigo 0 e sem mensagens de erro;
#   - a AST anotada deve ser igual a produzida pelo semant de referencia;
#   - o programa e compilado com mycoolc e executado no spim.
# Para cada programa incorreto (bad.cl e tests/bad/*.cl):
#   - o semant deve terminar com codigo 1;
#   - as mensagens sao gravadas e comparadas, em quantidade, com a referencia.

cd "$(dirname "$0")/.." || exit 1

REF_SEMANT=/var/tmp/cool/lib/.x86_64/semant
SPIM=/var/tmp/cool/bin/spim
OUT=tests/output
mkdir -p "$OUT"

pass=0
fail=0

ok()   { echo "  [OK]    $1"; pass=$((pass + 1)); }
erro() { echo "  [FALHA] $1"; fail=$((fail + 1)); }

echo "== Programas corretos =="
for f in good.cl tests/good/*.cl; do
    nome=$(basename "$f" .cl)
    ./lexer "$f" | ./parser "$f" > "$OUT/$nome.ast" 2> /dev/null
    ./semant < "$OUT/$nome.ast" > "$OUT/$nome.semant" 2> "$OUT/$nome.err"
    codigo=$?
    if [ $codigo -ne 0 ] || [ -s "$OUT/$nome.err" ]; then
        erro "$f rejeitado (veja $OUT/$nome.err)"
        continue
    fi
    if [ -x "$REF_SEMANT" ]; then
        "$REF_SEMANT" < "$OUT/$nome.ast" > "$OUT/$nome.ref" 2> /dev/null
        if ! cmp -s "$OUT/$nome.semant" "$OUT/$nome.ref"; then
            erro "$f AST anotada difere da referencia"
            continue
        fi
    fi
    ./cgen < "$OUT/$nome.semant" > "$OUT/$nome.s" 2> /dev/null
    "$SPIM" -file "$OUT/$nome.s" < /dev/null 2>&1 | tail -n +6 > "$OUT/$nome.run"
    if grep -q "Abort\|Exception\|error" "$OUT/$nome.run"; then
        erro "$f falhou na execucao (veja $OUT/$nome.run)"
    else
        ok "$f (saida da execucao em $OUT/$nome.run)"
    fi
done

echo "== Programas incorretos =="
for f in bad.cl tests/bad/*.cl; do
    nome=$(basename "$f" .cl)
    ./lexer "$f" | ./parser "$f" > "$OUT/$nome.ast" 2> /dev/null
    ./semant < "$OUT/$nome.ast" > /dev/null 2> "$OUT/$nome.err"
    codigo=$?
    nossos=$(grep -c ":[0-9]*: \|^Class Main" "$OUT/$nome.err")
    if [ $codigo -ne 1 ]; then
        erro "$f deveria ser rejeitado"
        continue
    fi
    if [ -x "$REF_SEMANT" ]; then
        "$REF_SEMANT" < "$OUT/$nome.ast" > /dev/null 2> "$OUT/$nome.referr"
        deles=$(grep -c ":[0-9]*: \|^Class Main" "$OUT/$nome.referr")
        ok "$f rejeitado com $nossos erro(s); referencia: $deles"
    else
        ok "$f rejeitado com $nossos erro(s)"
    fi
done

echo
echo "Resultado: $pass ok, $fail falha(s)"
[ $fail -eq 0 ]
