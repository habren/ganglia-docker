FROM centos:6.6

RUN curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo


RUN yum install -y rsync tar wget freetype-devel rpm-build php httpd libpng-devel libart_lgpl-devel python-devel pcre-devel autoconf automake libtool expat-devel rrdtool-devel glibc apr-devel gcc-c++ make glibc vim telnet lsof


RUN mkdir -p /opt/ganglia &&\
	wget https://dl.fedoraproject.org/pub/epel/6/x86_64/libconfuse-2.7-4.el6.x86_64.rpm -P /opt/ganglia &&\
	wget https://dl.fedoraproject.org/pub/epel/6/x86_64/libconfuse-devel-2.7-4.el6.x86_64.rpm -P /opt/ganglia &&\
	touch /var/lib/rpm/* &&\
	yum install -y /opt/ganglia/*.rpm


RUN curl -o /opt/ganglia/ganglia-3.7.2.tar.gz https://cytranet.dl.sourceforge.net/project/ganglia/ganglia%20monitoring%20core/3.7.2/ganglia-3.7.2.tar.gz &&\
	rpmbuild -tb /opt/ganglia/ganglia-3.7.2.tar.gz &&\
	touch /var/lib/rpm/* &&\
	yum install -y /root/rpmbuild/RPMS/x86_64/*.rpm

RUN wget https://cytranet.dl.sourceforge.net/project/ganglia/ganglia-web/3.7.2/ganglia-web-3.7.2.tar.gz -P /opt/ganglia &&\
	pushd /opt/ganglia &&\
	tar zxvf ganglia-web-3.7.2.tar.gz
RUN cd /opt/ganglia/ganglia-web-3.7.2 &&\
	sed -i 's%GDESTDIR = /usr/share/ganglia-webfrontend%GDESTDIR = /var/www/html/ganglia%g' Makefile  &&\
	sed -i 's%APACHE_USER = www-data%APACHE_USER = root%g' Makefile &&\
	touch /var/lib/rpm/* &&\
	make install &&\
	chmod -R a+w /var/lib/ganglia-web/dwoo


RUN sed -i 's%owner = "unspecified"%owner = "DSS"%g' /etc/ganglia/gmond.conf &&\
	sed -i '50c  host = gmetad' /etc/ganglia/gmond.conf &&\
	sed -i '57d' /etc/ganglia/gmond.conf &&\
	sed -i 's%bind = 239.2.11.71%bind = 0.0.0.0%g' /etc/ganglia/gmond.conf &&\
	sed -i 's%user = nobody%user = root%g' /etc/ganglia/gmond.conf &&\
	sed -i '73,$d' /etc/ganglia/gmond.conf

RUN sed -i 's%# setuid_username "nobody"%setuid_username "root"%g' /etc/ganglia/gmetad.conf &&\
	chown -R root:root /var/lib/ganglia/ &&\
	chown -R root:root /var/lib/ganglia-web/

RUN echo "sed -i 's/location = \"unspecified\"/location = \"'"\$LOCATION"'\"/g' /etc/ganglia/gmond.conf" > /opt/ganglia/start_gmetad.sh &&\
	echo "sed -i 's/name = \"unspecified\"/name = \"'"\$CLUSTER_NAME"'\"/g' /etc/ganglia/gmond.conf" >> /opt/ganglia/start_gmetad.sh &&\
	echo "sed -i 's%^data_source.*$%data_source \"'"\$CLUSTER_NAME"'\" 10 gmetad%g' /etc/ganglia/gmetad.conf" >> /opt/ganglia/start_gmetad.sh &&\
	echo "sed -i 's%^# gridname.*$%gridname \"'"\$GRID_NAME"'\"%g' /etc/ganglia/gmetad.conf" >> /opt/ganglia/start_gmetad.sh &&\
	echo "sed -i 's%^Listen.*$%Listen '"\$HTTP_PORT"'%g' /etc/httpd/conf/httpd.conf" >> /opt/ganglia/start_gmetad.sh &&\
	echo "service gmond restart" >> /opt/ganglia/start_gmetad.sh &&\
	echo "service gmetad restart" >> /opt/ganglia/start_gmetad.sh &&\
	echo "service httpd restart" >> /opt/ganglia/start_gmetad.sh &&\
	echo "sleep 100000d" >> /opt/ganglia/start_gmetad.sh &&\
	chmod a+x /opt/ganglia/start_gmetad.sh


WORKDIR /opt/ganglia

CMD ["sh", "/opt/ganglia/start_gmetad.sh"]