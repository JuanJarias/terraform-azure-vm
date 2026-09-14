# Máquina virtual Linux en Azure con Terraform

Este repositorio aprovisiona una máquina virtual Ubuntu en Microsoft Azure usando Terraform. El propósito es demostrar infraestructura como código (IaC): la infraestructura se define en archivos HCL versionables en lugar de crearse manualmente desde Azure Portal.

> Estado: configuración lista para desplegar. Antes de ejecutar `terraform apply`, debe crearse un archivo local `terraform.tfvars` a partir de la plantilla y deben configurarse una clave SSH pública y la IP pública permitida.

## Objetivos

- Entender el flujo básico de Terraform: `init`, `plan`, `apply` y `destroy`.
- Desplegar una VM Linux Ubuntu y sus recursos de red de apoyo en Azure.
- Aplicar una regla de seguridad que permita SSH únicamente desde una IP pública autorizada.
- Mantener la infraestructura y su documentación en un repositorio GitHub.

## Conceptos de Terraform

Terraform es una herramienta de infraestructura como código. La configuración describe el estado final deseado y Terraform compara esa declaración con el estado actual para determinar qué debe crear, modificar o eliminar.

| Concepto | Aplicación en este proyecto |
| --- | --- |
| Provider | `azurerm` permite a Terraform comunicarse con Azure. |
| Resource | Cada bloque `resource` representa un elemento de Azure, por ejemplo una red o una VM. |
| Variable | Permite parametrizar nombres, región, tamaño de VM, clave SSH e IP autorizada. |
| Output | Muestra datos útiles tras el despliegue, como la IP pública y el comando SSH. |
| State | `terraform.tfstate` registra los recursos administrados. Es local y no se publica. |

### Ciclo de trabajo

```text
Archivos .tf → terraform init → terraform fmt / validate → terraform plan → terraform apply
                                                                           ↓
                                                               terraform destroy
```

- `terraform init`: inicializa el directorio y descarga el proveedor AzureRM.
- `terraform fmt`: aplica formato estándar a los archivos Terraform.
- `terraform validate`: verifica la validez sintáctica y estructural.
- `terraform plan`: genera una vista previa de los cambios sin modificar Azure.
- `terraform apply`: crea o actualiza la infraestructura declarada.
- `terraform destroy`: elimina los recursos que Terraform administra.

## Arquitectura

La configuración crea los siguientes recursos:

- Grupo de recursos de Azure.
- Red virtual (VNet) con el espacio `10.0.0.0/16`.
- Subred con el rango `10.0.1.0/24`.
- Dirección IP pública estática SKU Standard.
- Grupo de seguridad de red (NSG) con acceso SSH por TCP/22 solo desde la IP configurada.
- Interfaz de red (NIC) asociada a la IP pública y al NSG.
- Máquina virtual Ubuntu 24.04 LTS.

```text
Internet
   |
   | SSH TCP/22 solamente desde allowed_ssh_ip
   v
Dirección IP pública
   |
   v
NIC + NSG
   |
   v
Subred (10.0.1.0/24)
   |
   v
VNet (10.0.0.0/16)
   |
   v
VM Ubuntu 24.04 LTS
```

## Estructura

```text
.
├── .gitignore
├── README.md
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
└── variables.tf
```

Después de ejecutar `terraform init` también aparecerá `.terraform.lock.hcl`. Debe versionarse porque fija las dependencias del proveedor. No se debe subir el directorio `.terraform/`.

## Prerrequisitos

- Una suscripción activa de Azure, por ejemplo Azure for Students.
- Terraform instalado. Esta configuración acepta Terraform 1.5 o superior.
- Azure CLI instalada.
- Git instalado y una cuenta GitHub.
- Una llave SSH disponible en el equipo local.

Verifique Terraform y Azure CLI:

```bash
terraform --version
az version
```

Inicie sesión y seleccione la suscripción correcta:

```bash
az login
az account list --output table
az account set --subscription "Azure for Students"
az account show --output table
```

<img width="946" height="845" alt="image" src="https://github.com/user-attachments/assets/8a2afd08-01b5-48c3-af02-c8159c69fe6c" />
<img width="931" height="318" alt="image" src="https://github.com/user-attachments/assets/c7b254ce-e30e-4eb6-a05b-fc928c0d0d7e" />


## Configuración local

### 1. Crear una llave SSH

Si no tiene un par de claves SSH, créelo en Linux/Fedora:

