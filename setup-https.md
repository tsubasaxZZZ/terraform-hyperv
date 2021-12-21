# HTTPS で構成するパターン

## 手順

1. サーバー上で `Enable-PSRemoting -SkipNetworkProfileCheck -Force` を実行
2. サーバー上で HTTPSの設定と証明書の生成
	- [WinRM allow HTTPS](https://github.com/taliesins/terraform-provider-hyperv#:~:text=ValueSet%20%40%7BNegotiate%20%3D%20%24true%7D-,WinRM%20allow%20HTTPS,-%23Create%20CA%20certificate) のコマンドをそのまま実行。
	- ここまでの設定で`terraform apply`をするとローカル上にデプロイできる。
3. (リモートから実行する場合)リモートクライアント上に 2. で生成した自己署名証明書をインポート
    - 自己署名証明書(<ホスト名>.pfx)をリモートクライアントにインポートすることでリモートからの実行が可能となる。
    - 2.のコマンドのまま実行した場合、証明書のパスワードは、`P@ssw0rd`。

## Terraform の設定例

```
provider "hyperv" {
  user            = var.user
  password        = var.password
  host            = var.host

  # for HTTPS
  port            = 5986
  https           = true <----------- https を true にする

  insecure        = false
  use_ntlm        = true
  script_path     = "C:/Temp/terraform_%RAND%.cmd"
  timeout         = "30s"
```
