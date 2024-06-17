resource "aws_security_group" "allow_tls" {
  name        = "${var.name}-${var.env}"
  description =  "Description - ${var.name}-${var.env}"

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    description = "SSH Port"
  }
  #Application port
  ingress {
    from_port        = var.port_no
    to_port          = var.port_no
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    description = "App Port"
  }

  #prometheus port
  ingress {
    from_port        = 9100
    to_port          = 9100
    protocol         = "tcp"
    cidr_blocks      = var.prometheus_servers
    description = "Prometheus Port"
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
  vpc_security_group_ids = [aws_security_group.allow_tls.id]

  tags = {
    Name = "${var.name}-${var.env}"
    Monitor = "yes"
    env       = var.env
    component = var.name
  }

  # this to not re-create machines on tf-apply again and again. This will not be needed later when we go with ASG
  lifecycle {
    ignore_changes = [
      "ami"
    ]
  }

}
resource "aws_route53_record" "record" {
 zone_id  = var.zone_id
  name    = "${var.name}-${var.env}.vikramdevops.tech"
  type    = "A"
  ttl     = 30
  records = [aws_instance.node.private_ip]
}
#this resource is useful to open  nginx exporter port only for frontend
resource "aws_security_group_rule" "nginx-exporter-port" {
  count             = var.name == "Frontend" ? 1 : 0
  from_port         = 9113
  protocol          = "tcp"
  security_group_id = aws_security_group.allow_tls.id
  to_port           = 9113
  type              = "ingress"
  cidr_blocks       = var.prometheus_servers
}
resource "null_resource" "provisioner"{
  depends_on = [aws_route53_record.record]
  #null resource don't know new server is created for we trigger null resource for every new instance
  triggers = {
    instance_id = aws_instance.node.id
  }
  connection {
    host        = aws_instance.node.private_ip
    user        = "ec2-user"
    password    = var.SSH_PASSWORD
    type        = "ssh"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo pip3.11 install hvac",
      "ansible-pull -i localhost, -U https://github.com/vikramdevopsb79/expense-ansible -e role_name=${var.name} -e env=${var.env} -e vault_token=${var.vault_token}  expense.yml"
    ]
  }
}


