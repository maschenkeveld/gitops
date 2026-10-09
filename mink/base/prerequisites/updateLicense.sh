kubectl -n kong-mesh-system create secret generic kong-mesh-license \
--from-file=license=license \
--save-config --dry-run=client -o yaml > license.yaml

yq eval 'del(.metadata.annotations)' license.yaml | yq eval 'del(.metadata.creationTimestamp)' > license.yaml.new
rm license.yaml
mv license.yaml.new license.yaml