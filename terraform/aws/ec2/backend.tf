terraform {
  backend "s3" {
    bucket  = "terraform-state-bucket-g1-2403"    # Nombre del bucket S3 donde se almacenará el estado
    key     = "ec2/statefile.tfstate"      # Ruta y nombre del archivo de estado dentro del bucket
    region  = "us-east-1"
    encrypt = true

    # La siguiente línea se utiliza para habilitar el bloqueo del estado usando una tabla DynamoDB.
    # El bloqueo evita que múltiples procesos modifiquen el estado simultáneamente.
    # Como no es un ambiente productivo se deshabilita el bloqueo comentando dicha linea.
    # dynamodb_table = "terraform-lock-table"
  }
}