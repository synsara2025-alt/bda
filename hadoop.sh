#!/bin/bash

# Color variables
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

print_section() {
    echo -e "\n${BOLD}${CYAN}========== $1 ==========${RESET}"
}

print_info() {
    echo -e "${YELLOW}🔧 $1${RESET}"
}

print_success() {
    echo -e "${GREEN}✅ $1${RESET}"
}

print_error() {
    echo -e "${RED}❌ $1${RESET}"
}

echo -e "${BOLD}${CYAN}
--------------------------------------------
     Hadoop 2.7.0 Automated Setup Script
   (With Local JDK 8u45 Installation)
--------------------------------------------
${RESET}"

# Step 1: Install SSH
print_section "Step 1: Installing SSH (required for Hadoop)"
sudo apt update
sudo apt install -y ssh
print_success "SSH installed."

# Step 2: Install JDK from local tarball
print_section "Step 2: Installing JDK 8u45 from local tarball"
JDK_TARBALL=~/Downloads/jdk-8u45-linux-x64.tar.gz
JDK_TARGET_DIR=$HOME/java

mkdir -p $JDK_TARGET_DIR
tar -xzf $JDK_TARBALL -C $JDK_TARGET_DIR
JAVA_HOME=$JDK_TARGET_DIR/jdk1.8.0_45
print_success "JDK extracted to $JAVA_HOME"

# Step 3: Set up environment variables
print_section "Step 3: Setting Up Environment Variables"
print_info "Appending Hadoop and Java environment variables to ~/.bashrc..."

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

print_success "Environment variables added to ~/.bashrc"
print_info "Please run: ${BOLD}source ~/.bashrc${RESET} before continuing."

# Step 4: Extract Hadoop
print_section "Step 4: Extracting Hadoop"
print_info "Extracting Hadoop 2.7.0 from ~/Downloads..."
tar -zxvf ~/Downloads/hadoop-2.7.0.tar.gz -C ~/
mv ~/hadoop-2.7.0 ~/
print_success "Hadoop extracted."

# Step 5: Configure Hadoop
print_section "Step 5: Configuring Hadoop Environment"
HADOOP_CONF=~/hadoop-2.7.0/etc/hadoop

print_info "Setting JAVA_HOME in hadoop-env.sh..."
sed -i "s|export JAVA_HOME=.*|export JAVA_HOME=$JAVA_HOME|" $HADOOP_CONF/hadoop-env.sh

print_info "Configuring core-site.xml..."
cat <<EOF > $HADOOP_CONF/core-site.xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOF

print_info "Configuring hdfs-site.xml..."
cat <<EOF > $HADOOP_CONF/hdfs-site.xml
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
EOF

print_info "Configuring mapred-site.xml..."
cp $HADOOP_CONF/mapred-site.xml.template $HADOOP_CONF/mapred-site.xml
cat <<EOF > $HADOOP_CONF/mapred-site.xml
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
</configuration>
EOF

print_info "Configuring yarn-site.xml..."
cat <<EOF > $HADOOP_CONF/yarn-site.xml
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
</configuration>
EOF

print_success "Hadoop configuration files set."

# Step 6: SSH Setup
print_section "Step 6: Configuring SSH"
print_info "Generating SSH key and setting up local access..."
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
ssh -o StrictHostKeyChecking=no localhost echo "SSH connection success."
print_success "SSH setup complete."

# Step 7: Format HDFS
print_section "Step 7: Formatting HDFS"
~/hadoop-2.7.0/bin/hdfs namenode -format
print_success "HDFS formatted."

# Step 8: Start Hadoop
print_section "Step 8: Starting Hadoop Services"
print_info "Starting HDFS and YARN..."
start-dfs.sh
start-yarn.sh
print_success "Hadoop services started."

print_info "Creating user directory in HDFS..."
hadoop fs -mkdir /user
hadoop fs -mkdir /user/$USER

# Final Message
echo -e "\n${BOLD}${GREEN}🎉 Hadoop setup complete using local JDK!${RESET}"
echo -e "${CYAN}🌐 Access NameNode UI at: http://localhost:50070${RESET}"
echo -e "${YELLOW}⚠️  If you haven't yet, run: ${BOLD}source ~/.bashrc${RESET}${YELLOW} to activate environment variables.${RESET}"
echo -e "${YELLOW}🔁 You may need to rerun this script to activate Hadoop services correctly after sourcing.${RESET}"
