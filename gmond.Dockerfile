FROM centos:6.6

RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo


RUN yum install -y tar wget freetype-devel rpm-build php httpd libpng-devel libart_lgpl-devel python-devel pcre-devel autoconf automake libtool expat-devel rrdtool-devel glibc apr-devel gcc-c++ make glibc vim telnet lsof rsync


RUN mkdir -p /opt/ganglia &&\
	wget https://dl.fedoraproject.org/pub/epel/6/x86_64/libconfuse-2.7-4.el6.x86_64.rpm -P /opt/ganglia &&\
	wget https://dl.fedoraproject.org/pub/epel/6/x86_64/libconfuse-devel-2.7-4.el6.x86_64.rpm -P /opt/ganglia &&\
	touch /var/lib/rpm/* &&\
	yum install -y /opt/ganglia/*.rpm


RUN curl -o /opt/ganglia/ganglia-3.7.2.tar.gz https://cytranet.dl.sourceforge.net/project/ganglia/ganglia%20monitoring%20core/3.7.2/ganglia-3.7.2.tar.gz &&\
	rpmbuild -tb /opt/ganglia/ganglia-3.7.2.tar.gz &&\
	touch /var/lib/rpm/* &&\
	yum install -y /root/rpmbuild/RPMS/x86_64/*.rpm


RUN sed -i 's%owner = "unspecified"%owner = "DSS"%g' /etc/ganglia/gmond.conf &&\
	sed -i '50c  host = gmetad' /etc/ganglia/gmond.conf &&\
	sed -i '57d' /etc/ganglia/gmond.conf &&\
	sed -i 's%bind = 239.2.11.71%bind = 0.0.0.0%g' /etc/ganglia/gmond.conf &&\
	sed -i 's%user = nobody%user = root%g' /etc/ganglia/gmond.conf &&\
	sed -i '73,$d' /etc/ganglia/gmond.conf

	
RUN echo "sed -i 's/location = \"unspecified\"/location = \"'"\$LOCATION"'\"/g' /etc/ganglia/gmond.conf" > /opt/ganglia/start_gmond.sh &&\
    echo "sed -i 's/name = \"unspecified\"/name = \"'"\$CLUSTER_NAME"'\"/g' /etc/ganglia/gmond.conf" >> /opt/ganglia/start_gmond.sh &&\
	echo "service gmond restart" >> /opt/ganglia/start_gmond.sh &&\
	#echo "sleep 100000d" >> /opt/ganglia/start_gmond.sh &&\
	echo "i=0" >> /opt/ganglia/start_gmond.sh &&\
	echo "while [[ \$i -le 10000000 ]]" >> /opt/ganglia/start_gmond.sh &&\
	echo "do" >> /opt/ganglia/start_gmond.sh &&\
	echo "  for j in \`seq 1 30\`" >> /opt/ganglia/start_gmond.sh &&\
	echo "  do" >> /opt/ganglia/start_gmond.sh &&\
	echo "    gmetric -n test_metric\$j -t int8 -g test_group -C "\$CLUSTER_NAME" -T 'Test Metric '\$j -v \`shuf -i 5-10 -n 1\` -d 60" >> /opt/ganglia/start_gmond.sh &&\
	echo "  done" >> /opt/ganglia/start_gmond.sh &&\
	echo "  sleep 10s" >> /opt/ganglia/start_gmond.sh &&\
	echo "done" >> /opt/ganglia/start_gmond.sh &&\
	chmod a+x /opt/ganglia/start_gmond.sh

WORKDIR /opt/ganglia

CMD ["sh", "/opt/ganglia/start_gmond.sh"]