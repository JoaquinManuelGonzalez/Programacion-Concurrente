# Parcial MC - parcial.txt

## Ejercicio 1

SEMÁFOROS. Existen 15 sensores de temperatura y 2 módulos centrales de procesamiento. Un sensor mide la temperatura cada cierto tiempo (función medir()), la envía al módulo central para que le indique qué acción debe hacer (un número del 1 al 10) (función determinar() para el módulo central) y la hace (función realizar()). Los módulos atienden las mediciones por orden de llegada.

### Resolución

```c
Mediciones colaMediciones;
int accionesPorSensor[15] = ([15] 0);
sem asignarAccion[15] = ([15] 0); sem mutexColaMediciones = 1; sem hayMedicion = 0; 

Process Sensor[id: 1..15] {
    Medicion medicion;
    int accion;
    while true {
        medicion = medir();  // obtengo una medicion
        P(mutexColaMediciones);
        colaMediciones.push(id, medicion);  // encolo la medicion y mi id
        V(mutexColaMediciones);
        V(hayMedicion);  // aviso que hay medicion
        P(asignarAccion[id]);  // espero que me den una acción
        accion = accionesPorSensor[id];
        realizar(accion);  // realizo la acción
    }
}

Process ModuloCentral[id: 1..2] {
    int idSensor;
    Medicion medicion;
    while true {
        P(hayMedicion);  // espero que me avisen que hay medicion
        P(mutexColaMediciones);
        idSensor, medicion = colaMediciones.pop();
        V(mutexColaMediciones);
        accionesPorSensor[idSensor] = determinar(medicion);  // asigno una acción
        V(asignarAccion[idSensor]);  // aviso que asigné la acción
    }
}
```

## Ejercicio 2

MONITORES. Una boletería vende E entradas para un partido, y hay P personas (P>E) que quieren comprar. Se las atiende por orden de llegada y la función vender() simula la venta. La boletería debe informarle a la persona que no hay más entradas disponibles o devolverle el número de entrada si pudo hacer la compra.

### Resolución

```c
Monitor Boleteria {
    ColaPersonas personas;
    bool vendedorLibre = true;
    cond espera[P];
    int siguiente;

    Procedure LlegadaAlPartido(id: in int) {
        if (vendedorLibre) {
            vendedorLibre = false;
        } else {
            personas.push(id);
            wait(espera[id]);
        }
    }

    Procedure LiberarVendedor() {
        if (!personas.isEmpty()) {
            siguiente = personas.pop();
            signal(espera[siguiente]);
        } else {
            vendedorLibre = true;
        }
    }
}

Monitor Mostrador {
    bool llegadaPersona = false;
    cond esperaPersona; cond hayEntrada;
    int numeroActual;

    Procedure ComprarEntrada(numeroDeEntrada: out int) {
        llegadaPersona = true;
        signal(esperaPersona);
        wait(hayEntrada);
        numeroDeEntrada = numeroActual;
        llegadaPersona = false;
    }

    Procedure EsperaLlegadaPersona() {
        if (!llegadaPersona) {
            wait(esperaPersona);
        }
    }

    Procedure DepositarEntrada(numeroEntrada: in int) {
        numeroActual = numeroEntrada;
        signal(hayEntrada);
    }
}

Process Persona[id: 1..P] {
    int numeroDeEntrada;
    Boleteria.LlegadaAlPartido(id);
    Mostrador.ComprarEntrada(numeroDeEntrada);
    Boleteria.LiberarVendedor();
}

Process Vendedor {
    int numeroActual; int cantidadDeEntradas = E;
    for [int i = 1; i < P; i++] {
        Mostrador.EsperaLlegadaPersona();
        if (cantidadDeEntradas > 0) {
            numeroActual = vender();
            cantidadDeEntradas--;
        } else {
            numeroActual = -1;
        }
        Mostrador.DepositarEntrada(numeroActual);
    }
}
```

## Ejercicio 3

MONITORES. Por un puente turístico puede pasar sólo un auto a la vez. Hay N autos que quieren pasar (función pasar()) y lo hacen por orden de llegada.

### Resolución

```c
Monitor Puente {
    int siguiente;
    bool puenteLibre = true;
    Autos colaAutos;
    cond espera[N];

    Procedure Acceder(id: in int) {
        if (puenteLibre) {
            puenteLibre = false;
        } else {
            colaAutos.push(id);
            wait(espera[id]);
        }
    }

    Procedure Liberar() {
        if (colaAutos.isEmpty()) {
            puenteLibre = true;
        } else {
            siguiente = colaAutos.pop();
            signal(espera[siguiente]);
        }
    }
}

Process Auto[id: 1..N] {
    Puente.Acceder(id);
    // pasar
    Puente.Liberar();
}
```