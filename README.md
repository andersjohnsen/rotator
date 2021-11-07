# Toit rotator

A little Toit experiment to validate correctness and of an AHRS algorithm, as well as responsiveness. The orientation is broadcasted on the network using UDP.

The code is running on an ESP32 using the ICM20948 9-axis chip.

The main loop, running at 100Hz, is simply reading the latest accel/gyro and updating the AHRS algorithm.

```c#
  every UPDATE_RATE:
    accel := to_vector3 driver.read_accel
    gyro := to_vector3 driver.read_gyro

    madgwick.update_imu
      gyro * RAD_PER_DEG
      accel
      UPDATE_RATE
```

The network part is running in a different task, sending the 4 Quaternion parts on the UDP broadcast socket. Here the update rate is 20Hz.

```c#
  task::
    every BROADCAST_RATE:
      rotation := madgwick.rotation
      data := json.encode {
        "x": rotation.x,
        "y": rotation.y,
        "z": rotation.z,
        "w": rotation.w,
      }
      socket.send
        udp.Datagram data BROADCAST_ADDRESS
```


## Viewer

I made a small Unity3D viewer. It allowed me to, in real time, change orientation and validate that the orientation is as expected:

![Unity3D Viewer](https://user-images.githubusercontent.com/22043/140651576-6fdc41be-0ba1-4f5a-afe6-c34f01a66d3e.gif)

### Code

The Unity3D C# code is added here for convenience.

```C#
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using System.Threading;
using System.Net;
using System.Net.Sockets;
using System.Text;

[Serializable]
public class Rotation
{
    public float x;
    public float y;
    public float z;
    public float w;
}

public class UDPRotation : MonoBehaviour
{
    UdpClient client;
    Rotation rotation = new Rotation();

    public int port = 13280;

    // Start is called before the first frame update
    void Start()
    {
        // create thread for reading UDP messages
        Thread readThread = new Thread(new ThreadStart(ReceiveData));
        readThread.IsBackground = true;
        readThread.Start();
    }

    // Update is called once per frame
    void Update()
    {
        // Transform to the correct coordinate space (note z and y is swapped, z is negated).
        transform.rotation = new Quaternion(
            rotation.x,
            -rotation.z,
            rotation.y,
            rotation.w);
    }

    // Unity Application Quit Function
    void OnApplicationQuit()
    {
        client.Close();
    }

    // receive thread function
    private void ReceiveData()
    {
        client = new UdpClient();
        client.Client.Bind(new IPEndPoint(IPAddress.Any, port));
        while (true)
        {  
            IPEndPoint anyIP = new IPEndPoint(0, 0);
            byte[] data = client.Receive(ref anyIP);
            rotation = JsonUtility.FromJson<Rotation>(Encoding.UTF8.GetString(data));
        }
    }
}
```
