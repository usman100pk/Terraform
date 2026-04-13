# --- 1. Network Setup (VCN A and VCN B) ---
resource "oci_core_vcn" "vcn_a" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "VCN-A"
  dns_label      = "vcna"
}

resource "oci_core_vcn" "vcn_b" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.1.0.0/16"]
  display_name   = "VCN-B"
  dns_label      = "vcnb"
}
#============================================
# --- 2. DRG Setup (Connecting the two VCNs) ---
resource "oci_core_drg" "drg" {
  compartment_id = var.compartment_ocid
  display_name   = "My-DRG"
}

resource "oci_core_drg_attachment" "attach_a" {
  drg_id = oci_core_drg.drg.id
  network_details {
    id   = oci_core_vcn.vcn_a.id
    type = "VCN"
  }
}

resource "oci_core_drg_attachment" "attach_b" {
  drg_id = oci_core_drg.drg.id
  network_details {
    id   = oci_core_vcn.vcn_b.id
    type = "VCN"
  }
}

# --- 3. Gateways & Subnets ---
resource "oci_core_internet_gateway" "ig_a" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn_a.id
  display_name   = "IG-A"
}

resource "oci_core_subnet" "subnet_a" {
  cidr_block     = "10.0.1.0/24"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn_a.id
  display_name   = "Subnet-A"
  dns_label      = "subneta"
}

resource "oci_core_subnet" "subnet_b" {
  cidr_block     = "10.1.1.0/24"
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn_b.id
  display_name   = "Subnet-B"
  dns_label      = "subnetb"
}

# --- 4. Compute Instances ---
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

data "oci_core_images" "ol8" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.instance_shape
}

resource "oci_core_instance" "vm_a" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  shape               = var.instance_shape
  display_name        = "VM-A"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 6
  }

#==================================================
# We are creating Public and Private IPs for VM-A
#==================================================
  create_vnic_details {
    subnet_id        = oci_core_subnet.subnet_a.id
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ol8.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }
}

resource "oci_core_instance" "vm_b" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = var.compartment_ocid
  shape               = var.instance_shape
  display_name        = "VM-B"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 6
  }

#===========================================
# We are creating onlyPrivate IPs for VM-B
#===========================================
  create_vnic_details {
    subnet_id        = oci_core_subnet.subnet_b.id
    assign_public_ip = false
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ol8.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
  }
}

# --- 5. Load Balancer Setup ---
resource "oci_load_balancer_load_balancer" "lb" {
  compartment_id = var.compartment_ocid
  display_name   = "my-public-lb"
  shape          = "flexible"
  subnet_ids     = [oci_core_subnet.subnet_a.id]

  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 10
  }
}

resource "oci_load_balancer_backend_set" "lb_bes" {
  load_balancer_id = oci_load_balancer_load_balancer.lb.id
  name             = "my-backend-set"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol = "HTTP"
    port     = 80
    url_path = "/"
  }
}

resource "oci_load_balancer_backend" "be_a" {
  load_balancer_id = oci_load_balancer_load_balancer.lb.id
  backendset_name  = oci_load_balancer_backend_set.lb_bes.name
  ip_address       = oci_core_instance.vm_a.private_ip
  port             = 80
}

resource "oci_load_balancer_backend" "be_b" {
  load_balancer_id = oci_load_balancer_load_balancer.lb.id
  backendset_name  = oci_load_balancer_backend_set.lb_bes.name
  ip_address       = oci_core_instance.vm_b.private_ip
  port             = 80
}

resource "oci_load_balancer_listener" "lb_listener" {
  load_balancer_id         = oci_load_balancer_load_balancer.lb.id
  name                     = "http-listener"
  default_backend_set_name = oci_load_balancer_backend_set.lb_bes.name
  port                     = 80
  protocol                 = "HTTP"
}

# --- 6. Outputs ---
output "lb_public_ip" {
  value = oci_load_balancer_load_balancer.lb.ip_address_details
}