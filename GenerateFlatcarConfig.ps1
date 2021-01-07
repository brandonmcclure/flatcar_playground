param ($numOfHosts
	, $namePrefix
	, $discoveryToken = ''
	, $gatewayAddress = ''
	, $DNSAddress = '192.168.0.10'
	, $installDevice = '/dev/sda'
	, $targetVersion = '2512.4.0'
	, $flatCarMirrorURL = '192.168.0.10'
	,$baseIP = '192.168.0.10'
	,$bootstrapIP = '192.168.0.2'
	,$oem = 'hyperv'
)

Import-module powershell-yaml

$template = Get-Content $PSScriptRoot\template.yml | ConvertFrom-Yaml

foreach ($hostConfig in 1..$numOfHosts) {
	$HostName = "$namePrefix$hostConfig"
	$localIPAddress = "$baseIP$hostConfig"
	$outFile = $template

	foreach ($file in $outFile.storage.files ) {
		if ($file.Path -eq '/etc/hostname') {
			$file.Contents.inline = $HostName
		}
	}
	$outFile.etcd.listen_peer_urls = "http://$($localIPAddress):2380"
	$outFile.etcd.initial_advertise_peer_urls = "http://$($localIPAddress):2380"
	$outFile.etcd.advertise_client_urls = "http://$($localIPAddress):2379,http://$($localIPAddress):4001"
	$outFile.etcd.listen_client_urls = "http://0.0.0.0:2379,http://0.0.0.0:4001"
	$outFile.etcd.name = $HostName
	$outFile.etcd.discovery = "http://$($localIPAddress):8087/$discoveryToken"

	foreach ($unit in $outFile.networkd.units) {
		if ($unit.Name -eq '10.static.network') {
			$unit.contents = "
		[Match]
		Name=en*
  
		[Network]
		Address=$($localIPAddress)/24
		Gateway=$($gatewayAddress)
		DNS=$($DNSAddress)"
		}
	}
	ConvertTo-Yaml -Data $outFile | Set-Content "$PSScriptRoot\$HostName.yml"

	ConvertTo-Yaml -Data $outFile | docker run --rm -i -v ${PWD}:/src quay.io/coreos/ct:latest --in-file /src/$HostName.yml --out-file /src/$HostName.json
	# Generate install.sh
	"flatcar-install -i /mnt/installer/$HostName.json -b $flatCarMirrorURL/amd64-usr -V $targetVersion -d $installDevice $(if (-not [string]::IsNullOrEmpty($oem)){"-o $oem"})" | Set-Content "$PSScriptRoot\$($HostName)Install.sh"
}

#Generate bootstrap.sh
"docker run -d \
-p 4001:4001 -p 2380:2380 -p 2379:2379 \
--name etcd quay.io/coreos/etcd \
etcd \
-name etcd0 \
-advertise-client-urls http://$($bootstrapIP):2379,http://$($bootstrapIP):4001 \
-listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
-initial-advertise-peer-urls http://$($bootstrapIP):2380 -listen-peer-urls http://0.0.0.0:2380 \
-initial-cluster-token etcd-cluster-1 \
-initial-cluster etcd0=http://$($bootstrapIP):2380 \
-initial-cluster-state new

sudo docker run -d \
--net=host discoveryserver /discoveryserver \
--etcd http://$($bootstrapIP):2379 \
--addr $($bootstrapIP):8087 \
--host http://discovery.etcd.cogito.test

sudo docker run -d \
--name mirror_stable \
-e PORT=8080 \
-e folder=/var/www/ \
-p 8080:8080 \
-v /mnt/usb/mountPoints/flatcar/stable:/var/www/ \
halverneus/static-file-server
" | Set-Content "$PSScriptRoot\bootstrapserver.sh"

