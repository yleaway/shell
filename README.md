 一些脚本

 certbot自动申请证书脚本,每隔60天续签,会自动停止和重启nginx,支持standalone和cloudflare dns模式

 convert将img.gz或者img格式的固件转换成适合LXC容器的tar.gz格式,支持远程下载原始固件和本地固件,转换成功后回车存放到PVE的CT模板默认路径或者手动输入指定路径,完成后按y保留img格式原始固件,按其他则删除原始固件
 <font color="red"> PS 会生成一个/root/tmp.XXXXXXXXXX的临时目录用作挂载点,并在完成后删除该目录 </font>
