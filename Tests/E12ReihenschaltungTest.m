% Experiment zur Reihenschaltung
% Ist in elektro.m integriert, hier nur die Tests und Versuche

% lade elektro Skript
elektro


printf("reihe Funktion ausprobieren\n");
[e1, e2, abw] = reihe( 111, E12 )
[e1, e2, abw] = reihe( 4711, E12 )
[e1, e2, abw] = reihe( 0.9, E12 )

printf("\nparallel Funktion ausprobieren\n");
[e1, e2, abw] = parallel( 111, E12 )
[e1, e2, abw] = parallel( 4711, E12 )
[e1, e2, abw] = parallel( 0.9, E12 )

  
