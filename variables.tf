#引数の型定義
variable "alert_email" {
  type        = string
  description = "自身のメールアドレス"
}
variable "my_cidr" {
  type        = string
  description = "アクセスを許可するIPを定義する"
}
# variable "full_cidr" {
#   type        = string
#   description = "すべてのIPを許可する"
# }
variable "key_name" {
  type        = string
  description = "EC2インスタンスに登録するSSHキーペア名"
}

variable "ec2_subnet" {
  type        = string
  description = "EC2インスタンスを置いているパブリックサブネット"
}