```bash
ssh-keygen -t ed25519 -C "correo@ejemplo.com"
```

Muestre y copie la clave **pública**:

```bash
cat ~/.ssh/id_ed25519.pub
```

Nunca comparta ni suba al repositorio la clave privada `~/.ssh/id_ed25519`.

### 2. Consultar la IP pública

```bash
curl ifconfig.me
```

La regla de red usa el formato CIDR. Por ejemplo, para una IP `190.12.34.56`, el valor es `190.12.34.56/32`. El sufijo `/32` limita el acceso a una única IP.

### 3. Crear variables privadas

Copie la plantilla:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars` y reemplace los dos valores de ejemplo:

```hcl
ssh_public_key = "ssh-ed25519 AAAA... tu-clave-publica-real"
allowed_ssh_ip = "TU.IP.PUBLICA/32"
```

El archivo `terraform.tfvars` aparece en `.gitignore` y no se debe publicar.

## Despliegue

Desde la raíz del repositorio, ejecute los comandos en este orden.

### 1. Inicializar

```bash
terraform init
```

Terraform descargará el proveedor `hashicorp/azurerm` y creará el archivo de bloqueo `.terraform.lock.hcl`.

<img width="945" height="694" alt="image" src="https://github.com/user-attachments/assets/607e39a0-bfbd-438d-88b3-a9c8f50fd604" />


### 2. Formatear y validar

```bash
terraform fmt -recursive
terraform validate
```
<img width="962" height="114" alt="image" src="https://github.com/user-attachments/assets/ad0be770-816d-4957-abda-b309d5971740" />


La validación exitosa debe incluir un mensaje similar a:

```text
Success! The configuration is valid.
```

### 3. Revisar el plan

```bash
terraform plan -out=main.tfplan
```

Revise que el plan solo indique recursos esperados por crear. No continúe si aparecen destrucciones o cambios sobre recursos que no pertenecen a esta práctica.

### 4. Aplicar

```bash
terraform apply main.tfplan
```

Al finalizar, Terraform mostrará los outputs `resource_group_name`, `public_ip_address` y `ssh_command`.

### 5. Conectarse por SSH

Use el output generado o ejecute:

```bash
ssh azureuser@IP_PUBLICA_DE_LA_VM
```

Dentro de la VM, valide el sistema operativo:

```bash
hostnamectl
exit
```

## Seguridad

- La autenticación de la VM usa clave SSH, no contraseña.
- El puerto TCP 22 solo se permite desde `allowed_ssh_ip`; no use `0.0.0.0/0` para una entrega normal.
- `terraform.tfvars`, el estado de Terraform y las claves SSH están excluidos mediante `.gitignore`.
- Revise `git status` antes de cada commit para confirmar que no hay secretos.

## Evidencias 

**Creación de la VM
<img width="936" height="570" alt="image" src="https://github.com/user-attachments/assets/b34503a8-e38e-4f9d-9da8-462732bb07be" />

**Dentro de la VM

<img width="1916" height="920" alt="image" src="https://github.com/user-attachments/assets/832ff191-4e5a-4096-8d5a-73de6f8d1e4d" />


<img width="837" height="467" alt="image" src="https://github.com/user-attachments/assets/424610fc-dc5e-4d07-b823-5a8e89d59c6c" />


## Limpieza de recursos

Cuando ya tenga las evidencias requeridas, elimine la infraestructura para evitar consumo en la suscripción:

```bash
terraform destroy
```

Revise el plan de destrucción y escriba `yes` únicamente si los recursos corresponden a esta práctica.

## Solución de problemas

### Azure CLI no está autenticada

```bash
az login
az account show --output table
```

### La región o tamaño de VM no está disponible

Cambie `location` o `vm_size` en su archivo local `terraform.tfvars`. Algunas suscripciones académicas limitan regiones y tamaños disponibles.

### SSH no conecta

- Confirme que `allowed_ssh_ip` contiene su IP pública actual seguida de `/32`.
- Revise si cambió de red o activó una VPN; en ese caso, actualice la IP y ejecute `terraform apply`.
- Verifique que utiliza el usuario definido en `admin_username` y la clave privada correspondiente.
- Consulte la IP pública con `terraform output public_ip_address`.

### Terraform pide valores de variables

Compruebe que creó `terraform.tfvars` y que contiene `ssh_public_key` y `allowed_ssh_ip`.

## Autor

Juan José Arias Gallego  
Estudiante — Universidad ICESI
