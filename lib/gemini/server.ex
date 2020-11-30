defmodule Gemini.Server do
  use Task, restart: :permanent

  require Logger

  def start_link(arg) do
    Task.start_link(__MODULE__, :listen, [arg])
  end

  def listen(arg) do
    port = Keyword.get(arg, :port, 1965)

    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")

    accept_connections(socket)
  end

  defp accept_connections(listen_socket) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, socket} ->
        {:ok, pid} =
          Task.Supervisor.start_child(
            Gemini.RequestSupervisor,
            fn ->
              Logger.debug("Connection opened")
              serve_connection(socket)
            end
          )

        :ok = :gen_tcp.controlling_process(socket, pid)
      {:error, error} ->
        Logger.error(IO.inspect error)
    end

    accept_connections(listen_socket)
  end

  defp serve_connection(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        Logger.info(data)
        case data do
          "\r\n" ->
            Logger.debug("End of message")
          "\n" ->
            Logger.debug("End of message")
          data ->
            write_line(data, socket)
            serve_connection(socket)
        end
      {:error, :closed} ->
        Logger.debug("Connection closed")
    end
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end
end
