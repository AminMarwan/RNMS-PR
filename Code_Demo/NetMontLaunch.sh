#!/bin/bash/
echo "------------------------------------Launching the Network Monitor------------------------------------"
cd
cd NetMonitor
sudo systemctl daemon-reload #reload the configuration of the system and apply the new changes 

echo "------------------Starting Node-Exporter------------------"
sudo systemctl enable node_exporter  #enables node-exporter service
sudo systemctl start node_exporter.service #starts node-exporter service
#sudo systemctl status node_exporter #Check the status of node-exporter

#http://localhost:9200/metrics
#to verify

echo "------------------Starting SNMP-Exporter------------------"
sudo systemctl enable snmp-exporter   #enables snmp service
sudo systemctl start snmp-exporter  #starts snmp service
#sudo systemctl status snmp-exporter #to check for snmp status (remove '#')

echo "------------------Starting BlackBox-Exporter------------------"
cd 
cd NetMonitor
sudo systemctl enable blackbox.service #enables blackbox-exporter service
sudo systemctl start blackbox.service #starts blackbox-exporter service
#sudo systemctl status blackbox.service #Check the status of blackbox.service
#curl http://localhost:9115/metrics  #to check the metrics gathered by issuing a request to the HTTP API

echo "------------------Starting Grafana------------------"
cd
sudo systemctl enable grafana-server #Enable grafana 
sudo systemctl start grafana-server #Start grafana
#sudo systemctl status grafana-server #Check the status of grafana

echo "------------------Starting Prometheus------------------"
cd
cd NetMonitor/prometheus-2.51.1.linux-arm64
#xdg-open http://localhost/   #to open the website
./prometheus              #Execute this command to start prometheus then Ctrl+c to stop it
#http://localhost:9090

echo "---------------------------Network Monitor Terminated!------------------------------"
