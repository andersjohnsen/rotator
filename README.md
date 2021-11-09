# Toit rotator

A little Toit experiment to validate correctness and of an AHRS algorithm, as well as responsiveness. The orientation is broadcasted on the network using UDP.

The code is running on an ESP32 using the ICM20948 9-axis chip.

## Viewer

I made a small Unity3D viewer. It allowed me to, in real time, change orientation and validate that the orientation is as expected:

![Unity3D Viewer](https://user-images.githubusercontent.com/22043/140651576-6fdc41be-0ba1-4f5a-afe6-c34f01a66d3e.gif)


## Details

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

