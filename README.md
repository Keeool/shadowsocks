使用方法
	1.	下载脚本并安装：

bash <(wget -qO- https://raw.githubusercontent.com/Keeool/shadowsocks/main/shadowsocks/ss_manage.sh) install
解释：
	•	wget -qO- URL → 下载脚本内容并输出到 stdout
	•	<(...) → Bash 的进程替换，把下载内容当作脚本执行
	•	install → 传给脚本的参数，表示安装 Shadowsocks

	2.	卸载：

bash <(wget -qO- https://raw.githubusercontent.com/Keeool/shadowsocks/main/shadowsocks/ss_manage.sh) uninstall
