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
