variable "compartment_ocid" {
  description = "The OCID of your OCI compartment"
  type        = string
  default     = "ocid1.compartment.oc1..aaaaaaaatehscw46d6bzthvqc2qbqo4lj6abbi3hxrnujpobutxhx5nz3lxa"
}

# THIS IS THE PART I MISSED BEFORE:
variable "ssh_public_key_path" {
  description = "The path to your public SSH key on your local PC"
  type        = string
  default     = "./id_rsa.pub" 
}

variable "instance_shape" {
  description = "Shape for the ARM instances"
  type        = string
  default     = "VM.Standard.A1.Flex"
}