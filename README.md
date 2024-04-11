# LiveKit-Ecojourneys

This repository contains a deployment configuration(s) for using a LAN deployed livekit with EcoJourneys.


## Implementation
For this we created domains and generated certificates for them in an EC2 instance, ported the certificates to the local machine, hosted a local DNS server with `dnsmasq` and finally created a LAN deployed livekit-ecojourneys integration.


