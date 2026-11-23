SWIPL ?= swipl
PORT ?= 8080

.PHONY: test run docs-check verificar limpiar

test:
	$(SWIPL) -q -g run_tests -t halt tests/test_all.pl

run:
	$(SWIPL) main.pl -- --port=$(PORT)

docs-check:
	$(SWIPL) -q -s herramientas/docs_check.pl -g ejecutar -t halt

verificar: test docs-check

limpiar:
	find . -name '*.qlf' -delete
