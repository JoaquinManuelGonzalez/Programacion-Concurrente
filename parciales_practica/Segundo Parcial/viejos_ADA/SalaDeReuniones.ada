/*
Resolver este ejercicio con ADA. 
En un banco se tiene un sistema que administra el uso de una sala de reuniones
por parte de N clientes. Los clientes se clasifican en habituales o temporales.
La sala puede ser usada por un unico cliente a la vez
Y cuando esta libre se debe determinar a quien permitirle su uso siempre priorizando a los clientes habituales
Dentro de cada clase de cliente se debe respetar el orden de llegada
Nota: suponga que existe una funcion tipo() que le indica al cliente de que tipo esta
*/

procedure SalaDeReuniones is

task type Cliente;

task Sistema is
	entry pasarHabitual();
	entry pasarTemporal();
	entry liberar();
end sistema;

Clientes: array (0..N-1) of Cliente;


task body Cliente is
	id: Integer;
begin
	if (tipo() = "habitual") then
		Sistema.pasarHabitual(id);
	else
		Sistema.pasarTemporal(id);
	end if;

	usarSalaDeReuniones();
	Sistema.liberar();
end Cliente;


task body Sistema is
	idC: Integer;
	libre: Boolean := true;
begin
	loop
		select
			accept liberar();
			libre := true;
		or when (libre) =>
			accept pasarHabitual();
			libre := false;
		or when ((libre) and (pasarTemporal´count = 0))
			accept pasarTemporal();
			libre := false;
		end select;
	end loop;
end Sistema;


begin
	null;
end SalaDeReuniones;
