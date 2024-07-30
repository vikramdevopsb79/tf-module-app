env = "dev"

vpc = {
  main = {
   cidr   = "10.0.0/16"
   availability_zones = ["us-east-1a", "us-east-1b"]
   subnets = {
     public = {
       cidr = ["10.0.0.0/24", "10.0.1.0/24"]
       igw  = true
     }

     web = {
       cidr = ["10.0.2.0/24", "10.0.3.0/24"]
       ngw  = true
     }

     app = {
       cidr = ["10.0.4.0/24", "10.0.5.0/24"]
       ngw  = true
     }

     db = {
       cidr = ["10.0.6.0/24", "10.0.7.0/24"]
       ngw  = true
     }
   }
  }
}
