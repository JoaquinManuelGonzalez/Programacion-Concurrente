# Parcial MC - 2022

## Ejercicio 1

Resolver con SEMÁFOROS el siguiente problema. En una planta verificadora de vehículos, existen 7 estaciones donde se dirigen 150 vehículos para ser verificados. Cuando un vehículo llega a la planta, el coordinador de la planta le indica a qué estación debe dirigirse. El coordinador selecciona la estación que tenga menos vehículos asignados en ese momento. Una vez que el vehículo sabe qué estación le fue asignada, se dirige a la misma y espera a que lo llamen para verificar. Luego de la revisión, la estación le entrega un comprobante que indica si pasó la revisión o no. Más allá del resultado, el vehículo se retira de la planta. **Nota:** maximizar la concurrencia.

### Resolución

```c
int CantidadVehiculosPorEstacion[7] = ([7] 0); int estacionPorVehiculo[150] = ([150] -1); int colaVehiculos;
int colasPorEstacion[7];
Comprobante comprobantePorVehiculo[150];
sem avisoLlegada = 0; sem mutexColaVehiculos = 1; sem estacionAsignada[150] = ([150] 0);
sem mutexEstaciones = 1; sem avisoLlegadaEstacion[7] = ([7] 0); sem mutexColasPorEstacion[7] = ([7] 1);
sem esperaComprobante[150] = ([150] 0);

Process Vehiculo[id: 1..150] {
    int estacionDesignada; 
    Comprobante comprobante;
    P(mutexColaVehiculos);
    colaVehiculos.push(id);  // llego y me encolo
    V(mutexColaVehiculos);
    V(avisoLlegada);  // aviso al coordinador que un vehiculo llegó
    P(estacionAsignada[id]);  // espero a que me asignen una estación
    estacionDesignada = estacionPorVehiculo[id]; // obtengo la estación a la que tengo que ir
    P(mutexEstaciones);
    CantidadVehiculosPorEstacion[id]++;  // aumento la cantidad de vehiculos que esperan
    V(mutexEstaciones);
    P(mutexColasPorEstacion[estacionDesignada]);
    ColasPorEstacion[estacionDesignada].push(id);  // me encolo en la cola de mi estacion
    V(mutexColasPorEstacion[estacionDesignada]);
    V(avisoLlegadaEstacion[estacionDesignada]);  // aviso a la estación para que me atienda
    P(esperaComprobante[id]);  // espero a que me den mi comprobante
    comprobante = comprobantePorVehiculo[id];  // tomo mi comprobante
    P(mutexEstaciones);
    CantidadVehiculosPorEstacion[id]--;  // disminuyo la cantidad de vehiculos que esperan
    V(mutexEstaciones);
}

Process Coordinador {
    int vehiculo; int estacion;
    for (int i = 0; i < 150; i++) {
        P(avisoLlegada);  // espero a que llegue un vehículo;
        P(mutexColaVehiculos);
        vehiculo = colaVehiculos.pop();  // saco el vehículo de la cola de espera
        V(mutexColaVehiculos);
        P(mutexEstaciones);
        estacion = min(CantidadVehiculosPorEstacion)  // adquiero la estacion con menos vehiculos
        V(mutexEstaciones);
        estacionPorVehiculo[vehiculo] = estacion;  // asigno la estación
        V(estacionAsignada[vehiculo]);  // aviso que ya puede asignarse la estación
    }
}

Process Estacion[id: 1..7] {
    int vehiculo;
    while true {
        P(avisoLlegadaEstacion[id]);  // espero que me avisen que hay alguien en mi estacion
        P(mutexColasPorEstacion[id]);
        vehiculo = mutexColasPorEstacion[id].pop();  // saco al vehiculo que está esperando
        V(mutexColasPorEstacion[id]);
        comprobantePorVehiculo[vehiculo] = verificar(vehiculo);  // guardo el comprobante generado
        V(esperaComprobante[vehiculo]);  // le aviso al vehiculo que puede retirar el comprobante
    }
}
```

## Ejercicio 2

Resolver con MONITORES el siguiente problema. En un sistema operativo se ejecutan 20 procesos que periódicamente realizan cierto cómputo mediante la función **Procesar()**. Los resultados de dicha función son persistidos en un archivo, para lo que se requiere de acceso al subsistema de E/S. Sólo un proceso a la vez puede hacer uso del subsistema de E/S, y el acceso al mismo se define por la prioridad del proceso (menor valor indica mayor prioridad).

### Resolución

```c
Monitor Subsistema {
    bool subsistemaLibre = true;
    Procesos colaProcesos;
    cond espera[20];
    int siguiente;

    Procedure SolicitarAcceso(id: in int; nivelPrioridad: in int) {
        if (subsistemaLibre) {  // si esta libre el subsitema, lo apropio
            subsistemaLibre = false;
        } else {  // sino, me encolo ordenado
            colaProcesos.pushOrdenado(id, nivelPrioridad);
            wait(espera[id]);
        }
    }

    Procedure LiberarAcceso() {
        if (!colaProcesos.isEmpty()) {  // si hay procesos esperando, le doy paso al siguiente
            siguiente = colaProcesos.pop();
            signal(espera[siguiente]);
        } else {  // sino, libero el subsistema
            subsistemaLibre = true;
        }
    }
}

Process Proceso[id: 1..20] {
    int nivelPrioridad = ...;
    str resultado;
    while true {
        resultado = Procesar();
        Subsistema.SolicitarAcceso(id, nivelPrioridad);
        // escribe en el archivo
        Subsistema.LiberarAcceso();
    }
}
```