ssh_public = {
  type        = "ssh-rsa"
  key         = "AAAAB3NzaC1yc2EAAAADAQABAAACAQCY+X4Jwa3i+wVW+juThfArJMDOKK3PR1cbnDBZzddBH43wigrWG2qGnD/AXX7WmZUbeZxDHAj1nHzoxYwne4/04VkE5GSWBcpIDk1fXeE0i4r9gpvCAky2mpGmXCYEviQq4V16J8VOGSMliYjVh7ukwFqSxRmitgNEvXTQ+lpy8+FGDe5edsuMOI8bS5PRxzbaP8BJnS5rjPb8X3AOVuk6Q8IGRD5/uvv8bWVEK+xeH1rmkpU7DW7iQtYo93q4FwSXf+SDnLgTCH2lhOs79GYqGReoNE8DyzMSHpzlWCIlZ2snwRsPmIKCD+N0SkAfUe1KEZ9k/QNpjcPalwiJoGIKZBMXpR4WVY8ojB5bXurRghkxn6v8i3A0hcymvn/YyOLfE1INbMSCU5anVFbs9A/gyhRDhm8La/dWe7f+1aTQgjCd5WYwNfJi0qDnHNGa0PQnvKh5zZd7l32V53knJsf9sALeP8zXFr7iPFNVkJWoYQWYokltoQ0SatIZ9rGL7iZJF6aENCuWYTuHwl2qKrByd1/xNq0kRLDDXMaDDe7aQyKPNwL7RNVrYbbcwyptF1LpMMB2m8SJofGwtYk70Au2BF372COagYUGa1xUV1OQybk3UV6BXob1HIhuwfvdRy3eGkoLv2cSUslhsHkLdEFcY3KoGpargIjRITJna87+Xw=="
  host_origin = "kharma@www.contadoressa.local"
}

storage_pool = "default"

# Conexão local
#libvirt_uri = "qemu:///system"
#image_directory = "/home/mdonato/vm"

# Conexão remota
libvirt_uri     = "qemu+ssh://kharma@192.168.1.15/system"
image_directory = "/home/kharma/vm"
