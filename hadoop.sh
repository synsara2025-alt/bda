!/bin/bash

sudo apt update
sudo apt install -y ssh

JDK_TARBALL=~/Downloads/jdk-8u45-linux-x64.tar.gz
JDK_TARGET_DIR=$HOME/java

mkdir -p $JDK_TARGET_DIR
tar -xzf $JDK_TARBALL -C $JDK_TARGET_DIR
JAVA_HOME=$JDK_TARGET_DIR/jdk1.8.0_45


cat <<EOF >> ~/.bashrc

# Java and Hadoop Environment Variables
export JAVA_HOME=$JAVA_HOME
export HADOOP_HOME=\$HOME/hadoop-2.7.0
export PATH=\$PATH:\$JAVA_HOME/bin:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export YARN_HOME=\$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native
export HADOOP_OPTS="-Djava.library.path=\$HADOOP_HOME/lib/native"
export HADOOP_LOG_DIR=\$HADOOP_HOME/logs
export PDSH_RCMD_TYPE=ssh
EOF


tar -zxvf ~/Downloads/hadoop-2.7.0.tar.gz -C ~/
mv ~/hadoop-2.7.0 ~/

HADOOP_CONF=~/hadoop-2.7.0/etc/hadoop

sed -i "s|export JAVA_HOME=.*|export JAVA_HOME=$JAVA_HOME|" $HADOOP_CONF/hadoop-env.sh

cat <<EOF > $HADOOP_CONF/core-site.xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOF

cat <<EOF > $HADOOP_CONF/hdfs-site.xml
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
EOF

cp $HADOOP_CONF/mapred-site.xml.template $HADOOP_CONF/mapred-site.xml
cat <<EOF > $HADOOP_CONF/mapred-site.xml
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
</configuration>
EOF

cat <<EOF > $HADOOP_CONF/yarn-site.xml
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
</configuration>
EOF


ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
ssh -o StrictHostKeyChecking=no localhost echo "SSH connection success."

~/hadoop-2.7.0/bin/hdfs namenode -format

start-dfs.sh
start-yarn.sh

hadoop fs -mkdir /user
hadoop fs -mkdir /user/$USER
