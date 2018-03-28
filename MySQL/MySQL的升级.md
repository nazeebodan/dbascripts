MySQL版本的升级方法:
其实很简单，步骤如下：
1.安全的把老库停下来
2.安装一个新的版本在新目录下
3.unlink mysql
4.link 新的源到
ln -s xxx MySQL
5.启动mysql
6.mysql_upgrade -s
记得-s 的选项哦!
