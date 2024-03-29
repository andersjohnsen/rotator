import net
import i2c
import gpio
import icm20948
import math
import net.udp
import ahrs.madgwick as ahrs
import math3d
import encoding.json

BROADCAST_ADDRESS ::= net.SocketAddress
  net.IpAddress.parse "255.255.255.255"
  13280

UPDATE_RATE ::= Duration --ms=10
BROADCAST_RATE ::= Duration --ms=50
RAD_PER_DEG  ::= math.PI / 180.0

main:
  bus := i2c.Bus
    --sda=gpio.Pin 21
    --scl=gpio.Pin 22


  driver := icm20948.Driver
    bus.device icm20948.I2C_ADDRESS_ALT

  driver.on
  driver.configure_accel --scale=icm20948.ACCEL_SCALE_16G
  driver.configure_gyro --scale=icm20948.GYRO_SCALE_2000DPS

  madgwick ::= ahrs.Madgwick

  network := net.open
  socket := network.udp_open
  socket.broadcast = true

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

  every UPDATE_RATE:
    accel := to_vector3 driver.read_accel
    gyro := to_vector3 driver.read_gyro

    madgwick.update_imu
      gyro * RAD_PER_DEG
      accel
      UPDATE_RATE


every interval/Duration [block]:
  next := Time.monotonic_us
  while true:
    next += interval.in_us
    sleep --ms=(next - Time.monotonic_us) / 1000

    block.call

to_vector3 p/math.Point3f -> math3d.Vector3:
  return math3d.Vector3 p.x p.y p.z
