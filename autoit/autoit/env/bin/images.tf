# IMAGES
variable "images" {
   type = "map"
   default = {
     "0" = "test1tmp",
     "1" = "Axxana-3.13.x-31"
     "2" = "Oracle_Linux_6.10-x86_64"
  }
}

variable "images-credentials" {
   type = "map"
   default = {
     "0" = "'root','root','axxana'",
     "1" = "'sudo','axxbox','axxbox'",
     "2" = "'root','root','axxana'",
  }
}
