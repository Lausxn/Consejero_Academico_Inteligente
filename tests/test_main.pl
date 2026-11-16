:- use_module('../prolog/main').
:- use_module(library(plunit)).

:- begin_tests(main).

test(saludo) :- with_output_to(string(_), saludo).

:- end_tests(main).
