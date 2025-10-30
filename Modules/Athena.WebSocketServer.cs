// ====================================================================
// 🧠 Athena.WebSocketServer.cs
// Version : 1.0 – Native WebSocket Server for Athena Bridge
// Auteur  : Projet Ariane V4 / Athena Core
// ====================================================================

using System;
using System.Net;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Athena.WebSocketServer
{
    class Program
    {
        static async Task Main(string[] args)
        {
            int port = 49392;
            if (args.Length > 0 && int.TryParse(args[0], out int parsed))
                port = parsed;

string url = $"http://+:{port}/";

            Console.Title = $"Athena.WebSocketServer – {url}";

            HttpListener listener = new HttpListener();
            listener.Prefixes.Add(url);
            listener.Start();

            Console.WriteLine($"[INFO] 🚀 Serveur WebSocket actif sur ws://localhost:{port}/");
            Console.WriteLine($"[INFO] En attente de connexions clients...\n");

            while (true)
            {
                try
                {
                    HttpListenerContext context = await listener.GetContextAsync();

                    if (context.Request.IsWebSocketRequest)
                    {
                        _ = HandleWebSocketClient(context);
                    }
                    else
                    {
                        context.Response.StatusCode = 400;
                        byte[] buffer = Encoding.UTF8.GetBytes("WebSocket only");
                        context.Response.OutputStream.Write(buffer, 0, buffer.Length);
                        context.Response.Close();
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[ERROR] {ex.Message}");
                    Thread.Sleep(1000);
                }
            }
        }

        private static async Task HandleWebSocketClient(HttpListenerContext context)
        {
            try
            {
                HttpListenerWebSocketContext wsContext = await context.AcceptWebSocketAsync(null);
                WebSocket webSocket = wsContext.WebSocket;
                Console.WriteLine($"[+] Client connecté : {context.Request.RemoteEndPoint}");

                byte[] buffer = new byte[1024 * 4];
                while (webSocket.State == WebSocketState.Open)
                {
                    var result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), CancellationToken.None);

                    if (result.MessageType == WebSocketMessageType.Close)
                    {
                        await webSocket.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closed", CancellationToken.None);
                        Console.WriteLine("[-] Client déconnecté.");
                    }
                    else
                    {
                        string msg = Encoding.UTF8.GetString(buffer, 0, result.Count);
                        Console.WriteLine($"📩 {msg}");
                        string response = $"Bridge ACK: {msg}";
                        byte[] reply = Encoding.UTF8.GetBytes(response);
                        await webSocket.SendAsync(new ArraySegment<byte>(reply), WebSocketMessageType.Text, true, CancellationToken.None);
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[ERROR] Client : {ex.Message}");
            }
        }
    }
}
