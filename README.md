<p align="center"> <b>INFORME PROYECTO SISTEMAS OPERATIVOS</b></p>


Asignación FaaS, K8S, Inlets

<b>Informe despliegue tecnologías FaaS, K8S, Inlets</b>

Este informe presenta las actividades realizadas para llevar a cabo el despliegue de tecnologías FaaS (Function as a Service), K8S (Kubernetes) e Inlets. A continuación se presenta el diagrama con la arquitectura de despliegue.

<p align="center">
  <img src="https://github.com/hannibalhalo2/proyectoso/blob/master/Imagenes/Diagrama.png">

</p>

 <b> 1. Despliegue de Kubernetes </b>

 El ambiente que se eligió para llevar a cabo el despliegue de kubernetes fue Minikube en sistema Operativo Linux Ubuntu 20.04 LTS. Minikube es una versión reducida de Kubernetes que permite correr en una máquina virtual un nodo único de clúster de kubernetes, que hace las veces de máster y workers. A continuación se presentan los pasos realizados para instalar Minikube.

 <b> 1) Consideraciones Iniciales: </b>

 - Verificar si la virtualización es soportada en Linux ejecutando el siguiente comando y verificar que la salida no esta vacía.

           grep -E --color 'vmx|svm' /proc/cpuinfo

 - Instalar un hipervisor: Hipervisor elegido VirtualBox,

<b> 2) Instalar kubectl </b>

 - Descargar la versión mas reciente

           curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl

 - Dar permisos de ejecución al binario kubectl

           chmod +x ./kubectl

 - Mover el binario al path del usuario

           sudo mv ./kubectl /usr/local/bin/kubectl

 - Verificar que la version instalada sea la mas reciente

           kubectl version –client

<b>3) Instalar Minikube via descarga directa</b>

           curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \  && chmod +x minikube

<b>4) Adicionar el ejecutable de Minikube al path del usuario</b>

           sudo mkdir -p /usr/local/bin/
           sudo install minikube /usr/local/bin/

<b>5 ) Instalar helm que es un gestor de paquetes de kubernetes. (Versiones de Ubuntu 16.04 o 
superiores ya tienen instalado snap, versiones inferiores no lo incluyen y debe ser instalado previamente). </b>

           sudo snap install helm –classic

<b>6) Confirmar la instalación iniciando el cluster de Minikube </b>

           minikube start --driver=virtualbox

           minikube status


<b>2. Despliegue de OpenFaas a Minikube</b>

       - Crear una cuenta de servicio para el componente del servidor Helm tiller:
           kubectl -n kube-system create sa tiller && kubectl create clusterrolebinding tiller --clusterrole cluster-admin –serviceaccount=kube-system:tiller
       - Crear namespaces  para los componentes y funciones fundamentales de OpenFaaS:
           kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
       - Añadir el repositorio helm OpenFaaS helm:
           helm repo add openfaas https://openfaas.github.io/faas-netes/
       - Actualizar todos los charts para helm:
           helm repo update
        - Generar password aleatorio:
           export PASSWORD=$(head -c 12 /dev/urandom | shasum| cut -d' ' -f1)
       - Tomar nota del valor de la variable $PASSWORD
           lu@lu-Lenovo-G40-80:~/ProyectoSO/Minik$ echo $PASSWORD
           04aca00355215de5eb5ccd2107ceb4015a15d8f5
       - Crear un secreto para el password:
           kubectl -n openfaas create secret generic basic-auth --from-literal=basic-auth-user=admin --from-literal=basic-auth-password="$PASSWORD"
       - Instalar OpenFaaS usando el chart:
           helm upgrade openfaas --install openfaas/openfaas --namespace openfaas --set functionNamespace=openfaas-fn --set basic_auth=true
       - Establecer la variable OPENFAAS_URL
           export OPENFAAS_URL=$(minikube ip):31112
       -Después de que todos los Pods de OpenFaas estén iniciados se envía comando de Login:
           echo -n $PASSWORD | faas-cli login -g http://$OPENFAAS_URL -u admin — password-stdin

 - El siguiente comando entrega los pods OpenFaas instalados en el clúster de minikube.

          kubectl get pods -n openfaas


<b> 3. Despliegue de Inlets en Google Cloud Platform</b>

