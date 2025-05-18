#!/bin/bash

# ==================== 脚本说明 ====================
# 功能：自动化安装Rust、Solana工具链，创建Solana钱包并部署bitz应用
# 适用：Linux/Unix系统
# 注意：需要sudo权限安装部分依赖
# ====================================================

# 1️⃣ 输入密码变量
# 安全地读取用户输入的密码，-s参数确保输入不显示在屏幕上
read -s -p "请输入你的 Solana 钱包密码（用于生成 keypair）: " password
echo "" # 输出空行，提高可读性

# 2️⃣ 安装 Rust
# 使用官方安装脚本安装Rust编程语言，-y参数表示自动确认所有提示
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# 加载Rust环境变量，使rust命令可用于当前会话
source $HOME/.cargo/env

# 3️⃣ 安装 Solana
# 下载并安装Solana命令行工具
curl --proto '=https' --tlsv1.2 -sSfL https://solana-install.solana.workers.dev | bash
# 将Solana二进制文件路径添加到PATH环境变量
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# 4️⃣ 安装 expect（如未安装）
# expect是一个自动化交互式应用程序的工具，用于自动输入密码
if ! command -v expect &>/dev/null; then
  echo "🔧 未检测到 expect，正在安装..."
  sudo apt update && sudo apt install -y expect
else
  echo "✅ expect 已安装"
fi

# 5️⃣ 自动输入密码生成 keypair
# 创建Solana配置目录
mkdir -p "$HOME/.config/solana"

# 使用expect脚本自动处理交互式密码输入
# EOF是here document的结束标记
expect <<EOF
# 启动solana-keygen命令生成新密钥对，--force参数会覆盖已存在的密钥
spawn solana-keygen new --force
# 等待密码提示并发送之前保存的密码
expect "Enter same passphrase again:"
send "$password\r"
# 再次确认密码
expect "Enter same passphrase again:"
send "$password\r"
# 等待命令执行完成
expect eof
EOF

# 6️⃣ 输出私钥内容
echo ""
echo "✅ 你的 Solana 私钥已生成如下，请复制导入 Backpack 钱包："
echo ""
# 显示生成的密钥文件内容
cat $HOME/.config/solana/id.json
echo ""
echo "⚠️ 这是一组数组形式的私钥，请妥善保存并导入 bp 钱包"

# 7️⃣ 提示是否继续（默认 y）
# 询问用户是否已准备好继续后续操作
read -p "是否已向该钱包的 Eclipse 网络转入 0.005 ETH？[Y/n]: " confirm
# 如果用户直接按回车，默认值为y
confirm=${confirm:-y}

# 根据用户输入决定是否继续执行
if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
  echo "🚀 开始安装并部署 bitz..."

  # 安装 bitz
  # 使用Cargo（Rust的包管理器）安装bitz应用
  cargo install bitz

  # 设置 RPC
  # 配置Solana连接到Eclipse网络的RPC节点
  solana config set --url https://mainnetbeta-rpc.eclipse.xyz/

  # 直接运行 bitz collect（前台模式）
  echo ""
  echo "🚀 正在运行 bitz collect..."
  echo "📌 如果需要后台运行，可按 Ctrl+C 后用 pm2/screen/tmux 等工具手动处理"
  echo ""

  # 启动bitz应用的collect功能
  bitz collect

else
  # 用户选择不继续时的提示
  echo "❌ 已取消后续操作，退出。"
fi