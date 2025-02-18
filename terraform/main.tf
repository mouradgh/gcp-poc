terraform { 
  cloud { 
    
    organization = "data-engineer" 

    workspaces { 
      name = "gcp-poc" 
    } 
  } 
}