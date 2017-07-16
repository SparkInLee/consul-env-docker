### 一. 构建Consul学习环境
使用docker基于[Offical Consul](https://github.com/hashicorp/docker-consul/)搭建一个由三个server节点以及1个client节点组成的consul环境。

### 二. 使用
**1. 启动consul环境**

```
# 启动consul
docker-compose up -d
```
**2. 使用consul**  
client默认给予了`managerment`权限，因此启动完成之后，就可以宿主机上执行所有consul操作：

```
# 查看节点信息
➜  consul git:(master) consul members -detailed
Node      Address             Status  Tags
client-1  192.168.1.104:8301  alive   build=0.8.5:2c77151,dc=dc1,id=8f41f83a-6359-37cb-43e5-33fc7f129a4b,role=node,vsn=2,vsn_max=3,vsn_min=2
server-1  192.168.1.101:8301  alive   build=0.8.5:2c77151,dc=dc1,expect=3,id=f67bd812-a301-b4bf-8e4e-bb66abe9abe2,port=8300,raft_vsn=2,role=consul,vsn=2,vsn_max=3,vsn_min=2,wan_join_port=8302
server-2  192.168.1.102:8301  alive   build=0.8.5:2c77151,dc=dc1,id=b977ae97-a8de-c879-0567-239360c4d0be,port=8300,raft_vsn=2,role=consul,vsn=2,vsn_max=3,vsn_min=2,wan_join_port=8302
server-3  192.168.1.103:8301  alive   build=0.8.5:2c77151,dc=dc1,id=4909f124-b6ea-1ab8-7863-5482f6a59a4b,port=8300,raft_vsn=2,role=consul,vsn=2,vsn_max=3,vsn_min=2,wan_join_port=8302

# 存储kv
➜  consul git:(master) consul kv put lee 1
Success! Data written to: lee

# 获取kv
➜  consul git:(master) consul kv get lee
1
```
**3. 校验consul环境**  
可以尝试关停一个server节点以查看consul是否能继续健康运行：

```
# 当前leader节点
➜  consul git:(master) curl localhost:8500/v1/status/leader
"192.168.1.101:8300"                                                                                                                                                                             ➜  consul git:(master) curl localhost:8500/v1/status/peers
["192.168.1.101:8300","192.168.1.102:8300","192.168.1.103:8300"]

# 关停当前leader节点                                                                                                                                 ➜  consul git:(master) docker-compose stop consul-server-1
Stopping consul-server-1 ... done

# server-3竞选为leader节点
➜  consul git:(master) curl localhost:8500/v1/status/leader
"192.168.1.103:8300"

# 信息显示server-1已经处于failed状态                                                                                                                             ➜  consul git:(master) consul members -detailed
Node      Address             Status  Tags
client-1  192.168.1.104:8301  alive   build=0.8.5:2c77151,dc=dc1,id=8f41f83a-6359-37cb-43e5-33fc7f129a4b,role=node,vsn=2,vsn_max=3,vsn_min=2
server-1  192.168.1.101:8301  failed  build=0.8.5:2c77151,dc=dc1,expect=3,id=f67bd812-a301-b4bf-8e4e-bb66abe9abe2,port=8300,raft_vsn=2,role=consul,vsn=2,vsn_max=3,vsn_min=2,wan_join_port=8302
server-2  192.168.1.102:8301  alive   build=0.8.5:2c77151,dc=dc1,id=b977ae97-a8de-c879-0567-239360c4d0be,port=8300,raft_vsn=2,role=consul,vsn=2,vsn_max=3,vsn_min=2,wan_join_port=8302
server-3  192.168.1.103:8301  alive   build=0.8.5:2c77151,dc=dc1,id=4909f124-b6ea-1ab8-7863-5482f6a59a4b,port=8300,raft_vsn=2,role=consul,vsn=2,vsn_max=3,vsn_min=2,wan_join_port=8302
```
**4. 使用UI界面**

```
浏览器打开：localhost:8500/ui
```
### 3. 配置
**1. 添加server节点**  
1) 在`docker-compose.xml`中添加新的server服务，参考：

```
  consul-server-{server-id}:
    container_name: consul-server-{server-id}
    image: consul:0.8.5
    command: consul agent -config-dir=/consul/config
    volumes:
      - ./conf/server-{server-id}:/consul/config
      - ./data/server-{server-id}:/consul/data
      - ./script:/consul/script
    networks:
      app_net:
        ipv4_address: 192.168.1.{server-ip}
```  
&nbsp;&nbsp;&nbsp;&nbsp;其中，server-id及server-ip根据个人喜好指定。  
2) 在`conf`目录创建`server-{server-id}`的目录，并添加配置文件`server.json`，参考：

```
{
	"datacenter":"dc1",
	"data_dir":"/consul/data",
	"log_level":"INFO",
	"node_name":"server-{server-id}",
	"server":true,
	"ui":false,
	"encrypt":"2zCAu5bA5exHi3I/S5u+8g==",
	"client_addr":"192.168.1.{server-ip}",
	"retry_join":[
		"192.168.1.101"
	],
	"acl_datacenter":"dc1",
	"acl_default_policy":"deny",
	"acl_down_policy":"extend-cache",
	"acl_master_token":"consul-bootstrap-default",
	"acl_agent_token":"consul-bootstrap-default"
}
```
3）在`data`目录创建`server-{server-id}`的目录，用于存放新增server的数据。  
4）运行该docker服务`docker-compose start consul-server-{server-id}`

**2. 更换client的acl配置**  
1）通过acl接口添加新acl;  
2）配置新acl的ID至`conf/client-1/server.json`;  
3）重启docker服务：`docker-compose stop consul-client-1 && docker-compose start consul-client-1`
