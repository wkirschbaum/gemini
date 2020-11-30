defmodule Gemini.Server do
  use Task, restart: :permanent

  require Logger

  def start_link(arg) do
    Task.start_link(__MODULE__, :listen, [arg])
  end

  def listen(arg) do
    port = Keyword.get(arg, :port, 1965)

    {:ok, listen_socket} =
      :ssl.listen(port, [:binary, :inet6, certfile: "certificate.pem", keyfile: "key.pem", packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")

    accept_connections(listen_socket)
  end

  defp accept_connections(listen_socket) do
    case  :ssl.transport_accept(listen_socket) do
      {:ok, socket} ->
        {:ok, pid} =
          Task.Supervisor.start_child(
            Gemini.RequestSupervisor,
            fn ->
              Logger.debug("Connection opened")
              :ok = :ssl.ssl_accept(socket)
              serve_connection(socket)
            end
          )

        :ssl.controlling_process(socket, pid)
      {:error, error} ->
        Logger.error(IO.inspect error)
    end

    accept_connections(listen_socket)
  end

  defp serve_connection(socket) do
    case :ssl.recv(socket, 0) do
      {:ok, data} ->
        Logger.info(IO.inspect data)
        status = "20"
        meta = "text/plain; charset=utf-8"
        body = "Hello, World!"

        result = "#{status} #{meta}\r\n#{body}"

        Logger.info(IO.inspect result)

        :ssl.send(socket, result)
      {:error, :closed} ->
        Logger.debug("Connection closed")
    end
  end
end
