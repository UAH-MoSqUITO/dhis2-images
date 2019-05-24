# Miscellaneous notes

## References

* Original Packer template from [Getting started](https://www.packer.io/intro/getting-started/build-image.html#the-template)
* AWS permissions from [builder docs](https://www.packer.io/docs/builders/amazon.html#iam-task-or-instance-role)

## AWS setup

* Add [policy](`aws-policy.json`)
* Add IAM role (or group or user), and attach policy

TODO: shutdown after idle? Maybe have web page that user refreshes to reset timer?

```console
$ ec2metadata 
ami-id: ami-08f3798e5da1a43c4
ami-launch-index: 0
ami-manifest-path: (unknown)
ancestor-ami-ids: unavailable
availability-zone: us-west-2b
block-device-mapping: ami
root
instance-action: none
instance-id: i-█████████████████
instance-type: t2.micro
local-hostname: ip-███-███-███-███.us-west-2.compute.internal
local-ipv4: ███.███.███.███
kernel-id: unavailable
mac: unavailable
profile: default-hvm
product-codes: unavailable
public-hostname: ec2-███-███-███-███.us-west-2.compute.amazonaws.com
public-ipv4: ███.███.███.███
public-keys: ['ssh-rsa AAAA... █████████']
ramdisk-id: unavailable
reserveration-id: unavailable
security-groups: ████████████████
user-data: unavailable
```

## Ubuntu TLS

### ssl-cert snakeoil certificate

```shell
sudo apt install ssl-cert
```

```console
$ openssl x509 -in /etc/ssl/certs/ssl-cert-snakeoil.pem -noout -subject -issuer -dates
subject=CN = ip-███-███-███-███.us-west-2.compute.internal
issuer=CN = ip-███-███-███-███.us-west-2.compute.internal
notBefore=Apr 29 12:22:28 2019 GMT
notAfter=Apr 26 12:22:28 2029 GMT
```
Key is `/etc/ssl/private/ssl-cert-snakeoil.key`

### manual self-signed certificate for localhost

```shell
sudo openssl req -x509 -newkey rsa:4096 -keyout /etc/ssl/private/localhost.key.pem -out /etc/ssl/private/localhost.cert.pem -days 365 -nodes -subj /CN=localhost
sudo cat /etc/ssl/private/localhost.{cert,key}.pem | sudo tee /etc/ssl/private/localhost.cert+key.pem > /dev/null
```

### haproxy reverse proxy

```shell
sudo apt install haproxy
```

Ciphers and HSTS from: https://mozilla.github.io/server-side-tls/ssl-config-generator/?server=haproxy-1.8.0&openssl=1.1.0g&hsts=yes&profile=modern

```console
$ cat /etc/haproxy/test.cfg
global
    ssl-default-bind-ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256
    ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11 no-tls-tickets
    ssl-default-server-ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256
    ssl-default-server-options no-sslv3 no-tlsv10 no-tlsv11 no-tls-tickets

listen x
    mode http
    bind :443 ssl crt localhost.cert+key.pem
    bind :80
    redirect scheme https code 301 if !{ ssl_fc }
    http-response set-header Strict-Transport-Security max-age=15768000
    option forwardfor
    http-request set-header X-Forwarded-Port %[dst_port]
    http-request set-header X-Forwarded-Proto https if { ssl_fc }
    http-request set-header X-Forwarded-Host %[req.hdr(Host)]
    server tomcat 127.0.0.1:8080
```

```console
$ grep CONFIG /etc/default/haproxy
#CONFIG="/etc/haproxy/haproxy.cfg"
CONFIG="/etc/haproxy"

$ sudo haproxy -f /etc/haproxy -c
Configuration file is valid

$ sudo systemctl restart haproxy
```

### how to generate localhost certificate

Maybe hook into systemd dependency chain?

```
[Unit]
Description=...
After=network.target

[Service]
Type=oneshot
ExecStart=...
RemainAfterExit=true

[Install]
WantedBy=haproxy.service
```


## Clean packer instance before saving as AMI

https://gist.github.com/jdowning/5921369

* Clean Apt
* Remove SSH keys (authorized keys)
* Cleanup log files
* Cleanup bash history

http://docs.amazonaws.cn/en_us/AWSEC2/latest/UserGuide/building-shared-amis.html

* Update the AMI Tools Before Using Them
* Disable Password-Based Remote Logins for Root
* Disable Local Root Access
* Remove SSH Host Key Pairs
* Install Public Key Credentials ("Many distributions, including Amazon Linux and Ubuntu, use the `cloud-init` package to inject public key credentials for a configured user.")
* Disabling sshd DNS Checks (Optional)

[What should I include in an Amazon Machine Image (AMI)?](https://aws.amazon.com/answers/configuration-management/aws-ami-design/)
![Fully-baked, Hyrbid, JeOS AMIs](https://d1.awsstatic.com/aws-answers/answers-images/ami-design-tradeoff.fc1a6d4fd21bd3ba1bf5b76477b28aa4d0de3a0d.png)
