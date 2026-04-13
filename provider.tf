terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
  }
}

provider "oci" {
  region           = "me-riyadh-1"
  tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaaoancm5qghz7lljg33uyicmeothnzfm65oskc4k3oxo4d5xclvbiq"
  user_ocid        = "ocid1.user.oc1..aaaaaaaay6yfmpjslsnrhndwxnoieqiks2gxqzctfnfuqv5oho27i7a24ytq"
  fingerprint      = "0e:17:6c:cb:91:10:9d:d8:21:7d:32:81:c6:13:2b:98"
  private_key_path = "D:\\terraform-intro\\Example_02\\oci_api_key.pem"
}