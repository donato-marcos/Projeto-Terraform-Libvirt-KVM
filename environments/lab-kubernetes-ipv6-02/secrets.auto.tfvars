ssh_public = {
  type        = "ssh-rsa"
  key         = "AAAAB3NzaC1yc2EAAAADAQABAAABAQDhRcBsR4KZ9f8fq1Jtpkhg4j0dzCYpRFXGk2L59BYrp6cHt/cz7WE+NRpF5PwP0dvMK/Ai8Ab3jE5F4Gm6gmwvsQhQg8B7HXRu5f+TdOnnhdHhlriZlYvCcUS9C+Ys61gU7/WWiEpIrp4vFTo4zOKkraMKaIEABKXn0IbTXj0NP64xM3ArOj8G0Cy+XTHJtMR9HRyLRcvVQtgwPvyigNwyit9Tu2hYzqPDz3vSvX9mILaFh8IuWGxVa0+GdtfKOSMqnY4WymPHjl7pwkaBbpwC6zHMEVycP7WBmQbkD34NBbzGrK2n/NbM3CvMJ2YqhQ0iOt1pr/sgAIGzg0A+TvQ5"
  host_origin = "mdonato@aesthar"
}

storage_pool = "default"

# Conexão local
#libvirt_uri = "qemu:///system"
#image_directory = "/home/mdonato/vm"

# Conexão remota
libvirt_uri     = "qemu+ssh://kharma@192.168.0.16/system?keyfile=/home/mdonato/.ssh/id_rsa"
image_directory = "/home/kharma/vm"
