## 被测试AP配置要求

- 2.4G: trex-1810-0
- 5.8G: trex-1810-1
- key: ken@1810
- encryption: psk2

## FAQ

-  dhcp 获取失败?
    1) 查看 ```cat /var/lib/kea/kea-lease4.csv ``` 是否有分配记录, 有则ping对应的sta看看是否通?
    2) 1)不通过, 检查sta与ap的链路; 
    3) 如果WiFi链路正常, 执行: ```tcpdump -i eno1 -nne 执行 ``` 查看网口是否有来自 sta 的 dhcp 请求; 
    4) 1-3)均正常, 需要重置dhcp服务器, 执行 ```reset.sh```, 并重启 sta 或者 ap;

## 