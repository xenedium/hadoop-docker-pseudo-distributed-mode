FROM debian:bullseye

# Install dependencies
RUN apt update && apt install -y \
    build-essential \
    openjdk-11-jdk \
    wget \
    openssh-server \
    openssh-client \
    supervisor

# set up ssh
RUN ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
    chmod 0600 ~/.ssh/authorized_keys && \
    echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config


# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

RUN mkdir -p /var/run/sshd && \
    mkdir -p /var/log/supervisor

# Download and extract hadoop
RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.4/hadoop-3.3.4.tar.gz && \
    tar -xzf hadoop-3.3.4.tar.gz && \
    mv hadoop-3.3.4 /usr/local/hadoop && \
    rm hadoop-3.3.4.tar.gz

# Configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY core-site.xml /usr/local/hadoop/etc/hadoop/core-site.xml
COPY hdfs-site.xml /usr/local/hadoop/etc/hadoop/hdfs-site.xml
RUN sed -i "s|# export JAVA_HOME=|export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64|g" /usr/local/hadoop/etc/hadoop/hadoop-env.sh

# Format namenode
RUN /usr/local/hadoop/bin/hdfs namenode -format

# env variables
ENV HDFS_NAMENODE_USER=root
ENV HDFS_DATANODE_USER=root
ENV HDFS_SECONDARYNAMENODE_USER=root
ENV YARN_RESOURCEMANAGER_USER=root
ENV YARN_NODEMANAGER_USER=root

# Expose ports
EXPOSE 50070 9000 9870

# Start hadoop
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]