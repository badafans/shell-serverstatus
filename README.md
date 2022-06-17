# shell-serverstatus

一款纯 shell 实现简易的 linux 设备状态监测

可部署http服务,通过浏览器html可视化展示,看着舒服！

重复造轮子、简易、自用！

## 使用申明

个人作品，无版权。欢迎改造！

## Linux

目前已经测试 OpenWrt、Ubuntu、Debian、CentOS、Raspbian、Armbian、Porteus等Linux发行版

服务端推荐简易的http文件服务 https://github.com/search?l=Go&q=http+file+server 自行查找合适的

详细使用信息自行参考脚本注释

发现明显bug提交issue

``` bash
curl https://raw.githubusercontent.com/badafans/shell-serverstatus/main/status.sh -o status.sh && chmod +x status.sh && ./status.sh
```

## 演示链接

https://dash.baipiao.eu.org