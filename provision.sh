docker load -i /vagrant/rancher.tar 
docker run --privileged -d --restart=unless-stopped -p 80:80 -p 443:443 rancher/rancher