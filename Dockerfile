FROM centos
RUN yum update -y
RUN yum install git -y
RUN yum install net-tools -y
RUN mkdir /opt/dummy
RUN git clone https://github.com/ops-school/session-monitoring /opt/dummy/
WORKDIR /opt/dummy/training_session/
CMD ["python", "my_dummy_exporter.py"]