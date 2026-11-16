:- module(main, [saludo/0]).

saludo :- format("Entorno Prolog listo.~n").

:- initialization(saludo).