Para realizar el despliegue de Inlets se realizaron los siguientes pasos, tomando como referencia el repositorio de git https://github.com/josanabr/tunneling-inlets.git.

 - Instalar los siguientes paquetes: docker, gcloud

  docker: usando el script [install-docker.sh](scripts/install-docker.sh)

           apt-get update
           apt-get -y --force-yes install docker.io
           usermod -aG docker vagrant

  GCLOUD: usando el script [install-gcloud.sh](scripts/install-gcloud.sh)

          echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
          curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
          sudo apt-get update && sudo apt-get -y install google-cloud-sdk



- Después de realizar la instalación se ejecuto el script encargado de crear el Exit Node en GCP [crear-inlets-exit-node.sh](/scripts/crear-inlets-exit-node.sh), y se guardo la información de las variables que se requieren para ejecutar el cliente de inlets que se comunica con el contenedor que está en GCP.

          REMOTE="35.233.171.84:8090"
          TOKEN="aca84fefcb3aad602c52531cca66aff4bf79cc58b1c211d62ee5afd4dc379ddd"
          DIGEST="sha256:e1ae8711fa5a7ee30bf577d665a7a91bfe35556f83264c06896765d75b84a99


Después de tener la configuración y despliegue del Exit Node procedemos a correr la función que se desea exponer.


  <b> 4. Despliegue de Función</b>

Para realizar esta tarea se utilizó la herramienta de escaneo de red Nmap. Se realizo el despliegue de una función que permite realizar el descubrimiento de los equipos conectados a la red privada donde se encuentra desplegado el clúster de kubernetes. Se siguieron los siguientes pasos:

  - Invocar la función nmap usando lenguaje “Dockerfile”

          faas new --lang dockerfile nmap

  - Este comando creo 2 archivos nmap.yml y Dockerfile en el directorio nmap


  - Se edito el archivo [Dockerfile](scripts/Dockerfile) y se añadieron las siguientes lineas:

    - Comando que añade el paquete nmap a la imagen de docker:

          RUN apk add --no-cache nmap

    - Se modificó ENV fprocess añadiendo el comando xargs nmap que permite pasar parametros cuando se invoca la función.

          ENV fprocess="xargs nmap"

    - Y se añadieron las siguientes lineas para extender el tiempo que podría tomar la ejecución de nmap.

          ENV read_timeout="60" ENV write_timeout="60"


 - Se edito el archivo [nmap.yml](scripts/nmap.yml) y se modifico el puerto y la dirección IP de la url de la variable gateway con la Ip de Minikube, puerto 31112.

        kubectl get node minikube -o wide

  - Construcción, Envío y Despliegue de la función.



   <b> 5. Invocación local de la función</b>

       export gw=http://$(minikube ip):31112
       echo -n "-sP 192.168.0.0/24" | faas invoke nmap --gateway $gw


<p align="center">
  <img src="https://github.com/hannibalhalo2/proyectoso/blob/master/Imagenes/9.png">

</p>

Se observó la ejecución de la función y el resultado de los hosts que se encuentran arriba

  <b> 6. Ejecutando el cliente inlets</b>

 Con el Exit Node en GCP y la función desplegada se procedió a ejecutar el script del cliente Inlets.

  [correr-cliente-inlets.sh](scripts/correr-cliente-inlets.sh)


<p align="center">
  <img src="https://github.com/hannibalhalo2/proyectoso/blob/master/Imagenes/8.png">

</p>

        echo -n "-sP 192.168.1.0/24" | faas invoke nmap --gateway $gw



   <b> 7. Invocación de la función desde Internet a través del Exit Node</b>

           echo -n "-sP 192.168.1.0/24" | faas invoke nmap --gateway 35.233.171.84:8090

<p align="center">
  <img src="https://github.com/hannibalhalo2/proyectoso/blob/master/Imagenes/10.png">
</p>

[ENLACE A VIDEO ASCIINEMA](https://asciinema.org/connect/65a9828a-e49b-4316-ade2-c790c1189ca7)


ENLACES DE REFERENCIA

  [https://medium.com/faun/getting-started-with-openfaas-on-minikube-634502c7acdf](https://medium.com/faun/getting-started-with-openfaas-on-minikube-634502c7acdf)

  [https://kubernetes.io/docs/tasks/tools/install-minikube/](https://kubernetes.io/docs/tasks/tools/install-minikube/)
  
  [https://blog.alexellis.io/cli-functions-with-openfaas/](https://blog.alexellis.io/cli-functions-with-openfaas/)
                                                                                                                                  	   
