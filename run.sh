#!/bin/bash

# Función para obtener la IP del router del inventario de ansible
function get_router_ip() {
    awk '/^[^#]/ && NF==1 { print $1; exit }' /etc/ansible/hosts
}

# Función para saber si tenemos comunicación con la máquina
function run_ansible_ping() {
    ansible -m ping router | grep -E -i "UNREACHABLE|SUCCESS"
}

ROUTER_IP=$(get_router_ip)

# Número máximo de intentos fallidos permitidos
MAX_TRIES=3

# Contador de intentos fallidos
try_count=0

# Mientras no tengamos conexión y no hayamos alcanzado el límite de intentos fallidos generamos claves ssh y la añadimos al router
while ! run_ansible_ping | grep -q "SUCCESS" && [ $try_count -lt $MAX_TRIES ]; do
    if run_ansible_ping | grep -q "UNREACHABLE"; then
        echo "Router inalcanzable. Generando claves SSH..."
        ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
        ssh-copy-id -i ~/.ssh/id_rsa.pub $ROUTER_IP
        #Posible fallo que pida contraseña root vps y se detenga por no estar contemplado
        ((try_count++))
    fi

    echo "Esperando 5 segundos antes de volver a intentarlo..."
    sleep 5
done

# Si alcanzamos el límite de intentos fallidos, mostrar mensaje y cancelar la ejecución (podríamos acabar tirando alguna máquina si no)
if [ $try_count -eq $MAX_TRIES ]; then
    echo "No se ha podido establecer la conexión tras $MAX_TRIES intentos. Saliendo... "
    exit 1
fi

# Ejecutar el playbook ya que el router es accesible
echo "Existe conexión con el router. Ejecutando Playbook..."
ansible-playbook /etc/ansible/playbooks/ddos-path.yaml
