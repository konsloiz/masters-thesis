ARG IMAGE_TYPE="cpu"
FROM jupyter/pyspark-notebook:ubuntu-18.04

USER root

RUN touch /etc/apt/apt.conf.d/99verify-peer.conf \
&& echo >>/etc/apt/apt.conf.d/99verify-peer.conf "Acquire { https::Verify-Peer false }"



# Install basic dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates bash-completion tar less \
        python-pip python-setuptools build-essential python-dev \
        python3-pip python3-wheel && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get install -y git

ENV SHELL /bin/bash
COPY bashrc /etc/bash.bashrc
RUN echo "set background=dark" >> /etc/vim/vimrc.local

#RUN pip3 install jupyterlab-gitlab==2.0.0
# Install latest KFP SDK
RUN pip3 freeze
RUN pip3 install --upgrade pip && \
    # XXX: Install enum34==1.1.8 because other versions lead to errors during
    #  KFP installation
    pip3 install --upgrade "enum34==1.1.8" && \
    pip3 install jupyterlab-gitlab==2.0.0 && \
    pip3 install --upgrade "jupyterlab>=2.0.0,<3.0.0"

#Install libraries for the demo
RUN pip3 install --upgrade pip && \
    pip3 install pillow==7.2.0 && \
    pip3 install tensorflow==2.3.0 && \
    pip3 install matplotlib==3.3.1 && \
    pip3 install torch &&\
    pip3 install torchvision

# Install Kale from KALE_BRANCH (defaults to "master")
ARG KALE_BRANCH="master"
WORKDIR /
RUN git config --global http.sslverify false
RUN git clone -b ${KALE_BRANCH} https://github.com/kubeflow-kale/kale

WORKDIR /kale/backend
RUN pip3 install --upgrade .

WORKDIR /kale/labextension
RUN npm config set strict-ssl false && \
    npm install --global yarn && \
    yarn config set "strict-ssl" false && \
    jlpm install && \
    jlpm run build && \
    jupyter labextension install .

#RUN pip install jupyterlab jupyterlab-git
RUN jupyter labextension install @jupyterlab/git
RUN pip3 install jupyterlab-git==0.24.0
RUN jupyter lab build

# RUN jupyter lab build --dev-build=False

USER ${NB_UID}
WORKDIR "${HOME}"
