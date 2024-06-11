

resource "aws_security_group" "allow_tls" {
  name        = "${var.name}-${var.env}"
  description =  "Description - ${var.name}-${var.env}"

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  #Application port
  ingress {
    from_port        = var.port_no
    to_port          = var.port_no
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
resource "aws_instance" "node" {
  ami           = data.aws_ami.ami.id
  instance_type = var.instance_type
  vpc_security_group_ids = [data.aws_security_group.allow-all.id]

  tags = {
    name = "${var.name}-${var.env}"
  }

}
resource "aws_route53_record" "record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.name}-${var.env}.vikramdevops.tech"
  type    = "A"
  ttl     = 30
  records = [aws_instance.node.private_ip]
}
resource "null_resource" "provisioner"{
  depends_on = [aws_route53_record.record]
  provisioner "local-exec" {
    command = "sleep 120; cd /home/ec2-user/expense-ansible ; ansible-playbook -i ${aws_instance.node.private_ip}, -e ansible_user=ec2-user -e ansible_password=DevOps321 -e role_name=${var.name}-${var.env} -e env=dev expense.yml"
  }

}