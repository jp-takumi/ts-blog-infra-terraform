# ステップ1：環境の初期化
# terraform init

# ステップ2：実行計画の確認（シミュレーション）
# terraform plan
# terraform plan -out=my_plan
# terraform show -json my_plan | jq . > my_output.json

# ステップ3：本番反映（適用）
# terraform apply

# ステップ4：生成したリソースの削除
# terraform destroy

# ==========================================
# 1. 前提設定（グローバル）
# ==========================================
# 最初に「どこのクラウドの、どのリージョンか」を明確にする
provider "aws" {
  region = "ap-northeast-1"
}

# ==========================================
# 2. ネットワークインフラ（土台・外枠）
# ==========================================
# 地盤となるVPCや、外部との境界線をまず定義

# 1 VPCの定義
resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-ts-blog-vpc"
  }
}

# 2 IGWの定義
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-igw"
  }
}

# パブリックサブネットの作成
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true # 起動したインスタンスに自動でパブリックIPを付与するか（true / false)
  tags = {
    Name = "public-subnet"
  }
}

# ルートテーブル
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my-rt"
  }
}

# ルート
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

# サブネットとルートテーブルの関連付け
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ルートテーブルの作成
# ==========================================
# 3. セキュリティ・権限（ガードレール）
# ==========================================
# サーバーを置く前に、通す箱（ファイアウォール）や鍵を定義

resource "aws_security_group" "web_sg" {
  name        = "my-ts-blog-ts"
  description = "Allow SSH from my IP and HTTP from world"
  vpc_id      = aws_vpc.my_vpc.id

  # インバウンド制御:SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_cidr]
  }
  # インバウンド制御:HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # アウトバウンド
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-web-sg"
  }
}

# ==========================================
# 4. コンピューティング・ストレージ（実体）
# ==========================================
# 最後に、ネットワークとセキュリティの中に「中身」を配置

# ==========================================
# 5. その他・運用系（周辺リソース）
# ==========================================
# 予算管理やアラートなど、独立した運用設定
