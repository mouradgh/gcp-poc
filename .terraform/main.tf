terraform { 
  cloud { 
    
    organization = "data-engineer" 

    workspaces { 
      name = "gcp-poc" 
    } 
  } 
}

provider "google" {
  credentials = var.gcp-creds
  project     = var.project
  region      = var.region
}