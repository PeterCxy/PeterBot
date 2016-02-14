FROM base/archlinux:2015.06.01
MAINTAINER Peter Cai "peter@typeblog.net"

# Use Rackspace's mirror
RUN echo -e 'Server = http://mirror.rackspace.com/archlinux/$repo/os/$arch\nServer = http://mirrors.kernel.org/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist

# Do an update
RUN pacman -Syyu --noconfirm

# Install dependencies
RUN pacman -S --noconfirm nodejs npm coffee-script git

# Initialize the environment
WORKDIR /usr/src/bot
ENV TAG=rel.7
RUN git clone -b ${TAG} --depth 1 https://github.com/PeterCxy/PeterBot.git . && \
  npm install

# Finalize
CMD ["npm", "start"]
