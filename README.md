# dxlAPRS_LoRa_iGate
dxlAPRS Internet Gateway for LoRa with RTL-SDR

### Unpack  :

```
  git clone https://github.com/DO2JMG/dxlAPRS_LoRa_iGate.git
  cd dxlAPRS_LoRa_iGate
```

### Create folders and permissions  :

```
  mkdir bin
  mkdir fifos
  mkdir pidfiles
```
```
  sudo chmod +x lora.sh
```

### Download dxlAPRS  :

```
  cd bin
  wget http://oe5dxl.hamspirit.at:8025/aprs/bin/armv7hf/lorarx
  wget http://oe5dxl.hamspirit.at:8025/aprs/bin/armv7hf/udpgate4
  wget http://oe5dxl.hamspirit.at:8025/aprs/bin/armv7hf/sdrtst
```

Permissions

```
  cd bin
  sudo chmod +x lorarx
  sudo chmod +x udpgate4
  sudo chmod +x sdrtst
```
```
  cd ..
```
### Settings  :
  Change your call and passcode in lora-options.conf

```
  nano lora-options.conf
```

  Change your beacon message in beacon.txt
```
  nano beacon.txt
```
  
### Run  :

Start

  ```
    ./lora.sh
  ```
Stop

  ```
  ./lora.sh stop
  ```
